# PMS Integration Systems

> Documentation for Property Management System integrations

## Current Architecture

### Standard Integrations (in app-sightmap)
Built into the main Laravel Feed system:
- Schedule-triggered polling
- Direct API/SFTP data fetch
- Processed via queue workers

### Non-Standard Integrations (in atlas-integrations)
Kubernetes CronJobs using `smctl`:
- ~208 customer deployments
- ~14 container types (PMS-specific)
- Run as scheduled jobs on GKE cluster

## Active PMS Providers

| Provider | smctl Command | Container | Notes |
|----------|--------------|-----------|-------|
| Entrata | `smctl entrata` | `std/entrata` | floor_plans, unit_amenities, student_pricing, affordable_units |
| RentCafe (Yardi) | `smctl rentcafe` | `std/rentcafe`, `std/rentcafe_v2` | Multiple versions |
| RealPage OneSite | `smctl onesite` | `std/onesite` | - |
| AppFolio | `smctl appfolio` | `appfolio` | - |
| Matterport | `smctl matterport` | `std/matterport` | 3D tours |
| SiteLink | `smctl sitelink` | `std/sitelink` | Self-storage |
| Rent Manager | - | `std/rentmanager` | - |
| Let It Rain | `smctl letitrain` | `std/letitrain` | - |

## Large Customers (Custom Containers)

| Customer | Container | Integration Types |
|----------|-----------|-------------------|
| Greystar | `greystar` | expenses (10+ jobs), floor_plans, pricing_disclaimers |
| AMLI | `amli` | Custom |
| AvalonBay | `avalonbay` | Custom |
| Bozzuto | `bozzuto` | Custom |
| Carlyle | `carlyle` | Custom |
| Cortland | `cortland` | Custom |
| Equity | `equity` | Custom |
| Essex | `essex` | Custom |
| Spectrum | `spectrum` | Custom |

## Integration Pattern (atlas-integrations)

```
Kubernetes CronJob
  └─ Docker Container (with smctl installed)
      └─ command.sh script
          └─ Reads config/assets.csv
          └─ Loops through assets
          └─ Calls smctl {provider} import {type}
          └─ Writes to SightMap API
```

## Migration Target (app-sightmap)

Moving integration logic into main Laravel app while keeping cron scheduling in atlas-integrations.

---
*To be expanded during migration project scoping*
