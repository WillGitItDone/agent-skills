---
name: release-notes
description: >
  Release Notes skill for Engrain. Use this when asked to write, generate, or draft
  a release note (internal or external). Accepts a Jira ticket key, fetches ticket
  details, and produces a formatted internal release note using the appropriate
  LaunchNotes template. Includes hero image upload and LaunchNotes API integration.
version: 2.0.0
requires:
  env:
    - LAUNCHNOTES_API_TOKEN
    - LAUNCHNOTES_PROJECT_ID
  tools:
    - mcp-atlassian-jira_get_issue
---

# Release Notes Skill

You are generating an internal release note for Engrain using the LaunchNotes system.

## Process

Follow these steps exactly.

### Step 1: Identify the Jira Ticket

The user will provide a Jira ticket key (e.g., `SM-3028`). If they don't, ask:
"What's the Jira ticket number for this release?"

### Step 2: Fetch the Jira Ticket

Use the `jira_get_issue` tool to fetch the ticket. Read:

- **Summary** — the title of the change
- **Description** — full context, implementation notes, and acceptance criteria
- **Issue type** — Story, Bug, Task, Improvement, etc.
- **Status** — confirm it's done / in review / ready to release
- **Labels** — may indicate product area (SightMap, TouchTour, Atlas, etc.)

### Step 3: Determine the Release Note Type

**Always ask the user to select the release note type** unless they have already
specified it in their request. Do not infer or reason about the type based on the
Jira ticket contents or issue type.

Prompt the user with these choices:
- **Improvement**
- **Bug Fix**
- **New Feature**

### Step 4: Load the Correct Template and TouchTour Context

For any TouchTour release note, read `/Users/alexlevangie/Timmy/knowledge/touchtour.md` before writing.

**Critical:** TouchTour's front end is rendered from a JSON service feed delivered by the CMS backend. CMS changes are **not reflected immediately** on the front end — they only take effect **after a TouchTour restart**. Never use language like "immediately," "automatically," or "in real time" when describing how CMS changes surface on the front end. Instead use:
> "After saving your changes in the CMS, the updated configuration will be applied on the next TouchTour restart."

Read the appropriate template from `/Users/alexlevangie/Timmy/templates/launchNotes/`:

| Note Type | Template File |
|-----------|--------------|
| New Feature | `new-feature-template.md` |
| Bug Fix | `bug-template.md` |
| Improvement | `improvements-template` |

Also read `/Users/alexlevangie/Timmy/templates/launchNotes/examples/README.md` to
calibrate tone, detail level, and terminology before writing.

### Step 5: Write the Release Note

Use the loaded template structure. Fill it in using ticket details.

#### New Feature

**What's changed?**
- Start with a single summary sentence: what was added, where it appears, and who benefits.
- Add context on how the feature works (UI behavior, Atlas config, workflows).
- If it affects multiple surfaces (e.g., SightMap front-end AND Atlas), describe each separately.

**When was this feature released?**
- Use the format: `This feature was implemented in [Month Year] and is now live.`
- Use the current month/year if not specified in the ticket.

**What's important or valuable about this change?**
- 3–5 bullet points describing user/business benefits.
- Focus on outcomes, not implementation.

**How to get started?**
- If automatically enabled: "No action is required." Then specify where: "This update has been automatically applied to [specific surface/endpoint/environment]."
- If optional/off by default: describe where to enable it with the exact UI path (e.g., `Atlas → SightMap Configuration → Expenses`).
- If setup is required: provide brief steps or link to a guide.

---

#### Bug Fix

**What was the issue?**
- Describe the problem that was resolved: what feature/area was affected, what the fix ensures.

**Who was affected and when?**
- When the issue first appeared, and which users/integrations were impacted.
- **Name the affected audience specifically** — don't write "some users." Use concrete personas:
  "developers using the Pathfinding SDK," "mobile visitors on landing pages,"
  "integrations consuming the MITS resource." Mine the Jira ticket for the real impacted group.

**What's improved with this fix?**
- Bullet points describing what works correctly now.
- May include a closing sentence about overall system consistency.

**When did it change?**
- Format: `This update went live in [Month Year].`

