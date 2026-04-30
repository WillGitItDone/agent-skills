---
name: smartsheet-validation
description: >
  Validate a customer's Smartsheet fee configuration for errors. Use this when
  the user asks whether anything is wrong, wants a health check, asks why a fee
  isn't showing up, or wants to validate a customer's fee setup. Runs
  Fee_Validation.py and classifies issues as true errors vs. warnings. Can also
  draft a customer-facing email. Prefer this skill over the smartsheet-lookup
  skill for any diagnostic or validation question.
version: 1.0.0
requires:
  env:
    - SMARTSHEET_API_TOKEN
  bins:
    - python3
---

# Smartsheet Validation Skill

You are helping the Engrain Fees Team diagnose data entry errors in customer fee
configurations. You will run `Fee_Validation.py`, interpret its output, and optionally
draft a customer-facing email summarizing the issues and how to fix them.

## Process

Follow these steps exactly.

### Step 1: Identify information from the user's question

Parse the user's prompt for:
- **Customer name** (e.g., "Mill Creek", "The Blue") — **exactly one company is required**
- **Property name** (e.g., "Westhouse Flats", "3100 Pearl") - may be omitted if the 
  customer has only one property or if the user is asking about a fee that isn't property-specific
- **Specific fee / fees** (e.g., "pet fee", "security deposits") — may be omitted if the
  user wants a full validation

**This skill validates one company at a time.** If the user:
- **Does not name a company** → do not proceed; ask them to specify exactly one company.
- **Names more than one company** → do not proceed; tell them only one company can be
  validated at a time and ask them to pick one.
- **Asks to validate all companies** → do not proceed; tell them only one company can be
  validated at a time and ask them to specify which one.

If anything else is ambiguous, ask the user to clarify before proceeding.

### Step 2: Locate Fee_Validation.py and Companies_on_Automation.csv

Check `local.md` in this skill's directory for `script_path` and `csv_path` entries.

**For `script_path` (Fee_Validation.py):**
- If a path is recorded **and the file exists at that path**, use it.
- If no path is recorded or the file doesn't exist there, search in this order:
  1. `~/Desktop/xp-fee-team/Fee_Validation/Fee_Validation.py`
  2. `~/Repos/xp-fee-team/Fee_Validation/Fee_Validation.py`
- If found, **update `local.md`** with the discovered path before continuing.
- If not found, ask the user for the path, then update `local.md`.

**For `csv_path` (Companies_on_Automation.csv):**
- If a path is recorded **and the file exists at that path**, use it.
- If no path is recorded or the file doesn't exist there, search in this order:
  1. `~/Desktop/xp-fee-team/Updated Fee Update Automation/Companies_on_Automation.csv`
  2. `~/Repos/xp-fee-team/Updated Fee Update Automation/Companies_on_Automation.csv`
- If found, **update `local.md`** with the discovered path before continuing.
- If not found, ask the user for the path, then update `local.md`.

### Step 3: Resolve the Company Name

Read `Companies_on_Automation.csv` to get the list of valid company names.

- Fuzzy-match the user-provided company name against the names in the
  CSV (case-insensitive, partial match is fine). Use the exact name from the CSV when
  calling the script.
- For each match found, decide whether it is **confident** or **iffy**:
  - **Confident** (proceed without asking): only case, spacing, or punctuation differs,
    OR one name is a prefix/abbreviation of the other (every word in the shorter name
    appears in the longer name) — e.g., `"avenue5"` → `"Avenue 5"`, `"Hines"` →
    `"Hines Residential"`, `"Lyon"` → `"Lyon Living"`.
  - **Iffy** (ask the user first): a word in the user's query does not appear in the CSV
    match at all, meaning a word was substituted — e.g., `"Asset Living"` → `"Asset West"`
    where `"Living"` does not appear in `"Asset West"`. Tell the user what was found and
    ask them to confirm or correct it before proceeding.
- If the user-provided name is ambiguous (multiple matches), list the candidates and ask
  the user to confirm which one they mean.
- If the user-provided name has no match in the CSV, tell the user and proceed to the API
  sheet lookup fallback below.
- If the user did not specify a company, ask them to provide exactly one before proceeding.
- If the user specified more than one company, tell them only one company can be validated
  at a time and ask them to specify which one they want.
- If the user asked to validate all companies, tell them only one company can be validated
  at a time and ask them to specify which one they want.

### Step 3a: API Sheet Lookup Fallback (company not found in CSV)

