---
title: Notion Export Distillation Guide
labels: [process, internal, ai-operations]
owner: Will Fagan
updated: 2026-03-10
---

# Notion Export Distillation Guide

> How to process raw Notion exports into clean, AI-optimized Data Lake documents.

## Process

1. **Read** the full Notion export in conversation
2. **Identify** the target domain(s) using the routing table below
3. **Strip** noise (see Strip List)
4. **Distill** signal into structured markdown with frontmatter
5. **File** into the correct Data Lake domain folder
6. **Update** the domain's `_overview.md` to register the new doc
7. **Selectively update** `context/engrain-context.md` if the doc contains critical company-wide facts

## Routing Decision Tree

| If the doc is about... | File it in... |
|------------------------|---------------|
| A business process or workflow | `operations/` |
| A product feature or capability | `products/` |
| A PMS integration or data sync | `integrations/` |
| Architecture, code, or infrastructure | `technical/` |
| Company culture, values, org structure | `company/` |
| Customer personas, onboarding, support | `customers/` |
| Lookup data (pricing, glossary, contacts) | `reference/` |
| A step-by-step "how to" guide | `journeys/` |

**Multiple domains?** File in the primary domain. Add `[[links]]` to related domains.

## Strip List (Noise)

Remove or ignore these when distilling:

- **Notion UUIDs** in filenames and links (e.g., `28e3924d726780ffb4dedf9f7fd39c6d`)
- **Internal Notion links** (`https://www.notion.so/...`) — convert to `[[local-doc-name]]` if target exists in Data Lake, otherwise drop
- **`<aside>` blocks** with navigation hints only
- **Subpage index listings** ("Subpages in this Section" blocks) — these are Notion navigation, not content
- **Empty sections** or placeholder text
- **Storylane/interactive embed references** — AI can't use these
- **Transient info** — meeting links, office hours schedules, temporary hypercare details
- **Redundant formatting** — excessive bold, emoji-heavy headers, decorative elements

## Keep List (Signal)

Extract and preserve these:

| Signal Type | Example |
|-------------|---------|
| System architecture | "Salesforce is the source of truth for what was sold" |
| Responsibility tables | System of Record mapping (who owns what) |
| Process flows | Quote-to-Cash: SF RCA → Continuous → NetSuite |
| Business rules | "Amendments = Cancel/Replace, never edit mid-term" |
| Role-specific guidance | "Sales lives in Salesforce, Finance lives in NetSuite" |
| Terminology & definitions | Asset-based subscription model |
| Decision frameworks | When to do X vs Y |
| Data model relationships | Property → Quote Line (1:1 mapping) |
| Error handling patterns | "Continuous stops sync on bad data" |

## Output Format

Every distilled document must follow the Data Lake template:

```markdown
---
title: Document Title
labels: [label1, label2]
owner: Team or Person
updated: YYYY-MM-DD
notion_link: https://notion.so/original-page-url (if known)
---

# Document Title

> One-line summary of what this doc covers.

## Overview
Brief intro — what is this, why does it matter?

## [Main Sections]
Content with clear H2/H3 structure.
Tables over paragraphs where possible.

## Related
- [[other-doc]] - Why it's related

---
*Last updated: YYYY-MM-DD | Owner: Team or Person*
```

### Constraints

- **Max ~200 lines** per file — split large docs into focused files
- **Tables** for structured data, comparisons, system mappings
- **Concise prose** — no filler, no "this section covers..."
- **Engrain terminology** — Asset (not Property), PMS (not property management system after first use)

## When to Update `engrain-context.md`

Only update `context/engrain-context.md` when a Notion doc reveals:

- A new system or tool used company-wide (e.g., Salesforce RCA, NetSuite)
- A new product or major product change
- A change to company terminology or data hierarchy
- A critical business rule that affects cross-team work

Keep additions to 3-5 lines max. The Data Lake has the details.

---

*Last updated: 2026-03-10 | Owner: Will Fagan*
