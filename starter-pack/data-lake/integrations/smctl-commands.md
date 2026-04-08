---
title: smctl Command Reference
labels: [integration, technical, smctl, reference]
owner: Engineering
updated: 2026-03-10
---

# smctl Command Reference

> Complete catalog of smctl CLI commands with credential requirements and provider-specific options. Use this when building, debugging, or configuring PMS integrations.

## Command Categories

| Category | Purpose | Example |
|----------|---------|---------|
| **Core** | API and HTTP requests to SightMap/Unit Map | `smctl api`, `smctl http` |
| **Utility** | Data conversion, logging, matching | `smctl convert`, `smctl log`, `smctl match` |
| **Export** | Extract data for matching | `smctl export unit-match` |
| **Report** | Generate reports | `smctl report units` |
| **Provider** | PMS-specific import/export commands | `smctl entrata import floor-plans` |

## Credential Requirements by Provider

Each provider requires different authentication. **All provider import commands require `api-key`** (Engrain SightMap API key) plus the provider-specific credentials below.

| Provider | Required Credentials |
|----------|---------------------|
| **AppFolio** | `appfolio-api-key`, `subdomain` |
| **Entrata** | `domain`, `entrata-api-key`, `property-id` |
| **Matterport** | `token-id`, `token-secret` |
| **OneSite** | `site-id`, `pmc-id`, `username`, `password` |
| **RentCafe** | `username`, `password`, `sitelink-api-key`, `corporate-code`, `client-id`, `property-code` (+ optional `voyager-property-code`, `api-token`) |
| **SiteLink** | `property-id`, `username`, `password`, `sitelink-api-key`, `corporate-code`, `client-id` |

### Customer-Specific (`xp` namespace)

| Provider | Required Credentials | Customer |
|----------|---------------------|----------|
| **AMLI** | `domain`, `entrata-api-key`, `property-id`, `amli-api-base-url` | AMLI |
| **AvalonBay** | `salesforce-username`, `salesforce-password`, `salesforce-client-id`, `salesforce-client-secret` | AvalonBay |
| **Bozzuto** | `property-id`, `config`, `source` | Bozzuto |
| **Carlyle** | `config`, `references`, `community-code`, `sub-community-code` | Carlyle |
| **Cortland** | `property-id`, `cortland-api-key` | Cortland |
| **Equity** | (source CSV input) | Equity |
| **Essex** | `entrata-api-key`, `api-token` | Essex |
| **Greystar** | `greystar-api-base-url`, `auth-key`, `yardi-code` | Greystar |
| **Spectrum** | `config`, `community-id` | Spectrum |

## Provider Commands

### Standard Providers

| Command | Description | Extra Options |
|---------|-------------|---------------|
| `smctl appfolio import pricing` | Import pricing from AppFolio listings API | `property-list-name` |
| `smctl entrata export unit-match` | Export unit data for matching | `include-space-number` |
| `smctl entrata import affordable-units` | Import affordable units | — |
| `smctl entrata import floor-plans` | Import floor plans | `update-unit-sqft` |
| `smctl entrata import unit-amenities` | Import unit amenities to description group | `label`; requires `description-group-id` |
| `smctl entrata import student-pricing` | Import student pricing | requires `lease-period-name`, `lease-period-pricing-id` |
| `smctl matterport import virtual-tours` | Import virtual tour URLs | requires `outbound-link-id` |
| `smctl matterport manage virtual-tours` | Manage archived state of tours | — |
| `smctl onesite export unit-match` | Export unit data for matching | — |
| `smctl onesite import floor-plans` | Import floor plans | `name-node`, `group-by-name` |
| `smctl rentcafe export unit-match` | Export unit data for matching | — |
| `smctl rentcafe import asset` | Import an asset | `building`, `floor`, `split-image-url` |
| `smctl rentcafe import floor-plans` | Import floor plans | `split-image-url`, `update-unit-sqft` |
| `smctl rentcafe import unit-amenities` | Import unit amenities to description group | `separator`, `label`, `sort-file` |
| `smctl sitelink import pricing` | Import pricing | — |

### Customer-Specific (`xp` namespace)

| Command | Description | Customer |
|---------|-------------|----------|
| `smctl xp amli import pricing` | AMLI pricing & availability | AMLI |
| `smctl xp avalonbay import floor-plans` | AvalonBay floor plan import | AvalonBay |
| `smctl xp bozzuto import floor-plans` | Bozzuto MITS floor plan import | Bozzuto |
| `smctl xp carlyle import mass-elemental` | Carlyle masselemental.com import | Carlyle |
| `smctl xp cortland import pricing` | Cortland pricing & availability | Cortland |
| `smctl xp equity convert source2ai` | Convert Equity CSV to AI SFTP JSON | Equity |
| `smctl xp essex import floor-plans` | Essex floor plan import | Essex |
| `smctl xp greystar import expenses` | Greystar expenses import | Greystar |
| `smctl xp greystar import pricing-disclaimer` | Greystar pricing disclaimers | Greystar |
| `smctl xp merge-pricing` | Merge pricing between processes | Various |
| `smctl xp spectrum import pricing` | Spectrum pricing & availability | Spectrum |

## Global Options

Available on all commands:

| Option | Description |
|--------|-------------|
| `dry-run` | Preview changes without applying |
| `chunk-size` | Batch size for API calls |
| `days-out` | How far ahead to look for availability |
| `http-timeout` | HTTP request timeout |
| `storage` / `storage-base-path` / `storage-bucket` | Storage configuration |
| `log-output` | Log destination |
| `verbose` / `strace` | Debug output |
| `http-capture-path` / `http-capture-format` | Capture HTTP requests for debugging |
| `pretty` / `output` | Output formatting |

## Related

- [[integrations/custom-integrations]] — Custom integration catalog (CMS, K8s, Ingest)
- [[reference/data-standards]] — Feed naming conventions
- `data-lake/integrations/pms-systems.md` — High-level PMS integration architecture

---

*Last updated: 2026-03-10 | Owner: Engineering*
