---
name: jira-ticket
description: >
  Write Jira tickets for the SightMap team at Engrain. Use this when asked to write,
  draft, or create a Jira story, epic, or bug. Loads Engrain context, applies the
  6-section template with correct Jira formatting (blue/green panels), calibrates
  tone from examples, and creates or updates the ticket via MCP.
---

# Jira Ticket Skill

You are writing a Jira ticket for the SightMap team at Engrain.

## Required Context

Before writing any ticket, read these files to inform your writing:

1. **Engrain context** — `context/engrain-context.md` (terminology, data hierarchy, products)
2. **Examples** — `templates/jira/examples/README.md` (tone calibration, annotations)

Read both before drafting. Do not skip this step.

## Ticket Structure

All ticket types (stories, epics, bugs) use the same **6 sections**, in this order:

1. **User Story** (blue panel — no heading)
2. **Context**
3. **Specifications**
4. **Not in Scope**
5. **Acceptance Criteria** (green panel)
6. **Open Questions** (yellow panel — only if needed)

Every section is required. "Not in Scope" must include at least one item.

## Description Format — Markdown with Panel Markers

Write ticket descriptions in **Markdown** with `:::panel` markers for colored panels.
This format is used both for drafting and for the ADF update script.

### Panel marker syntax

```
:::panel <type>
content (regular markdown)
:::
```

Panel types: `info` (blue), `success` (green), `note` (purple), `warning` (yellow), `error` (red)

### Section formatting

**User Story** — blue info panel, heading inside:

```
:::panel info
## User Story
As a [user type]
I want [goal]
So that [benefit]
:::
```

- No bold on "As a" / "I want" / "So that"
- Multiple user stories are allowed (separate with a blank line inside the panel)

**Context** — H2 heading, regular markdown:

```
## Context

[Background, motivation, links to related tickets, why now]
```

- Link related Jira tickets: `[TICKET-KEY](https://engrain.atlassian.net/browse/TICKET-KEY)`
- Explain the "why" — not just the "what"

**Specifications** — H2 + H3 subsections:

```
## Specifications

### [Subsection Name]

- [Detailed requirements]
```

- Organize by concern (e.g., Data Model, API, UI, Behavior, Persistence)
- Use `` `code` `` for inline code references
- Use fenced code blocks for payloads or examples

**Not in Scope** — H2 heading, bullet list:

```
## Not in Scope

- [What this ticket does NOT cover]
```

- Always include at least one item

**Acceptance Criteria** — green success panel, heading inside:

```
:::panel success
## Acceptance Criteria
- Given [precondition], when [action], then [expected result].
:::
```

- Always use Given/When/Then format
- Each criterion must be independently testable by QA without asking the author
- Plain bullets (`-`), never checkboxes

**Open Questions** — warning panel, only if needed:

```
:::panel warning
## Open Questions
- [Question that needs resolution]
:::
```

## Title Conventions

- **Story/Epic titles**: `[Verb] [what] [where/for whom]`
- **Bug titles**: `[Component]: [Brief description of the issue]`

## Engrain Terminology

Always use Engrain terms — see `context/engrain-context.md`:

| Use This | Not This |
|----------|----------|
| Asset | Property (in SightMap context) |
| PMS | Property Management System (spell out first use) |
| Feed | Data sync / integration |
| Consumer | API client / partner |
| Unit-level data | Apartment data |

**Data hierarchy**: Account → Asset → Building → Floor → Unit

## Process

### Step 1: Understand the Request

Read what the user wants. If ambiguous, ask clarifying questions:
- What type of ticket? (story, epic, bug)
- What Jira project? (SM, TT, etc.)
- What's the scope — what's in and what's out?
- Are there related tickets to reference?
- Is there a specific assignee or story point estimate?

### Step 2: Load Context

Read these files (do not skip):
1. `context/engrain-context.md`
2. `templates/jira/examples/README.md` (at least the first 3 examples + Writing Principles)

### Step 3: Research Prior Art

Before drafting, check if related work already exists:

**Check the Jira ticket, not just the request.** If the user references a predecessor
ticket (e.g., "Phase 1 was SM-3084"), fetch that ticket with `jira_get_issue` AND
check its development info with `jira_get_issue_development_info` to find the branch/PR.

**Read the code, not just the ticket.** Ticket descriptions often diverge from what was
actually implemented. The branch diff is the source of truth for established patterns.
When prior art exists:
- Diff the feature branch against its target to see what was actually built
- Note implementation patterns (param naming, HTTP status codes, error handling,
  permission conventions, observer patterns) that the new ticket should follow
