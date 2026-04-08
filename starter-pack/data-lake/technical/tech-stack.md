# Tech Stack

> Engrain technology stack documentation (from AGENTS.md analysis)

## Backend

### Main Server (app-sightmap/server/)
- **Framework:** Laravel 11.x
- **Language:** PHP 8.0/8.1/8.2
- **Database:** MySQL 8.0 (primary)
- **Cache/Session:** Memcached, MongoDB (performance indexes)
- **Queue:** Beanstalkd (local), RabbitMQ (production)
- **Testing:** PHPUnit 11.x, ParaTest (parallel)

### Microservices
| Service | Runtime | Purpose |
|---------|---------|---------|
| **parser/** | Node.js 16 | SVG unit map parsing |
| **geojson/** | Deno 1.14.1 | GeoJSON conversion |
| **navigation/** | Deno 2.3.7 | Routing/pathfinding (Valhalla) |
| **tilesets/** | Deno 1.42.1 | Vector tile serving (MBTiles) |

## Frontend (app-sightmap/clients/)

| App | React Version | UI Library | Purpose |
|-----|---------------|------------|---------|
| **app/** | React 18 | Emotion, Mapbox GL | Main embed (interactive maps) |
| **customer/** | React 18 | Ant Design 5 | **Atlas** - Modern admin UI |
| **manage/** | React 15 | AdminLTE, jQuery | Legacy admin (maintenance mode) |
| **landing-page/** | React 18 | Emotion | Simplified embed |
| **locator/** | React 18 | Google Places | Property finder |
| **iframe-api/** | Vanilla JS | - | External embed API |

**Build:** Webpack 5 → `web/public/{app}/`

## CLI Tools

### smctl (app-smctl/)
- **Runtime:** Deno
- **Purpose:** Internal CLI for integration commands
- **Key commands:** entrata, rentcafe, onesite, appfolio, matterport, sitelink, mri
- **Used by:** atlas-integrations cron jobs

## Infrastructure

- **Web Server:** Nginx 1.26.1
- **API Gateway:** Kong
- **Containers:** Docker, Docker Compose
- **Cloud:** GCP (GKE for atlas-integrations)
- **Storage:** S3/GCS for files, maps, captures

## Data Model Hierarchy

```
Account (Customer org)
  └─ Asset (Property)
      └─ Building
          └─ Floor
              └─ Unit
```

## Key Integrations (PMS Systems)

| Provider | smctl command | Type |
|----------|--------------|------|
| Entrata | `smctl entrata` | API |
| RentCafe (Yardi) | `smctl rentcafe` | API |
| RealPage OneSite | `smctl onesite` | API |
| AppFolio | `smctl appfolio` | API |
| Matterport | `smctl matterport` | API |
| SiteLink | `smctl sitelink` | API |
| MRI | `smctl mri` | API |

---
*Last updated: February 2026*
