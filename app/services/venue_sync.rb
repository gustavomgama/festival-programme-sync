class VenueSync
  def initialize(venues)
    @venues = venues
  end

  def call
    @venues.each do |attrs|
      venue = Venue.find_or_initialize_by(name: attrs["name"])
      venue.external_id = attrs.fetch("id")
      venue.address     = attrs["address"]
      venue.capacity    = attrs["capacity"]
      venue.save!
    end
  end
end
