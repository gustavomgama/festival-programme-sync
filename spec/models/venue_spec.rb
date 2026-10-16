require "rails_helper"

RSpec.describe Venue do
  before do
    Screening.delete_all
    Venue.delete_all
  end

  it "requires an external id and name" do
    expect(build(:venue, external_id: nil)).not_to be_valid
    expect(build(:venue, name: nil)).not_to be_valid
  end

  it "enforces unique external ids" do
    create(:venue, external_id: "VEN-01")
    expect(build(:venue, external_id: "VEN-01")).not_to be_valid
  end
end
