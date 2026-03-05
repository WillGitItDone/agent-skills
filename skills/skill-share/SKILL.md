---
name: skill-share
description: >
  Browse, install, update, and publish Copilot CLI skills from the shared
  agent-skills repo. Use this when asked to list skills, install a skill,
  update skills, or share/publish a skill.
---

# Skill Share

You are managing Copilot CLI skills from the shared `agent-skills` repository.

## Configuration

```
REPO_URL: https://github.com/WillGitItDone/agent-skills.git
CACHE_DIR: ~/.copilot/skill-cache/agent-skills
SKILLS_DIR: ~/.copilot/skills
```

If the repo has not been cloned yet, clone it to `CACHE_DIR`. If it already exists,
pull the latest from `main`.

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

2. Read the SKILL.md front matter (name + description) from each skill in
   `~/.copilot/skill-cache/agent-skills/skills/*/SKILL.md`.

3. For each skill, check if it's installed by looking for
   `~/.copilot/skills/{name}/SKILL.md` (case-insensitive filename match on SKILL.md
   or skill.md).

4. Present a table:

   | Skill | Description | Status |
   |-------|-------------|--------|
   | name  | description | ✅ Installed / ⬇️ Available / 🔄 Update available |

   **Determining "Update available":** Compare the repo version with the installed
   version using `diff -rq`. If any files differ, mark as 🔄.

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

6. Tell the user:
   > ✅ Installed **{name}** to `~/.copilot/skills/{name}/`.
   > Restart your Copilot CLI session (or start a new one) for the skill to appear
   > in `/skills`.

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

4. Report results:
   - List skills that were updated
   - List skills that were already up to date
   - If any installed skills are NOT in the repo (custom/local-only), note them
     as "local only — not in repo"

5. Tell the user to restart their session if any skills were updated.

---

### Publish — "publish {name}", "share {name}", "upload my {name} skill"

**Steps:**

1. Verify the skill exists at `~/.copilot/skills/{name}/`.

2. Verify it has a SKILL.md (or skill.md) with valid front matter:
   - Must have `name:` field
   - Must have `description:` field
   If front matter is missing or incomplete, help the user add it before proceeding.

3. Ensure the repo cache is up to date (same as List step 1).

4. Check if a skill with the same name already exists in the repo:
   - If yes, ask: "A skill named **{name}** already exists in the repo. Do you want
     to update it with your local version?"
   - If no, proceed.

5. Create a branch and commit:
   ```bash
   cd ~/.copilot/skill-cache/agent-skills
   git checkout main
   git pull --quiet
   git checkout -b skill/{name}
   rm -rf skills/{name}
   cp -R ~/.copilot/skills/{name} skills/{name}
   git add skills/{name}
   git commit -m ":art: Add {name} skill."
   ```
   If updating an existing skill, use commit message: `:art: Update {name} skill.`

6. Push the branch:
   ```bash
   git push origin skill/{name}
   ```

7. If the push succeeds, tell the user:
   > ✅ Pushed branch `skill/{name}` to the repo.
   > Create a PR in Bitbucket to merge it:
   > https://github.com/WillGitItDone/agent-skills/compare/skill/{name}?expand=1

8. If the push fails (e.g., no remote configured yet), tell the user:
   > ⚠️ Branch `skill/{name}` created locally but could not push — the Bitbucket
   > remote isn't set up yet. When `engrain/agent-skills` is created, run:
   > ```
   > cd ~/.copilot/skill-cache/agent-skills
   > git remote add origin https://github.com/WillGitItDone/agent-skills.git
   > git push origin skill/{name}
   > ```

9. Return to main branch:
   ```bash
   cd ~/.copilot/skill-cache/agent-skills && git checkout main
   ```

---

## Edge Cases

- **No git available:** Tell the user to install git.
- **No SSH key for Bitbucket:** If clone/push fails with auth errors, suggest:
  "Make sure you have access to the repo. Run `git ls-remote https://github.com/WillGitItDone/agent-skills.git` to test."
- **Repo not on Bitbucket yet:** Clone will fail. Fall back to local-only mode:
  check if `CACHE_DIR` exists as a local repo and use it directly. If it doesn't
  exist either, tell the user the repo hasn't been set up yet and provide manual
  setup instructions.
- **Conflicting skill names:** If the user tries to publish a skill with a name that
  differs only in case from an existing one, warn them and suggest renaming.

## Important Notes

- **Never delete a user's local skill** without explicit confirmation.
- **Always pull before any operation** to avoid working with stale data.
- **Restart required:** After install/update, skills only appear after restarting
  the Copilot CLI session.
- **This skill updates itself:** The skill-share skill is in the repo too. When the
  user runs "update all", it will update itself along with everything else.
