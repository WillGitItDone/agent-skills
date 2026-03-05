# Agent Skills

Shared skill library for Copilot CLI users at Engrain.

## What Are Skills?

Skills are instruction files that teach the Copilot CLI agent how to perform specific
tasks. Each skill is a folder in `~/.copilot/skills/` containing a `SKILL.md` file
(and optional supporting files). When invoked, the agent follows the skill's instructions
to complete a task.

## Available Skills

| Skill | Description |
|-------|-------------|
| [jira-ticket](skills/jira-ticket/) | Write Jira tickets for Engrain using the 6-section template with colored panels |
| [qa-review](skills/qa-review/) | QA review PRs — extracts Jira ticket, diffs branch, produces structured report |
| [skill-share](skills/skill-share/) | Browse, install, update, and publish skills from this repo |

## Quick Start

### Install the skill-share skill (one-time setup)

```bash
# Clone this repo
git clone https://github.com/WillGitItDone/agent-skills.git ~/.copilot/skill-cache/agent-skills

# Install the skill-share skill
cp -R ~/.copilot/skill-cache/agent-skills/skills/skill-share ~/.copilot/skills/skill-share
```

Then restart your Copilot CLI session. You'll see `skill-share` in your `/skills` menu.

### Use skill-share to install other skills

Once `skill-share` is installed, just ask Copilot:

- *"List available skills"*
- *"Install the jira-ticket skill"*
- *"Update all my skills"*
- *"Publish my custom skill to the repo"*

### Manual install (no skill-share)

```bash
# Clone if you haven't already
git clone https://github.com/WillGitItDone/agent-skills.git ~/.copilot/skill-cache/agent-skills

# Copy any skill to your local skills directory
cp -R ~/.copilot/skill-cache/agent-skills/skills/jira-ticket ~/.copilot/skills/jira-ticket
cp -R ~/.copilot/skill-cache/agent-skills/skills/qa-review ~/.copilot/skills/qa-review
```

## Contributing a Skill

### Skill structure

```
skills/your-skill-name/
├── SKILL.md              # Required — front matter (name, description) + instructions
├── supporting-file.md    # Optional — templates, reference docs, etc.
└── another-file.md       # Optional
```

### SKILL.md front matter

Every skill must start with YAML front matter:

```yaml
---
name: your-skill-name
description: >
  One-paragraph description of what the skill does and when to use it.
---
```

### Publishing via skill-share

If you have the `skill-share` skill installed, just ask Copilot:
*"Publish my-skill-name to the skills repo"*

It will create a branch, commit your skill, push, and guide you through the PR.

### Publishing manually

```bash
cd ~/.copilot/skill-cache/agent-skills
git checkout -b skill/your-skill-name
cp -R ~/.copilot/skills/your-skill-name skills/
git add skills/your-skill-name
git commit -m ":art: Add your-skill-name skill."
git push origin skill/your-skill-name
# Then create a PR in Bitbucket
```

## Repo Setup

This repo is hosted at https://github.com/WillGitItDone/agent-skills.
Until the Bitbucket repo is created, we will just use this git repo.
