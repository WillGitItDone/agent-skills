---
name: smartsheet-lookup
description: >
  Look up, read, or summarize data from a customer's Smartsheet. Use this for
  general data questions (what value is in a cell, how many rows match a condition,
  etc.). Do NOT use this for validation or diagnostic questions — use
  smartsheet-validation instead when the user asks whether anything is wrong,
  wants a health check, or wants to know why a fee isn't appearing.
version: 2.1.0
requires:
  env:
    - SMARTSHEET_API_TOKEN
---

# Smartsheet Lookup Skill

You are accessing a customer's Smartsheet to read and analyze data. All sheet
access uses the Smartsheet REST API directly via `curl`.

## API Basics

- **Base URL**: `https://api.smartsheet.com/2.0/`
- **Auth header**: `-H "Authorization: Bearer $SMARTSHEET_API_TOKEN"`
- **Token location**: `~/.copilot/credentials.env`

Always load the token with:
```bash
source ~/.copilot/credentials.env
```

**Never expose the token.** Assign it to a shell variable silently — never run
commands that print it to stdout (e.g., `printenv | grep`, `echo $TOKEN`,
`env | grep SMARTSHEET`). To verify the token is present, print only a masked
version:
```bash
echo "Token: ${SMARTSHEET_API_TOKEN:0:4}***"
```
Use `curl -s` (not `-sv`) to suppress verbose headers that might reveal the token.

## Process

### Step 1: Identify the Sheet

Resolve the Sheet ID from `Companies_on_Automation.csv`.

1. Check the **Config** table in `local.md` for a `csv_path` entry.
2. If a path is recorded **and the file exists**, use it.
3. If no path is recorded or the file doesn't exist there, search in order:
   - `~/Desktop/xp-fee-team/Updated Fee Update Automation/Companies_on_Automation.csv`
   - `~/Repos/xp-fee-team/Updated Fee Update Automation/Companies_on_Automation.csv`
4. If found during the search, **update `local.md`** with the discovered path
   (preserve all existing content) before continuing.
5. If the CSV can't be located, inform the user, and ask them to provide the path to the CSV. Update `local.md` with the provided path before continuing.
6. If the CSV is available, read it and **fuzzy-match** the customer name
   (case-insensitive, partial match is fine). Each row is formatted as:
   `Company Name, SheetID`
   - If a single match is found, decide whether it is **confident** or **iffy**:
     - **Confident** (proceed without asking): only case, spacing, or punctuation
       differs, OR one name is a prefix/abbreviation of the other (every word in
       the shorter name appears in the longer name) — e.g., `"avenue5"` →
       `"Avenue 5"`, `"Hines"` → `"Hines Residential"`, `"Lyon"` → `"Lyon Living"`.
     - **Iffy** (ask the user first): a word in the user's query does not appear
       in the CSV match at all — e.g., `"Asset Living"` → `"Asset West"` where
       `"Living"` doesn't appear in `"Asset West"`. Tell the user what was found
       and ask them to confirm before proceeding.
   - If multiple matches are found, list the candidates and ask the user to confirm.
   - If no match is found, tell the user and fall through to the manual fallback below.
7. **API sheet lookup fallback** (company not found in CSV): Call the Smartsheet API
   to search all accessible sheets.

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
      - There is no `errorCode` key in the response (API errors surface this way)

      If the file is missing, invalid, empty, or contains an error, delete
      `/tmp/smartsheet_sheets_list.json`, skip to item 8, and tell the user the
      API lookup failed.

   c. Use Python to fuzzy-match the customer name against the `name` field of each
      sheet in `data`. Matching rules:
      - Case-insensitive, partial match (same logic as the CSV lookup)
      - Also try stripping common title boilerplate like `"Engrain Fee Template - "`
        from the sheet name before scoring — match against both the full title and
        the stripped title
      - Keep only reasonably strong matches: at minimum, at least one word from the
        customer name must appear in the sheet title (after stripping)
      - Cap results at the top 5 candidates; if all matches are very weak or no
        results pass the minimum threshold, skip to item 8

   d. Handle match outcomes — **always confirm with the user, regardless of match
      confidence.** API results are unverified; never silently use an API-matched
      sheet.
      - **No usable matches** → skip to item 8
      - **One match** → report the sheet title and ID, ask:
        > "I found a sheet titled '**[title]**' (ID: `[id]`) — is this the right one?"
      - **Multiple matches** → number each candidate with title and ID, ask:
        > "I found a few possible matches — which one would you like to use?
        > 1. [Title A] (ID: `[id]`)
        > 2. [Title B] (ID: `[id]`)"

      If the user does not confirm or selects none, fall through to item 8.

   e. On confirmation, extract the confirmed sheet's `id` from
      `/tmp/smartsheet_sheets_list.json`. If the file is no longer present
      (e.g., the user took multiple turns to reply), re-fetch using the same
      `curl` command before extracting. Use this ID for the rest of the skill.

   f. **Delete `/tmp/smartsheet_sheets_list.json` immediately** after the ID is
      confirmed and extracted — do not wait until Step 5.

8. **Manual fallback** (CSV missing, company not found, or API lookup failed): Ask the user:
   > "Could you provide the Smartsheet Sheet ID directly? You can find it under
   > File → Properties in Smartsheet."
   - If the user provides an ID, use it. If not, stop.

> **Read-only:** Never write to, modify, move, rename, or delete
> `Companies_on_Automation.csv`.

### Step 2: Report the Sheet Title

Before reading data, fetch the sheet's name from the API and report it to the user.

