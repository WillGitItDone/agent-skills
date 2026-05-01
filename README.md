# Agent Skills

Shared skill library for Copilot CLI users at Engrain.

## Available Skills

| Skill | Description | Version |
|-------|-------------|---------|
| [api-data-fetch](skills/api-data-fetch/) | Bulk-fetch data from SightMap or UnitMap APIs for a list of Engrain asset IDs. | 1.1.0 |
| [build-integration](skills/build-integration/) | Build new PMS integrations for Engrain. | 1.2.0 |
| [fetch-knowledge](skills/fetch-knowledge/) | Manage a local knowledge base of web-crawled documentation. | 1.2.0 |
| [jira-ticket](skills/jira-ticket/) | Write Jira tickets for the SightMap team at Engrain. | 2.0.0 |
| [qa-review](skills/qa-review/) | QA review skill for Engrain PRs. | 1.1.0 |
| [release-notes](skills/release-notes/) | Release Notes skill for Engrain. | 2.0.1 |
| [salesforce-analytics](skills/salesforce-analytics/) | Analyze Salesforce support tickets for actionable product insights. | 1.3.0 |
| [skill-share](skills/skill-share/) | Browse, install, update, and publish Copilot CLI skills from the shared agent-skills repo. | 3.0.0 |
| [smartsheet-lookup](skills/smartsheet-lookup/) | Look up, read, or summarize data from a customer's Smartsheet. | 2.1.0 |
| [smartsheet-validation](skills/smartsheet-validation/) | Validate a customer's Smartsheet fee configuration for errors. | 1.0.0 |

## Skill Details

### api-data-fetch

Bulk-fetch data from SightMap or UnitMap APIs for a list of Engrain asset IDs. Walks the user through selecting an API, resource group, and GET endpoint, then makes sequential API calls and compiles all response data into a single CSV. GET-only — no POST, PUT, DELETE, or PATCH calls are ever made.


### build-integration

Build new PMS integrations for Engrain. Covers the full lifecycle: smctl client, smctl command, tests, atlas container, and atlas deployment. Use this when asked to build, scaffold, or plan a new integration with a Property Management System.

**Requirements:**
- Environment variables: SIGHTMAP_API_KEY
- CLI tools: git, deno, docker
- MCP tools: mcp-atlassian-jira_get_issue

### fetch-knowledge

Manage a local knowledge base of web-crawled documentation. Use this when asked to fetch docs, add a knowledge source, update knowledge files, crawl a website, or refresh external documentation for use in Copilot context.

**Requirements:**
- CLI tools: python3, bash

### jira-ticket

Write Jira tickets for the SightMap team at Engrain. Use this when asked to write, draft, or create a Jira story, epic, or bug. Loads Engrain context, applies the 6-section template with correct Jira formatting (blue/green panels), calibrates tone from examples, and creates or updates the ticket via MCP.

**Requirements:**
- Environment variables: JIRA_API_TOKEN, JIRA_URL, JIRA_USERNAME
- CLI tools: python3
- MCP tools: mcp-atlassian-jira_create_issue, mcp-atlassian-jira_update_issue, mcp-atlassian-jira_get_issue, mcp-atlassian-jira_search, mcp-atlassian-jira_create_issue_link

### qa-review

QA review skill for Engrain PRs. Use this when asked to QA, review, or validate a feature branch or PR. Extracts the Jira ticket from commit messages, fetches ticket details via mcp-atlassian, diffs the branch against its target, and produces a structured QA report checking scope, code quality, conventions, and test coverage.

**Requirements:**
- Environment variables: JIRA_API_TOKEN, JIRA_URL, JIRA_USERNAME
- CLI tools: git
- MCP tools: mcp-atlassian-jira_get_issue

### release-notes

Release Notes skill for Engrain. Use this when asked to write, generate, or draft a release note (internal or external). Accepts a Jira ticket key, fetches ticket details, and produces a formatted internal release note using the appropriate LaunchNotes template. Includes hero image upload and LaunchNotes API integration.

**Requirements:**
- Environment variables: LAUNCHNOTES_API_TOKEN, LAUNCHNOTES_PROJECT_ID
- MCP tools: mcp-atlassian-jira_get_issue

### salesforce-analytics

Analyze Salesforce support tickets for actionable product insights. Queries the Salesforce Cases API (READ-ONLY) and produces a structured report with theme clustering, sub-type analysis, repeat offenders, churn risk flags, and specific action recommendations. GET-only — no POST, PUT, PATCH, or DELETE calls are ever made.

**Requirements:**
- Environment variables: SALESFORCE_USERNAME, SALESFORCE_CONSUMER_KEY, SALESFORCE_CONSUMER_SECRET, SALESFORCE_SECURITY_TOKEN
- CLI tools: python3

### skill-share

Browse, install, update, and publish Copilot CLI skills from the shared agent-skills repo. Use this when asked to list skills, install a skill, update skills, or share/publish a skill.

**Requirements:**
- CLI tools: git, gh, python3

### smartsheet-lookup

Look up, read, or summarize data from a customer's Smartsheet. Use this for general data questions (what value is in a cell, how many rows match a condition, etc.). Do NOT use this for validation or diagnostic questions — use smartsheet-validation instead when the user asks whether anything is wrong, wants a health check, or wants to know why a fee isn't appearing.

**Requirements:**
- Environment variables: SMARTSHEET_API_TOKEN

### smartsheet-validation

Validate a customer's Smartsheet fee configuration for errors. Use this when the user asks whether anything is wrong, wants a health check, asks why a fee isn't showing up, or wants to validate a customer's fee setup. Runs Fee_Validation.py and classifies issues as true errors vs. warnings. Can also draft a customer-facing email. Prefer this skill over the smartsheet-lookup skill for any diagnostic or validation question.

**Requirements:**
- Environment variables: SMARTSHEET_API_TOKEN
- CLI tools: python3

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

## Credential Management

Skills that need API tokens expect environment variables. Store credentials in
`~/.copilot/credentials.env` (not in `.zshrc`):

```bash
# Create the file
touch ~/.copilot/credentials.env
chmod 600 ~/.copilot/credentials.env

# Add to .zshrc (one time)
echo '[ -f ~/.copilot/credentials.env ] && source ~/.copilot/credentials.env' >> ~/.zshrc
```

Then edit `~/.copilot/credentials.env` with your tokens. Run "setup credentials"
in the skill-share skill for guided setup.

## Publishing Skills

To share a skill you've created:

1. Create a `SKILL.md` with valid frontmatter (name, description, version, requires)
2. Tell Copilot: "publish my-skill-name"
3. The skill-share skill will scan for credentials, update this README, and push a branch
4. A PR is auto-created via `gh pr create`

---

*This README is auto-generated by the skill-share skill. Do not edit manually.*

