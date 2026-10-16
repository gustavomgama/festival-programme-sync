require "rails_helper"

RSpec.describe Screening do
  it "requires an external id, film, venue and start time" do
    expect(build(:screening, external_id: nil)).not_to be_valid
    expect(build(:screening, film: nil)).not_to be_valid
    expect(build(:screening, venue: nil)).not_to be_valid
    expect(build(:screening, starts_at: nil)).not_to be_valid
  end

  it "enforces unique external ids" do
    create(:screening, external_id: "SCR-0001")
    expect(build(:screening, external_id: "SCR-0001")).not_to be_valid
  end
end