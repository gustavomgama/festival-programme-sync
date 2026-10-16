require "rails_helper"

RSpec.describe ProgrammeSync do
  before do
    Screening.delete_all
    Venue.delete_all
    Film.delete_all
    SyncRun.delete_all
  end

  it "imports generation 1 and is idempotent on a second run" do
    first = described_class.call(generation: 1)
    expect(first.status).to eq("success")
    expect(first.fetched).to eq(60)
    expect(Film.count).to eq(12)
    expect(Venue.count).to eq(6)
    expect(Screening.count).to eq(60)

    second = described_class.call(generation: 1)
    expect(second.status).to eq("success")
    expect(second.created).to eq(0)
    expect(Screening.count).to eq(60)
  end

  it "applies all generation-2 mutations without duplicating records" do
    described_class.call(generation: 1)
    result = described_class.call(generation: 2)

    expect(result.status).to eq("success")
    expect(Screening.count).to eq(62)
    expect(Film.find_by(external_id: "FILM-005").title).to eq("Autumn in Trieste (Director's Cut)")
    expect(Venue.find_by(external_id: "VEN-03").name).to eq("City Gallery Auditorium")
    expect(Screening.find_by(external_id: "SCR-0001").venue.external_id).to eq("VEN-06")
    expect(Screening.find_by(external_id: "SCR-0010").status).to eq("cancelled")
    expect(Screening.exists?(external_id: "SCR-0060")).to be(true)
    expect(Screening.exists?(external_id: "SCR-0061")).to be(true)
    expect(Screening.where(external_id: "SCR-0061").count).to eq(1)
  end

  it "keeps records fetched before a partial API failure" do
    result = described_class.call(generation: 1, fail_after: 8)

    expect(result.status).to eq("partial_failure")
    expect(result.fetched).to eq(8)
    expect(result.errors).not_to be_empty
    expect(Screening.count).to eq(8)
    expect(SyncRun.last.partially_failed?).to be(true)
  end
  it "records a skipped run when another sync is already running" do
    SyncRun.create!(status: "running", started_at: Time.current, generation: 1)

    result = described_class.call(generation: 1)

    expect(result.status).to eq("skipped")
    expect(result.fetched).to eq(0)
  end

  it "captures malformed API responses without raising" do
    sync = described_class.new(generation: 1)
    allow(sync).to receive(:fetch_page).and_return(described_class::ApiResponse.new(200, "{not json"))

    result = sync.call

    expect(result.status).to eq("failed")
    expect(result.errors.join).to match(/JSON::ParserError|not a JSON object/)
    expect(SyncRun.last.status).to eq("failed")
  end

  it "captures per-record errors and continues importing the rest" do
    sync = described_class.new(generation: 1)
    response = described_class::ApiResponse.new(
      200,
      {
        page: 1,
        total_pages: 1,
        screenings: [
          { "id" => "SCR-BAD", "film" => { "id" => "FILM-BAD" }, "venue" => { "id" => "VEN-BAD" }, "starts_at" => "not-a-time", "status" => "scheduled" },
          mock_api_screening
        ]
      }.to_json
    )
    allow(sync).to receive(:fetch_page).and_return(response)

    result = sync.call

    expect(result.failed).to eq(1)
    expect(result.fetched).to eq(2)
    expect(result.errors.join).to include("SCR-BAD")
  end

  def mock_api_screening
    {
      "id" => "SCR-OK",
      "starts_at" => "2027-03-06T16:00:00Z",
      "status" => "scheduled",
      "film" => { "id" => "FILM-OK", "title" => "OK Film", "synopsis" => nil, "runtime" => 90, "year" => 2027 },
      "venue" => { "id" => "VEN-OK", "name" => "OK Venue", "address" => "Addr", "capacity" => 10 }
    }
end
end
