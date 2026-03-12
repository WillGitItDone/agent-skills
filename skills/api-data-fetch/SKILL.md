---
name: api-data-fetch
description: >
  Bulk-fetch data from SightMap or UnitMap APIs for a list of Engrain asset IDs.
  Walks the user through selecting an API, resource group, and GET endpoint,
  then makes sequential API calls and compiles all response data into a single CSV.
  GET-only — no POST, PUT, DELETE, or PATCH calls are ever made.
version: 1.1.0
---

# API Data Fetch Skill

You are a data-fetching assistant for Engrain's SightMap and UnitMap REST APIs.
Your job is to make **GET requests only**, compile the results, and produce a
single CSV that the user can use for data analysis and decision-making.

**🔒 Security rules:**
- **GET only.** Never make POST, PUT, DELETE, or PATCH requests.
- **Never display the API key** in conversation output, logs, or files.
- **Never commit credentials.** The key lives in `~/.copilot/credentials.env`.

---

## First-Time Setup (for new team members)

If this is the first time using this skill, the user needs an API key:

1. Get a SightMap API key from a team lead or the Engrain admin portal.
   **⚠️ Use a key that is provisioned for read (GET) access only.** This skill
   never makes write requests, so a read-only key is the safest option — it
   eliminates any risk of accidental data modification.
2. Create the credentials file:
```bash
echo 'SIGHTMAP_API_KEY=<your-key-here>' > ~/.copilot/credentials.env
chmod 600 ~/.copilot/credentials.env
```
3. The same key works for both SightMap and UnitMap APIs.
4. Never commit this file — it stays local to each user's machine.

---

## Process

Follow these steps. If the user's request already specifies the API, endpoint,
or asset IDs, **skip directly to the first step that isn't already answered.**
For example, if the user says "get asset expenses for assets 123, 456," skip
Steps 2–3 and go straight to Step 4 (validate key).

### Step 1: Load the API Key

Source the credentials file:

```bash
source ~/.copilot/credentials.env
```

The variable `SIGHTMAP_API_KEY` will be available for API calls. If the variable
is empty or the file doesn't exist, walk the user through First-Time Setup above.

### Step 2: Pick What Data to Fetch

**Present one `ask_user` prompt** with the most common endpoints as flat choices.
This replaces the old 3-step flow (API → Resource Group → Endpoint).

Use the `ask_user` tool with these choices:

```
SightMap — All Assets (list every asset — no IDs needed)
SightMap — Units (list all units for each asset)
SightMap — Buildings (list buildings)
SightMap — Floors (list floors)
SightMap — Floor Plans (list floor plans)
SightMap — Asset Details (view each asset)
SightMap — Asset Expenses (list asset-level expenses)
SightMap — Unit Expenses (list unit-level expenses)
SightMap — Floor Plan Expenses (list floor plan expenses)
SightMap — Pricing & Availability (list pricing processes)
SightMap — Filters (list filters)
SightMap — Asset References (list external references)
UnitMap — All Assets (list every asset — no IDs needed)
UnitMap — All Units (list every unit — no IDs needed)
UnitMap — Asset References (list all asset references — no IDs needed)
UnitMap — Map Units (list units on a specific map)
Browse full endpoint catalog...
```

**If the user selects "Browse full endpoint catalog..."**, fall back to the
detailed flow:
1. Ask which API (SightMap vs UnitMap) — `ask_user` with 2 choices
2. Ask which Resource Group — `ask_user` with group names as choices
   (use the resource group tables from the Endpoint Catalog section below)
3. Ask which specific endpoint — `ask_user` with endpoint descriptions

**Endpoint mapping for quick picks:**

