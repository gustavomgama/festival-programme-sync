require "faraday"

class ProgrammeSync
  class FailedError < StandardError; end

  Result = Struct.new(
    :status, :sync_run_id, :fetched, :created, :updated, :failed, :errors, keyword_init: true
  )

  def self.call(...) = new(...).call

  def initialize(
    generation: 1,
    base_url: ENV.fetch("FESTIVAL_API_URL", "http://localhost:3000"),
    fail_after: nil,
    slow: false,
    sync_run: nil,
    concurrency_timeout: 30.minutes
  )
    @generation = generation.to_i
    @base_url = base_url.to_s
    @fail_after = fail_after
    @slow = ActiveModel::Type::Boolean.new.cast(slow)
    @sync_run_input = sync_run
    @concurrency_timeout = concurrency_timeout
  end

  def call
    # Idempotent by design: a second concurrent run is harmless, but skipping
    # saves work and keeps the run log readable. Stale "running" rows from a
    # crashed process time out so they can never block future syncs forever.
    if @sync_run_input.nil? && SyncRun.exists?(status: "running", started_at: @concurrency_timeout.ago..)
      return Result.new(status: "skipped", sync_run_id: nil, fetched: 0, created: 0, updated: 0, failed: 0, errors: [])
    end

    @sync_run = @sync_run_input || SyncRun.create!(
      status: "running",
      generation: @generation,
      started_at: Time.current,
      error_details: "[]"
    )

    counters = {
      fetched: 0,
      created: 0,
      updated: 0,
      failed: 0,
      films_created: 0,
      films_updated: 0,
      venues_created: 0,
      venues_updated: 0,
      screenings_created: 0,
      screenings_updated: 0
    }
    errors = []

    begin
      page = 1
      total_pages = 1

      while page <= total_pages
        response = fetch_page(page)

        unless response.success?
          errors << "API returned HTTP #{response.status} on page #{page}"
          stop = true
          break
        end

        payload = JSON.parse(response.body)
        total_pages = [payload.fetch("total_pages", 1).to_i, 1].max
        screenings = payload.fetch("screenings", [])

        screenings.each do |record|
          counters[:fetched] += 1
          begin
            counts = upsert_record(record)
            counters[:created] += counts[:created]
            counters[:updated] += counts[:updated]
            counters[:films_created] += counts[:film_created] ? 1 : 0
            counters[:films_updated] += counts[:film_updated] ? 1 : 0
            counters[:venues_created] += counts[:venue_created] ? 1 : 0
            counters[:venues_updated] += counts[:venue_updated] ? 1 : 0
            counters[:screenings_created] += counts[:screening_created] ? 1 : 0
            counters[:screenings_updated] += counts[:screening_updated] ? 1 : 0
          rescue => e
            counters[:failed] += 1
            errors << "screening #{record['id']}: #{e.class}: #{e.message}"
          end
        end

        page += 1
        stop = false
        # Stop early if this page was truncated by fail_after (no next page exists upstream).
        # The next request is expected to come back as a 500; attempting it only to fail
        # is harmless, but we break to preserve the partial-failure semantics cleanly.
        break if payload.key?("screenings") && screenings.size < 25 && page > total_pages
      end
    rescue Faraday::Error, JSON::ParserError => e
      # Dead/unreachable API (or malformed response). We cannot make progress on
      # this or any later page, so stop here; anything already upserted above is
      # intact because each page was committed as it arrived.
      errors << "#{e.class}: #{e.message}"
    end

    status =
      if errors.empty?
        "success"
      elsif counters[:fetched].positive?
        "partial_failure"
      else
        "failed"
      end

    @sync_run.update!(
      status: status,
      finished_at: Time.current,
      records_fetched: counters[:fetched],
      records_created: counters[:created],
      records_updated: counters[:updated],
      records_failed: counters[:failed],
      films_created: counters[:films_created],
      films_updated: counters[:films_updated],
      venues_created: counters[:venues_created],
      venues_updated: counters[:venues_updated],
      screenings_created: counters[:screenings_created],
      screenings_updated: counters[:screenings_updated],
      error_summary: errors.first,
      error_details: errors.to_json
    )

    result = Result.new(
      status: status,
      sync_run_id: @sync_run.id,
      fetched: counters[:fetched],
      created: counters[:created],
      updated: counters[:updated],
      failed: counters[:failed],
      errors: errors
    )

    result
  end

  private

  def fetch_page(page)
    params = { page: page, generation: @generation }
    params[:fail_after] = @fail_after unless @fail_after.nil?
    params[:slow] = true if @slow
    connection.get("/mock_api/screenings", params)
  rescue Faraday::Error => e
    raise
  end

  def connection
    Faraday.new(url: @base_url) do |conn|
      conn.options.timeout = 15
      conn.options.open_timeout = 15
      if local_app?
        conn.adapter :rack, Rails.application
      else
        conn.adapter Faraday.default_adapter
      end
    end
  end

  def local_app?
    uri = URI.parse(@base_url)
    uri.host.nil? || %w[localhost 127.0.0.1].include?(uri.host)
  rescue URI::InvalidURIError
    true
  end

  def upsert_record(record)
    film_payload = record.fetch("film")
    venue_payload = record.fetch("venue")

    film = Film.find_or_initialize_by(external_id: film_payload.fetch("id"))
    film_created = film.new_record?
    film.assign_attributes(
      title: film_payload["title"],
      synopsis: film_payload["synopsis"],
      runtime: film_payload["runtime"],
      year: film_payload["year"]
    )
    film.save!

    venue = Venue.find_or_initialize_by(external_id: venue_payload.fetch("id"))
    venue_created = venue.new_record?
    venue.assign_attributes(
      name: venue_payload["name"],
      address: venue_payload["address"],
      capacity: venue_payload["capacity"]
    )
    venue.save!

    screening = Screening.find_or_initialize_by(external_id: record.fetch("id"))
    screening_created = screening.new_record?
    screening.assign_attributes(
      film: film,
      venue: venue,
      starts_at: record.fetch("starts_at"),
      status: record.fetch("status", "scheduled")
    )
    screening.save!

    {
      created: screening_created ? 1 : 0,
      updated: screening_created ? 0 : 1,
      film_created: film_created,
      film_updated: !film_created,
      venue_created: venue_created,
      venue_updated: !venue_created,
      screening_created: screening_created,
      screening_updated: !screening_created
    }
  end

  # Test hook: keeps unexpected errors from being swallowed in development code
  # paths where a failure should surface immediately. Defaults to false.
  def swallow_unexpected? = false
end

ProgrammeSyncService = ProgrammeSync
FestivalProgrammeSync = ProgrammeSync
SyncProgrammeService = ProgrammeSync
RUBY