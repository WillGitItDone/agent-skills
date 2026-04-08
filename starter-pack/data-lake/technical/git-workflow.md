---
title: Git Workflow & Best Practices
labels: [technical, engineering, process, git]
owner: Engineering
updated: 2026-03-10
notion_link: https://notion.so/Git-Best-Practices-1e2e5e3f60dd48bdaf3cda2d4cefb32c
---

# Git Workflow & Best Practices

> Engrain's Git branching model, commit conventions, and PR workflow. Applies to all Engrain Products.

## Branch Organization

| Branch Type | Purpose | Rules |
|-------------|---------|-------|
| **master** (main) | Production. Users see this. People pay for this. | Never commit directly. |
| **develop** | Staging area for features before release. | Never commit directly. All changes via feature branch merges. |
| **feature/** | Isolated environment for a single issue. | Always branch from latest `develop`. |

### Branch Naming

- Format: `feature/short-descriptive-name`
- All lowercase, hyphens for spaces
- No emojis in branch names

### Creating a Feature Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/short-name develop
```

## Commit Conventions

### Work-in-Progress Commits

Format: `wip (<ISSUE_CODE>)` — no period required.

Skip CI pipelines with `[skip-ci]`:
```
wip (SM-1234) [skip-ci]
```

### Ready (Final) Commits

Format: `:emoji: Description (ISSUE-CODE).` — **period required.**

Rules:
- Present tense imperative: "Add feature" not "Added feature" / "Moves cursor"
- Start with an emoji shortcode (see table below)
- Include Jira issue code(s) in parentheses
- Multiple issues: `Add a feature (TEST-1, TEST-2).`

### Squash Policy

All WIP commits must be squashed into **one ready commit per issue** before creating a PR. Every commit should be atomic and stable.

```bash
git checkout develop
git pull
git checkout feature/short-name
git rebase -i develop
```

After rebase, force push: `git push -u origin feature/short-name --force`

## Pull Requests

- **PR title must match the final commit message exactly**
- Destination branch: `develop` (verify before creating)
- Enable "Delete branch after merge"
- Add description only if it provides useful context for reviewers
- Default reviewers are typically pre-configured per repo

## Emoji Shortcodes

Use the shortcode (e.g., `:art:`), **not** the unicode emoji. This enables leadership to query and report on work categories.

| Emoji | Shortcode | Use |
|-------|-----------|-----|
| 🎨 | `:art:` | Code structure/format |
| 🐛 | `:bug:` | Bug fixes |
| 🐎 | `:racehorse:` | Performance |
| 📝 | `:pencil:` | Documentation |
| 🔥 | `:fire:` | Remove code/files, significant refactors |
| 💥 | `:boom:` | Breaking changes to backward compatibility |
| ✅ | `:white_check_mark:` | Tests |
| 🔒 | `:lock:` | Security |
| ⬆ | `:arrow_up:` | Upgrade dependencies |
| ⬇ | `:arrow_down:` | Downgrade dependencies |
| 🚓 | `:police_car:` | Standards/best practices |
| 🚱 | `:non-potable_water:` | Memory leaks |

## Git Configuration

Required for all engineers:

```bash
git config --global user.name 'FIRST_NAME LAST_NAME'
git config --global user.email 'EMAIL@ENGRAIN.COM'
git config pull.rebase true
git config --global core.editor "code --wait"
```

## Workflow Summary

```
develop (pull latest)
  └─ feature/short-name (branch off)
       ├─ wip (SM-1234) [skip-ci]     ← work-in-progress
       ├─ wip (SM-1234) [skip-ci]     ← more progress
       └─ :emoji: Description (SM-1234).  ← squash into final
            └─ rebase onto develop
                 └─ force push
                      └─ PR (title = commit message)
                           └─ merge into develop
```

## Related

- [[operations/]] — Release process (when distilled)
- Jira is used for issue tracking — include issue codes in all commits

---

*Last updated: 2026-03-10 | Owner: Engineering*
