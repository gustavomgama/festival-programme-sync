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
end