---
name: skill-share
description: >
  Browse, install, update, and publish Copilot CLI skills from the shared
  agent-skills repo. Use this when asked to list skills, install a skill,
  update skills, or share/publish a skill.
version: 2.0.0
requires:
  bins:
    - git
---

# Skill Share

You are managing Copilot CLI skills from the shared `agent-skills` repository.

## Configuration

```
REPO_URL: https://github.com/WillGitItDone/agent-skills.git
CACHE_DIR: ~/.copilot/skill-cache/agent-skills
SKILLS_DIR: ~/.copilot/skills
CREDENTIALS_FILE: ~/.copilot/credentials.env
```

If the repo has not been cloned yet, clone it to `CACHE_DIR`. If it already exists,
pull the latest from `main`.

## Frontmatter Specification

Every skill must have a `SKILL.md` (or `skill.md`) with YAML frontmatter containing
at minimum `name` and `description`. The full spec:

```yaml
---
name: my-skill            # required — lowercase kebab-case
description: >            # required — one-line summary for catalog
  What this skill does.
version: 1.0.0            # required — semver, bump on meaningful changes
requires:                  # optional — runtime dependencies
  env:                     # env vars the skill needs (checked on install)
    - MY_API_TOKEN
  tools:                   # MCP tools the skill invokes
    - mcp-server-tool_name
  bins:                    # CLI binaries needed (checked via `which`)
    - git
    - python3
---
```

## Commands

The user will ask you to do one of these things. Determine intent from their message.

---

### List — "list skills", "what skills are available", "show me skills"

**Steps:**

1. Ensure the repo cache is up to date:
   ```bash
   if [ -d ~/.copilot/skill-cache/agent-skills/.git ]; then
     cd ~/.copilot/skill-cache/agent-skills && git pull --quiet
   else
     mkdir -p ~/.copilot/skill-cache
     git clone https://github.com/WillGitItDone/agent-skills.git ~/.copilot/skill-cache/agent-skills
   fi
   ```

2. Read the SKILL.md front matter (name, description, version) from each skill in
   `~/.copilot/skill-cache/agent-skills/skills/*/SKILL.md`.

3. For each skill, check if it's installed by looking for
   `~/.copilot/skills/{name}/SKILL.md` (case-insensitive filename match on SKILL.md
   or skill.md).

4. Present a table:

   | Skill | Description | Version | Status |
   |-------|-------------|---------|--------|
   | name  | description | 1.0.0   | ✅ Installed / ⬇️ Available / 🔄 Update available |

   **Determining "Update available":** Compare the repo version with the installed
   version using `diff -rq` (exclude `.DS_Store`). If any files differ, mark as 🔄.

5. Tell the user they can say "install {name}" or "update all" to take action.

---

### Install — "install {name}", "add the {name} skill", "get {name}"

**Steps:**

1. Ensure the repo cache is up to date (same as List step 1).

2. Verify the requested skill exists in `~/.copilot/skill-cache/agent-skills/skills/{name}/`.
   If not, list available skills and ask the user to pick one.

3. Check if already installed at `~/.copilot/skills/{name}/`. If so, tell the user
   it's already installed and ask if they want to update it instead.

4. Copy the skill folder:
   ```bash
   cp -R ~/.copilot/skill-cache/agent-skills/skills/{name} ~/.copilot/skills/{name}
   ```

5. Verify the copy succeeded by listing the installed files.

6. **Run dependency checks** (see Dependency Checks section below).

7. Tell the user:
   > ✅ Installed **{name}** to `~/.copilot/skills/{name}/`.
   > Restart your Copilot CLI session (or start a new one) for the skill to appear
   > in `/skills`.

   Include any dependency warnings from step 6.

---

### Update — "update skills", "update {name}", "update all", "refresh skills"

**Steps:**

1. Ensure the repo cache is up to date (same as List step 1).

2. If a specific skill name is given, update just that one. If "all" or no name,
   update all installed skills that have a matching folder in the repo.

3. For each skill to update:
   a. Check if it exists in both the repo and `~/.copilot/skills/`.
   b. Compare with `diff -rq` (exclude `.DS_Store`).
   c. If differences found, copy the repo version over the installed version:
      ```bash
      rm -rf ~/.copilot/skills/{name}
      cp -R ~/.copilot/skill-cache/agent-skills/skills/{name} ~/.copilot/skills/{name}
      ```