a. Fetch the full sheets list and cache it to disk:
   ```bash
   source ~/.copilot/credentials.env
   curl -s -H "Authorization: Bearer $SMARTSHEET_API_TOKEN" \
     "https://api.smartsheet.com/2.0/sheets?includeAll=true" \
     > /tmp/smartsheet_sheets_list.json
   ```
   Always write to the temp file — never pipe this response into context.

b. **Validate the response before proceeding.** Use Python to check that:
   - The file is valid JSON with a `data` array
   - The `data` array is not empty
   - There is no `errorCode` key in the response

   If the file is missing, invalid, empty, or contains an error, delete
   `/tmp/smartsheet_sheets_list.json`, skip to Step 3b, and tell the user the API lookup failed.

c. Use Python to fuzzy-match the customer name against the `name` field of each sheet in
   `data`. Matching rules:
   - Case-insensitive, partial match (same logic as the CSV lookup)
   - Also try stripping common title boilerplate like `"Engrain Fee Template - "` from the
     sheet name before scoring — match against both the full title and the stripped title
   - Keep only reasonably strong matches: at minimum, at least one word from the customer name
     must appear in the sheet title (after stripping)
   - Cap results at the top 5 candidates; if all matches are very weak or no results pass the
     minimum threshold, skip to Step 3b

d. Handle match outcomes — **always confirm with the user, regardless of match confidence.**
   API results are unverified; never silently use an API-matched sheet.
   - **No usable matches** → skip to Step 3b
   - **One match** → report the sheet title and ID, ask:
     > "I found a sheet titled '**[title]**' (ID: `[id]`) — is this the right one?"
   - **Multiple matches** → number each candidate with title and ID, ask:
     > "I found a few possible matches — which one would you like to use?
     > 1. [Title A] (ID: `[id]`)
     > 2. [Title B] (ID: `[id]`)"

   If the user does not confirm or selects none, fall through to Step 3b.

e. On confirmation, extract the confirmed sheet's `id` from
   `/tmp/smartsheet_sheets_list.json`. If the file is no longer present (e.g., the user
   took multiple turns to reply), re-fetch using the same `curl` command before extracting.

f. **Delete `/tmp/smartsheet_sheets_list.json` immediately** after the ID is confirmed and
   extracted — do not wait until the end of the skill.

g. Use this sheet ID for both Step 4 (`--sheet_ids`) and Step 6 (sheet fetching). Proceed
   to Step 4.

### Step 3b: Manual Sheet ID Fallback (API lookup failed or user didn't confirm)

Ask the user:
> "Could you provide the Smartsheet Sheet ID directly? You can find it under
> File → Properties in Smartsheet."

- If the user provides an ID, use it for Step 4 (`--sheet_ids`) and Step 6. Proceed to Step 4.
- If the user does not provide one, stop.

### Step 4: Run Fee_Validation.py

**Before running the script, check for existing results.** Look in
`<script_dir>/Validation_Results/` for the most recently modified subfolder that
contains a per-company CSV for the company being validated.
- If you have a company name from Step 3, look for a per-company CSV named after that company.
- If you have a confirmed sheet ID from Step 3a or Step 3b, look for a per-company CSV named after that sheet ID rather than the company name.

Then apply these rules:

- **No existing results found** → run the script.
- **Results found, older than 1 hour** → rerun automatically. Do not ask the user;
  stale results are not safe to reuse.
- **Results found, less than 1 hour old** → **you must ask the user before doing
  anything else.** Do not proceed until you have their answer. Ask: *"I found
  validation results from [X minutes] ago — would you like to use those or run a
  fresh validation?"* This step is mandatory and cannot be skipped regardless of
  context (e.g., even if a fresh validation was just run earlier in the same
  conversation).
- **Age cannot be determined** → rerun. When in doubt, always rerun.

Use the file modification time (`os.path.getmtime`) of the per-company CSV to determine
age. Never reuse results without explicitly asking the user first.

**Having result data in your context window does not satisfy this check.** If you
already have validation results in memory from an earlier turn, you must still
physically check the filesystem for the per-company CSV and apply the rules above.
Never skip Step 4 because you remember prior results.

**Run the script.** Build the command from the arguments available:

```bash
python3 <script_path> --companies "<name>" [--mode <mode>]
# OR, when a sheet ID was obtained from Step 3a or Step 3b:
python3 <script_path> --sheet_ids "<sheetId>" [--mode <mode>]
```

- Use **`--companies`** with the single company name resolved from the CSV in Step 3 when
  the company was found in the CSV.
