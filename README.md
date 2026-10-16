# Festival Programme Sync

Rails 8 app that syncs film festival screenings from a mock external API and
renders a filtered screenings list.

## Primary run: Docker (challenge-provided, not run in this local environment)

```bash
docker compose up --build
```

- App: http://localhost:3000
- Sidekiq dashboard: http://localhost:3000/sidekiq
- Postgres on host port 5544

## Local run (commands tested in this environment)

```bash
# Requires PostgreSQL and Ruby. PostgreSQL is on port 5544 in this setup.
export DATABASE_HOST=localhost DATABASE_PORT=5544 DATABASE_USER=postgres DATABASE_PASSWORD=postgres

bundle install
bundle exec rails db:prepare
bundle exec rails tailwindcss:build
bundle exec rails server -p 3000
```

- App: http://localhost:3000
- Sidekiq dashboard: http://localhost:3000/sidekiq

Redis is needed only for Sidekiq or queueing/enqueuing jobs (`REDIS_URL` defaults to `redis://localhost:6379/0`).

## Tests (tested)

```bash
export DATABASE_HOST=localhost DATABASE_PORT=5544 DATABASE_USER=postgres DATABASE_PASSWORD=postgres
bundle exec rspec
```

The suite uses PostgreSQL and passes all 13 examples.

## Environment
- `FESTIVAL_API_URL` (default `http://localhost:3000`) - base URL of the mock/external API.
- `REDIS_URL` (default `redis://localhost:6379/0`) for Sidekiq when running jobs.
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`.

## Notes
- The starter repository documents a Docker path (`docker compose up --build` and `make test`); Docker was not available in this local environment.
- Candidate brief and implementation details are in `INSTRUCTIONS.MD`.
- Internal spec, rubric and traps are in `AGENTS.md`.