4. **Run dependency checks** on each updated skill (see Dependency Checks section).

5. Report results:
   - List skills that were updated (include version numbers)
   - List skills that were already up to date
   - If any installed skills are NOT in the repo (custom/local-only), note them
     as "local only — not in repo"
   - Include any dependency warnings

6. Tell the user to restart their session if any skills were updated.

---

### Publish — "publish {name}", "share {name}", "upload my {name} skill"

**Steps:**

1. Verify the skill exists at `~/.copilot/skills/{name}/`.

2. **Validate frontmatter.** Read the SKILL.md (or skill.md) and check:
   - Must have `name:` field
   - Must have `description:` field
   - Must have `version:` field
   If any are missing, help the user add them before proceeding. Suggest a version
   of `1.0.0` for new skills, or a bumped version for existing ones.

3. **Run credential scan** (see Credential Scanning section below). If credentials
   are detected, **stop and do not proceed** until resolved.

4. Ensure the repo cache is up to date (same as List step 1).

5. Check if a skill with the same name already exists in the repo:
   - If yes, ask: "A skill named **{name}** already exists in the repo. Do you want
     to update it with your local version?"
   - If no, proceed.

6. Copy skill files to repo cache:
   ```bash
   cd ~/.copilot/skill-cache/agent-skills
   git checkout main
   git pull --quiet
   git checkout -b skill/{name}
   rm -rf skills/{name}
   cp -R ~/.copilot/skills/{name} skills/{name}
   ```

7. **Regenerate the README** (see README Generation section below).

8. Commit and push:
   ```bash
   cd ~/.copilot/skill-cache/agent-skills
   git add skills/{name} README.md
   git commit -m ":art: Add {name} skill."
   ```
   If updating an existing skill, use commit message: `:art: Update {name} skill.`

9. Push the branch:
   ```bash
   git push origin skill/{name}
   ```

10. If the push succeeds, tell the user:
    > ✅ Pushed branch `skill/{name}` to the repo.
    > Create a PR to merge it:
    > https://github.com/WillGitItDone/agent-skills/compare/skill/{name}?expand=1

11. If the push fails (e.g., no remote configured yet), tell the user:
    > ⚠️ Branch `skill/{name}` created locally but could not push. Check your
    > git remote config and authentication:
    > ```
    > cd ~/.copilot/skill-cache/agent-skills
    > git remote -v
    > git push origin skill/{name}
    > ```

12. Return to main branch:
    ```bash
    cd ~/.copilot/skill-cache/agent-skills && git checkout main
    ```

---

### Setup Credentials — "setup credentials", "configure credentials", "setup creds"

**Steps:**

1. Check if `~/.copilot/credentials.env` exists.

2. **If it does not exist**, create it with the template:
   ```bash
   cat > ~/.copilot/credentials.env << 'CREDS_EOF'
   # Copilot CLI Credentials
   # This file is sourced by your shell to provide credentials to MCP servers
   # and Copilot skills. Keep it secure (chmod 600).
   #
   # After editing, restart your shell or run: source ~/.copilot/credentials.env

   # Jira / Confluence (mcp-atlassian)
   # export JIRA_URL="https://your-org.atlassian.net"
   # export JIRA_USERNAME="you@company.com"
   # export JIRA_API_TOKEN="atl_..."
   # export CONFLUENCE_URL="https://your-org.atlassian.net/wiki"

   # GitHub (for MCP servers — copilot login handles CLI auth separately)
   # export GITHUB_TOKEN="ghp_..."

   # Bitbucket
   # export BITBUCKET_APP_PASSWORD="..."
   CREDS_EOF
   chmod 600 ~/.copilot/credentials.env
   ```

3. **If it already exists**, read it and show which variables are configured
   (show variable names only, never values):
   ```bash
   grep -E '^export ' ~/.copilot/credentials.env | sed 's/=.*//' | sed 's/export /  ✅ /'
   ```

4. **Check if `.zshrc` sources it.** Look for the source line:
   ```bash
   grep -q 'credentials.env' ~/.zshrc && echo "✅ Already sourced in .zshrc" || echo "⚠️ Not sourced in .zshrc"
   ```