- Flag anything the prior ticket missed that the code added — these are implicit
  requirements the new ticket should make explicit

**Name the reference implementation in Context.** When a ticket follows an established
pattern, the Context section should link the predecessor ticket AND name the branch:
```
This ticket applies the same pattern established in [SM-XXXX|url] (Resource Name).
The implementation on branch {{feature/branch-name}} is the reference — follow the
same patterns for [specific areas].
```

### Step 4: Analyze Model Relationships (Backend Stories)

For any ticket that touches a database model, enumerate its relationships and address
cascade concerns:

- **HasMany children** — should they soft delete when the parent does? Or just become
  inaccessible? Are any of them public-facing (like landing pages)?
- **BelongsToMany pivots** — pivot detaches typically should only run on force delete
- **Parent models** — what happens to this resource when its parent is deleted?
- **Raw SQL queries** — are there queries bypassing Eloquent that need `whereNull('deleted_at')`?

Include a "Cascading Behavior" subsection in Specifications when relationships are
involved. Be explicit about what happens on soft delete vs force delete vs restore.

### Step 5: Draft the Ticket

Write the ticket following all formatting standards above. Match the tone and detail
level from the examples:

- **Right-size the detail** — a 1-point bug fix needs less spec than a 13-point integration story
- **Be specific** — name endpoints, field names, models, database columns, method names,
  permission strings, and class names when they exist or can be inferred from prior art
- **Link, don't duplicate** — reference Figma, Notion, or other tickets by URL
- **Name the data hierarchy** — specify where in Account → Asset → Building → Floor → Unit the work applies

**Organize backend/full-stack specs by layer:**
For stories that touch multiple layers, organize Specifications subsections in this order:
1. Data Model (model traits, migration, seeder)
2. API Behavior (endpoints, params, response codes, error handling)
3. Permissions / Policy (new permissions, policy methods)
4. Cascading Behavior (soft delete vs force delete vs restore)
5. Lifecycle / Jobs (scheduled tasks, background processing)
6. Observability (logging, AMQP events, metrics)
7. UI (if applicable)
8. Documentation (OpenAPI, internal docs)

Not every ticket needs all layers — use only the ones that apply.

**Always include error/edge case ACs alongside happy path:**
Don't stop at "Given X, when delete, then deleted." Also cover:
- What happens when the operation is repeated? (idempotency / 422s)
- What happens without the required permission? (403s)
- What happens when the resource is in an unexpected state? (already deleted, not deleted, etc.)
- What happens to related/child resources?

### Step 6: Confirm with User

Present the drafted ticket to the user and ask:
- Does this capture the scope correctly?
- Anything to add or remove?
- Ready to push to Jira?

### Step 7: Create or Update in Jira

#### Creating a new ticket

Use `jira_create_issue` with Markdown description (no panels). Then immediately
update it with the ADF script to add panels.

#### Updating the description (with panels)

The MCP tools (`jira_create_issue`, `jira_update_issue`) convert Markdown to ADF
internally, but their converter **does not support colored panels**. Wiki markup
`{panel:...}` also gets escaped.

**Use `scripts/jira-adf-update.py` for any description that needs panels.** This
script converts Markdown with `:::panel` markers directly to ADF and PUTs it to
the Jira v3 REST API, which renders panels natively.

**Workflow:**

1. Draft the full description in Markdown with `:::panel` markers (see format above)
2. Save to a temp file or pipe via stdin:
   ```bash
   python3 scripts/jira-adf-update.py ISSUE-KEY description.md
   # or
   cat <<'EOF' | python3 scripts/jira-adf-update.py ISSUE-KEY -
   :::panel info
   ## User Story
   As a ...
   :::
   ## Context
   ...
   :::panel success
   ## Acceptance Criteria
   - Given ...
   :::
   EOF
   ```
3. The script requires `JIRA_API_TOKEN` env var (already set in this workspace)

**For non-description fields** (summary, labels, priority, epic link, assignee),
use the MCP tools (`jira_update_issue`, `jira_create_issue`) as normal — panels
are only a description concern.

After creating/updating, confirm the ticket key and link to the user.

## Important Notes

- **Never ask for story points** — points are determined at sprint kickoff, not during ticket writing
- **Always assign tickets to Will Fagan** (`wfagan@engrain.com`) unless explicitly told otherwise
- **Reference existing tickets** when creating related work
- **Never assume the project key** — ask the user if not clear
- Output scoping documents to `projects/[project-name]/` when the ticket involves discovery or planning artifacts
