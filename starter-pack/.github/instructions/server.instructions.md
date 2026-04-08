---
applyTo: "repos/app-sightmap/server/**"
---

# Server Instructions (PHP / Laravel)

**Always read `repos/app-sightmap/server/AGENTS.md` first** — it has 1000+ lines of detailed conventions.

## Quick Reference

- **Stack**: PHP 8.x, Laravel 11, MySQL, Redis
- **Run commands**: `docker compose exec app {command}`
- **Tests**: `docker compose exec app tests`
- **Lint**: `vendor/bin/phpcs` / `vendor/bin/phpcbf`
- **Architecture**: Domain-driven with Services, Repositories, Actions
- **Key models**: Account → Asset → Building → Floor → Unit

## Critical Patterns

- Feed system: FeedSource → Feed → FeedRun → ProcessExecution
- API versioning via route prefixes (`/v1/`, `/v2/`)
- Authorization: Policies + Gates (never inline auth checks)
- Queue jobs for heavy processing (feeds, map generation)
- Feature flags via `Feature` facade

## Don't Forget

- Run `phpcs` before committing — CI will catch violations
- Database changes need migrations AND seeders
- API changes may need OpenAPI spec updates in `openapi/`
