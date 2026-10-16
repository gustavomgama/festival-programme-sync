# Festival Programme Sync

Rails 8 app that syncs film festival screenings from a mock external API and
renders a filtered screenings list.

## Run

```bash
docker compose up --build
```

- App: http://localhost:3000
- Sidekiq dashboard: http://localhost:3000/sidekiq
- Postgres on host port 5544

Or, with Ruby installed locally:

```bash
bin/setup
bin/dev
```

## Environment
- `FESTIVAL_API_URL` (default `http://localhost:3000`) - base URL of the mock/external API.
- `REDIS_URL` (default `redis://localhost:6379/0`)
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`

## Tests

```bash
make test
# or
bundle exec rspec
```

## Notes
- Candidate brief and implementation details are in `INSTRUCTIONS.MD`.
- Internal spec, rubric and traps are in `AGENTS.md`.
