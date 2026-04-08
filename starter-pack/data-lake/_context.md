# Engrain Context

> Persistent context about Engrain for AI assistant reference.

## Company Overview

**Engrain** is a PropTech company (~200 employees, Denver, CO) providing interactive property maps and unit-level data visualization for the multifamily real estate industry.

**Value Proposition:** Centralize property data at the unit level, visualize it on interactive maps, transforming fragmented content into actionable context for renters and operational consistency for property teams.

## Core Values

1. **Tenacity** - Find a way and don't quit. Always forward.
2. **Longevity** - Consider long-term implications. Make sustainable, scalable choices.
3. **Empathy** - Actively listen. Build on trust. Be accountable. Design for inclusivity.
4. **Focus** - Know when to say no. Minimize distraction. Optimize daily.
5. **Design** - Design-first mindset in everything. It's our superpower.
6. **Perspective** - Be curious about other viewpoints. Foster diversity.

## Data Hierarchy

```
Account → Asset → Building → Floor → Unit
```

- **Account**: A customer organization (e.g., Greystar, Lincoln Property)
- **Asset**: A property/community (e.g., "The Pines at Westborough")
- **Building**: A physical building within an asset
- **Floor**: A floor within a building
- **Unit**: An individual apartment unit

## Products

| Product | Purpose | Users |
|---------|---------|-------|
| **SightMap** | Interactive property maps (6M API calls/day) | Renters, property managers |
| **Atlas** | Internal management portal (React 18 + Ant Design 5) | Property managers, Engrain staff |
| **SightMap API** | Public API for unit data, maps, pricing | Partner integrations |
| **Unit Map API** | Map rendering and geographic data | Internal services |
| **smctl** | CLI tool for API & PMS integrations (Deno/TypeScript) | Engineering, data team |

## Repositories

| Repo | Purpose | Tech |
|------|---------|------|
| `app-sightmap` | Main monorepo (SightMap, Atlas, APIs) | PHP/Laravel, React, Deno |
| `app-smctl` | CLI tool for integrations | Deno/TypeScript |
| `atlas-integrations` | Kubernetes CronJobs for integrations | Bash, Docker, K8s |
| `xp-data-integrations` | Data team scripts/tools | Python, misc |

## Tech Stack (Summary)

- **Backend:** Laravel 11, PHP 8.x, MySQL 8, MongoDB, Memcached
- **Frontend:** React (15/18), Ant Design, Mapbox GL
- **Microservices:** Deno (navigation, geojson, tilesets), Node.js (parser)
- **Infrastructure:** Docker, Nginx, Kong API Gateway, GKE
- **Full details:** `data-lake/technical/tech-stack.md`

## Team

**{{NAME}}** - Product Manager
- Primary focus: {{TEAM}}
- Works on: {{FOCUS}}
- Handles: {{RESPONSIBILITIES}}

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

## Terminology

| Term | Definition |
|------|------------|
| Asset (SightMap) | A property/community (not "property" — ambiguous in software) |
| Asset (Salesforce) | An active subscription record on a customer account |
| PMS | Property Management System — software used by properties |
| Feed | Data sync connection between PMS and Engrain |
| FeedSource → Feed → FeedRun → ProcessExecution | The data pipeline for PMS syncs |
| Consumer | External API client or integration partner |
| Unit-level data | Per-apartment data (pricing, availability, floor plans) |

## Key Integrations (PMS)

- **RentCafe** (Yardi) — largest integration
- **Entrata**
- **OneSite** (RealPage)
- **AppFolio**
- **MRI**
- **SiteLink**
- **Matterport** (3D tours)

## Revenue Operations (Quote-to-Cash)

Salesforce RCA → Continuous → NetSuite. Salesforce is the source of truth for *what was sold*. NetSuite is the source of truth for *money collected*. Continuous bridges them automatically. All subscription changes use Cancel/Replace from the Salesforce Asset record — never edit NetSuite directly. See `data-lake/operations/quote-to-cash.md` for full details.

## Data Lake Structure

This knowledge base is organized by **topic domains**:

| Domain | Contents |
|--------|----------|
| `company/` | Mission, values, org structure |
| `customers/` | Customer personas, onboarding, support |
| `integrations/` | PMS integration docs, smctl commands |
| `journeys/` | Task-based guides ("How to do X") |
| `operations/` | Business processes (sales, hiring, releases) |
| `products/` | Product documentation (SightMap, Atlas, APIs) |
| `reference/` | Quick lookups (data standards, glossary, contacts) |
| `technical/` | Architecture, tech stack, repositories |

Each document has YAML frontmatter with `title`, `labels`, `owner`, `updated`, and optional `notion_link`. Check each domain's `_overview.md` for contents.

## Git Conventions (Summary)

- **Main branch (app-sightmap):** `develop` for PRs, `master` for production
- **Main branch (app-smctl):** `main`
- **Branch naming:** `feature/short-descriptive-name`
- **Commit format:** `:emoji: Description (JIRA-123).` (always end with period)
- **Full details:** `data-lake/technical/git-workflow.md`

---

*Update this file as new context is learned*
