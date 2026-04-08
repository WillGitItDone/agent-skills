---
applyTo: "templates/**,projects/**"
---

# Jira Ticket Instructions

## Templates

Always use templates from `templates/jira/`:
- `story-template.md` for user stories
- `epic-template.md` for epics
- `bug-template.md` for bugs

## Ticket Structure

All ticket types (stories, epics, bugs) use the same 6 sections:

1. **Title** — `[Verb] [what] [where/for whom]` (stories/epics) or `[Component]: [description]` (bugs)
2. **User Story** — As a / I want / So that
3. **Context** — Background, motivation, links
4. **Specifications** — Detailed requirements, implementation notes, repro steps (bugs)
5. **Not in Scope** — Explicit boundaries (always include at least one item)
6. **Acceptance Criteria** — Given/When/Then format

## Examples

Before writing any ticket, read `templates/jira/examples/README.md` for tone and detail calibration. Study the annotations to understand WHY each example works.

## Title Conventions

- **Story/Epic titles**: `[Verb] [what] [where/for whom]`
- **Bug titles**: `[Component]: [Brief description]`

## Jira Formatting Standards

When writing tickets directly to Jira, use Markdown with `:::panel` markers.
The `scripts/jira-adf-update.py` script converts this to Jira's native ADF format
with colored panels and PUTs it via the REST API v3.

### Panel marker syntax

```
:::panel <type>
content (regular markdown)
:::
```

Panel types: `info` (blue), `success` (green), `note` (purple), `warning` (yellow), `error` (red)

- **User Story block**: Wrap in `:::panel info` with `## User Story` heading inside. No bold on "As a / I want / So that" keywords.
  ```
  :::panel info
  ## User Story
  As a [user type]
  I want [goal]
  So that [benefit]
  :::
  ```
- **Acceptance Criteria block**: Wrap in `:::panel success` with `## Acceptance Criteria` heading inside. Use plain bullet points — **not** checkboxes.
  ```
  :::panel success
  ## Acceptance Criteria
  - Given [context], when [action], then [result]
  :::
  ```
- **Open Questions**: Use `:::panel warning` when questions need to be resolved.

### Pushing to Jira

Use `scripts/jira-adf-update.py` for descriptions with panels:
```bash
python3 scripts/jira-adf-update.py ISSUE-KEY description.md
```
Use MCP tools (`jira_create_issue`, `jira_update_issue`) for non-description fields
(summary, labels, assignee, etc.) and for descriptions without panels.

## Acceptance Criteria

Use Given/When/Then format:
```
Given [precondition]
When [action]
Then [expected result]
```

## Rules

- **Never ask for story points** — points are determined at sprint kickoff, not during ticket writing
- **Reference** existing tickets when creating related work
- Use Engrain terminology (see workspace instructions)
- Output scoping documents to `projects/[project-name]/`