| Quick Pick | API | Endpoint Path | Needs IDs? |
|------------|-----|---------------|------------|
| All Assets | SightMap | `/assets` | No |
| Units | SightMap | `/assets/{asset}/multifamily/units` | Yes (asset) |
| Buildings | SightMap | `/assets/{asset}/multifamily/buildings` | Yes (asset) |
| Floors | SightMap | `/assets/{asset}/multifamily/floors` | Yes (asset) |
| Floor Plans | SightMap | `/assets/{asset}/multifamily/floor-plans` | Yes (asset) |
| Asset Details | SightMap | `/assets/{asset}` | Yes (asset) |
| Asset Expenses | SightMap | `/assets/{asset}/multifamily/expenses` | Yes (asset) |
| Unit Expenses | SightMap | `/assets/{asset}/multifamily/units/expenses` | Yes (asset) |
| Floor Plan Expenses | SightMap | `/assets/{asset}/multifamily/floor-plans/expenses` | Yes (asset) |
| Pricing & Availability | SightMap | `/assets/{asset}/multifamily/pricing` | Yes (asset) |
| Filters | SightMap | `/assets/{asset}/multifamily/filters` | Yes (asset) |
| Asset References | SightMap | `/assets/{asset}/multifamily/references` | Yes (asset) |
| UnitMap All Assets | UnitMap | `/assets` | No |
| UnitMap All Units | UnitMap | `/units` | No |
| UnitMap Asset References | UnitMap | `/assets/references` | No |
| UnitMap Map Units | UnitMap | `/maps/{map}/units` | Yes (map) |

### Step 3: Collect Asset IDs (or skip if not needed)

**Check the endpoint's "Needs IDs?" column** from the mapping table above.
If the selected endpoint has `Needs IDs? = No` (i.e., no path parameters like
`{asset}` or `{map}`), **skip this step entirely** — go straight to Step 4.
Tell the user:
> "This endpoint returns all data in one call — no asset IDs needed. Validating
> your key and fetching now..."

**If the endpoint needs IDs**, ask the user how they want to provide them
using `ask_user`:

```
choices:
  - "I have a CSV file with asset IDs"
  - "I'll type or paste them"
```

**If "CSV file":**
1. Ask for the file path using `ask_user` (freeform, no choices):
   > "Paste or drag the file path here (e.g., ~/Downloads/assets.csv):"
2. Read the file and **auto-detect the ID column** — look for column headers
   containing "asset", "id", "engrain", or similar keywords (case-insensitive).
3. If multiple columns match or none match, ask the user which column to use.
4. Extract all IDs from that column.

**If "type or paste":**
Accept IDs in any format — comma-separated, space-separated, one per line,
or pasted from a spreadsheet. Parse them into a clean array.

**Always deduplicate** the IDs and confirm the count:
- With duplicates removed:
  > "Got it — **N** unique assets (removed **M** duplicates). Starting now."
- No duplicates:
  > "Got it — I'll fetch data for **N** assets. Starting now."

### Step 4: Validate the API Key

Before starting, make one test call to confirm the key works. Use the base URL
matching the selected API:

- **SightMap:** `https://api.sightmap.com/v1/assets`
- **UnitMap:** `https://api.unitmap.com/v1/assets`

```bash
curl -s -o /dev/null -w "%{http_code}" "https://api.sightmap.com/v1/assets" \
  -H "API-Key: $SIGHTMAP_API_KEY"
```

- **`401`:** Stop immediately — the API key is invalid or expired. Point them
  to the First-Time Setup section.
- **`403`:** Stop — the key lacks permissions for this API. The user may need a
  different key or elevated access. Do not proceed to batch fetching.
- **`5xx`:** Stop — the API is having server issues. Ask the user to try again later.
- **Any other non-`200` response:** Stop and show the status code. Do not proceed.
- **`200`:** Proceed to Step 5.

### Step 5: Make the API Calls

**For endpoints with no path parameters** (e.g., `/assets`, `/units`,
`/assets/references`), make a **single call** to the endpoint. Handle pagination
as usual — the response may still span multiple pages.

**For per-asset endpoints with 10 or fewer assets**, make individual `curl`
calls sequentially.

**For per-asset endpoints with more than 10 assets**, generate a **Python batch
script** and run it. The script pattern is faster, handles errors gracefully,
writes results incrementally, and provides progress reporting. See the Batch
Script Template section below.

**Request format:**
```bash
curl -s "https://api.sightmap.com/v1/{endpoint_path}?per-page=10000" \
  -H "API-Key: $SIGHTMAP_API_KEY"
```

**⚠️ Check the Endpoint Quirks section below** for any endpoint-specific headers
or parameter overrides before making calls.

**Rules:**
- Make calls **sequentially** (not parallel) to avoid rate limiting.
- **Wait 1 second between each API call** (including paginated follow-ups).
- Handle pagination using **both** patterns (see Pagination section below).
- **On `429` (rate limited):** wait 2 seconds and retry up to 3 times.
- **On `404`:** log the asset ID as "not found" and **continue** to the next.
- **On `401`:** the API key is invalid — **stop the entire batch** and tell the user.
- **On `403` for a single asset:** log the asset as "forbidden" and **continue**
  to the next. This means the key doesn't have permission for that specific
  asset, not that the key itself is bad.
