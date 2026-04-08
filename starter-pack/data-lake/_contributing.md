# Contributing to the Engrain Knowledge Base

> This guide explains how anyone at Engrain can add or update knowledge docs.

## Where Does My Doc Go?

| If your doc is about... | Put it in... |
|------------------------|-------------|
| A product (SightMap, Atlas, APIs) | `products/` |
| A PMS integration or data feed | `integrations/` |
| Customer personas, onboarding, support | `customers/` |
| A business process (sales, hiring, releases) | `operations/` |
| Architecture, code, infrastructure | `technical/` |
| Company info (mission, values, org chart) | `company/` |
| Quick-lookup data (pricing, glossary, contacts) | `reference/` |
| A step-by-step task guide ("How to do X") | `journeys/` |

**Still unsure?** Pick the domain that's the closest fit. Cross-domain topics go where the *primary* audience would look first, with [[links]] to related docs elsewhere.

## Document Template

Every doc should follow this structure:

```markdown
---
title: Your Document Title
labels: [label1, label2]
owner: Team or Person
updated: YYYY-MM-DD
notion_link: https://notion.so/... (if source lives in Notion)
---

# Your Document Title

> One-line summary of what this doc covers.

## Overview
Brief introduction — what is this, why does it matter?

## [Main Sections]
Content organized with clear headers (H2, H3).
Use tables, lists, and code blocks where helpful.

## Related
- [[other-doc]] - Why it's related
- [[another-doc]] - Why it's related

---
*Last updated: YYYY-MM-DD | Owner: Team or Person*
```

## Guidelines

### Content
- **Be comprehensive** — one thorough doc is better than many fragments
- **Use clear headers** — AI and humans both benefit from well-structured content
- **Use Engrain terminology** — see `_context.md` for the terminology table
- **Link generously** — use `[[doc-name]]` to connect related topics

### Labels
Add relevant labels in frontmatter. Common labels:

| Label | Use for |
|-------|---------|
| `product` | Product-related content |
| `pms` | PMS integration content |
| `sales-relevant` | Useful for sales team |
| `cs-relevant` | Useful for customer success |
| `engineering` | Technical content |
| `process` | Business process docs |
| `reference` | Quick-lookup data |
| `onboarding` | Useful for new employees |

### Notion Links
If the source of truth for a doc lives in Notion, include the `notion_link` in frontmatter. This enables future automated sync.

### Ownership
Every doc needs an `owner` in frontmatter. The owner is responsible for keeping the doc current. If you don't know who should own it, set `owner: TBD` and flag it.

## Updating Existing Docs

1. Edit the doc directly
2. Update the `updated` date in frontmatter
3. If you change scope significantly, update the domain's `_overview.md`

---

*Questions? Reach out to {{NAME}}.*
