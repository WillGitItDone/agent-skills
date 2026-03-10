---
name: qa-review
description: >
  QA review skill for Engrain PRs. Use this when asked to QA, review, or validate
  a feature branch or PR. Extracts the Jira ticket from commit messages, fetches
  ticket details via mcp-atlassian, diffs the branch against its target, and produces
  a structured QA report checking scope, code quality, conventions, and test coverage.
version: 1.1.0
requires:
  env:
    - JIRA_API_TOKEN
    - JIRA_URL
    - JIRA_USERNAME
  tools:
    - mcp-atlassian-jira_get_issue
  bins:
    - git
---

# QA Review Skill

You are performing a QA code review of a feature branch for Engrain.

## Review Philosophy

Embody Alan Kay's principle: **"Simple things should be simple, complex things should
be possible."**

Focus on code quality, readability, and adherence to required practices outlined in
AGENTS.md, README.md, and all prior art. Provide constructive feedback and suggest
improvements where necessary. Be thoughtful and critical of all changes — ask questions
if you are unsure of why a change is being made. Check for unnecessary complexity,
dead code, and suggest simplifications as needed.

## Process

Follow these steps exactly.

### Step 1: Identify the Branch and Repo

The user may provide:
- A **branch name** (e.g., `feature/add-pricing-display-tiers`)
- A **feature environment URL** (e.g., `https://add-pricing-display-tiers.feature.dev.sightmap.com/`)
- A **PR link** or number

**URL → Branch mapping:**

| URL Pattern | Repo | Branch |
|-------------|------|--------|
| `{name}.feature.dev.sightmap.com` | app-sightmap | `feature/{name}` |
| `{name}.feature.dev.unitmap.com` | app-sightmap | `feature/{name}` |

If the branch can't be inferred, search with `git branch -r | grep -i <keyword>` and
confirm with the user if multiple matches are found.

Determine the repo and its PR target branch using this mapping:

| Repo | Local Path | PR Target |
|------|-----------|-----------|
| app-sightmap | `repos/app-sightmap` | `develop` |
| app-smctl | `repos/app-smctl` | `main` |
| atlas-integrations | `repos/atlas-integrations` | `main` |
| xp-data-integrations | `repos/xp-data-integrations` | `main` |

### Step 2: Fetch Latest and Diff

Run these commands in the repo directory. **Always use `--no-pager`** to avoid
interactive pagers that block the review:

```bash
git fetch origin
git --no-pager log <target>..<branch> --oneline
git --no-pager diff <target>...<branch> --stat
```

Note the three-dot syntax (`...`) for the diff — this shows changes introduced on the
branch since it diverged from the target.

### Step 3: Extract the Jira Ticket Key

Scan the commit messages on the branch for a Jira ticket key:

```bash
git --no-pager log <target>..<branch> --format="%s" | grep -oE '[A-Z]+-[0-9]+'
```

Engrain commit convention: `:emoji: Description (SM-XXXX).`

- Use the **first unique ticket key** found.
- If multiple different keys are found, list them and ask the user which to use.
- If **no key is found**, ask the user: "I couldn't find a Jira ticket key in the
  commit messages. What's the ticket number?"

### Step 4: Fetch the Jira Ticket

Use the `jira_get_issue` tool (from mcp-atlassian) to fetch the ticket:

- Read the **summary**, **description**, and **acceptance criteria**
- Note the **issue type** (story, bug, epic, task)
- Note the **status** and **assignee**

If acceptance criteria are not explicitly labeled, look for Given/When/Then patterns
or numbered requirements in the description.

### Step 5: Identify Relevant Conventions

Based on the files changed in the diff, load the relevant AGENTS.md and README.md files:

| Files Changed In | Read |
|-----------------|------|
| `server/` | `repos/app-sightmap/server/AGENTS.md` |
| `clients/app/` | `repos/app-sightmap/clients/app/AGENTS.md` |
| `clients/customer/` | `repos/app-sightmap/clients/customer/AGENTS.md` |
| `clients/manage/` | `repos/app-sightmap/clients/manage/AGENTS.md` |
| `navigation/` | `repos/app-sightmap/navigation/AGENTS.md` |
| `geojson/` | `repos/app-sightmap/geojson/AGENTS.md` |
| `tilesets/` | `repos/app-sightmap/tilesets/AGENTS.md` |
| `openapi/` | `repos/app-sightmap/openapi/AGENTS.md` |
| Any file in app-smctl | `repos/app-smctl/AGENTS.md` |

Also read any README.md files in the same directories as changed files for prior art
and context.

Only read the files relevant to the changed paths — do not load all of them.

### Step 6: Review the Code

For each changed file, review the actual diff content:

```bash
git --no-pager diff <target>...<branch> -- <file>
```

For small diffs (under ~300 lines total), read the full diff in one call. For large
diffs (300+ lines), review per-file and use sub-agents to review files in parallel.

Apply the review philosophy throughout. For every change, ask yourself:
- **Is this simple enough?** Could it be simpler without losing capability?
- **Is there dead code?** Unused variables, unreachable branches, commented-out code?
- **Does it follow prior art?** Is it consistent with existing patterns in the codebase?
- **Why was this change made?** If the motivation isn't clear, flag it as a question.

Check for:

#### Bugs & Logic Errors
- Off-by-one errors, null/undefined checks, race conditions
- Incorrect conditional logic
- Missing return statements or early exits
- Type mismatches

#### Security
- SQL injection, XSS, mass assignment vulnerabilities
- Hardcoded credentials or secrets
- Missing authorization checks (Engrain uses Policies + Gates)
- Unsafe data handling

#### Unnecessary Complexity
- Over-engineered abstractions where a simpler approach exists
- Premature generalization
- Complex conditionals that could be simplified
- Redundant code that could be extracted or removed

#### Architecture & Conventions
- Does the code follow patterns from the relevant AGENTS.md?
- Correct use of Services, Repositories, Actions (server)
- Correct component patterns for the client (React 15 for manage, React 18 for others)
- Proper use of i18n for user-facing strings (app, customer clients)
- Database migrations have proper rollbacks

#### Related Code Search
Search for code that **might also need changes** but wasn't touched. This catches
omissions:
- If a model gained a column, search for other serializers/transforms of that model
  (e.g., `grep` for adjacent fields in the transform to find other transform methods)
- If a migration was added, check for seeders and factories that may need updating
- If an API response shape changed, check clients that consume it

#### Area-Specific Checklists

**Server (apply when `server/` files changed):**
- Migration has `down()` method (or confirm repo convention allows omission)
- Seeder updated if column added/changed (`database/seeders/`)
- Factory updated if model changed (`database/factories/`)
- `$fillable` / `$guarded` reviewed — is the new field mass-assignable as intended?
- `$casts` updated if the field needs type casting
- Policy/Gate updated if new access patterns introduced
- `phpcs` should pass (note in report if you can't run it)

**OpenAPI (apply when `openapi/` files changed):**
- Schema, path files, and examples all updated consistently
- `nullable: true` marked where appropriate
- `npx @redocly/cli lint` should pass (note in report if you can't run it)

**React Clients (apply when `clients/` files changed):**
- `clients/manage` uses React 15 patterns (no hooks, class components)
- `clients/app` and `clients/customer` use React 18 patterns
- User-facing strings wrapped in i18n (`react-intl`)
- CSS approach matches the client (CSS Modules, Ant Design, AdminLTE)

#### Test Coverage
- Are new code paths covered by tests?
- Are edge cases tested?
- Do test names clearly describe what they verify?

#### API Contract
- If API routes or transformers changed, are OpenAPI specs in `openapi/` updated?
- Are response shapes consistent with existing patterns?

### Step 7: Produce the QA Report

Output the report in two places:
1. **In the conversation** — display the **full** report (do NOT condense or summarize)
2. **As a markdown file** — save to `projects/qa-reviews/{TICKET_KEY}-review.md`

Use the template in `qa-report-template.md` in this skill's directory. The report
must include:

1. **Ticket Summary** — What the Jira ticket asks for
2. **Branch Overview** — Commits, files changed, lines added/removed
3. **Scope Check** — Does the diff match the ticket? Anything missing or extra?
4. **Code Review Findings** — Organized by severity:
   - ❌ **Blocker** — Must fix before merge
   - ⚠️ **Concern** — Worth discussing, may need changes
   - ❓ **Question** — Unclear motivation, need author to explain
   - 💡 **Suggestion** — Non-blocking improvement or simplification
5. **Convention Compliance** — Any AGENTS.md violations
6. **Test Coverage** — Assessment of test additions relative to code changes
7. **API Contract** — Only if API changes detected
8. **Verdict** — One of: ✅ Ready to Merge | ⚠️ Merge with Concerns | ❌ Changes Needed

## Important Notes

- **Be specific.** Reference exact file names and line numbers for every finding.
- **Be proportional.** A 5-line bug fix needs a quick review, not a dissertation.
- **Be constructive.** Don't just point out problems — suggest improvements.
- **Ask questions.** If you're unsure why a change was made, ask rather than assume.
- **Check for simplicity.** Flag unnecessary complexity and suggest simplifications.
- **Flag dead code.** Unused imports, unreachable branches, commented-out code.
- **Acknowledge good work.** If the code is solid, say so. Don't invent problems.