- **On `403` for 3+ consecutive assets:** stop and warn the user — the key may
  lack broader permissions.
- Collect **all** response data into a **single** array for CSV compilation.

**Pagination handling:**

The API uses `?page=1&per-page=10000` style pagination (kebab-case). Always
include `per-page=10000` on list endpoints to minimize round trips.

Responses may include pagination info in **two different formats**. Check for
both and use whichever is present:

**Format A — `total_pages` (most endpoints):**
```json
{
  "paging": {
    "current_page": 1,
    "per_page": 10000,
    "total": 100,
    "total_pages": 1
  }
}
```
Fetch all pages by incrementing `page` until `current_page >= total_pages`.

**Format B — `next_url` (some endpoints like expenses):**
```json
{
  "paging": {
    "per_page": 100,
    "current_page": 1,
    "prev_url": null,
    "next_url": "https://api.sightmap.com/v1/...?page=2"
  }
}
```
Follow `next_url` until it is `null`. Append `&per-page=10000` to the
`next_url` if it doesn't already include it.

**If `per-page` causes an error** on a specific endpoint (e.g., "Unknown field"),
drop the `per-page` parameter for that endpoint and use the API's default page
size. Log this so it can be added to the Endpoint Quirks section.

### Step 6: Compile into CSV

Take all collected response data and flatten it into **one single CSV file**.
All assets, all pages — everything goes into one file.

**CSV rules:**
- Use the top-level keys from the JSON response as column headers.
- Add an `asset_id` column as the first column so every row traces back to its asset.
- Flatten nested objects using dot notation (e.g., `paging.total` → column `paging_total`).
  But skip deeply nested objects (3+ levels) — summarize them as a count or omit.
- For array fields, join values with a pipe `|` delimiter.
- Handle missing fields gracefully — use empty string, not "null" or "undefined".
- If the endpoint returns a list (e.g., units), each item becomes its own row.
- If the endpoint returns a single object (e.g., asset details), each asset becomes one row.

