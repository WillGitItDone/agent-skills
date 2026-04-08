---
title: Data Standards — ATLAS Naming Conventions
labels: [reference, data-governance, atlas, standard]
owner: Kam Deno
updated: 2026-03-10
notion_link: https://notion.so/Engrain-Systems-Data-Standards-1ab3924d726780ae8d51eb85fdcd88c7
---

# Data Standards — ATLAS Naming Conventions

> Naming conventions and tagging standards for Assets, Feeds, and Elements in ATLAS. Ensures data cleanliness across all internal systems and partner integrations.

## Terminology Note

"Element" refers to groupings in ATLAS: unit description groups, pricing processes, virtual tour groups, filters, outbound links, etc. — **not** granular items like individual units or floor plans.

## Tagging System

Tags use square brackets `[ ]` and appear at the start or end of a name.

| Tag | Meaning |
|-----|---------|
| `[CAMPUS]` | Multi-building campus property |
| `[DEPRECATED]` | No longer in use — see deprecated workflow below |
| `[MERGE]` | Feed that merges data from multiple sub-feeds |
| `[SUB FEED]` | Feed whose data is merged into a `[MERGE]` feed |
| `[RENTABLE ITEMS]` | Contains rentable item data |
| `[CUSTOM]` | Custom element (e.g., custom filter) |
| `[URL]` | Outbound link using hard-coded URLs |
| `[R&D]` | Research & development / testing |

## Asset Naming

**Format:** `[TAG] Property Name - Phase / Care-Level [TAG]`

| ✅ Valid | ❌ Invalid |
|----------|-----------|
| `[R&D] The Oaks - Phase I` | `The Oaks (FKA The Pines)` |
| `The Oaks [CAMPUS]` | `The Oaks (Greystar)` |
| `Senior Living Space - Independent Living` | `The Oaks (use this)` |

**Rules:**
- Name should match the Salesforce property record (but see differences below)
- No account names, FKA references, or parenthetical notes in ATLAS
- Addresses: **no abbreviations** — spell out Boulevard, Street, Avenue, etc.

### Salesforce vs ATLAS Differences

Salesforce allows abbreviations and parenthetical info for billing purposes. When creating an ATLAS Asset from a Salesforce record, **correct these before entering in ATLAS.**

## Feed Naming

**Format:** `[TAG] Asset Name (Optional Info) - Provider Name [TAG]`

| Component | Description | Example |
|-----------|-------------|---------|
| TAG | Optional context tag | `[SUB FEED]` |
| Asset Name | The ATLAS Asset this feed belongs to | `The Miro` |
| Optional Info | Phase, care level, or other context | `(Phase 2)` |
| Provider Name | The PMS/integration provider | `Yardi RentCafe v2` |

**Example:** `The Miro (Phase 2) - Yardi RentCafe v2 [SUB FEED]`

From this name, users can deduce: RentCafe v2 integration, Phase 2 data, merged with other feeds.

## Element Naming

**Format:** `[TAG] Core Grouping - Optional Info [TAG]`

Applies to: Filters, Outbound Links, Unit Descriptions, Unit Disclaimers.

### Core Groupings

| Grouping | Grouping |
|----------|----------|
| Bathrooms | Unit Features |
| Bedrooms | Unit Move-in |
| Building | Unit Price |
| Floor | Unit Status |
| Floor Plan | Rental Options |
| Property Information | Square Footage |

When an element fits multiple groupings, pick the primary one and use the Optional Info section to clarify. Example: `Floor Plan - Includes Bedroom Count`

**Example:** `Virtual Tour - Matterport [URL]` → Virtual tour data, Matterport provider, hard-coded URLs.

## Deprecated Element Workflow

When a `[DEPRECATED]` element exists and you need a similar element:

| Scenario | Action |
|----------|--------|
| Deprecated element matches your use case / provider | Remove `[DEPRECATED]` tag, update name to current conventions |
| Deprecated element is a different provider or use case | Create a new element using standard naming |

**Common processes that produce deprecated elements:** Audits, Cancellations, Feed Migrations, Transfers.

## Related

- [[products/]] — SightMap and Atlas product documentation
- [[integrations/]] — PMS provider details and feed system architecture

---

*Last updated: 2026-03-10 | Owner: Kam Deno*
