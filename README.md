# Agent Skills

Shared skill library for Copilot CLI users at Engrain.

## Available Skills

| Skill | Description | Version |
|-------|-------------|---------|
| [api-data-fetch](skills/api-data-fetch/) | Bulk-fetch data from SightMap or UnitMap APIs for a list of Engrain asset IDs. Walks the user through selecting an API, resource group, and GET endpoint, then makes sequential API calls and compiles all response data into a single CSV. GET-only — no POST, PUT, DELETE, or PATCH calls are ever made. | 1.1.0 |
| [build-integration](skills/build-integration/) | Build new PMS integrations for Engrain. Covers the full lifecycle: smctl client, smctl command, tests, atlas container, and atlas deployment. Use this when asked to build, scaffold, or plan a new integration with a Property Management System. | 1.2.0 |
| [jira-ticket](skills/jira-ticket/) | Write Jira tickets for the SightMap team at Engrain. Use this when asked to write, draft, or create a Jira story, epic, or bug. Loads Engrain context, applies the 6-section template with correct Jira formatting (blue/green panels), calibrates tone from examples, and creates or updates the ticket via MCP. | 1.1.0 |
| [qa-review](skills/qa-review/) | QA review skill for Engrain PRs. Use this when asked to QA, review, or validate a feature branch or PR. Extracts the Jira ticket from commit messages, fetches ticket details via mcp-atlassian, diffs the branch against its target, and produces a structured QA report checking scope, code quality, conventions, and test coverage. | 1.1.0 |
| [release-notes](skills/release-notes/) | Release Notes skill for Engrain. Use this when asked to write, generate, or draft a release note (internal or external). Accepts a Jira ticket key, fetches ticket details, and produces a formatted internal release note using the appropriate LaunchNotes template. Includes hero image upload and LaunchNotes API integration. | 2.0.0 |
| [skill-share](skills/skill-share/) | Browse, install, update, and publish Copilot CLI skills from the shared agent-skills repo. Use this when asked to list skills, install a skill, update skills, or share/publish a skill. | 2.1.0 |

## Skill Details

### api-data-fetch

Bulk-fetch data from SightMap or UnitMap APIs for a list of Engrain asset IDs. Walks the user through selecting an API, resource group, and GET endpoint, then makes sequential API calls and compiles all response data into a single CSV. GET-only — no POST, PUT, DELETE, or PATCH calls are ever made.

### build-integration

Build new PMS integrations for Engrain. Covers the full lifecycle: smctl client, smctl command, tests, atlas container, and atlas deployment. Use this when asked to build, scaffold, or plan a new integration with a Property Management System.

**Requirements:**
- Environment variables: `SIGHTMAP_API_KEY`
- CLI tools: `git`, `deno`, `docker`
- MCP tools: `mcp-atlassian-jira_get_issue`

### jira-ticket

Write Jira tickets for the SightMap team at Engrain. Use this when asked to write, draft, or create a Jira story, epic, or bug. Loads Engrain context, applies the 6-section template with correct Jira formatting (blue/green panels), calibrates tone from examples, and creates or updates the ticket via MCP.

**Requirements:**
- Environment variables: `JIRA_API_TOKEN`, `JIRA_URL`, `JIRA_USERNAME`
- CLI tools: `python3`
- MCP tools: `mcp-atlassian-jira_create_issue`, `mcp-atlassian-jira_update_issue`, `mcp-atlassian-jira_get_issue`, `mcp-atlassian-jira_search`

### qa-review

QA review skill for Engrain PRs. Use this when asked to QA, review, or validate a feature branch or PR. Extracts the Jira ticket from commit messages, fetches ticket details via mcp-atlassian, diffs the branch against its target, and produces a structured QA report checking scope, code quality, conventions, and test coverage.

**Requirements:**
- Environment variables: `JIRA_API_TOKEN`, `JIRA_URL`, `JIRA_USERNAME`
- CLI tools: `git`
- MCP tools: `mcp-atlassian-jira_get_issue`

### release-notes

Release Notes skill for Engrain. Use this when asked to write, generate, or draft a release note (internal or external). Accepts a Jira ticket key, fetches ticket details, and produces a formatted internal release note using the appropriate LaunchNotes template. Includes hero image upload and LaunchNotes API integration.

**Requirements:**
- Environment variables: `LAUNCHNOTES_API_TOKEN`, `LAUNCHNOTES_PROJECT_ID`
- MCP tools: `mcp-atlassian-jira_get_issue`

### skill-share

Browse, install, update, and publish Copilot CLI skills from the shared agent-skills repo. Use this when asked to list skills, install a skill, update skills, or share/publish a skill.

**Requirements:**
- CLI tools: `git`

## Quick Start

### Install the skill-share skill (one-time bootstrap)

```bash
git clone https://github.com/WillGitItDone/agent-skills.git ~/.copilot/skill-cache/agent-skills
cp -R ~/.copilot/skill-cache/agent-skills/skills/skill-share ~/.copilot/skills/skill-share
```

Then restart your Copilot CLI session. You'll see `skill-share` in `/skills`.

### Use skill-share to manage skills

- *"List available skills"*
- *"Install the jira-ticket skill"*
- *"Update all my skills"*
- *"Setup credentials"*

---

*This README is auto-generated by the skill-share skill. Do not edit manually.*