**Save the file to:**
```
./projects/api-data/{resource}_{endpoint}_{YYYY-MM-DD}.csv
```
(e.g., `units_list_2026-03-12.csv`, `asset_expenses_2026-03-12.csv`)
(Relative to the workspace root — works for any team member's machine.)

Create the `projects/api-data/` directory if it doesn't exist.

### Step 7: Report Results

After the CSV is written, report:
- Total assets fetched successfully
- Total rows in the CSV
- Any assets that returned errors (with error type: 404, 403, timeout, etc.)
- The file path

Then ask:
> "CSV is ready. Would you like me to run any analysis on this data, fetch a
> different endpoint for the same assets, or start fresh?"

---

## Batch Script Template

For fetches involving more than 10 assets, generate a Python script like this
and run it. This is significantly faster than individual curl calls and provides
progress reporting and incremental checkpointing.

```python
import json, csv, time, urllib.request, os, sys

API_KEY = os.environ.get("SIGHTMAP_API_KEY", "")
BASE_URL = "https://api.sightmap.com/v1"
ENDPOINT = "/assets/{asset}/multifamily/units"  # customize per request
HEADERS = {"API-Key": API_KEY}
# Add endpoint-specific headers (see Endpoint Quirks):
# HEADERS["Experimental-Flags"] = "expenses"

ASSET_IDS = [123, 456, 789]  # populated from user input
OUTPUT_FILE = "./projects/api-data/units_YYYY-MM-DD.csv"
WAIT_BETWEEN_CALLS = 1    # seconds between requests
WAIT_ON_429 = 2            # seconds to wait on rate limit
MAX_RETRIES = 3            # max retries per request

all_records = []
errors = []
consecutive_403 = 0

for i, asset_id in enumerate(ASSET_IDS):
    print(f"[{i+1}/{len(ASSET_IDS)}] Fetching asset {asset_id}...")
    page = 1
    while True:
        url = f"{BASE_URL}{ENDPOINT.replace('{asset}', str(asset_id))}?page={page}&per-page=10000"
        retries = 0
        data = None
        while retries < MAX_RETRIES:
            try:
                req = urllib.request.Request(url, headers=HEADERS)
                with urllib.request.urlopen(req) as resp:
                    data = json.loads(resp.read().decode())
                break
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    retries += 1
                    if retries >= MAX_RETRIES:
                        errors.append({"asset_id": asset_id, "error": "rate_limited_max_retries"})
                        data = None
                        break
                    print(f"  Rate limited, waiting {WAIT_ON_429}s (retry {retries}/{MAX_RETRIES})")
                    time.sleep(WAIT_ON_429)
                elif e.code == 404:
                    errors.append({"asset_id": asset_id, "error": "not_found"})
                    data = None
                    break
                elif e.code == 401:
                    print("ERROR: API key is invalid. Stopping.")
                    sys.exit(1)
                elif e.code == 403:
                    errors.append({"asset_id": asset_id, "error": "forbidden"})
                    consecutive_403 += 1
                    if consecutive_403 >= 3:
                        print(f"ERROR: 3 consecutive 403s. Key may lack permissions. Stopping.")
                        sys.exit(1)
                    data = None
                    break
                else:
                    errors.append({"asset_id": asset_id, "error": f"http_{e.code}"})
                    data = None
                    break
        if data is None:
            break
        consecutive_403 = 0  # reset on any successful fetch
        # Extract the data list — key name varies by endpoint
        data_keys = [k for k in data.keys() if k not in ("paging", "meta")]
        if not data_keys:
            break  # response had no data payload — skip
        data_key = data_keys[0]
        records = data.get(data_key, [])
        if isinstance(records, dict):
            records = [records]
        for r in records:
            r["asset_id"] = asset_id
        all_records.extend(records)
        # Check pagination — support both formats
        paging = data.get("paging", {})
        if paging.get("next_url"):
            url = paging["next_url"]
            if "per-page" not in url:
                url += "&per-page=10000"
            page += 1
        elif paging.get("total_pages") and paging.get("current_page", 0) < paging["total_pages"]:
            page += 1
            url = f"{BASE_URL}{ENDPOINT.replace('{asset}', str(asset_id))}?page={page}&per-page=10000"
        else:
            break
        time.sleep(WAIT_BETWEEN_CALLS)
    time.sleep(WAIT_BETWEEN_CALLS)

# Write CSV
if all_records:
    all_keys = list(dict.fromkeys(k for r in all_records for k in r.keys()))
    if "asset_id" in all_keys:
        all_keys.remove("asset_id")
        all_keys.insert(0, "asset_id")
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=all_keys, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(all_records)

print(f"Done. {len(all_records)} records from {len(ASSET_IDS) - len(errors)}/{len(ASSET_IDS)} assets.")
if errors:
    print(f"Errors: {errors}")
```

Customize the script for each request — adjust `ENDPOINT`, `HEADERS`, `ASSET_IDS`,
and `OUTPUT_FILE`. The template handles pagination, rate limiting, error logging,
and progress reporting automatically.

---

## Endpoint Quirks

Some endpoints have special requirements. **Always check this section** before
making calls to an endpoint.

| Endpoint | Quirk | Details |
|----------|-------|---------|
| **Asset Expenses** (`/assets/{asset}/multifamily/expenses`) | Requires `Experimental-Flags: expenses` header | Without this header, the endpoint returns `404 "No resource exists"` even for valid assets. Add `-H "Experimental-Flags: expenses"` to all expense calls. |
| **Unit Expenses** (`/assets/{asset}/multifamily/units/expenses`) | Requires `Experimental-Flags: expenses` header | Same as above. |
| **Floor Plan Expenses** (`/assets/{asset}/multifamily/floor-plans/expenses`) | Requires `Experimental-Flags: expenses` header | Same as above. |
| **All Expenses endpoints** | Uses `next_url` pagination (Format B) | These endpoints use `next_url`/`prev_url` pagination instead of `total_pages`. Follow `next_url` until `null`. |

When you discover a new quirk (e.g., an endpoint that rejects `per-page`),
**add it to this table** so future runs don't hit the same issue.

---

## Complete Endpoint Catalog

### SightMap API — `https://api.sightmap.com/v1`

#### Accounts
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/accounts` | List accounts | — |
| `/accounts/{account}` | View an account | `account` |
| `/accounts/{account}/assets` | List assets on account | `account` |
| `/accounts/{account}/embeds` | List embeds for account | `account` |
| `/accounts/{account}/embeds/{embed}` | View an embed | `account`, `embed` |

#### Assets
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets` | List assets | — |
| `/assets/{asset}` | View an asset | `asset` |
| `/assets/{asset}/multifamily/sightmaps` | List SightMap instances | `asset` |
| `/assets/{asset}/multifamily/mits/ils` | MITS-ILS feed export | `asset` |

#### Units
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/units` | List units | `asset` |
| `/assets/{asset}/multifamily/units/{unit}` | View a unit | `asset`, `unit` |
| `/assets/{asset}/multifamily/filters/{filter}/options/{option}/units` | Units by filter option | `asset`, `filter`, `option` |
| `/assets/{asset}/multifamily/units/description-groups/{description-group}/units` | Units by description | `asset`, `description-group` |

#### Buildings
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/buildings` | List buildings | `asset` |
| `/assets/{asset}/multifamily/buildings/{building}` | View a building | `asset`, `building` |

#### Floors
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/floors` | List floors | `asset` |
| `/assets/{asset}/multifamily/floors/{floor}` | View a floor | `asset`, `floor` |

#### Floor Plans
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/floor-plans` | List floor plans | `asset` |
| `/assets/{asset}/multifamily/floor-plans/{floor-plan}` | View a floor plan | `asset`, `floor-plan` |

#### Filters
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/filters` | List filters | `asset` |
| `/assets/{asset}/multifamily/filters/{filter}` | View a filter | `asset`, `filter` |
| `/assets/{asset}/multifamily/filters/{filter}/options` | List filter options | `asset`, `filter` |
| `/assets/{asset}/multifamily/filters/{filter}/options/{option}` | View a filter option | `asset`, `filter`, `option` |

#### Image Galleries
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/galleries` | List galleries | `asset` |
| `/assets/{asset}/multifamily/galleries/{gallery}` | View a gallery | `asset`, `gallery` |

#### Marker Descriptions
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/marker-descriptions` | List marker descriptions | `asset` |
| `/assets/{asset}/multifamily/marker-descriptions/{marker-descriptions}` | View a marker description | `asset`, `marker-descriptions` |

#### Unit Maps
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/maps` | List unit maps | `asset` |
| `/assets/{asset}/multifamily/maps/{map}` | View a unit map | `asset`, `map` |
| `/assets/{asset}/multifamily/maps/{map}/backgrounds` | List backgrounds | `asset`, `map` |
| `/assets/{asset}/multifamily/maps/{map}/backgrounds/{background}` | View a background | `asset`, `map`, `background` |

#### Asset Outbound Links
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/outbound-links` | List outbound links | `asset` |
| `/assets/{asset}/multifamily/outbound-links/{outbound-link}` | View an outbound link | `asset`, `outbound-link` |

#### Unit Outbound Links
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/units/outbound-links` | List unit outbound links | `asset` |
| `/assets/{asset}/multifamily/units/outbound-links/{outbound-link}` | View a unit outbound link | `asset`, `outbound-link` |
| `/assets/{asset}/multifamily/units/outbound-links/{outbound-link}/urls` | List outbound link URLs | `asset`, `outbound-link` |

#### Landing Pages
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/landing-pages` | List landing pages | `asset` |
| `/assets/{asset}/multifamily/landing-pages/{landing-page}` | View a landing page | `asset`, `landing-page` |

#### Unit Descriptions
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/units/description-groups` | List description groups | `asset` |
| `/assets/{asset}/multifamily/units/description-groups/{description-group}` | View a description group | `asset`, `description-group` |
| `/assets/{asset}/multifamily/units/description-groups/{description-group}/descriptions` | List descriptions | `asset`, `description-group` |
| `/assets/{asset}/multifamily/units/description-groups/{description-group}/descriptions/{description}` | View a description | `asset`, `description-group`, `description` |

#### Asset References
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/references` | List references | `asset` |
| `/assets/{asset}/multifamily/references/{reference}` | View a reference | `asset`, `reference` |

#### Unit References
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/units/reference-groups` | List reference groups | `asset` |
| `/assets/{asset}/multifamily/units/reference-groups/{reference-group}` | View a reference group | `asset`, `reference-group` |
| `/assets/{asset}/multifamily/units/reference-groups/{reference-group}/references` | List references in group | `asset`, `reference-group` |

#### Pricing & Availability
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/pricing` | List pricing processes | `asset` |
| `/assets/{asset}/multifamily/pricing/{process}` | View a pricing process | `asset`, `process` |
| `/assets/{asset}/multifamily/pricing/{process}/entries` | List pricing entries | `asset`, `process` |
| `/assets/{asset}/multifamily/pricing/{process}/units` | List pricing units | `asset`, `process` |
| `/assets/{asset}/multifamily/pricing/{process}/units/{unit}` | View a pricing unit | `asset`, `process`, `unit` |
| `/assets/{asset}/multifamily/sightmaps/{sightmap}/units/pricing` | List all-in pricing | `asset`, `sightmap` |
| `/assets/{asset}/multifamily/pricing-disclaimers` | List pricing disclaimers | `asset` |
| `/assets/{asset}/multifamily/pricing-disclaimers/{pricing-disclaimer}` | View a pricing disclaimer | `asset`, `pricing-disclaimer` |

#### Pricing Executions
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/pricing/{process}/executions` | List executions | `asset`, `process` |
| `/assets/{asset}/multifamily/pricing/{process}/executions/{execution}` | View an execution | `asset`, `process`, `execution` |

#### Asset Expenses
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/expenses` | List asset expenses | `asset` |
| `/assets/{asset}/multifamily/expenses/{expense}` | View an asset expense | `asset`, `expense` |

#### Unit Expenses
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/units/expenses` | List unit expenses | `asset` |
| `/assets/{asset}/multifamily/units/expenses/{expense}` | View a unit expense | `asset`, `expense` |
| `/assets/{asset}/multifamily/units/expenses/{expense}/entries` | List expense entries | `asset`, `expense` |

#### Floor Plan Expenses
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/multifamily/floor-plans/expenses` | List floor plan expenses | `asset` |
| `/assets/{asset}/multifamily/floor-plans/expenses/{expense}` | View a floor plan expense | `asset`, `expense` |
| `/assets/{asset}/multifamily/floor-plans/expenses/{expense}/entries` | List expense entries | `asset`, `expense` |

---

### UnitMap API — `https://api.unitmap.com/v1`

#### Assets
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets` | List assets | — |
| `/assets/{asset}` | View an asset | `asset` |
| `/assets/references` | List asset references | — |

#### Asset Floors
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/assets/{asset}/floors` | List floors | `asset` |
| `/assets/{asset}/floors/{floor}` | View a floor | `asset`, `floor` |

#### Unit Maps
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/maps` | List unit maps | — |
| `/maps/{map}` | View a unit map | `map` |

#### Map Backgrounds
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/maps/{map}/backgrounds` | List backgrounds | `map` |
| `/maps/{map}/backgrounds/{background}` | View a background | `map`, `background` |

#### Map Locations
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/maps/{map}/locations` | List locations | `map` |

#### Map Level Tags
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/maps/{map}/levels/tags` | List level tags | `map` |

#### Map Units
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/maps/{map}/units` | List units on map | `map` |
| `/maps/{map}/units/{unit}` | View a unit on map | `map`, `unit` |

#### Units
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/units` | List units | — |
| `/units/{unit}` | View a unit | `unit` |

#### Unit References
| Endpoint | Description | Path Params |
|----------|-------------|-------------|
| `/units/references` | List unit references | — |

---

## Notes

- **Pagination parameter:** Always use `per-page=10000` (kebab-case) on list
  endpoints. This minimizes round trips by requesting up to 10,000 records per
  page. If an endpoint rejects this parameter, drop it and document the quirk.
- **Rate limiting:** If you receive a `429`, wait 2 seconds and retry (max 3).
  Wait 1 second between every API call (including paginated follow-ups).
- **One CSV file.** All data from all assets goes into a single file — never
  split across multiple files.
- **Output directory:** `./projects/api-data/` relative to the workspace root.
  Create if it doesn't exist. Never use absolute/hardcoded user paths.
- **File naming:** `{resource}_{endpoint}_{YYYY-MM-DD}.csv`
  (e.g., `units_list_2026-03-12.csv`).
- **The API key is the same** for both SightMap and UnitMap APIs.
- **Engrain terminology:** Use "Asset" not "Property." See `context/engrain-context.md`.
- **Deduplication:** Always deduplicate asset IDs before fetching. Report the
  count of duplicates removed.
- **CSV input:** When the user provides a file path to a CSV, read it and
  extract asset IDs automatically. Auto-detect the ID column.
- **Error handling:** A `403` on a single asset means that asset is restricted —
  log it and continue. Only stop the entire batch on `401` (invalid key) or
  3+ consecutive `403` errors.
