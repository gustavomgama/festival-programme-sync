class ProgrammeSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(generation: 1, fail_after: nil, slow: false)
    lock_key = "programme_sync:execution_lock"
    acquired = true
    begin
      acquired = Sidekiq.redis { |conn| conn.set(lock_key, Time.now.to_f.to_s, nx: true, ex: 1800) != nil }
    rescue => e
      Rails.logger.warn("programme_sync.lock.unavailable: #{e.class}: #{e.message}")
      acquired = true
    end

    result =
      if acquired
        begin
          ProgrammeSync.call(generation: generation, fail_after: fail_after, slow: slow)
        ensure
          Sidekiq.redis { |conn| conn.del(lock_key) } if acquired
        end
      else
        ProgrammeSync::Result.new(status: "skipped", sync_run_id: nil, fetched: 0, created: 0, updated: 0, failed: 0, errors: ["another sync run is in progress"])
      end

    if result.status == "failed" && result.fetched.zero?
      raise ProgrammeSync::FailedError, (result.errors.join("; ").presence || "programme sync failed")
    end

    result
  end
end

SyncProgrammeJob = ProgrammeSyncJob
ProgrammeSyncWorker = ProgrammeSyncJob