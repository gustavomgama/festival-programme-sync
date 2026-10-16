# Festival Programme Sync

Rails 8 app that syncs film festival screenings from a mock external API and
renders a filtered screenings list.

## Run with Docker

```bash
docker compose up --build
```

- App: http://localhost:3000
- Sidekiq: http://localhost:3000/sidekiq
- Postgres: localhost:5544
- Redis: localhost:6380

## Run locally

Requires Ruby 3.3, PostgreSQL 16 and Redis 6+.

```bash
export DATABASE_HOST=127.0.0.1 DATABASE_PORT=5432 DATABASE_USER=postgres DATABASE_PASSWORD=postgres
bundle install
bundle exec rails db:prepare
bundle exec rails tailwindcss:build
bundle exec rails server -p 3000
```

Sidekiq is optional: `bundle exec sidekiq`.

## Tests

```bash
bundle exec rspec
```

## Environment

- `FESTIVAL_API_URL` (default `http://localhost:3000`)
- `REDIS_URL` (default `redis://localhost:6379/0`)
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`

## What changed

- `ProgrammeSync` imports `/mock_api/screenings` page by page, upserts `Film`,
  `Venue` and `Screening` by `external_id`, commits each page separately, and
  records status, counts and errors in `sync_runs`.
- `ScreeningsController` eager-loads film/venue and applies date, venue and `q`
  filters. The form targets the `screenings` Turbo Frame.
- The planted `VenueSync` trap is left untouched; the new sync never matches
  venues by name and does not abort a whole run on one bad record.

## Assumptions and trade-offs

- Upstream external IDs are stable across generations.
- Upstream-deleted screenings are left in place; soft delete would be safer in
  production but is not required by the brief.
- Overlap safety combines a running-`SyncRun` check with a Redis execution lock;
  upserts by external ID keep retries idempotent.
- A full hourly sync is a poor fit for festival week; event-driven deltas would
  be better if the upstream API supports them.
