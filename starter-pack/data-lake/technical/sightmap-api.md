# SightMap API Reference

> Curated summary for quick context. Full specs: `repos/app-sightmap/openapi/`

## Overview
- **Base URL**: `https://api.sightmap.com/v1`
- **Traffic**: ~6 million calls/day
- **Format**: JSON over HTTPS only
- **Versioning**: `VERSION.RELEASE-DATE` (e.g., `v1.20241230`)
- **Docs site**: [developers.sightmap.com](https://developers.sightmap.com)

## Authentication

API Key via header (preferred) or query parameter:
```
curl -i https://api.sightmap.com/v1/assets \
  -H "API-Key: YOUR_KEY"
```
- Missing key → `401`
- Invalid key → `403`
- Experimental features: `Experimental-Flags: flag-1,flag-2` header

## Resource Groups

| Group | Key Endpoints |
|-------|--------------|
| **Accounts** | CRUD accounts, manage account-level assets and embeds |
| **Assets** | Core resource — buildings, floors, floor plans, units |
| **Units** | Unit details, descriptions, outbound links, references |
| **Pricing** | Pricing & availability, pricing executions, expenses, disclaimers |
| **Maps** | Unit maps, map backgrounds, caches |
| **Filters** | Custom filtering system for units |
| **Galleries** | Image galleries per asset |
| **SightMaps** | SightMap embed configurations |
| **Landing Pages** | Simplified embed landing pages |
| **References** | Asset and unit external references (PMS IDs, etc.) |
| **Marker Descriptions** | Map marker tooltip content |
| **MITS** | MITS-ILS feed format export |

## Common Patterns

- **Pagination**: `?page=1&per_page=25` — responses include `paging` object
- **IDs**: String format, max 255 chars
- **Permissions**: Scoped per resource (e.g., `sightmap.units.read`, `sightmap.units.create`)
- **Errors**: Standard HTTP codes with `{ "message": "..." }` body
- **Rate limiting**: `429` when exceeded

## Data Hierarchy

```
Account → Asset → Building → Floor → Unit
                → Floor Plan (template for units)
                → Unit Map (interactive map)
                → Embed (SightMap widget config)
```

## Full OpenAPI Specs

For endpoint details, request/response schemas, and examples:
- **SightMap**: `repos/app-sightmap/openapi/sightmap/openapi.yaml` (root)
- **UnitMap**: `repos/app-sightmap/openapi/unitmap/openapi.yaml` (root)
- **Schema components**: `openapi/{api}/components/schemas/`
- **Path definitions**: `openapi/{api}/paths/`

---

# Unit Map API Reference

## Overview
- **Base URL**: `https://api.unitmap.com/v1`
- **Auth**: Same as SightMap (`API-Key` header)
- **Purpose**: Map documents, SVG parsing, geographic data

## Resource Groups

| Group | Purpose |
|-------|---------|
| **Assets** | Asset floors and references |
| **Maps** | Unit map documents, backgrounds, locations, level tags |
| **Units** | Unit geometry data and references |

## Full Spec
`repos/app-sightmap/openapi/unitmap/openapi.yaml`
