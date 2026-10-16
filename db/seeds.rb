
sample = MockApi::Dataset.generation_one.first(20)

sample.each do |record|
  film = Film.find_or_initialize_by(external_id: record["film"]["id"])
  film.update!(
    title:    record["film"]["title"],
    synopsis: record["film"]["synopsis"],
    runtime:  record["film"]["runtime"],
    year:     record["film"]["year"]
  )

  venue = Venue.find_or_initialize_by(external_id: record["venue"]["id"])
  venue.update!(
    name:     record["venue"]["name"],
    address:  record["venue"]["address"],
    capacity: record["venue"]["capacity"]
  )

  screening = Screening.find_or_initialize_by(external_id: record["id"])
  screening.update!(
    film:      film,
    venue:     venue,
    starts_at: record["starts_at"],
    status:    record["status"]
  )
end

puts "Seeded #{Screening.count} screenings across #{Film.count} films and #{Venue.count} venues."