- Use **`--sheet_ids`** when a sheet ID was obtained via the API fallback (Step 3a) or
  manually provided (Step 3b). **Never pass both `--companies` and `--sheet_ids` together,
  and never pass more than one sheet ID.**
- When `--sheet_ids` is used, the per-company output CSV will be **named after the sheet ID**
  rather than the company name — use the sheet ID when locating the output file in Step 5.
- Include `--mode` only if the user explicitly asks to validate **only live** or **only non-live** 
  fees. Valid values are `live`, `non-live`, and `all`. In practice, omit
  this argument in almost all cases — the script defaults to `all`, which is correct.
  - `live` — validates only rows where **Engrain Asset ID is filled out**
  - `non-live` — validates only rows where **Engrain Asset ID is blank**
  - `all` (default) — validates every row regardless of live status

Capture the full output (stdout and stderr). Script output is typically short — it
is safe to capture into a shell variable or read inline; unlike sheet data, no disk
caching is needed. If the script errors out, report the error to the user and ask
for guidance before continuing.

### Step 5: Read the Output CSVs

After the script finishes, locate the output directory:

```
<script_dir>/Validation_Results/
```

where `<script_dir>` is the directory containing `Fee_Validation.py`. Inside, find the
**most recently timestamped subfolder** (e.g., `Validation_Results_(all_fees)_Apr13_0233PM/`).
That folder contains:

- **Summary CSV**: `Validation_Summary_(<mode>_fees)_<timestamp>.csv`
  — one row per company, high-level counts
- **Per-company CSVs**: `<Company Name>_Validation_Results_(<mode>_fees)_<timestamp>.csv`
  — one row per error type for that company. **When the script was run with `--sheet_ids`,
  this file is named after the sheet ID instead of the company name.**

**Summary CSV columns:**

| Column | Meaning |
|--------|---------|
| `Company` | Company name |
| `Total Fees` | Total fee rows validated |
| `Good Fees` | Fee rows with no errors |
| `Fees with Errors` | Fee rows with at least one error |
| `Fees with Errors Proportion` | Percentage of fee rows with errors |
| `Missing Columns` | Any required columns entirely absent from the sheet |

**Per-company CSV columns:**

| Column | Meaning |
|--------|---------|
| `Error` | Machine error code (e.g., `amount_missing`) |
| `Error Description` | Short human-readable description |
| `Error Count` | Number of fee rows affected |
| `Out Of` | Total fee rows of the relevant type |
| `Proportion` | Percentage of relevant rows affected |
| `Long Error Description` | Detailed explanation of why this is an error |
| `Error Example` | Example of a bad value seen in the data |
| `Good Example` | Example of a valid value for this field |
| `Error Rows` | Smartsheet row numbers with this error |
| `Some Good Rows` | Sample of row numbers without this error |

**Row count discrepancy is normal.** The script may report fewer rows than the
total sheet row count (e.g., "70 rows" on a 133-row sheet). This happens because
blank rows are filtered out before validation. Importantly, the remaining rows
keep their original **Smartsheet UI row numbers** — the sequential integers
displayed in the leftmost column of the sheet. So `Error Rows` values are
reliable and correctly identify those rows. Trust them and use them as-is.

### Step 6: Interpret and Present Findings

1. **Cache the sheet to disk — only if errors exist.** If the validation script
discovered errors, it will say so in the per-company CSV. In this case, fetch the full
sheet and cache it to a temp file. 

```bash
source ~/.copilot/credentials.env
SHEET_FILE="/tmp/smartsheet_{sheetId}.json"
if [ ! -f "$SHEET_FILE" ]; then
  curl -s -H "Authorization: Bearer $SMARTSHEET_API_TOKEN" \
    "https://api.smartsheet.com/2.0/sheets/{sheetId}" > "$SHEET_FILE"
fi
```

The sheet ID comes from:
- The CSV row matched in Step 3 (when the company was found in the CSV), or
- The confirmed sheet ID from Step 3a or Step 3b (API lookup or manual fallback).

The `if` guard reuses the file if it was already fetched earlier in the same
task — no redundant API calls.

**API response structure:**
- **`columns`**: array of `{"id": <columnId>, "title": <column name>, ...}`
- **`rows`**: array of `{"rowNumber": <UI row number>, "cells": [{"columnId": <id>, "value": <value>}, ...]}`

To read a cell value, match `cell.columnId` to the column with the desired title.

**Never pipe a full-sheet response directly into Python** — the raw JSON enters your
context window and is extremely token-expensive for large sheets. Always write the
response to a temp file and filter with Python.

