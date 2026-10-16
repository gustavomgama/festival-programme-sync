require "rails_helper"

RSpec.describe "Screenings", type: :request do
  before do
    ProgrammeSync.call(generation: 1)
  end

  it "filters by venue" do
    venue = Venue.order(:name).first
    get screenings_path, params: { venue_id: venue.id }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(venue.name)
  end

  it "filters by title text" do
    get screenings_path, params: { q: "Autumn" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Autumn in Trieste")
  end

  it "supports date filtering" do
    get screenings_path, params: { date: "2027-03-09" }
    expect(response).to have_http_status(:ok)
  end
end