**What does the customer need to do?**
- If no action needed: "No action is required." **Then add specificity about where the fix
  was applied** — e.g., "The fix has been automatically applied to the MITS resource in
  the SightMap REST API" or "included in the next beta release on [date]."
  Never leave this section as just "No action is required" with no further detail.
- If action is needed: describe what users should do (refresh, reconfigure, etc.)

---

#### Improvement

**What was the initial challenge or limitation that led to this improvement?**
- Describe the gap, pain point, or previous behavior that was being addressed.

**What was the improvement?**
- One clear sentence describing what changed.

**How was the improvement made?**
- Bullet points describing system-level behavior changes (no code details).

**What's improved with this change?**
- 3–5 bullet points of practical benefits.

**When was this improvement released?**
- Format: `This update went live in [Month Year].`

**How to get started?**
- Default: "No action is required." Then specify where: "This update has been automatically applied to [specific surface/endpoint/environment]."
- If configuration is needed, provide the exact UI path and briefly explain.

---

### Step 6: Apply Style Guidelines

Always follow these rules regardless of note type:

**Tone:**
- Professional, clear, internal-facing, moderately technical
- No marketing language, no humor, no casual commentary
- No Jira ticket references in the note body
- No code-level details (no class names, file names, DB schemas, commit references)

**Terminology — always use Engrain terms:**

| Use | Not |
|-----|-----|
| Asset | Property (in SightMap context) |
| PMS | Property Management System (spell out on first use) |
| Feed | Data sync / integration |
| Consumer | API client / partner |
| Unit-level data | Apartment data |
| Atlas | The internal management UI |
| SightMap | The interactive map product |

**Formatting:**
- Bold section headers
- Short paragraphs — prefer concise over exhaustive
- Bullet points for benefits or steps
- End every bullet point sentence with a period
- Match product UI terminology exactly (e.g., "Calculator Modal", "Unit Toggle")

**Writing calibration — always apply these principles:**
- **Be concise.** Get to the point quickly. Avoid restating what was just said in a different way.
- **Prefer tight bullet labels.** Lead each benefit bullet with a short, bold label followed by a colon and one clear sentence (e.g., "More accurate move-in cost estimates: Explains why...").
- **Avoid over-explaining.** Don't add subsections or extra prose when a single clear sentence will do.
- **"How to get started?" should be steps, not paragraphs.** Use a numbered list with a brief closing sentence summarizing the outcome. Include the exact UI path (e.g., `Atlas → SightMap Configuration → Expenses`).
- **"What's changed?" should open with one summary sentence**, followed only by what's necessary to understand the change — not a full re-description of every implementation detail.
- **Reference SM-3167's release note** (`projects/release-notes/SM-3167-release-note.md`) as the gold standard for tone, length, and structure.

### Step 7: Output

Display the completed release note in the conversation in clean markdown.

Then ask the user:
> "Would you like me to save this as a file, push it to LaunchNotes as a draft, or both? Is there anything you'd like to adjust?"

**If saving as a file**, write it to:
`/Users/alexlevangie/Timmy/projects/release-notes/{TICKET_KEY}-release-note.md`

Create the `projects/release-notes/` directory if it doesn't exist.

**If pushing to LaunchNotes**, follow Step 8.

### Step 8: Push to LaunchNotes (Optional)

When the user approves the release note and wants it pushed to LaunchNotes, create a
**draft announcement** via the LaunchNotes GraphQL API. Never publish directly — always
create as a draft for human review.

**API Configuration:**
- Endpoint: `https://app.launchnotes.io/graphql`
- Auth: `Authorization: Bearer $LAUNCHNOTES_API_TOKEN` (env var from `~/.zshrc`)
- Project ID: `$LAUNCHNOTES_PROJECT_ID` (env var from `~/.zshrc`)

**Step 8a: Create the draft announcement**

Use `bash` with `curl` or `python3` to call the GraphQL API:

