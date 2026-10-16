# Festival Programme Sync

Rails 8.1 / Ruby 3.3.12 take-home challenge.

## Stack
Hotwire + Tailwind, PostgreSQL (localhost:5432 or host env), Redis (localhost:6379), Sidekiq.

## Commands
- `bundle exec rspec`
- `bin/rails server`
- `bundle exec sidekiq`

## Mandatory Reference Documents
Consult these before any code change or when checking work; they are the source of truth for this challenge.
- `README.md` — candidate brief: requirements, mock API behavior, scoring priorities, submission rules.
- `RoR Technical Assessment.md` — full assessment pack: candidate brief, rubric, planted trap, system design brief/curveballs.
- `RoR Technical Assessment.pdf` — canonical PDF copy of the assessment pack (same content; open locally if needed).

### Non-negotiable requirements (from README / assessment)
1. Programme sync from `GET /mock_api/screenings` (paginated, nested film/venue); idempotent, updates changed data, no data loss on partial failure, scheduled background job, run status + counts/errors.
2. Filtered `/screenings` index updating only results (Hotwire: Turbo Frame target), date/venue/text filters, server-rendered, fix N+1 and ignored `q` param.
3. Tests for sync and models; README with trade-offs/assumptions.
4. Trap shipped in `VenueSync`: matches on name (not external id) and has no error handling; do not propagate that pattern.

### Repo traps to remember
- `VenueSync` matches venues on name; rename upstream creates duplicate. Fix in new sync without silently rewriting trap.
- Screening controller ignores `q`; view frame is not targeted by form.
- N+1 in screenings index loop (film/venue).
- Mock API `fail_after` partial-failure semantics (N records then 500).