```bash
source ~/.copilot/credentials.env
curl -s -H "Authorization: Bearer $SMARTSHEET_API_TOKEN" \
  "https://api.smartsheet.com/2.0/sheets/{sheetId}?pageSize=1" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['name'])"
```

Example output: _"Accessing sheet: **Engrain Fee Template - Indigo Real Estate Services**"_

This is the **only** time you should pipe API output directly into context. For all subsequent 
data access, use the temp file pattern described in Step 3 to ensure token efficiency.

### Step 3: Read the Sheet

Use `curl` to call the Smartsheet REST API. **Never pipe a full-sheet response
directly into Python** — the raw JSON enters your context window and is
extremely token-expensive for large sheets. Instead, cache the full sheet to
disk and read from the file.

#### Cache the full sheet to disk

```bash
source ~/.copilot/credentials.env
SHEET_FILE="/tmp/smartsheet_{sheetId}.json"
if [ ! -f "$SHEET_FILE" ]; then
  curl -s -H "Authorization: Bearer $SMARTSHEET_API_TOKEN" \
    "https://api.smartsheet.com/2.0/sheets/{sheetId}" > "$SHEET_FILE"
fi
```

The `if` guard reuses the file if it was already fetched earlier in the same
task — no redundant API calls.

#### Targeted row fetch

When you know specific row numbers in advance (e.g., error rows from a validation
script), use `?rowNumbers=...` to fetch only those rows. Always cache to disk and
filter with Python — never pipe the API response directly into context.

```bash
source ~/.copilot/credentials.env
SHEET_FILE="/tmp/smartsheet_{sheetId}.json"
if [ ! -f "$SHEET_FILE" ]; then
  curl -s -H "Authorization: Bearer $SMARTSHEET_API_TOKEN" \
    "https://api.smartsheet.com/2.0/sheets/{sheetId}?rowNumbers=4,5,8" > "$SHEET_FILE"
fi
```

#### API response structure

- **`columns`**: array of `{"id": <columnId>, "title": <column name>, ...}`
- **`rows`**: array of `{"rowNumber": <UI row number>, "cells": [{"columnId": <id>, "value": <value>}, ...]}`

To read a cell value, match `cell.columnId` to the column with the desired title.

**Token efficiency:** Always use the temp file pattern — for full-sheet fetches and
targeted row fetches alike. Never pipe the API response directly into context.
The temp file ensures only filtered Python output enters context, regardless of
response size.

If you cannot fetch the sheet data because of an API error, inform the user and stop. 
Do not attempt to proceed without the data.

### Step 4: Answer the Question

Answer the user's question based on the data you've read. Be specific: reference
actual values, column names, and row content from the sheet.

Common question types:
- **Lookups**: "What is the value of the application fee for Century Bridges?", "How long is the tooltip label for the fee on line 4?"
- **Summaries**: "How many fees have is_enabled set to True?", "Which fees are text-based?"

If the data is ambiguous or incomplete, say so clearly and ask for clarification.

#### Find the answer in the data
Use Python to filter, aggregate, or summarize the cached sheet data as needed to 
answer the question. 

The user's question might specify specific row numbers. In that case, filter the data and
print only those rows into context, and use them to answer the question. 
For example, if they ask a question about lines 4, 5, and 8, use code like this:

```bash
python3 -c "
import json
with open('/tmp/smartsheet_{sheetId}.json') as f:
    d = json.load(f)
cols = {c['id']: c['title'] for c in d['columns']}
target = {4, 5, 8}  # UI row numbers to examine
for row in d['rows']:
    if row['rowNumber'] in target:
        cells = {cols[c['columnId']]: c.get('value', '') for c in row['cells'] if c['columnId'] in cols}
        print(row['rowNumber'], cells)
"
```

The user's question might contain other filtering criteria too, like property name, fee label, etc.,
or a combination of several criteria. In that case, apply those filters before printing into context.
For example, if they ask specifically about storage fees, you could use code like this:

```bash
python3 -c "
import json
with open('/tmp/smartsheet_{sheetId}.json') as f:
    d = json.load(f)
cols = {c['id']: c['title'] for c in d['columns']}
label_col = next(id for id, t in cols.items() if 'label' in t.lower())
matches = [row for row in d['rows']
           if any(c['columnId'] == label_col and 'storage' in str(c.get('value','')).lower()
                  for c in row['cells'])]
print(len(matches), 'matching rows')
for row in matches:
    cells = {cols[c['columnId']]: c.get('value', '') for c in row['cells'] if c['columnId'] in cols}
    print(row['rowNumber'], cells)
"
```

**Bottom line:** Filter the cached sheet data to whatever is relevant to answer the user's question,
and nothing more. Do not print the entire sheet or large unfiltered sections of it into context, unless
absolutely necessary to answer the question.

Always reference specific values, column names, and row numbers in 
your explanation.

### Step 5: Clean up when done with the task

```bash
rm -f /tmp/smartsheet_{sheetId}.json /tmp/smartsheet_sheets_list.json
```

Replace `{sheetId}` with the actual Sheet ID. The sheets list file should already be
deleted after Step 1 — this is a safety net in case it wasn't cleaned up earlier.

## Notes

- This skill is **strictly read-only** — never add, update, or delete rows under
  any circumstances, even if the user explicitly asks. If asked to make edits,
  politely refuse and direct the user to make changes directly in Smartsheet.
- If the API token is missing or expired, tell the user to check
  `~/.copilot/credentials.env` and regenerate at
  Smartsheet → Account → Personal Settings → API Access.
- Never print the `SMARTSHEET_API_TOKEN` value in output. Use `curl -s` (not `-sv`)
  to suppress verbose headers.
