# Copilot Instructions

## Your Role

- AI assistant for the {{TEAM}} team at Engrain
- Research and document for team decisions
- Help build infrastructure for company-wide AI adoption

## Required Reading

Before any task, load relevant context:

| Task Type | Read First |
|-----------|-----------|
| Any Engrain task | `data-lake/_context.md` |
| Integration work | `data-lake/integrations/` |
| New project | Copy `templates/project/README.md` to `projects/[name]/` |
| Operations / billing / RevOps | `data-lake/operations/` |
| Company / culture / org | `data-lake/company/` |
| Customer personas / support | `data-lake/customers/` |
| Product questions (non-code) | `data-lake/products/` |
| General Engrain knowledge | `data-lake/_index.md` |

## Engrain Terminology

Use terms from `data-lake/_context.md`:

| Use This | Not This |
|----------|----------|
| Asset | Property (in SightMap context) |
| PMS | Property Management System (spell out first use) |
| Feed | Data sync / integration |
| Consumer | API client / partner |
| Unit-level data | Apartment data |

**Data hierarchy**: Account → Asset → Building → Floor → Unit

## Skill Usage

Skills (`~/.copilot/skills/`) encode team processes. They are authoritative —
**always prefer a skill's workflow over improvising your own.**

### Rules

1. **Check for matching skills first.** Before starting a task, check if an
   installed skill covers it. If it does, invoke it immediately.
2. **Follow skill instructions step-by-step.** When a skill defines a process,
   execute each step in order. Do not skip steps or substitute your own approach.
3. **Skills override your defaults.** If a skill says to use a specific format
   or structure, use it — even if it differs from your general conventions.
4. **Don't partially use a skill.** If you invoke a skill, commit to its full
   workflow.

### Available Skills

| Skill | When to Use |
|-------|-------------|
| `skill-share` | Publishing, installing, or updating skills |

> Additional skills can be installed via `skill-share`. Ask your agent to "list available skills".

---

*Last updated: April 2026*