```python
import json, subprocess

query = """mutation CreateAnnouncement($input: CreateAnnouncementInput!) {
  createAnnouncement(input: $input) {
    announcement { id headline state privatePermalink }
    errors { message path }
  }
}"""

variables = {
    "input": {
        "announcement": {
            "projectId": os.environ["LAUNCHNOTES_PROJECT_ID"],
            "headline": "<RELEASE NOTE TITLE>",
            "contentMarkdown": "<FULL MARKDOWN BODY — exclude the HTML comment line>"
        }
    }
}
```

**Step 8b: Upload hero image and add category/change type labels**

Every release note pushed to LaunchNotes must include a hero image. Select the
image based on the **product** and **release note type**.

Hero images are stored in two locations:
- **TouchTour images:** `templates/launchNotes/` (in the workspace)
- **All other product images:** `~/.copilot/skills/release-notes/` (shipped with the skill)

| Product | Bug Fix | Improvement | New Feature |
|---------|---------|-------------|-------------|
| TouchTour (all) | `templates/launchNotes/tt-bug-fix.png` | `templates/launchNotes/tt-improvement.png` | `templates/launchNotes/tt-new-feature.png` |
| SightMap | `~/.copilot/skills/release-notes/sm-bug-fix.png` | `~/.copilot/skills/release-notes/sm-improvement.png` | `~/.copilot/skills/release-notes/sm-new-feature.png` |
| Asset Intelligence | `~/.copilot/skills/release-notes/ai-bug-fix.png` | `~/.copilot/skills/release-notes/ai-improvement.png` | `~/.copilot/skills/release-notes/ai-new-feature.png` |
| Spaces | `~/.copilot/skills/release-notes/spaces-bug-fix.png` | `~/.copilot/skills/release-notes/spaces-improvement.png` | `~/.copilot/skills/release-notes/spaces-new-feature.png` |

For products not listed above (API, ATLAS, Portal, Shade, Unit Map), ask the user
to provide a hero image or skip the hero image step.

**Upload workflow (3 steps):**

1. **Get file metadata** — compute byte size and MD5 checksum (base64-encoded):
```python
import os, hashlib, base64
img_path = "<path to image from table above>"
size = os.path.getsize(img_path)
with open(img_path, "rb") as f:
    checksum = base64.b64encode(hashlib.md5(f.read()).digest()).decode()
```

2. **Create a direct upload** — call `createDirectUpload` to get a pre-signed S3 URL:
```python
query = """mutation CreateDirectUpload($input: CreateDirectUploadInput!) {
  createDirectUpload(input: $input) {
    blob { id signedId url headers imagekitUrl }
    errors
  }
}"""
variables = {
    "input": {
        "filename": os.path.basename(img_path),
        "byteSize": size,
        "checksum": checksum,
        "contentType": "image/png"
    }
}
```

3. **PUT the file to S3** — upload the binary file to the returned `url` with the
   returned `headers` (parsed from JSON string):
```python
headers = json.loads(blob["headers"])
# Use curl: curl -X PUT <url> --data-binary @<img_path> -H "Content-Type: ..." -H "Content-MD5: ..."
```

Then **update the announcement** with the hero image `signedId`, category, and change type
in a single call:

```python
query = """mutation UpdateAnnouncement($input: UpdateAnnouncementInput!) {
  updateAnnouncement(input: $input) {
    announcement { id heroImage { url filename } categories { id name } changeTypes(first: 10) { nodes { id name } } }
    errors { message path }
  }
}"""

variables = {
    "input": {
        "announcement": {
            "id": "<ANNOUNCEMENT_ID from step 8a>",
            "heroImage": "<signedId from createDirectUpload>",
            "categories": [{"id": "<CATEGORY_ID>"}],
            "changeTypeIds": ["<CHANGE_TYPE_ID>"]
        }
    }
}
```

**Category mapping (product → LaunchNotes category ID):**

| Product | Category ID |
|---------|------------|
| API | `cat_0h4MbtUUt6fva` |
| Asset Intelligence | `cat_dL9SZVutFm8a3` |
| ATLAS | `cat_t1Tws8b8Hgepa` |
| Portal | `cat_BYa8QF0PW7tFy` |
| SightMap | `cat_EKO0fQQFToACg` |
| Spaces | `cat_C9x9f5TqWnf8i` |
| TouchTour Flex | `cat_e5uBymxWMWoY4` |
| TouchTour Senior | `cat_ewSeZ3wpOdSxz` |
| TouchTour for iPad | `cat_sRPrxsmRtoXDY` |
| Shade | `cat_MKSF0ceb7nomA` |
| Unit Map | `cat_eumNvVI7go4k6` |

