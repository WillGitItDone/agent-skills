---
title: Custom Integrations Reference
labels: [integration, pms, custom, reference]
owner: Kam Deno
updated: 2026-03-10
notion_link: https://notion.so/Engrain-Approved-Custom-Integrations-KAM-SAVE-2ef3924d7267808a9de9c05575803223
---

# Custom Integrations Reference

> Catalog of integrations not natively supported in ATLAS, requiring additional setup effort. Three deployment types: CMS, Kubernetes/SMCTL, and Customer Ingest.

## Deployment Types

| Type | Host | Description |
|------|------|-------------|
| **CMS** | `ipadpush.mytouchtour.com` or `atlaspush.mytouchtour.com` | Hosted in Engrain's Content Management System. Most common type. |
| **Kubernetes (SMCTL)** | K8s CronJobs via `app-smctl` | Deployed on Kubernetes using Engrain's CLI. For complex or high-volume integrations. |
| **Customer Ingest** | Customer-managed | Customer pushes data to ATLAS via the [Ingest API](https://developers.sightmap.com/docs/pushing-pricing-data-to-sightmap). Per-customer setup. |

## Custom Integration Catalog

### CMS-Based

| Provider | Frequency | Pricing Support | Usage | Notes |
|----------|-----------|----------------|-------|-------|
| Yardi Voyager Rentable Items | Hourly | Flat | All | Parking/storage properties only |
| Entrata Rentable Items | Hourly | Flat | All | Parking/storage properties only |
| Entrata Student | 2x Daily or Hourly | Flat | All | Student housing, by-the-bed rental |
| Salesforce | Per-integration | Flat | All | Per-customer; requires integration request |
| Welcome Home | 2x Daily (~8AM/8PM EST) | Flat | All | |
| Self Storage Manager | Hourly | Flat | All | |
| On-Site | Hourly | Flat | All | |
| Eldermark | Hourly | Flat | All | |
| Smartsheet | Hourly | Flat | All | |
| Fortress | Hourly | Flat | All | |
| Rent Manager | Hourly | Flat | All | |
| Custom SFTP | Per-integration | Flat + RM | All | Per-customer; requires integration request |
| Funnel | Hourly | RM only | All | SFTP-based; Funnel provides file |
| LRO (Letitrain) | Every 4 hours | RM only | IMT only | |
| Blue Notch | Hourly | Flat | All | Currently no active properties |
| Enquire Solutions | Hourly | Flat | All | Partnered with Sherpa to form Aline; uses Enquire API |
| Sherpa | 2x Daily (~7AM/7PM EST) | Flat | All | Partnered with Enquire to form Aline; uses Sherpa API |
| Quickbase | Hourly | Flat | All | Currently one property only |
| Mass Elemental | Hourly | Flat | All | |

### Kubernetes (SMCTL)

| Provider | Frequency | Pricing Support | Usage | Notes |
|----------|-----------|----------------|-------|-------|
| Entrata Custom (AMLI) | 4x Daily (~4AM/10AM/1PM/4PM EST) | RM only | AMLI only | Exclusively for AMLI |
| MRI | Hourly | Flat + RM | All | `xp-mri-push-process` repo |
| SiteLink | Hourly (configurable) | Flat | All | |
| Cortland (RealPage) | — | — | Cortland only | |
| Entrata Student | — | — | Greystar only | |
| Rent Manager | — | — | All | |
| SFTP | 1x Daily (7AM CST) | — | All | Currently Equity AI products only |

### Customer Ingest

| Provider | Frequency | Pricing Support | Usage | Notes |
|----------|-----------|----------------|-------|-------|
| Spherexx / Adkast | Hourly (historically) | Flat | All | Vendor pushes to ATLAS |
| Quext | ~Every 5 min (historically) | Flat | All | Vendor pushes to ATLAS |

**Key:** Flat = flat pricing only. RM = revenue management pricing. Flat + RM = both supported.

## Feed Naming Convention

Format follows ATLAS data standards (see [[reference/data-standards]]):

| Deployment | Naming Pattern |
|------------|---------------|
| CMS | `{Asset Name} - {Provider} Push [ipadpush.mytouchtour.com]` |
| Kubernetes | `{Asset Name} - {Provider} Push [SMCTL]` |
| Customer Ingest | `{Asset Name} - Vendor Push [{Account} / {Provider}]` |

## Requesting a New Custom Integration

New custom integrations require a Non-Standard Integration Request. These are not self-service — they require approval and additional engineering effort.

## Related

- [[reference/data-standards]] — ATLAS naming conventions and tagging
- [[integrations/]] — Standard (native ATLAS) integration docs
- [[products/]] — SightMap and Atlas product context

---

*Last updated: 2026-03-10 | Owner: Kam Deno*
