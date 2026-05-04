# Engrain Context

> Persistent context about Engrain for AI assistant reference

## Company Overview

**Engrain** is a PropTech company providing interactive property maps and unit-level data visualization for the multifamily real estate industry.

**Value Proposition:** Centralize property data at the unit level, visualize it on interactive maps, transforming fragmented content into actionable context for renters and operational consistency for property teams.

## Core Values

1. **Tenacity** - Find a way and don't quit. Always forward.
2. **Longevity** - Consider long-term implications. Make sustainable, scalable choices.
3. **Empathy** - Actively listen. Build on trust. Be accountable. Design for inclusivity.
4. **Focus** - Know when to say no. Minimize distraction. Optimize daily.
5. **Design** - Design-first mindset in everything. It's our superpower.
6. **Perspective** - Be curious about other viewpoints. Foster diversity.

## Products

### SightMap (Flagship)
- Interactive property maps
- Unit-level data visualization
- **6 million API calls per day**
- Main external-facing product
- Repo: `app-sightmap`

### Atlas (Internal)
- Internal management UI (`clients/customer/`)
- CRUD operations on Engrain data
- React 18 + Ant Design 5
- Used by Engrain employees

### smctl (CLI Tool)
- Internal CLI for running integrations
- Written in Deno/TypeScript
- Commands for each PMS provider
- Repo: `app-smctl`

### Integrations
- Connect with Property Management Systems (PMS)
- Non-standard integrations in `atlas-integrations` (Kubernetes CronJobs)
- Standard integrations built into Laravel Feed system
- **Migration planned** to consolidate in `app-sightmap`

## Repositories

| Repo | Purpose | Tech |
|------|---------|------|
| `app-sightmap` | Main monorepo (SightMap, Atlas, APIs) | PHP/Laravel, React, Deno |
| `app-smctl` | CLI tool for integrations | Deno/TypeScript |
| `atlas-integrations` | Kubernetes CronJobs for integrations | Bash, Docker, K8s |
| `xp-data-integrations` | Data team scripts/tools | Python, misc |

## Tech Stack

- **Backend:** Laravel 11, PHP 8.x, MySQL 8, MongoDB, Memcached
- **Frontend:** React (15/18), Ant Design, Mapbox GL
- **Microservices:** Deno (navigation, geojson, tilesets), Node.js (parser)
- **Infrastructure:** Docker, Nginx, Kong API Gateway, GKE
- **See:** `knowledge/tech-stack.md` for full details

## Team

**Will Fagan** - Product Manager
- Primary focus: SightMap team
- Works on: Atlas, SightMap API, Integrations
- Handles: New PMS integration requests from Sales

## Tools & Systems

| Category | Tool |
|----------|------|
| Source Control | Bitbucket |
| Project Management | Jira Cloud |
| Documentation | Notion, Google Docs |
| Communication | Zoom Chat, Email |
| CRM / Subscriptions | Salesforce (Revenue Cloud) |
| Financials | NetSuite |
| SF ↔ NS Integration | Continuous |
| Contract Signing | DocuSign (via Salesforce) |

## Git Conventions

- **Main branch (app-sightmap):** `develop` for PRs, `master` for production
- **Main branch (app-smctl):** `main`
- **Branch naming:** `feature/short-descriptive-name`
- **Commit format:** `:emoji: Description (JIRA-123).` (always end with period)
- **Emoji guide:** 🎨art, 🐛bug, 🔥fire, 📝pencil, ✅white_check_mark

## Revenue Operations (Quote-to-Cash)

Salesforce RCA → Continuous → NetSuite. Salesforce is the source of truth for *what was sold* (quotes, subscriptions, assets). NetSuite is the source of truth for *money collected* (invoicing, AR, revenue recognition). Continuous bridges them automatically. All subscription changes use Cancel/Replace from the Salesforce Asset record — never edit NetSuite directly. See `knowledge/Engrain Data Lake/operations/quote-to-cash.md` for full details.

## Terminology

| Term | Definition |
|------|------------|
| PMS | Property Management System - software used by properties |
| Unit-level data | Data specific to individual apartment/property units |
| Feed | Automated data ingestion from external PMS |
| Consumer | API client/integration partner |
| Asset (SightMap) | A property in the SightMap system |
| Asset (Salesforce) | An active subscription record on a customer account |

---

*Update this file as new context is learned*
