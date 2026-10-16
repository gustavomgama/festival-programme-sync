require "rails_helper"

RSpec.describe Film do
  before do
    Screening.delete_all
    Film.delete_all
    Venue.delete_all
  end

  it "requires an external id and title" do
    expect(build(:film, external_id: nil)).not_to be_valid
    expect(build(:film, title: nil)).not_to be_valid
  end

  it "enforces unique external ids" do
    create(:film, external_id: "FILM-001")
    expect(build(:film, external_id: "FILM-001")).not_to be_valid
  end
end