5. **If not sourced**, ask the user: "Add source line to your `.zshrc`?" If yes:
   ```bash
   echo '' >> ~/.zshrc
   echo '# Copilot CLI credentials (MCP servers, skills)' >> ~/.zshrc
   echo '[ -f ~/.copilot/credentials.env ] && source ~/.copilot/credentials.env' >> ~/.zshrc
   ```

6. **Migration check.** Scan `.zshrc` for credential-like exports that should move
   to `credentials.env`:
   ```bash
   grep -nE '^export (JIRA_|CONFLUENCE_|GITHUB_TOKEN|BITBUCKET_|OPENAI_API)' ~/.zshrc
   ```
   If any are found, tell the user:
   > ⚠️ Found credentials in `.zshrc` that should move to `~/.copilot/credentials.env`:
   > [list the variable names and line numbers]
   >
   > Move them manually, then remove the old exports from `.zshrc`. This keeps your
   > shell config clean and your credentials in one secured file.

7. Tell the user:
   > Edit `~/.copilot/credentials.env` to add your API tokens, then restart your
   > shell (or run `source ~/.copilot/credentials.env`).

---

## Credential Scanning

This section is used by the **Publish** command. Run it BEFORE committing any files.

### Purpose

Prevent accidental publication of API keys, tokens, passwords, and other secrets
to the shared repo. This addresses OWASP LLM06 (Sensitive Information Disclosure).

### Scan Process

Scan **every file** in the skill folder (`~/.copilot/skills/{name}/`) for credentials:

#### 1. Regex Pattern Scan

Search all files for these patterns (case-insensitive where noted):

```
# Atlassian API tokens
atl_[A-Za-z0-9_-]{10,}

# OpenAI / AI provider keys
sk-[A-Za-z0-9_-]{20,}

# GitHub tokens
(ghp_|ghs_|gho_|github_pat_)[A-Za-z0-9_]{20,}

# AWS access keys
AKIA[0-9A-Z]{16}

# Slack tokens
xox[bpras]-[A-Za-z0-9-]{10,}

# Generic secrets (case-insensitive)
(token|secret|password|api_key|apikey|api-key)\s*[:=]\s*["'][^"'\s]{8,}["']
```

Run this as a single grep command:
```bash
grep -rnE '(atl_[A-Za-z0-9_-]{10,}|sk-[A-Za-z0-9_-]{20,}|(ghp_|ghs_|gho_|github_pat_)[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[bpras]-[A-Za-z0-9-]{10,}|(token|secret|password|api_key|apikey|api-key)\s*[:=]\s*["'"'"'][^"'"'"'\s]{8,})' ~/.copilot/skills/{name}/
```

#### 2. Value Scan (if credentials.env exists)

If `~/.copilot/credentials.env` exists, extract the actual credential values and
search for literal matches in the skill files:

```bash
# Extract values from credentials.env (skip comments and empty lines)
grep -E '^export ' ~/.copilot/credentials.env | while IFS='=' read -r key value; do
  # Strip 'export ' prefix and quotes from value
  clean_value=$(echo "$value" | sed 's/^["'"'"']//;s/["'"'"']$//')
  if [ ${#clean_value} -ge 8 ]; then
    # Search for the literal value in skill files
    grep -rl "$clean_value" ~/.copilot/skills/{name}/ 2>/dev/null
  fi
done
```

**Important:** Never display the actual credential values in output. Only show file
names and line numbers where matches were found.

#### 3. Action on Detection

**If any credentials are found:**

> 🚫 **Credential scan failed.** Found potential secrets in the following files:
>
> | File | Line | Pattern |
> |------|------|---------|
> | SKILL.md | 42 | Matches `atl_*` (Atlassian API token) |
>
> **Do not publish until resolved.** Remove the credential and use an environment
> variable instead. Declare it in your SKILL.md frontmatter under `requires.env`.

**If the user insists it's a false positive** ("it's not a credential", "publish
anyway", "false positive"):
- Allow the publish to proceed
- Add to the commit message: `⚠️ Credential scan override — user confirmed false positive.`
- Tell the user: "Publishing with override. The PR reviewer should double-check
  the flagged content."

**If no credentials found:**
> ✅ Credential scan passed — no secrets detected.

---

## README Generation

This section is used by the **Publish** command. Run it AFTER copying skill files
to the repo cache, BEFORE committing.

### Process