Clean up the temp file when Step 6 is complete. Alternatively, if the per-company CSV
has no rows (zero error types found), skip fetching the sheet and proceed directly to
presenting findings.

2. **Filter the sheet data to the relevant rows.** Apply all filters before loading
any rows into context — the full sheet may have hundreds of rows but only a fraction
are relevant. Work through these layers in order:

- **Criteria filter** (specific queries only): if the user is asking about a specific
  fee, type of fee, property, or combination of criteria, filter to those rows first.
  Skip this layer for full-sheet validations.

  **Before filtering on any user-supplied term** (property name, fee label, expense
  type, etc.), resolve it against the actual values present in the cached sheet.
  Apply the same confident/iffy logic as Step 3:
  - **Confident** (filter without asking): only case, spacing, or punctuation differs,
    or the user's term is a prefix/abbreviation of a sheet value (every word in the
    shorter name appears in the longer).
  - **Iffy** (ask the user first): a word in the user's term does not appear in the
    closest sheet match at all. Tell the user what value was found and ask them to
    confirm before filtering.
  - **No match**: tell the user the value wasn't found and, where practical, list the
    available values so they can correct it.
    
- **Error row filter**: filter to only the rows identified in `Error Rows` from the
  per-company CSV.
- **Sampling** (full validations only): for each error type, if more than 5 rows remain,
  randomly select 5 to load into context. If 5 or fewer, load all. Skip this layer for
  specific-fee or specific-property queries.

Apply every applicable layer before loading anything. Never print the entire sheet into
context.

**Example**: If a user asks about errors with "pet fees", filter to rows where the fee
label contains "pet" (case-insensitive), then filter to the error rows. (No sampling —
this is a specific query, not a full validation.)

> **Note:** If no rows remain after filtering, report to the user that the validation
> script didn't find any errors matching their criteria. Tell them the Smartsheet may
> need human review in case the script missed something, or that the issue may be on 
the SightMap/Engrain side rather than in the sheet data.

3. **Classify and analyze errors.**

**Classify each issue as a true error or warning.** Read the `Long Error Description`
and use judgment:

- **❌ True error**: the fee is blocked — cannot be stored, processed, or displayed in
  SightMap. Examples: "cannot be ingested into Sightmap", "cannot be processed",
  "will not appear on the calculator", "prevents the fees from appearing". These are
  illustrative, not exhaustive — use judgment for descriptions that imply blocking even
  without these exact phrases.

- **⚠️ Warning**: misconfigured but the fee still appears (possibly with incorrect
  defaults). Examples: "will be marked False by default", "will be given a limit of 1
  by default", "won't have a descriptive name on the calculator". Use judgment.

When a user asks why a fee isn't appearing in SightMap, only point to **true errors**
as potential causes — never suggest a warning as the reason.

**Analyze root cause.** For each error type, examine the sampled rows and all their
columns — not just the one flagged. Reason critically about what the customer most
likely intended. The correct fix may differ from what the `Good Example` implies.

**Example:** `amount_missing` flags a missing value in the `Amount` column. The obvious
fix is to add the amount — but if the row already has a value in `Text Amount`, the root
cause is probably that `Value Type` is set to `amount` when it should be `text`.

**Before drawing any conclusions about an error type**, check whether all rows in your 
sample share the same root cause. This is a mandatory gate for sample-based analysis — 
do not skip it if you sampled 5 rows for this error type:

- If **all rows share one root cause**: proceed with analysis. No expansion needed.
- If **rows show multiple root causes**: stop, expand the sample to up to 25 total rows
  for that error type from the cached file, then re-analyze with the expanded set before
  drawing conclusions.

If multiple errors share the same root cause, group them and recommend a single fix.

**When multiple root causes are confirmed**, recommend one fix per root cause so the
customer knows which applies to which fees.

**Communicate sampling clearly:**
- **To the user**: note when your analysis is based on a sample; recommendations may not
  capture every root cause present in the full data.
- **In customer emails**: hedge language when working from a sample — don't mention
  sampling to the customer, but avoid ruling out additional issues (e.g., "here are some
  issues we noticed" rather than "these are the only issues").

**Self-check recommendations with schema.md.** Before suggesting any fix, read
`schema.md` in this skill's directory. It contains valid enum values (Value Type,
Frequency, Due At Timing, Expense Type) and format constraints (numeric format, length
limits, cross-field rules). Use it to ensure any value you recommend would itself pass
validation. Do not use schema.md to independently judge customer data — that is
exclusively determined by `Fee_Validation.py` output.

