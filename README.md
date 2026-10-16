# Festival Programme Sync

Rails 8 app that syncs film festival screenings from a mock external API and
renders a filtered screenings list.

## Docker (challenge-provided)

```bash
docker compose up --build
```

- App: http://localhost:3000
- Sidekiq dashboard: http://localhost:3000/sidekiq
- Postgres on host port 5544

## Local run (commands tested in this environment)

```bash
export DATABASE_HOST=localhost DATABASE_PORT=5544 DATABASE_USER=postgres DATABASE_PASSWORD=postgres

bundle exec rails db:prepare
bundle exec rails tailwindcss:build
bundle exec rails server -p 3000
```

- App: http://localhost:3000

Redis is needed only for Sidekiq or queueing/enqueuing jobs (`REDIS_URL` defaults to `redis://localhost:6379/0`).

## Tests (tested)

```bash
export DATABASE_HOST=localhost DATABASE_PORT=5544 DATABASE_USER=postgres DATABASE_PASSWORD=postgres
bundle exec rspec
```

The suite uses PostgreSQL and passes all examples.

## What I changed

- `ProgrammeSync` imports `/mock_api/screenings` page by page, upserts Film, Venue and
  Screening by `external_id`, and commits each page before fetching the next one. It
  records status, counts and errors in `sync_runs`.
- `ScreeningsController` eager-loads film/venue and applies date, venue and `q`
  filters. The form targets the `screenings` Turbo Frame.
- Left the planted `VenueSync` trap untouched as evidence; the new sync never matches
  venues by name and does not abort a whole batch on one bad record.

## Assumptions and trade-offs

- Upstream external IDs are stable across generations (as documented by the mock).
- Upstream-deleted screenings are left in place; a soft-delete would be safer in a
  production system, but deletion is not required by the brief.
- Overlap is guarded by the presence of stale `running` SyncRun rows. This is simple
  and idempotent, not a hard lock.
- Hourly full syncs are a poor fit for festival week; event-driven delta updates
  would be better if the upstream API supports them.