1. Read the SKILL.md frontmatter from every skill in the repo cache:
   ```bash
   ls ~/.copilot/skill-cache/agent-skills/skills/
   ```
   For each skill directory, read the SKILL.md and extract: `name`, `description`,
   `version`, `requires`.

2. Generate the README content using this template (replace the dynamic sections):

````markdown
# Agent Skills

Shared skill library for Copilot CLI users at Engrain.

## Available Skills

| Skill | Description | Version |
|-------|-------------|---------|
{FOR_EACH_SKILL}
| [{name}](skills/{name}/) | {description} | {version} |
{END_FOR_EACH}

## Skill Details

{FOR_EACH_SKILL}
### {name}

{description}

**Requirements:**
{IF_REQUIRES_ENV}- Environment variables: {comma-separated list of env vars}{END_IF}
{IF_REQUIRES_BINS}- CLI tools: {comma-separated list of bins}{END_IF}
{IF_REQUIRES_TOOLS}- MCP tools: {comma-separated list of tools}{END_IF}

{END_FOR_EACH}

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
4. Open a PR for review

---

*This README is auto-generated by the skill-share skill. Do not edit manually.*
````

3. Write the generated content to `~/.copilot/skill-cache/agent-skills/README.md`.

---

## Dependency Checks

This section is used by **Install** and **Update** commands. Run it AFTER copying
skill files to `~/.copilot/skills/{name}/`.

### Process

1. Read the `requires` block from the skill's SKILL.md frontmatter.

2. **Check environment variables** (`requires.env`):
   For each env var, check if it's set:
   ```bash
   [ -n "${VAR_NAME}" ] && echo "✅ ${VAR_NAME}" || echo "⚠️ ${VAR_NAME} — not set"
   ```
   If any are missing, add guidance:
   > Run "setup credentials" to configure missing environment variables,
   > or add them to `~/.copilot/credentials.env`.

3. **Check CLI binaries** (`requires.bins`):
   For each binary, check if it exists:
   ```bash
   which {bin} >/dev/null 2>&1 && echo "✅ {bin}" || echo "⚠️ {bin} — not found"
   ```
   If any are missing, suggest how to install (e.g., `brew install {bin}` on macOS).

4. **Check MCP tools** (`requires.tools`):
   This is best-effort. For each tool, note it for the user:
   > ℹ️ This skill uses MCP tool `{tool}`. Make sure the corresponding MCP server
   > is configured in your Copilot CLI settings.

5. **Never block installation** on dependency failures. Always install the skill,
   then present warnings so the user can fix issues before trying to use it.

6. Present results as a summary:
   > **Dependency check for {name}:**
   >
   > | Dependency | Type | Status |
   > |-----------|------|--------|
   > | JIRA_API_TOKEN | env | ✅ Set |
   > | JIRA_URL | env | ⚠️ Not set |
   > | git | bin | ✅ Found |
   > | python3 | bin | ✅ Found |

---

## Edge Cases

- **No git available:** Tell the user to install git.
- **No SSH key / auth failure:** If clone/push fails with auth errors, suggest:
  "Make sure you have access to the repo. Run `git ls-remote https://github.com/WillGitItDone/agent-skills.git` to test."
- **Repo not accessible:** Clone will fail. Fall back to local-only mode:
  check if `CACHE_DIR` exists as a local repo and use it directly. If it doesn't
  exist either, tell the user the repo hasn't been set up yet and provide manual
  setup instructions.
- **Conflicting skill names:** If the user tries to publish a skill with a name that
  differs only in case from an existing one, warn them and suggest renaming.
- **credentials.env doesn't exist during scan:** Skip the value scan (step 2),
  still run the regex scan (step 1).
- **Frontmatter missing `version`:** During List/Install, treat as `0.0.0` and
  note that the skill should add a version field. During Publish, require it.

## Important Notes

- **Never delete a user's local skill** without explicit confirmation.
- **Always pull before any operation** to avoid working with stale data.
- **Restart required:** After install/update, skills only appear after restarting
  the Copilot CLI session.
- **This skill updates itself:** The skill-share skill is in the repo too. When the
  user runs "update all", it will update itself along with everything else.
- **Never display credential values.** When checking credentials.env or running
  scans, show variable names and file locations only — never actual secret values.
- **README is auto-generated.** The Publish command regenerates it from frontmatter.
  Manual edits to the repo README will be overwritten on next publish.
