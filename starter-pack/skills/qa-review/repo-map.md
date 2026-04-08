# Engrain Repo Map

Reference for the QA review skill. Maps repos to their conventions.

## Feature Environment URLs

Feature branches deploy to predictable URLs. Use these to map a URL back to a branch:

| URL Pattern | Repo | Branch Format |
|-------------|------|---------------|
| `https://{name}.feature.dev.sightmap.com` | app-sightmap | `feature/{name}` |
| `https://{name}.feature.dev.unitmap.com` | app-sightmap | `feature/{name}` |

Example: `https://asset-account-owner.feature.dev.sightmap.com` → `feature/asset-account-owner` in `app-sightmap`

## Repositories

| Repo | Local Path | Default Branch | PR Target | Tech Stack |
|------|-----------|---------------|-----------|------------|
| app-sightmap | `repos/app-sightmap` | `master` | `develop` | PHP/Laravel, React, Deno |
| app-smctl | `repos/app-smctl` | `main` | `main` | Deno / TypeScript |
| atlas-integrations | `repos/atlas-integrations` | `main` | `deploy/*` | Bash / K8s CronJobs |
| xp-data-integrations | `repos/xp-data-integrations` | `main` | `main` | Python + Streamlit |

## AGENTS.md Locations (app-sightmap)

| Path Pattern | AGENTS.md |
|-------------|-----------|
| `server/**` | `server/AGENTS.md` |
| `clients/app/**` | `clients/app/AGENTS.md` |
| `clients/customer/**` | `clients/customer/AGENTS.md` |
| `clients/manage/**` | `clients/manage/AGENTS.md` |
| `navigation/**` | `navigation/AGENTS.md` |
| `geojson/**` | `geojson/AGENTS.md` |
| `tilesets/**` | `tilesets/AGENTS.md` |
| `openapi/**` | `openapi/AGENTS.md` |
| `parser/**` | `parser/AGENTS.md` |

## Critical Conventions by Area

### Server (PHP/Laravel)
- Architecture: Domain-driven with Services, Repositories, Actions
- Auth: Policies + Gates (never inline)
- DB changes: migrations AND seeders required
- Linting: `phpcs` must pass
- API changes: update OpenAPI specs in `openapi/`

### clients/manage (⚠️ React 15)
- NO hooks, NO functional components with state
- Class components with `createClass` or ES6 classes
- `redux-actions` + `handleActions` pattern
- jQuery is available and used
- AdminLTE for layout/UI

### clients/app & clients/customer (React 18)
- Hooks and functional components OK
- i18n via react-intl — all user-facing strings must be translatable
- CSS Modules (app), Ant Design tokens (customer)

### Deno Services
- geojson/tilesets: Deno 1.x (no `npm:` specifiers)
- navigation: Deno 2.x (`npm:` specifiers OK)
- app-smctl: Latest Deno
- Run `deno fmt` and `deno lint` before committing

## Local Commands

### Running Tests & Linting (app-sightmap)

These require Docker to be running. If Docker is not available, note in the report
that linting/tests could not be verified locally.

```bash
# PHP linting
docker compose exec app vendor/bin/phpcs

# PHP tests (all)
docker compose exec app tests

# PHP tests (specific file)
docker compose exec app vendor/bin/phpunit --filter=AssetsTest

# OpenAPI linting (from openapi/ directory)
npx @redocly/cli lint sightmap/openapi.yaml
npx @redocly/cli lint unitmap/openapi.yaml

# Client builds (from client directory, inside devtools)
docker compose run --rm devtools
yarn build
yarn test
```

### Running Tests & Linting (app-smctl)

```bash
./fmt.sh
./lint.sh
./test.sh
```

## Jira Ticket Key Patterns

Engrain Jira projects use these key prefixes:
- `SM-` — SightMap (most common)
- `ENG-` — Engineering
- `ATLAS-` — Atlas portal
- `NAV-` — Navigation

Commit message convention: `:emoji: Description (SM-XXXX).`
