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

## Detailed Challenge Spec

### Run and submit
- Run: `docker compose up --build` (or `bin/setup` then `bin/dev` per assessment).
- App `http://localhost:3000`; Sidekiq dashboard `http://localhost:3000/sidekiq`; Postgres on host port 5544.
- Submit as private git repo with all commits, no squashing.
- Commit incrementally; do not squash.

### Delivered scope order (correctness under failure first)
1. Programme sync (highest value).
2. Filtered screenings index (Hotwire).
3. Short README (trade-offs, assumptions, code you would change).

### Programme sync contract
- Endpoint: `GET /mock_api/screenings`.
- Shape: `{ page, per_page:25, total_pages, total_count, screenings: [ { id, starts_at, status, film: {id,title,synopsis,runtime,year}, venue:{id,name,address,capacity} } ] }`.
- Paginated 25/page.
- Datasets:
  - generation 1: base state, 60 screenings; films FILM-001..FILM-012, venues VEN-01..VEN-06.
  - generation 2: same IDs plus mutations:
    - 4 screenings move venue (SCR-0001→VEN-06, SCR-0002→VEN-05, SCR-0003→VEN-06, SCR-0004→VEN-05)
    - 3 screenings cancelled (SCR-0010, SCR-0011, SCR-0012)
    - 1 film retitled same id: FILM-005 "Autumn in Trieste" → "Autumn in Trieste (Director's Cut)"
    - 1 venue renamed same id: VEN-03 "City Gallery Screening Room" → "City Gallery Auditorium"
    - 2 new screenings (SCR-0061, SCR-0062)
    - 1 removed (SCR-0060)
- Failure simulation:
  - `?fail_after=N`: returns N records across pages, then 500 on next page (partial-failure handling proof).
  - `?slow=true`: 6 second response delay.
- Requirements:
  - upsert by **external ID** for film, venue, screening (not name/title).
  - idempotent: running twice creates no duplicates.
  - generation 2 changes propagate: moves, cancellations, retitles, renames, additions.
  - partial failure commits already fetched pages; earlier records must not be lost.
  - side-effects: film/venue created or updated by nested data.
  - scheduled as Sidekiq job.
  - track run outcome: at minimum timestamp + status; preferred counts created/updated + captured errors.
  - errors isolated per record/API and reported (do not abort whole batch on one bad record).
  - concurrency/overlap handling should be considered (not necessarily implemented, but reasoned about in README).
  - deletions: likely leave or discuss; not hard requirement.

### Existing code / files
- Models: `app/models/film.rb`, `venue.rb`, `screening.rb` (unique index on external_id each).
- Trap: `app/services/venue_sync.rb` (`VenueSync`) matches venue by `name`, no error handling.
- Trap test: `spec/services/venue_sync_spec.rb` covers only create path.
- Filter UI: `app/controllers/screenings_controller.rb`, `app/views/screenings/index.html.erb`.
- Mock API: `app/controllers/mock_api/screenings_controller.rb`, `app/services/mock_api/dataset.rb`.
- Routes: `config/routes.rb`.
- Migrations/schema and seeds in `db/`.

### Known defects to fix in index
- Form does not target Turbo Frame `screenings`; filtering does full page reload.
- N+1 in loop (`screening.film.title`, `screening.venue.name`); eager load.
- Controller ignores `q`; implement title search (`film.title ILIKE` or case-insensitive).
- Controller does not filter by text.
- Text field param must actually be applied.
- Optional: Turbo Stream/filtering response, Stimulus debounced search (not required).

### Repo model details
- `Film`: external_id, title, synopsis, runtime, year; `has_many :screenings, dependent: :destroy`.
- `Venue`: external_id, name, address, capacity; `has_many :screenings, dependent: :destroy`.
- `Screening`: external_id, film_id, venue_id, starts_at, status enum (`scheduled`, `cancelled`).
- Unique indexes on `external_id` for each model.

### Observability floor
- `sync_runs` table manually added.
- Fields minimum: status, started_at, completed_at (or timestamp + status).
- Better: created/updated counts, failed count, error text.
- Alert-friendly structure earns top score.

### Scoring rubric (internal) - targets
- A Idempotency: upsert by external id, proven by reruns and gen2. 4 = handles retitled film/renamed venue.
- B Partial failure: per-record isolation, capture/report, commit successes, distinguish bad record vs dead API. Prefer per-page transactions (3) at minimum, global one transaction loses everything.
- C Background job: Sidekiq, idempotent, retry-aware, overlap-safe. Hourly full sync question should be discussed (event-driven upgrade signal).
- D Trap: find it, explain, README mention, do not silently rewrite; never propagate pattern. Most important non-functional.
- E Hotwire: target frame, possibly Turbo Stream/Stimulus.
- F Query discipline: eager load existing N+1.
- G Tests: failure paths, idempotency, changed-data coverage.
- H Communication: concise, useful, non-defensive README.

### Internal rubric wording that matters
- "Someone who inherits a bad pattern and propagates it is a real risk."
- Correctness under failure outweighs feature completeness.
- Tests expected for sync + models; view tests not.
- Check after gen2: one film with new title or two?
- Check deletion handling as discussion, mostly not fail.

### Stage two (system design) brief context
Domain: City Arts Pass membership (cinemas, theatres, galleries, music venues).
Three screens: member home, event detail with multiple occurrences, account/household/booking history.
Key modelling traps:
- event vs occurrence (sessions carry venue/start/capacity)
- polymorphic saves (events, venues, artists, articles) and FK enforcement trade-off
- price changes over time (record price on membership or tier_prices validity ranges)
- household vs login identity (child no login)
- history snapshot fidelity; sold-out/concurrency; reporting; deletion/anonymisation.
Reference model ~9 tables (organisations, venues, events, sessions, people, users, households, household_memberships, memberships, tiers/tier_prices, bookings, saves).
"Good answers differ; ask before committing; adapt under curveballs."

### Implementation guardrails
- Preserve validation/error handling when refactoring.
- Prefer root cause in shared code; no single-implementation abstraction.
- Use Rails conventions already present (RSpec already installed; PostgreSQL; Sidekiq).
- Fix trap behavior in new sync code; leave `VenueSync` in place as example if possible and mention it.
- Do not add client-side framework.
- Add only needed dependencies.

### Verification
- RSpec all green.
- Manual: sync gen1 twice → same counts/no duplicates.
- Manual: sync gen1 then gen2 → updates/inserts/no duplicate film/venue; removed screening handling as designed.
- Manual: gen1 fail_after=8 → nothing lost.
- Filter: date, venue, q all work and update frame only.
- Inspect logs/N+1 with eager loading.

### Before submitting
- Rename README.md to INSTRUCTIONS.MD
- Create README.md with contents of how to run the project and relevant information