4. **Present findings.** Report every error and warning found, with your recommendation
for how to fix it. Use ❌ for true errors and ⚠️ for warnings:

```
## Validation Results for [Customer Name]

[X] fees validated — [N] have errors/warnings

### ❌ [Error Description] ([Error Count] fees affected)
[Why this blocks the fee — plain language]
- **Affected rows**: [Error Rows]
- _(If sampled: **Analysis based on a sample of N of M affected rows** — additional root causes may be present.)_
→ **Fix**: [Plain-language instruction]

### ⚠️ [Warning Description] ([Error Count] fees affected)
[What will happen if left unfixed — plain language, note fee still appears]
- **Affected rows**: [Error Rows]
- _(If sampled: **Analysis based on a sample of N of M affected rows** — additional root causes may be present.)_
→ **Fix**: [Plain-language instruction]
```

If the summary CSV shows `Missing Columns`, call that out prominently — a missing
required column will invalidate every fee row that depends on it.

If no issues are found, say so clearly — and still report the total fee count
(e.g., "70 fees validated — no issues found.").

### Step 7: Draft Customer Email (if requested)

If the user asks you to draft an email to the customer, write as a **helpful,
friendly fee QA analyst** — a knowledgeable colleague reaching out to help, not
a formal support department.

**Tone rules:**
- Use contractions naturally: we've, you'll, it's, here's, that's
- Write short, direct sentences — get to the point quickly
- Describe fixes conversationally: "just change X to Y" rather than "it is
  required that the X column be updated to reflect Y"
- Open warmly but without lengthy preamble
- Sign off warmly: "Thanks!" or "Let us know if you have questions!" — not "Best regards"
- **Avoid**: "please be advised", "kindly", "as per", "please do not hesitate",
  "we apologize for any inconvenience", or any other corporate filler phrases

The email should also:
- Clearly describe each issue in plain language (no internal jargon)
- Give specific, actionable steps referencing exact column names and expected values
- **Distinguish true errors from warnings in the email:**
  - **True errors**: clearly state that this issue is preventing the fee from
    appearing or being processed, and that fixing it will resolve the problem
  - **Warnings**: make clear that the fee still appears, but something is
    misconfigured and should be corrected — avoid implying it's blocking
  - If a customer reports a fee isn't showing and only warnings are present (no
    true errors), be honest: the warning is likely not the cause, and further
    investigation on the SightMap/Engrain side may be needed
- When recommending a value for an enum field (Value Type, Frequency, Due At Timing,
  Expense Type), always use a value from `schema.md`:
  - If you can confidently infer the correct value from row context → recommend that
    specific value
  - If you can't confidently infer the correct value:
    - For **Value Type, Frequency, Due At Timing** → list all valid options from
      `schema.md` so the customer can choose
    - For **Expense Type** → do NOT list the full enum; instead, use row context
      (fee label, category, frequency) to narrow it down to 2–4 plausible options
      and offer those
- Be signed generically (e.g., "The Engrain Fees Team") unless the user provides a name

Use this structure:

```
Subject: Fee Configuration Updates – [Customer Name]

Hi [Customer Name / Team],

We took a look at your fee setup and spotted a few things that need updating
before [fee(s)] will show up correctly in SightMap.

**[Fee Name]**
[Conversational description of the issue and exact fix]

**[Fee Name]**
[Conversational description of the issue and exact fix]

Once you've made these updates in your Smartsheet, everything should reflect in
SightMap shortly after[, usually within X — omit if unknown].

Let us know if you have any questions — happy to help!

Thanks,
The Engrain Fees Team
```

## Notes

- **Always load the API token with `source ~/.copilot/credentials.env`** before
  making any Smartsheet API calls. Do not improvise alternative lookup methods
  (e.g., grepping shell rc files, `printenv`, `cat ~/.copilot/env`). Never expose
  the token value in output — to verify it's present, print only a masked version:
  `echo "Token: ${SMARTSHEET_API_TOKEN:0:4}***"`
- This skill is diagnostic only — never modify the customer's Smartsheet.
- If `Fee_Validation.py` output format changes over time, adapt your interpretation
  accordingly rather than failing silently.
- When updating `local.md`, preserve all existing content and only add/update the
  relevant entry (`script_path` or `csv_path`).
- **Read-only files**: `Companies_on_Automation.csv` and all files under
  `Validation_Results/` are strictly read-only. Never write to, modify, move,
  rename, or delete them under any circumstances.