**Change type mapping (note type → LaunchNotes change type ID):**

| Note Type | Change Type ID |
|-----------|---------------|
| Bug Fix | `ct_rAlWEagdNeb7b` |
| New Feature | `ct_OLwWThtwkFjFf` |
| Integrations | `ct_uC9B6OPAxi5GN` |
| Partnerships | `ct_NUQhTu2nCOI7W` |

Note: There is no "Improvement" change type in LaunchNotes currently. For improvement
notes, use **New Feature** as the change type, or ask the user which label to apply.

**Step 8c: Report back to the user**

After a successful push, display:
- The announcement ID
- The state (should be "draft")
- The private permalink (link to view/edit in LaunchNotes)
- The hero image URL

Example:
> ✅ Draft announcement created in LaunchNotes.
> - **ID:** ann_AXuod5nap6KC9
> - **Status:** Draft
> - **Hero image:** tt-improvement.png
> - **Review link:** https://app.launchnotes.com/projects/$LAUNCHNOTES_PROJECT_ID/announcements/<ID>/published

If there are errors, display them and ask the user how to proceed.

**Templates in LaunchNotes** (reference only — do NOT use `templateId` on create):

| Template | ID |
|----------|-----|
| Bug Fix | `tem_4o5rKg7m9LChx` |
| Improvement | `tem_RhfJWamrI122p` |
| Feature Announcement [TT] | `tem_Nn1WHqtkkZIBt` |
| Feature Announcement [SightMap] | `tem_N2H7m94Ym58kw` |
| Feature Announcement [AI] | `tem_FGrmSzGfmKIIf` |
| Code or Feature Removal | `tem_ldaxSI6nvn9Cm` |
| Spaces Update | `tem_ZTKyfhHNPClE4` |

> **⚠️ Template API limitation:** While `CreateAnnouncementAttributes` accepts a
> `templateId` field, passing it **overrides both headline and contentMarkdown**
> with the template's placeholder content — and the template structure is sticky
> (it re-applies on subsequent updates, overwriting custom content). There is no
> reliable way to create a template-linked draft with custom content via API.
> Instead, create without `templateId` and provide content directly via
> `contentMarkdown`. The content already follows the template structure since
> we write it from the same templates in `templates/launchNotes/`.

---

## Important Notes

- **Match the examples.** Study `templates/launchNotes/examples/README.md` before writing.
  The examples show exact tone, sentence structure, and level of detail expected.
- **Don't over-explain.** Release notes are scannable. Prefer brevity over exhaustiveness.
- **Don't invent.** If the ticket is missing context (e.g., when the bug started, who was
  affected), note it and ask the user to fill in the gap before finalizing.
- **Date handling.** Use soft timeline language — "late 2025," "February 2026," "March 2026"
  rather than exact dates. Only pin to a specific day when it matters to the customer
  (e.g., a beta release date or a known regression date). Use the current month/year
  if the ticket doesn't specify.
- **Multi-ticket releases.** If the user provides multiple tickets, generate one note per
  ticket unless they explicitly ask for a combined digest.
- **Bundle related fixes.** If multiple small fixes stem from the same recently-shipped
  feature, combine them into one release note and reference the original launch note.
  Don't write separate notes for each micro-fix.
- **Strip implementation details aggressively.** Jira tickets contain PR links, Loom videos,
  code snippets, DB column names, and migration strategies. The release note should describe
  *what changed* and *why it matters* — never *how it was built*. Example: Jira says
  "application-layer migration to a new float column" → Note says "a new database column
  to store decimal values."
- **Surface business context.** Tickets often assume domain knowledge. Connect technical
  changes to their business context (e.g., `per_installment` → student housing,
  delivery-generated maps → directions mode). Ask the user when the business context
  isn't clear from the ticket alone.
