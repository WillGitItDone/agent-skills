# QA Review: {BRANCH_NAME}

**Repo:** {REPO_NAME}
**Branch:** `{BRANCH_NAME}` → `{TARGET_BRANCH}`
**Jira Ticket:** [{TICKET_KEY}](https://engrain.atlassian.net/browse/{TICKET_KEY})
**Reviewed:** {DATE}

---

## 🎫 Ticket Summary

> {Brief summary of what the Jira ticket asks for, including issue type and key acceptance criteria}

## 📊 Branch Overview

- **Commits:** {N} commits
- **Files changed:** {N}
- **Lines:** +{added} / -{removed}

### Changed Files
| File | Change Type | Lines |
|------|------------|-------|
| {file path} | {modified/added/deleted} | +{n}/-{n} |

## 🎯 Scope Check

| Acceptance Criteria | Status | Notes |
|--------------------|--------|-------|
| {AC from ticket} | ✅ / ❌ / ⚠️ | {explanation} |

**Out-of-scope changes:** {List any changes not related to the ticket, or "None"}

## 🔍 Code Review Findings

### ❌ Blockers
{Issues that must be fixed before merge. If none, write "None."}

### ⚠️ Concerns
{Issues worth discussing or watching. If none, write "None."}

### 💡 Suggestions
{Non-blocking improvements. If none, write "None."}

## 📏 Convention Compliance

**AGENTS.md files checked:** {list}

| Convention | Status | Details |
|-----------|--------|---------|
| {convention name} | ✅ / ⚠️ | {details} |

## 🧪 Test Coverage

- **New test files:** {list or "None"}
- **Modified test files:** {list or "None"}
- **Assessment:** {Good / Adequate / Insufficient — with reasoning}
- **Untested paths:** {list specific code paths lacking tests, or "None identified"}

## 🔎 Related Code Check

{Search for code that might also need changes but wasn't touched. For example:
seeders, factories, other serializers/transforms, reports, exports, event payloads.}

- **Seeders checked:** {Yes/No — list any that need updating, or "N/A"}
- **Factories checked:** {Yes/No — list any that need updating, or "N/A"}
- **Other serializers/transforms:** {List any found that may need the new field, or "None found"}
- **Assessment:** {All related code updated / Gaps identified — list them}

## 📡 API Contract

{Only include this section if API routes, transformers, or response shapes changed.
Otherwise write "No API changes detected."}

- **Routes changed:** {list}
- **OpenAPI spec updated:** Yes / No / N/A
- **Breaking changes:** Yes / No

---

## 🏁 Verdict

{One of the following:}

**✅ Ready to Merge** — Code meets acceptance criteria, follows conventions, and has adequate test coverage.

**⚠️ Merge with Concerns** — Functional but has items worth addressing. List the key concerns.

**❌ Changes Needed** — Blockers must be resolved before merge. List the blockers.
