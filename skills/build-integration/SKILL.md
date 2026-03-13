---
name: build-integration
description: >
  Build new PMS integrations for Engrain. Covers the full lifecycle: smctl client,
  smctl command, tests, atlas container, and atlas deployment. Use this when asked
  to build, scaffold, or plan a new integration with a Property Management System.
version: 1.2.0
requires:
  env:
    - SIGHTMAP_API_KEY
  tools:
    - mcp-atlassian-jira_get_issue
  bins:
    - git
    - deno
    - docker
---

# Build Integration Skill

You are building a new PMS integration for Engrain's SightMap platform. This
skill covers the complete lifecycle: smctl client → smctl command → tests →
atlas container → atlas deployment.

**Before starting, read:**
- `repos/app-smctl/AGENTS.md` — full repo conventions
- `repos/atlas-integrations/README.md` — deployment conventions
- `context/engrain-context.md` — Engrain terminology

---

## Section 1: Overview

### What Is an Integration?

An "integration" at Engrain is an automated data pipeline that syncs data from
a Property Management System (PMS) into SightMap via the SightMap API. Each
integration runs as an hourly Kubernetes CronJob.

### The 3 Components

Every integration has three parts:

| Component | Repo | Purpose |
|-----------|------|---------|
| **smctl Client** | `app-smctl/src/lib/<provider>/` | HTTP client for the PMS API |
| **smctl Command** | `app-smctl/src/commands/<provider>/` | CLI command that fetches, transforms, and ingests data |
| **Atlas Container + Deployment** | `atlas-integrations/` | Docker container + K8s CronJob for production |

### Integration Types

| Type | SightMap API Endpoint | Description |
|------|----------------------|-------------|
| Pricing | `POST /assets/{id}/multifamily/pricing/{id}/ingest` | Unit pricing & availability |
| Floor Plans | `POST/PUT /assets/{id}/multifamily/floor-plans` | Floor plan CRUD + unit assignment |
| Unit Amenities | `POST/PUT /assets/{id}/multifamily/units/description-groups/{id}/descriptions` | Unit feature text |
| Virtual Tours | `PUT /assets/{id}/multifamily/units/outbound-links/{id}/urls` | Matterport/tour URLs |
| Rentable Items | `POST /assets/{id}/multifamily/pricing/{id}/ingest` | Same as pricing, different source |
| Student Pricing | `POST /assets/{id}/multifamily/pricing/{id}/ingest` | Pricing with bed-space granularity |
| Affordable Units | Custom endpoint | Affordable housing data |
| Expenses | `POST /assets/{id}/multifamily/expenses` | Fee/expense data |

### Data Hierarchy

SightMap's entity model: **Account → Asset → Building → Floor → Unit**

A PMS "property" or "facility" maps to a SightMap **Asset**. The CSV config in
each deployment maps PMS identifiers (property IDs, facility IDs) to SightMap
asset IDs.

---

## Section 2: Discovery & Planning

### Analyzing a New PMS API

1. **Auth pattern** — Bearer token? API key in header? Basic auth? SOAP with
   embedded credentials? OAuth? Document it.
2. **Data format** — REST JSON? SOAP XML? GraphQL? File-based (CSV/XML)?
3. **Endpoint inventory** — Which endpoints return the data we need?
4. **Error handling** — HTTP status codes? In-band errors (JSON `status: "error"`)?
   SOAP faults? Rate limiting?
5. **Pagination** — Offset? Cursor? None?
6. **Rate limits** — Documented? Headers?

### Mapping PMS Concepts to SightMap

| PMS Concept | SightMap Concept |
|-------------|-----------------|
| Property / Facility / Site | Asset (identified by `asset_id`) |
| Unit / Space / Suite | Unit (matched by `unit_number` or `provider_id`) |
| Floor Plan / Unit Type | Floor Plan (matched by `provider_id` in JSON `name` field) |
| Rent / Rate / Price | PricingEntry.price |
| Availability / Status | PricingEntry.available_on + PricingEntry.status |
| Lease Term | PricingEntry.lease_term |

### Matching Strategy

PMS facilities/properties are matched to SightMap assets via a CSV config
file in the deployment (`config/assets.csv`). Each row maps one PMS
property to one SightMap asset with all needed IDs.

For unit-level matching in floor plan and amenity imports, use the
**References API** (`/lib/utils/references.ts`) or a CSV file passed via
`--references` flag.

### Building the Asset Mapping CSV (Discovery Phase)

The `config/assets.csv` doesn't appear from nowhere — you must build it by
matching PMS properties to SightMap assets. This is a critical early step.

**Approach:**

1. **Fetch the PMS facility/property list** — Call the PMS API to get all
   properties accessible under the client's API key. Note the ID, name, and
   any address information.

2. **Fetch the existing SightMap asset list** — Either from an existing
   Sitelink/other CSV in `atlas-integrations/deployments/<client>/` or via
   the SightMap API (`/v1/accounts/{id}/assets`).

3. **Fuzzy-match by name** — Normalize both sets of names (lowercase, strip
   "PS -", "Prime Storage", common prefixes, punctuation) and match by
   similarity. Common normalization:
   ```python
   def normalize(name):
       name = name.lower()
       name = re.sub(r'\b(ps|prime storage|self storage|storage)\b', '', name)
       name = re.sub(r'\s*-\s*', ' ', name)
       name = re.sub(r'[^a-z0-9\s]', '', name)
       return ' '.join(name.split())
   ```

4. **Validate weak matches** — Any match with low confidence should be
   manually verified. Look at address, unit count, or other identifying data.

5. **Output the CSV** — Include at minimum: `asset_id`, `pricing_id` (or
   relevant SightMap process ID), `<provider>_id` (PMS property/facility ID),
   `manage_url`, `asset_name`.

**Tip:** Build a reusable matching script in `projects/<integration>/` and
save it for re-running when new properties are onboarded. The script
typically lives at `projects/<integration>/match_facilities.py`.

### Request Pattern Variations

PMS APIs vary in how they expose data. The client must adapt:

| Pattern | Example | Implementation |
|---------|---------|---------------|
| **GET with query params** | AppFolio, Matterport | `http.fetch(\`\${url}?facility=\${id}\`)` |
| **POST with JSON body** | Cubby, Entrata | `http.fetch(url, { method: "POST", body: JSON.stringify({...}) })` |
| **POST with SOAP/XML** | SiteLink | `http.fetch(url, { body: xmlEnvelope })` |
| **GraphQL** | Matterport | `http.fetch(url, { body: JSON.stringify({ query, variables }) })` |

### Data Transformation Gotchas

- **Price units** — Some APIs return prices in cents (Cubby: `webRate: 12500`
  → `$125.00`). Always check and divide by 100 if needed.
- **Expansion/join patterns** — Some APIs return related data as separate
  arrays (Cubby returns `units[]` and `pricingGroups[]` — join on
  `pricingGroupId`). Build a `Map<id, object>` for lookups.
- **Date formats** — Normalize to ISO 8601 (`YYYY-MM-DD`). Use
  `DateTime.fromISO()` or `DateTime.fromFormat()` from Luxon.
- **Availability filtering** — Each PMS represents "available" differently:
  `rentable: true` + no `leaseId` (Cubby), `statusCode === "AVAILABLENOW"`
  (Cortland), `iDaysVacant >= 0` (SiteLink). Always log skipped units.
- **XML/MITS5 sources** — Use Cheerio via `/lib/utils/xml.ts` (`parse()`
  wraps `cheerio.load()` with `{ xml: true }`). MITS5 XML has multiple
  offer element types (`ChargeOfferItem`, `PetOfferItem`, `ParkingOfferItem`,
  `StorageOfferItem`) — use a combined CSS selector. Access tag names via
  `el.tagName` (Cheerio). When MITS codes don't map 1:1 to SightMap types,
  build a multi-tier resolution: InternalCode lookup → Name regex heuristics
  → ClassCode defaults.
- **API value normalization** — The SightMap API may normalize values on
  write (e.g., `""` → `null`, `"monthly_rent"` → `"base_rent"`). If your
  diff compares source values against API-returned values, use the API's
  canonical forms to avoid phantom updates on re-run. Always verify
  idempotency by running the command twice.

---

## Section 3: Building the smctl Client

### File Structure

```
src/lib/<provider>/
├── client.ts    # HTTP client class
└── mod.ts       # Re-exports
```

`mod.ts` simply re-exports:
```ts
export * from "./client.ts";
```

### Auth Patterns (Real Examples)

| Provider | Auth Style | Implementation |
|----------|-----------|----------------|
| Cubby | Bearer token | `headers.set("Authorization", \`Bearer ${this.apiKey}\`)` |
| SiteLink | SOAP embedded | Credentials in XML body |
| Entrata | Basic auth | `headers.set("Authorization", \`Basic ${encoded}\`)` |
| AppFolio | API key param | `?api_key=${this.apiKey}` |
| Matterport | Token auth | `headers.set("Authorization", \`Bearer ${jwt}\`)` |

### Error Handling Patterns

**Pattern A: In-band errors (Cubby-style)** — HTTP 200 but `status: "error"`:
```ts
const json = await res.json() as SearchResponse<T>;
if (json.status === "error") {
  throw new ProviderError(
    `provider.client: The API responded with error: '${json.errors?.join("; ")}'.`,
    res, json.errorCode, json.errors,
  );
}
```

**Pattern B: HTTP status codes (most REST APIs)** — Use `http.fetch` and check:
```ts
const res = await http.fetch(input, init);
if (!res.ok) {
  const message = `provider.client: '${res.url}' returned HTTP ` +
    `${res.status} status code with body '${await res.clone().text()}'.`;
  if (res.status >= 400 && res.status < 500) throw new HttpClientError(message, res);
  if (res.status >= 500 && res.status < 600) throw new HttpServerError(message, res);
  throw new HttpError(message, res);
}
```

**Pattern C: SOAP fault (SiteLink-style)** — Parse XML response body for errors:
```ts
const $ = parse(await res.clone().text());
const error = $("NewDataSet RT").first();
if (error.length) {
  throw new SiteLinkError(
    `sitelink.client: error '${error.find("Ret_Code").text()}'.`,
    error.find("Ret_Code").text(), res,
  );
}
```

### Client Template

```ts
// src/lib/<PROVIDER>/client.ts
import http, {
  HttpClientError,
  HttpError,
  HttpServerError,
} from "/lib/http.ts";

// Custom error class (optional but recommended).
export class <PROVIDER>Error extends HttpError {
  constructor(message: string, response: Response, options?: ErrorOptions) {
    super(message, response, options);
  }
}

// Type definitions for provider data structures.
export type <PROVIDER>Unit = {
  id: string;
  name: string;
  // ... provider-specific fields
};

export class Client {
  protected apiKey: string;
  protected baseUrl: string;

  constructor(
    apiKey: string,
    baseUrl: string = "https://api.<provider>.com/v1",
  ) {
    this.apiKey = apiKey;

    if (baseUrl.endsWith("/")) {
      baseUrl = baseUrl.slice(0, -1);
    }
    this.baseUrl = baseUrl;
  }

  async getUnits(facilityId: string): Promise<<PROVIDER>Unit[]> {
    const headers = new Headers();
    headers.set("Authorization", `Bearer ${this.apiKey}`);
    headers.set("Content-Type", "application/json");
    headers.set("Accept", "application/json");

    const res = await http.fetch(
      `${this.baseUrl}/units?facility=${facilityId}`,
      { method: "GET", headers },
    );

    if (!res.ok) {
      const body = await res.clone().text();
      const message = `<provider>.client: '${res.url}' returned HTTP ` +
        `${res.status} with body '${body}'.`;
      if (res.status >= 400 && res.status < 500) {
        throw new HttpClientError(message, res);
      } else if (res.status >= 500) {
        throw new HttpServerError(message, res);
      }
      throw new HttpError(message, res);
    }

    const json = await res.json();
    return json.data as <PROVIDER>Unit[];
  }
}
```

**Key rules:**
- Import `http` from `/lib/http.ts` (the global singleton). **Never** use
  raw `fetch` — always `http.fetch(...)`.
- Error messages follow: `<provider>.client: <description>.`
- Constructor validates/trims the base URL.
- Type all response shapes explicitly.

---

## Section 4: Building the smctl Command

### File Hierarchy

For a provider with a single import type (e.g., Cubby → pricing):

```
src/commands/
├── <provider>.ts                          # Top-level: credentials + subcommands
├── <provider>/
│   ├── index.ts                           # Exports [importCmd]
│   ├── import.ts                          # "import <command>" subcommand group
│   └── import/
│       ├── index.ts                       # Exports [pricing]
│       └── pricing.ts                     # Actual handler
```

For a provider with multiple import types (e.g., Entrata):

```
src/commands/
├── entrata.ts
├── entrata/
│   ├── index.ts                           # Exports [exportCmd, importCmd]
│   ├── export.ts
│   ├── import.ts
│   └── import/
│       ├── index.ts                       # Exports [affordableUnits, floorPlans, ...]
│       ├── affordable_units.ts
│       ├── floor_plans.ts
│       ├── student_pricing.ts
│       └── unit_amenities.ts
```

### Registration Files

**`src/commands/<provider>.ts`** — Top-level command with shared credentials:
```ts
import { YargsInstance } from "yargs/build/lib/yargs-factory.js";
import { commands } from "./<provider>/index.ts";

export const command = "<provider> <command>";
export const describe = "<ProviderName>";
export function builder(yargs: YargsInstance) {
  return yargs
    .command(commands)
    .option("<provider>-api-key", {
      type: "string",
      demand: true,
      describe: "<ProviderName> API key",
    })
    .option("<provider>-api-url", {
      type: "string",
      default: "https://api.<provider>.com/v1",
      describe: "<ProviderName> API base URL",
    }).group(
      ["<provider>-api-key", "<provider>-api-url"],
      "<ProviderName> Credentials:",
    );
}
```

**`src/commands/<provider>/index.ts`**:
```ts
import * as importCmd from "./import.ts";

export const commands = [
  importCmd,
];
```

**`src/commands/<provider>/import.ts`**:
```ts
import { YargsInstance } from "yargs/build/lib/yargs-factory.js";
import { commands } from "./import/index.ts";

export const command = "import <command>";
export const describe = "Import actions for <ProviderName>";
export function builder(yargs: YargsInstance) {
  return yargs.command(commands)
    .demandOption("api-key");
}
```

**`src/commands/<provider>/import/index.ts`**:
```ts
import * as pricing from "./pricing.ts";

export const commands = [
  pricing,
];
```

**Register in `src/commands/index.ts`** — Add the import and push to the array:
```ts
import * as <provider> from "./<provider>.ts";
// ... in the commands array:
export const commands = [
  // ... existing commands ...
  <provider>,
];
```

### Command Handler Pattern

Every command exports four things: `command`, `describe`, `builder`, `handler`.

The handler follows the pattern: **fetch → filter → transform → ingest**.

### Pricing Command Template

```ts
// src/commands/<provider>/import/pricing.ts
import log from "/lib/log.ts";
import { Arguments } from "yargs/deno-types.ts";
import { YargsInstance } from "yargs/build/lib/yargs-factory.js";
import { DateTime } from "luxon";
import {
  Client as SightMap,
  OpenedPricingTransaction,
  PricingEntry as FullPricingEntry,
} from "/lib/sightmap/mod.ts";
import {
  Client as <ProviderClass>,
  <ProviderUnit>,
} from "/lib/<provider>/mod.ts";

type PricingEntry = Partial<FullPricingEntry>;

export const command = "pricing";
export const describe = "<ProviderName> pricing import";

export function builder(yargs: YargsInstance) {
  return yargs
    .option("<provider>-specific-id", {
      type: "string",
      demand: true,
      describe: "The <ProviderName> identifier for this property/facility",
    })
    .option("asset-id", {
      type: "string",
      demand: true,
      describe: "The target Asset",
    })
    .option("pricing-id", {
      type: "string",
      demand: true,
      describe: "The target pricing process",
    })
    .option("received-from", {
      type: "string",
      describe:
        "The value of the X-Received-From header. When provided, the header " +
        "will be sent on all pricing transaction requests",
    });
}

export async function handler(argv: Arguments) {
  log.start(argv);

  // 1. Initialize clients.
  const sightmap = new SightMap(argv.apiKey, argv.apiBaseUrl);
  const provider = new <ProviderClass>(argv.<provider>ApiKey, argv.<provider>ApiUrl);

  // 2. Fetch data from PMS.
  const sourceUnits = await provider.getUnits(argv.<provider>SpecificId);
  log.info(`command: ${sourceUnits.length} source unit(s) found.`);

  // 3. Filter & transform into PricingEntry[].
  const entries = getPricingEntries(sourceUnits);
  log.info(`command: ${entries.length} available unit(s) to ingest.`);

  // 4. Send to SightMap.
  await sendTransaction(argv, sightmap, entries);

  log.end(argv);
}

function getPricingEntries(units: <ProviderUnit>[]): PricingEntry[] {
  const entries: PricingEntry[] = [];

  for (const unit of units) {
    // Filter out unavailable units.
    if (!unit.isAvailable) {
      log.debug(
        `command: Skipping unit '${unit.id}' ('${unit.name}') — not available.`,
      );
      continue;
    }

    log.debug(
      `command: Found unit '${unit.id}' with name '${unit.name}' and price ${unit.price}.`,
    );

    entries.push({
      unit_number: unit.name,
      provider_id: unit.id,
      available_on: DateTime.now().toISODate(),
      price: unit.price,
    });
  }

  return entries;
}

async function sendTransaction(
  argv: Arguments,
  sightmap: SightMap,
  entries: PricingEntry[],
) {
  const headers = new Headers();

  if (argv.receivedFrom) {
    headers.set("X-Received-From", argv.receivedFrom);
    log.debug(
      `command: 'X-Received-From' header set to '${argv.receivedFrom}'.`,
    );
  }

  const trx = await sightmap.create<OpenedPricingTransaction, PricingEntry[]>(
    `/assets/${argv.assetId}/multifamily/pricing/${argv.pricingId}/ingest?commit=1`,
    entries,
    headers,
  );

  log.debug(
    `command: Transaction '${trx.transaction_id}' committed with status '${trx.status}'.`,
  );
}
```

### SightMap Client Usage by Integration Type

Each integration type uses a different pattern. The table below summarizes,
and full handler templates follow.

| Type | Pattern | SM Methods | Experimental Flag | Unit Matching |
|------|---------|-----------|-------------------|---------------|
| Pricing | Transaction (ingest) | `create` | none | `unit_number` in payload |
| Rentable Items | Transaction (same as pricing) | `create` | none | `unit_number` in payload |
| Expenses | Individual CRUD loop | `all`, `create`, `update`, `destroy` | `expenses` | `provider_id` direct match |
| Floor Plans | CRUD + FormData/Images | `all`, `create`, `update`, `destroy` | none (`build-caches` only) | References API/CSV |
| Unit Amenities | Bulk CRUD via Collection | `each`, `create`, `update` | `unit-descriptions-resource` | References API/CSV |
| Virtual Tours | Full replacement PUT | `all`, `put` | `unit-outbound-links-resource` | Custom (Matterport internalId) |

**Pricing (transaction pattern):**
```ts
const trx = await sightmap.create<OpenedPricingTransaction, PricingEntry[]>(
  `/assets/${argv.assetId}/multifamily/pricing/${argv.pricingId}/ingest?commit=1`,
  entries,
  headers,
);
```

**Pricing with chunking** (for large payloads > 5000 entries):
```ts
// First chunk: open transaction (no ?commit=1)
const trx = await sightmap.create<OpenedPricingTransaction, PricingEntry[]>(
  `/assets/${assetId}/multifamily/pricing/${pricingId}/ingest`,
  firstChunk, headers,
);
// Middle chunks: append to existing transaction
await sightmap.create<OpenedPricingTransaction, PricingEntry[]>(
  trx.transaction_ingest_url, middleChunk, headers,
);
// Final chunk: commit
await sightmap.create<OpenedPricingTransaction, PricingEntry[]>(
  `${trx.transaction_ingest_url}?commit=1`, lastChunk, headers,
);
```

### Expenses Handler Template

Expenses use an individual CRUD pattern — fetch existing, diff, then
create/update/delete one at a time. This is fundamentally different from the
pricing transaction pattern.

```ts
// src/commands/<provider>/import/expenses.ts
import log from "/lib/log.ts";
import { Arguments } from "yargs/deno-types.ts";
import { YargsInstance } from "yargs/build/lib/yargs-factory.js";
import { Client as SightMap } from "/lib/sightmap/mod.ts";
import { Client as Provider } from "/lib/<provider>/mod.ts";

type SmExpense = {
  id: number;
  provider_id: string;
  name: string;
  description: string;
  amount: number;
  // ... other fields
};

export const command = "expenses";
export const describe = "<ProviderName> expenses import";

export function builder(yargs: YargsInstance) {
  return yargs
    .option("asset-id", { type: "string", demand: true, describe: "Target Asset" })
    .option("<provider>-property-id", { type: "string", demand: true });
}

export async function handler(argv: Arguments) {
  log.start(argv);

  const sightmap = new SightMap(argv.apiKey, argv.apiBaseUrl);
  const provider = new Provider(argv.<provider>ApiKey);

  // 1. Fetch from PMS.
  const sourceFees = await provider.getFees(argv.<provider>PropertyId);
  log.info(`command: ${sourceFees.length} source fee(s) found.`);

  // 2. Fetch existing from SightMap.
  const headers = new Headers({ "Experimental-Flags": "expenses" });
  const existing = await sightmap.all<SmExpense>(
    `/assets/${argv.assetId}/multifamily/expenses?per-page=50000`,
    headers,
  );
  log.info(`command: ${existing.length} existing expense(s) in SightMap.`);

  // 3. Diff — compute toCreate, toUpdate, toDelete.
  const existingMap = new Map(existing.map((e) => [e.provider_id, e]));
  const sourceIds = new Set<string>();

  for (const fee of sourceFees) {
    sourceIds.add(fee.id);
    const match = existingMap.get(fee.id);

    if (!match) {
      // CREATE
      await sightmap.create(
        `/assets/${argv.assetId}/multifamily/expenses`,
        { provider_id: fee.id, name: fee.name, amount: fee.amount },
        headers,
      );
      log.debug(`command: Created expense '${fee.name}'.`);
    } else if (hasChanged(match, fee)) {
      // UPDATE
      await sightmap.update(
        `/assets/${argv.assetId}/multifamily/expenses/${match.id}`,
        { name: fee.name, amount: fee.amount },
        headers,
      );
      log.debug(`command: Updated expense '${fee.name}'.`);
    }
  }

  // DELETE orphans.
  for (const expense of existing) {
    if (!sourceIds.has(expense.provider_id)) {
      await sightmap.destroy(
        `/assets/${argv.assetId}/multifamily/expenses/${expense.id}`,
        headers,
      );
      log.debug(`command: Deleted orphan expense '${expense.name}'.`);
    }
  }

  log.end(argv);
}
```

**Key differences from pricing:**
- No transaction — each CRUD operation is an individual HTTP call.
- Must fetch existing data first to compute the diff.
- `Experimental-Flags: expenses` header on ALL expense requests.
- Each operation wrapped in try/catch per item (one failure shouldn't abort).
- Match by `provider_id` — the PMS fee ID stored on the SightMap expense.

### Expenses: Valid SightMap Enum Values

**CRITICAL:** The SightMap API validates enum values strictly. Use these
exact strings — sourced from BH Management's `field_mappings.ts` (the
known-good reference) and confirmed against the live API.

**`value_type`** (what kind of amount this expense represents):

| Value | Use When |
|-------|----------|
| `"amount"` | Fixed dollar amount (most common) |
| `"range"` | Variable amount with min/max |
| `"percentage"` | Percentage of rent |
| `"text"` | Descriptive text, no numeric value |

> ⚠️ Do NOT use `"flat"` — the API rejects it. Use `"amount"` instead.

**`due_at_timing`** (when the fee is due):

| Value | Use When |
|-------|----------|
| `"move_in"` | Due at move-in |
| `"move_out"` | Due at move-out |
| `"application"` | Due at application |
| `null` | Recurring/during term |

> ⚠️ Do NOT use `"at_move_in"`, `"at_move_out"`, or `"at_application"` —
> the API rejects the `at_` prefix.

**`type`** (expense category — the API auto-assigns `category` and `group`):

| Category | Valid Types |
|----------|-------------|
| Administrative | `admin`, `application`, `deposit`, `screening`, `transfer`, `holding`, `subletting`, `move_in`, `move_out` |
| Penalties | `late_payment`, `insufficient_funds`, `violation` |
| Insurance | `renters_insurance` |
| Legal | `inspection`, `legal_fees` |
| Services | `amenity`, `cleaning`, `maintenance`, `packages`, `pest_control` |
| Utilities | `utilities_other`, `electricity`, `gas`, `water`, `trash`, `cable`, `internet`, `bundled_utilities`, `sewer` |
| Pets | `pets_other`, `pet_deposit_other`, `pet_rent_other` |
| Parking | `parking_other`, `assigned_parking`, `private_garage` |
| Storage | `storage` |
| Other | `other`, `technology` |

> ⚠️ Common mistakes: `"electric"` → use `"electricity"`, `"late"` → use
> `"late_payment"`, `"nsf"` → use `"insufficient_funds"`, `"pet_rent"` →
> use `"pet_rent_other"`, `"pet_deposit"` → use `"pet_deposit_other"`,
> `"trash_removal"` → use `"trash"`, `"parking"` → use `"parking_other"`.

**`percentage_ref`** (reference for percentage amounts):

| Value | Meaning |
|-------|---------|
| `"base_rent"` | Percentage of base rent |

> ⚠️ The API normalizes `"monthly_rent"` to `"base_rent"`. Use `"base_rent"`.

**`provider_code` and `tooltip_label`** — Use `null` (not `""`) when empty.
The API normalizes empty strings to `null`, causing phantom diffs on re-run.

### Expenses: Scoped Deletion Pattern

When deleting stale expenses, **scope deletions to your provider prefix**.
Don't delete all orphans — an asset may have expenses from multiple sources
(manual entry, other PMS integrations).

```ts
// Only delete expenses YOUR integration manages.
const PREFIX = "myprovider:";
for (const expense of existing) {
  if (expense.provider_id?.startsWith(PREFIX) && !sourceIds.has(expense.provider_id)) {
    await sightmap.destroy(...);
  }
}
```

Support a `--delete-on-empty` flag to protect against accidental bulk
deletion when the source returns empty data (API outage, auth error, etc.).

### Floor Plans Handler Template

Floor plans use CRUD with FormData for image uploads, plus a cache rebuild.

```ts
// Simplified flow — see entrata/import/floor_plans.ts for full implementation
export async function handler(argv: Arguments) {
  log.start(argv);

  const sightmap = new SightMap(argv.apiKey, argv.apiBaseUrl);

  // 1. Fetch existing floor plans.
  const existing = await sightmap.all<SightMapFloorPlan>(
    `/assets/${argv.assetId}/multifamily/floor-plans?per-page=50000`,
  );

  // 2. Fetch PMS floor plan data.
  const sourceFloorPlans = await provider.getFloorPlans(argv.propertyId);

  // 3. Match by provider_id (stored in JSON name field).
  const existingMap = new Map<string, SightMapFloorPlan>();
  for (const fp of existing) {
    try {
      const parsed = JSON.parse(fp.name);
      if (parsed.provider_id) existingMap.set(parsed.provider_id, fp);
    } catch { /* orphan — will be deleted */ }
  }

  // 4. Create/Update with FormData.
  for (const sourceFp of sourceFloorPlans) {
    const body = new FormData();
    body.append("data", JSON.stringify({
      asset_id: argv.assetId,
      name: JSON.stringify({ provider_id: sourceFp.id, name: sourceFp.name }),
    }));
    // Optional: download and attach images
    // body.append("image", imageBlob, "floorplan.jpg");

    if (existingMap.has(sourceFp.id)) {
      await sightmap.update<SightMapFloorPlan, FormData>(
        `/assets/${argv.assetId}/multifamily/floor-plans/${existingMap.get(sourceFp.id)!.id}`,
        body,
      );
    } else {
      await sightmap.create<SightMapFloorPlan, FormData>(
        `/assets/${argv.assetId}/multifamily/floor-plans`,
        body,
      );
    }
  }

  // 5. Build caches after creates/updates.
  await buildCaches(sightmap, argv.assetId);

  // 6. Delete orphans (after cache build).
  // ...

  log.end(argv);
}
```

**Key differences from pricing:**
- Uses `FormData` instead of JSON for image upload support.
- `provider_id` stored inside JSON `name` field (`JSON.parse(fp.name).provider_id`).
- Must call `buildCaches()` after mutations (POST to `/assets/{id}/multifamily/caches/build`).
- Delete orphans AFTER cache build, and catch HTTP 409 gracefully.
- Unit assignment is separate: `sightmap.update` on `/assets/{id}/multifamily/units/{unitId}`.

### Unit Amenities Handler Template

Unit amenities use bulk CRUD via `Collection<T[]>` wrapper with the References API.

```ts
export async function handler(argv: Arguments) {
  log.start(argv);

  const sightmap = new SightMap(argv.apiKey, argv.apiBaseUrl);
  const headers = new Headers({ "Experimental-Flags": "unit-descriptions-resource" });

  // 1. Get unit references (PMS unit ID → SM unit ID).
  const references = await getUnitReferencesAsMap(sightmap, argv);

  // 2. Get existing descriptions.
  const relations = [];
  for await (const relation of sightmap.each<UnitDescriptionRelation>(
    `/assets/${argv.assetId}/multifamily/units/description-groups/${argv.groupId}/units`,
    headers,
  )) {
    relations.push(relation);
  }

  // 3. Fetch amenity text from PMS.
  const amenities = await provider.getUnitAmenities(argv.propertyId);

  // 4. Bulk update existing descriptions.
  const updatePayload: Collection<UnitDescriptionUpdate[]> = {
    data: updates.map((u) => ({
      id: u.id, asset_id: argv.assetId, group_id: argv.groupId,
      is_enabled: true, body: formatAmenityText(u.amenities),
    })),
  };
  await sightmap.update(
    `/assets/${argv.assetId}/multifamily/units/description-groups/${argv.groupId}/descriptions`,
    updatePayload, headers,
  );

  // 5. Bulk create new descriptions.
  const createPayload: Collection<UnitDescriptionCreate[]> = {
    data: creates.map((c) => ({
      asset_id: argv.assetId, group_id: argv.groupId,
      name: c.unitNumber, label: c.unitNumber,
      body: formatAmenityText(c.amenities), is_enabled: true,
    })),
  };
  await sightmap.create(
    `/assets/${argv.assetId}/multifamily/units/description-groups/${argv.groupId}/descriptions`,
    createPayload, headers,
  );

  // 6. Assign new descriptions to units via relation update.
  // 7. Build caches.
  log.end(argv);
}
```

**Key differences:**
- `Experimental-Flags: unit-descriptions-resource` on ALL requests.
- Bulk operations via `Collection<T[]>` wrapper (`{ data: [...] }`).
- Two-step create: first create descriptions, then assign to units via relations.
- Uses References API (`/lib/utils/references.ts`) for unit matching.
- Amenity text formatted as Markdown: `### Unit Features\n* Amenity1\n* Amenity2`.

### Virtual Tours Handler Template

Virtual tours do a full replacement via `sightmap.put()` — no diffing needed.

```ts
export async function handler(argv: Arguments) {
  log.start(argv);

  const sightmap = new SightMap(argv.apiKey, argv.apiBaseUrl);
  const headers = new Headers({ "Experimental-Flags": "unit-outbound-links-resource" });

  // 1. Fetch all SM units.
  const units = await sightmap.all<Unit>(
    `/assets/${argv.assetId}/multifamily/units?per-page=50000`,
  );

  // 2. Fetch tour URLs from provider.
  const tours = await provider.getTours(argv.propertyId);
  const tourMap = new Map(tours.map((t) => [t.unitId, t.url]));

  // 3. Build full replacement payload — one entry per unit.
  const payload: UnitOutboundLinkUrl[] = units.map((unit) => ({
    unit_id: unit.id,
    url: tourMap.get(unit.provider_id) ?? null, // null clears the URL
  }));

  // 4. PUT (full replacement, not patch).
  await sightmap.put<UnitOutboundLinkUrl[]>(
    `/assets/${argv.assetId}/multifamily/units/outbound-links/${argv.outboundLinkId}/urls`,
    payload, headers,
  );

  log.end(argv);
}
```

**Key differences:**
- Uses `sightmap.put()` — the only integration type that does.
- Full replacement: every unit gets an entry, with `null` for no tour.
- No diffing, no create/update/delete — one atomic PUT replaces everything.
- `Experimental-Flags: unit-outbound-links-resource` header.

### Unit Matching Strategies

Different integration types match PMS units to SightMap units differently:

| Strategy | Used By | How It Works |
|----------|---------|-------------|
| **unit_number in payload** | Pricing, Rentable Items | PMS unit name → `PricingEntry.unit_number`. SightMap matches internally. |
| **provider_id direct match** | Expenses | PMS fee ID stored as `expense.provider_id` in SightMap. |
| **References API** | Floor Plans, Unit Amenities | `/units/references?key=<provider>` returns `Map<pms_unit_id, sm_unit_id>`. Import via `/lib/utils/references.ts`. |
| **Custom matching** | Virtual Tours | Provider encodes SM IDs in its own metadata (e.g., Matterport `internalId` JSON). |

### The `--received-from` Header

Most commands accept `--received-from`. When provided, set the
`X-Received-From` header on SightMap API requests. In production, this is set
to the GKE console URL for the CronJob for traceability.

### Logging Conventions

```ts
log.start(argv);                                    // Always first
log.info(`command: ${count} source unit(s) found.`); // Counts, status
log.debug(`command: Found unit '${id}' ...`);        // Per-item detail
log.warning(`command: Skipping unit '${id}' ...`);   // Filtered/skipped
log.end(argv);                                       // Always last
```

- Prefix with `command:` for handler logs, `<provider>.client:` for client logs.
- Wrap interpolated values in single quotes: `'${value}'`.

### Yargs Options: Environment Variable Mapping

Options are auto-populated from env vars with `SMCTL_` prefix. The mapping:
`SMCTL_<OPTION_NAME>` → `--option-name` (underscores become hyphens, lowercased).

Examples:
- `SMCTL_API_KEY` → `--api-key` → `argv.apiKey`
- `SMCTL_CUBBY_API_KEY` → `--cubby-api-key` → `argv.cubbyApiKey`
- `SMCTL_ASSET_ID` → `--asset-id` → `argv.assetId`

---

## Section 5: Writing Tests

### File Location

Tests are colocated with the command:
```
src/commands/<provider>/import/pricing.test.ts
```

### Test Structure

```ts
// src/commands/<provider>/import/pricing.test.ts
import * as test from "/lib/testing.ts";
import { assertDebugContains, assertInfoContains } from "/lib/asserts.ts";
import { assertEquals, assertRejects } from "testing/asserts.ts";
import { <ProviderError> } from "/lib/<provider>/mod.ts";
import sinon from "sinon";

Deno.test({
  name: "<provider> import pricing command",
  async fn(t) {
    // Set environment variables for the test.
    Deno.env.set("SMCTL_API_KEY", "test-api-key");
    Deno.env.set("SMCTL_<PROVIDER>_API_KEY", "test-<provider>-api-key");

    await t.step({
      name: "test a successful run",
      async fn() {
        // 1. Load fixtures from the test directory.
        const fetch = await test.fetchQueueFromDir(
          "test/<provider>/import/pricing/successful_run",
        );
        const stdout = sinon.stub(globalThis.console, "log");

        // 2. Execute the command.
        await test.exec(`
          <provider> import pricing -vv --asset-id=1 --pricing-id=6 \
            --<provider-specific-id>='test-value' \
            --received-from='test suite'
        `);

        // 3. Assert no stdout output.
        assertEquals(stdout.callCount, 0);

        // 4. Assert provider API was called.
        assertDebugContains(
          "http.fetch: GET https://api.<provider>.com/v1/units",
        );

        // 5. Assert source data was processed.
        assertInfoContains("command: 4 source unit(s) found.");
        assertInfoContains("command: 2 available unit(s) to ingest.");

        // 6. Assert pricing transaction was sent.
        assertDebugContains(
          "http.fetch: POST https://api.sightmap.com/v1/assets/1/multifamily/pricing/6/ingest?commit=1",
        );
        assertDebugContains(
          "command: Transaction '1' committed with status 'queued'.",
        );

        // 7. Assert X-Received-From header.
        assertDebugContains("'X-Received-From' header set to 'test suite'.");

        // 8. Cleanup — ALWAYS in this order.
        stdout.restore();
        fetch.restore();
        test.reset();
      },
    });

    await t.step({
      name: "test error when provider API returns an error",
      async fn() {
        const fetch = await test.fetchQueueFromDir(
          "test/<provider>/import/pricing/api_error",
        );
        const stdout = sinon.stub(globalThis.console, "log");

        await assertRejects(
          () => test.exec(`
            <provider> import pricing -vv --asset-id=1 --pricing-id=6 \
              --<provider-specific-id>='invalid-value'
          `),
          <ProviderError>,
          "expected error message substring",
        );

        assertEquals(stdout.callCount, 0);

        stdout.restore();
        fetch.restore();
        test.reset();
      },
    });

    await t.step({
      name: "test empty data produces zero entries",
      async fn() {
        const fetch = await test.fetchQueueFromDir(
          "test/<provider>/import/pricing/empty_facility",
        );
        const stdout = sinon.stub(globalThis.console, "log");

        await test.exec(`
          <provider> import pricing -vv --asset-id=1 --pricing-id=6 \
            --<provider-specific-id>='empty-value'
        `);

        assertEquals(stdout.callCount, 0);
        assertInfoContains("command: 0 source unit(s) found.");

        stdout.restore();
        fetch.restore();
        test.reset();
      },
    });

    // Clean up env vars.
    Deno.env.delete("SMCTL_API_KEY");
    Deno.env.delete("SMCTL_<PROVIDER>_API_KEY");
  },
});
```

### HTTP Fixture Format

Fixtures are `.http.txt` files that simulate HTTP responses. They live in the
test directory organized by scenario:

```
test/<provider>/import/pricing/
├── successful_run/
│   ├── 1741100000000-1.http.txt    # Provider API response
│   └── 1741100000000-2.http.txt    # SightMap API response
├── api_error/
│   └── 1741100000000-1.http.txt    # Provider error response
└── empty_facility/
    ├── 1741100000000-1.http.txt    # Empty provider response
    └── 1741100000000-2.http.txt    # SightMap API response
```

**File naming:** `<timestamp>-<sequence>.http.txt` — sorted alphabetically to
match the fetch call order. Use a fixed timestamp like `1741100000000`.

**File format (raw HTTP response):**
```
HTTP/1.1 200 OK
content-type: application/json

{"status":200,"data":{"units":[...]}}
```

The format is: `HTTP/<version> <status> <reason>\n<headers>\n\n<body>`

**For a SightMap pricing ingest response:**
```
HTTP/1.1 200 OK
content-type: application/json

{"transaction_id":"1","transaction_uuid":"abc-123","transaction_url":"/transactions/1","transaction_ingest_url":"/transactions/1/ingest","status":"queued","expires_in":3600}
```

**For error responses:**
```
HTTP/1.1 200 OK
content-type: application/json

{"status":"error","errorCode":404,"errors":["Facility not found"]}
```

### How `fetchQueueFromDir` Works

`test.fetchQueueFromDir(path)` reads all `*.http.txt` files from a directory,
sorts them alphabetically, then stubs `globalThis.fetch` so that:
- 1st `fetch()` call returns the 1st fixture
- 2nd `fetch()` call returns the 2nd fixture
- etc.

**One fixture per HTTP call your command makes.** Count carefully: if the
command calls the provider API once and then SightMap once, you need 2 fixtures.

### Assertion Helpers

```ts
import { assertDebugContains, assertInfoContains, assertWarningContains } from "/lib/asserts.ts";

assertDebugContains("expected message");    // Checks DEBUG level logs
assertInfoContains("expected message");     // Checks INFO level logs
assertWarningContains("expected message");  // Checks WARNING level logs
```

These check if ANY log message at that level contains the substring. They
work because tests use `TestHandler` which captures all log records.

### Cleanup Pattern (Critical)

**Every** test step must restore stubs before the next step runs. If a test
step throws before `fetch.restore()`, the sinon stub stays active and ALL
subsequent steps fail with "Attempted to wrap fetch which is already wrapped."

```ts
// Recommended order:
clock.restore();    // If using test.setTestNow()
stdout.restore();   // If using sinon.stub(globalThis.console, "log")
fetch.restore();    // MUST happen — releases the global fetch stub
```

> ⚠️ **Cascade failures:** If step 3 of 4 throws, step 4 will fail with a
> confusing sinon error — not a real test failure. Always fix the ROOT cause
> (the step that actually threw) and cascades resolve automatically.

### Running Tests

```bash
# From the app-smctl root:
RUNNING_UNIT_TESTS=1 TZ=UTC deno test --lock --allow-read --allow-env --allow-import \
  src/commands/<provider>/import/pricing.test.ts

# Or use the wrapper script:
./test.sh src/commands/<provider>/import/pricing.test.ts
```

**Gotchas:**
- `RUNNING_UNIT_TESTS=1` must be set — it switches the logger to `TestHandler`
  and changes error handling to throw instead of `Deno.exit()`.
- `TZ=UTC` is required for date-dependent tests.
- `--allow-import` flag is required for Deno to resolve the import map.
- The `--lock` flag validates the lock file.

### Common Test Scenarios

1. **Successful run** — Happy path with mixed data (some filtered, some ingested)
2. **API error** — Provider returns an error; assert the custom error is thrown
3. **Empty data** — No units from provider; assert zero entries sent
4. **Filtered data** — All units filtered out (e.g., all unavailable)
5. **Warning scenarios** — Invalid data triggers warnings but doesn't crash

### Unit Tests for Mapping Modules

For expenses (and any integration with complex field mapping), **extract
mapping logic into a separate module** (e.g., `expense_mappings.ts`) and
write unit tests for the exported functions. This is critical for:

- **Coverage:** Integration tests (HTTP fixtures) can't practically cover every
  mapping table entry, skip rule branch, or edge case. Unit tests can cover
  them all cheaply and push diff coverage above the Codacy 85% threshold.
- **Testability:** Mapping functions are pure (input → output) so they don't
  need HTTP fixtures, sinon stubs, or test clock setup.
- **Pattern:** Follow BH Management's approach — `src/lib/bh/field_mappings.ts`
  has a corresponding `src/lib/bh/field_mappings.test.ts`.

```ts
// src/lib/<provider>/expense_mappings.test.ts
import { assertEquals } from "testing/asserts.ts";
import { resolveType, shouldSkip, buildProviderId, transformToSM } from "./expense_mappings.ts";

Deno.test({
  name: "expense_mappings: resolveType",
  async fn(t) {
    await t.step("maps ADMIN_FEE to admin", () => {
      assertEquals(resolveType(makeItem({ internal_code: "ADMIN_FEE" })), "admin");
    });
    // Cover every entry in every mapping table...
  },
});
```

Aim for: every mapping table entry, every skip rule branch, every value_type
path (amount, range, percentage, text), label fallback chain, and edge cases
like NaN amounts.

---

## Section 6: Atlas Container

### File Structure

```
containers/std/<provider>/<type>/
├── Dockerfile
├── command.sh
└── deploy.sh
```

### Dockerfile Template

```dockerfile
FROM docker.engrain.io/library/smctl:build-XXXX
RUN apk --no-cache add bash jq
WORKDIR /usr/local/app
COPY ./command.sh .
ENTRYPOINT [ "tini", "--" ]
CMD [ "/usr/local/app/command.sh" ]
```

**Build numbers:** The `build-XXXX` tag comes from the app-smctl CI pipeline.
When you push a branch to `app-smctl`, Bitbucket Pipelines builds a Docker
image tagged `build-<pipeline-number>`. Use the latest successful build number.

### command.sh Template (Pricing)

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SIGHTMAP_API_KEY:-}" ]; then
  echo "ERROR: SIGHTMAP_API_KEY is not set" >&2
  exit 1
fi

if [ -z "${<PROVIDER_UPPER>_API_KEY:-}" ]; then
  echo "ERROR: <PROVIDER_UPPER>_API_KEY is not set" >&2
  exit 1
fi

smctl convert csv2ndjson <config/assets.csv | while read -r row; do
  asset_id=$(echo "$row" | jq -r '.asset_id')
  pricing_id=$(echo "$row" | jq -r '.pricing_id')
  <provider>_id=$(echo "$row" | jq -r '.<provider>_id')
  manage_url=$(echo "$row" | jq -r '.manage_url // empty')
  asset_name=$(echo "$row" | jq -r '.asset_name // empty')

  echo "Processing: ${asset_name} (asset=${asset_id})"

  smctl -vv --strace <provider> import pricing \
    --<provider>-api-key="${<PROVIDER_UPPER>_API_KEY}" \
    ${<PROVIDER_UPPER>_API_URL:+--<provider>-api-url="${<PROVIDER_UPPER>_API_URL}"} \
    --asset-id="$asset_id" \
    --pricing-id="$pricing_id" \
    --<provider-specific-id>="$<provider>_id" \
    ${RECEIVED_FROM:+--received-from="$RECEIVED_FROM"} || true
done
```

**Key patterns:**
- `set -euo pipefail` always.
- Validate required env vars at the top.
- `smctl convert csv2ndjson` to iterate over CSV rows as JSON.
- `jq -r '.field // empty'` for optional fields.
- `|| true` after each `smctl` call — one asset failing must NOT abort others.
- `${VAR:+--flag="$VAR"}` — conditional flag only when env var is set.
- `-vv --strace` for full debug logging and stack traces in production.

### command.sh Template (Non-Pricing)

For floor plans and other CRUD operations, the pattern is similar but the
`smctl` command differs:

```bash
  smctl -vv --strace <provider> import floor-plans \
    --<provider>-api-key="${<PROVIDER_UPPER>_API_KEY}" \
    --domain="${<PROVIDER_UPPER>_DOMAIN}" \
    --property-id="$property_id" \
    --update-unit-sqft="${UPDATE_SQFT}" || true
```

Some containers export `SMCTL_API_KEY` and `SMCTL_API_BASE_URL` at the top:
```bash
export SMCTL_API_KEY="${SIGHTMAP_API_KEY}"
export SMCTL_API_BASE_URL="${SIGHTMAP_API_BASE_URL}"
```

### deploy.sh Template

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"  # critical — without this, helpers.sh path fails
. ../../../../.pipelines/helpers.sh

container_deploy 'std/<provider>/<type>'
```

The `container_deploy` helper builds the Docker image for `linux/amd64` and
pushes it to `docker.engrain.io/atlas-integrations/std/<provider>/<type>`.

> ⚠️ **`cd "$(dirname "$0")"` is required.** The pipeline calls this script
> from the repo root, not from the script's directory. Without the `cd`, the
> relative `helpers.sh` path fails.

**Note:** The path in `container_deploy` uses hyphens not underscores
(e.g., `floor-plans` not `floor_plans`), even when the directory uses
underscores.

---

## Section 7: Atlas Deployment

### File Structure

```
deployments/<clientname>[-<provider>]/<type>/
├── .env                    # Secret env vars (committed — repo is access-restricted)
├── deploy.sh               # Deployment script (called by CI pipeline, not manually)
├── docker-compose.yml      # Local testing
├── cron-job.yaml           # K8s CronJob manifest
└── config/
    └── assets.csv          # Asset mapping configuration
```

### Naming Conventions

| Scenario | Directory Name | K8s Name |
|----------|---------------|----------|
| Client uses one provider | `<clientname>/pricing/` | `<clientname>-pricing` |
| Client uses multiple providers | `<clientname>-<provider>/pricing/` | `<clientname>-<provider>-pricing` |

Examples:
- `primegroupholdings/pricing/` — SiteLink is the only provider
- `primegroupholdings-cubby/pricing/` — Added Cubby as a second provider

### .env File (Committed)

```
SIGHTMAP_API_KEY=<key>
<PROVIDER_UPPER>_API_KEY=<key>
```

The `.env` file **IS committed** to the repo. The atlas-integrations repo has
restricted access specifically so secrets can live in it. The `.env` is loaded
as a K8s Secret by the deployment pipeline.

### deploy.sh Template

```bash
#!/usr/bin/env bash
set -euo pipefail

name="<clientname>-<provider>-<type>"

cd "$(dirname "$0")" || exit
. ../../../.pipelines/helpers.sh

set_kubectl_context

# Update the cronjob.
kubectl apply -f cron-job.yaml
gcloud_url "cronjob" "$name"

# Update the config.
configmap_name="$name-config"
kubectl create configmap "$configmap_name" \
  --from-file=./config --dry-run=client -o yaml |
  kubectl apply -f -
gcloud_url "configmap" "$configmap_name"

# Update the secret.
secret_name="$name-env-vars"
kubectl create secret generic "$secret_name" \
  --from-env-file=./.env --dry-run=client -o yaml |
  kubectl apply -f -
gcloud_url "secret" "$secret_name"
```

**Note:** The path to `helpers.sh` depends on directory depth. Most deployments
use `../../../.pipelines/helpers.sh` (3 levels up).

### docker-compose.yml Template

```yaml
services:
  integration:
    image: docker.engrain.io/atlas-integrations/std/<provider>/<type>
    pull_policy: always
    env_file: .env
    volumes:
      - ./config:/usr/local/app/config
```

### cron-job.yaml Template

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: <clientname>-<provider>-<type>
spec:
  schedule: "@hourly"
  startingDeadlineSeconds: 300
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 5
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: integration
              image: docker.engrain.io/atlas-integrations/std/<provider>/<type>
              imagePullPolicy: Always
              env:
                - name: SMCTL_LOG_OUTPUT
                  value: "gcloud"
                - name: RECEIVED_FROM
                  value: "https://console.cloud.google.com/kubernetes/cronjob/us-central1/atlas-integrations/default/<clientname>-<provider>-<type>/details?project=sightmap-infra"
                - name: SMCTL_STORAGE
                  value: "gcs"
                - name: SMCTL_STORAGE_BUCKET
                  value: "atlas-integrations-captures"
                - name: SMCTL_STORAGE_BASE_PATH
                  value: "jobs/<clientname>-<provider>-<type>"
                - name: SMCTL_HTTP_CAPTURE_PATH
                  value: "./"
                - name: GOOGLE_APPLICATION_CREDENTIALS
                  value: /var/secrets/gcloud/account.json
              envFrom:
                - secretRef:
                    name: <clientname>-<provider>-<type>-env-vars
              volumeMounts:
                - name: gcloud-credentials
                  mountPath: /var/secrets/gcloud
                  readOnly: true
                - name: config
                  mountPath: /usr/local/app/config
                  readOnly: true
              resources:
                requests:
                  cpu: "250m"
                  memory: "0.5Gi"
                  ephemeral-storage: "0.5Gi"
                limits:
                  cpu: "250m"
                  memory: "0.5Gi"
                  ephemeral-storage: "0.5Gi"
          volumes:
            - name: gcloud-credentials
              secret:
                secretName: integrations
            - name: config
              configMap:
                name: <clientname>-<provider>-<type>-config
```

**Standard env vars explained:**
- `SMCTL_LOG_OUTPUT=gcloud` — Structured JSON logging for GCP Cloud Logging.
- `RECEIVED_FROM` — GKE console URL for the CronJob (traceability).
- `SMCTL_STORAGE=gcs` + `SMCTL_STORAGE_BUCKET` — HTTP captures stored in GCS.
- `SMCTL_HTTP_CAPTURE_PATH=./` — Enable HTTP capture for debugging.
- `GOOGLE_APPLICATION_CREDENTIALS` — GCP service account for GCS access.

### config/assets.csv Format

The CSV columns vary by integration type. Common patterns:

**Pricing (simple — Cubby):**
```csv
asset_id,pricing_id,facility_id,manage_url,asset_name
26254,26374,fac_XXXX,https://sightmap.com/manage/assets/multifamily/26254,Property Name
```

**Pricing (with credentials per row — SiteLink):**
```csv
asset_id,pricing_id,property_id,corporate_code,username,password,manage_url,asset_name
26419,27548,NY49,CNYR,User,Pass123,https://sightmap.com/manage/assets/multifamily/26419,Property Name
```

**Floor Plans (Entrata):**
```csv
asset_id,entrata_property_id,manage_url,asset_name
123,456789,https://sightmap.com/manage/assets/multifamily/123,Property Name
```

**Virtual Tours (Matterport):**
```csv
asset_id,outbound_link_id,manage_url,asset_name
123,45,https://sightmap.com/manage/assets/multifamily/123,Property Name
```

---

## Section 8: Git & CI Workflow

### Branching

| Repo | Branch From | PR Target |
|------|-------------|-----------|
| `app-smctl` | `main` | `main` |
| `atlas-integrations` | `main` | **No PR** — `deploy/*` branches ARE the deployment |

> ⚠️ **Branch isolation:** Always create a dedicated branch per integration
> type (`feature/provider-expenses`, `feature/provider-pricing`). Never add
> a new integration command to an existing feature branch for a different
> integration type — it creates entangled PRs that are hard to review and
> must be untangled later via squash/cherry-pick.

### Commit Message Format

```
:emoji: Description (JIRA-123).
```

- Present tense, imperative mood.
- Always end with a period.
- Reference Jira ticket.

Common emojis for integrations:
- `:sparkles:` — New integration (new feature/command)
- `:art:` — Restructure/format existing code
- `:bug:` — Bug fix in existing integration
- `:white_check_mark:` — Adding tests
- `:pencil:` — Documentation

### CI/CD Flow

**app-smctl:**
1. Push feature branch → Bitbucket Pipelines builds + tests.
2. CI produces Docker image tagged `build-<pipeline-number>`.
3. Use this build number in your Dockerfile `FROM` line.
4. Open PR → review → merge to `main`.

**atlas-integrations:**

> ⚠️ **`deploy/*` branches ARE the deployment mechanism.** No PR needed, no
> merge into `main`. Pushing to a `deploy/*` branch triggers CI automatically.

1. Create branch: `deploy/<clientname>-<provider>-<type>`
   (e.g., `deploy/westcreekliving-eliseai-expenses`).
2. Commit everything — container files, deployment files, `.env` with secrets,
   config CSVs. The repo has restricted access so secrets are safe.
3. Push the branch. CI pipeline automatically:
   - Runs `containers/std/<provider>/<type>/deploy.sh` (builds Docker image)
   - Runs `deployments/<clientname>/<type>/deploy.sh` (applies K8s CronJob)
4. **You do NOT run `deploy.sh` manually.** The pipeline handles it.

### Getting the Build Number

After your `app-smctl` branch builds successfully:
1. Go to Bitbucket Pipelines for `app-smctl`.
2. Find your branch's latest successful pipeline.
3. The pipeline number IS the build number (e.g., `build-1334`).
4. Use it in your Dockerfile: `FROM docker.engrain.io/library/smctl:build-1334`.

---

## Section 9: Checklist

### Phase 1: smctl Client & Command

- [ ] Read AGENTS.md for app-smctl
- [ ] Study the PMS API documentation (auth, endpoints, data shapes, errors)
- [ ] Create `src/lib/<provider>/client.ts` with typed methods
- [ ] Create `src/lib/<provider>/mod.ts` (re-export)
- [ ] Create command hierarchy:
  - [ ] `src/commands/<provider>.ts` (top-level with credentials)
  - [ ] `src/commands/<provider>/index.ts`
  - [ ] `src/commands/<provider>/import.ts`
  - [ ] `src/commands/<provider>/import/index.ts`
  - [ ] `src/commands/<provider>/import/<type>.ts` (handler)
- [ ] Register in `src/commands/index.ts`
- [ ] Run `./fmt.sh` and `./lint.sh`

### Phase 2: Tests

- [ ] Create test fixture directories under `test/<provider>/import/<type>/`
- [ ] Create `.http.txt` fixtures for each scenario
- [ ] Write test file `src/commands/<provider>/import/<type>.test.ts`
- [ ] Test scenarios: successful run, API error, empty data
- [ ] Run `./test.sh src/commands/<provider>/import/<type>.test.ts`
- [ ] All tests pass

### Phase 3: Atlas Container + Deployment

> ⚠️ `deploy/*` branches are the deployment mechanism. No PR needed.

- [ ] Get the smctl build number from the app-smctl CI pipeline
- [ ] Create `deploy/<clientname>-<provider>-<type>` branch from `main`
- [ ] Create `containers/std/<provider>/<type>/Dockerfile` (with correct build number)
- [ ] Create `containers/std/<provider>/<type>/command.sh`
- [ ] Create `containers/std/<provider>/<type>/deploy.sh` (must include `cd "$(dirname "$0")"`)
- [ ] Create `deployments/<clientname>/<provider>_<type>/`
- [ ] Create `config/assets.csv` with asset mappings
- [ ] Create `cron-job.yaml` (use template, replace all placeholders)
- [ ] Create `docker-compose.yml` for local testing
- [ ] Create `deploy.sh`
- [ ] Create `.env` file with real credentials (committed — repo is access-restricted)
- [ ] Optional: test locally with `docker compose up`
- [ ] Commit all files (including `.env`) and push the `deploy/*` branch
- [ ] CI triggers automatically — builds Docker image + deploys K8s CronJob
- [ ] Verify CronJob runs successfully in GKE console

### Phase 4: Git & PR (app-smctl only)

- [ ] Squash WIP commits into one final commit
- [ ] Commit message: `:sparkles: Add <Provider> <type> integration (JIRA-XXX).`
- [ ] Push to feature branch
- [ ] Open PR with title matching commit message
- [ ] CI passes (lint, tests, Codacy coverage ≥ 85% diff)
- [ ] PR reviewed and merged

### Phase 5: Live Validation

- [ ] Obtain API keys for a real test property
- [ ] Run with `--dry-run` first — verify item counts, skip reasons, mapping
- [ ] Run live — verify all creates succeed (watch for 422 validation errors)
- [ ] Run a second time — verify **0 updates** (full idempotency)
- [ ] If any field gets 422'd, check the enum values reference in Section 4
- [ ] Verify data appears correctly in SightMap manage UI

---

## Appendix: Quick Reference

### Import Paths

All imports use the alias map from `import_map.json`:
```ts
import log from "/lib/log.ts";          // → src/lib/log.ts
import http from "/lib/http.ts";        // → src/lib/http.ts
import { Client } from "/lib/<provider>/mod.ts";
import { Client as SightMap } from "/lib/sightmap/mod.ts";
import { Arguments } from "yargs/deno-types.ts";
import { YargsInstance } from "yargs/build/lib/yargs-factory.js";
import { DateTime } from "luxon";
import sinon from "sinon";
import { assertEquals, assertRejects } from "testing/asserts.ts";
import * as test from "/lib/testing.ts";
import { assertDebugContains, assertInfoContains } from "/lib/asserts.ts";
```

### Key SightMap Types

```ts
type PricingEntry = {
  price: number;
  available_on: string;          // ISO date
  lease_term: number | string | null;
  lease_starts_on: string | null;
  unit_id: string;
  unit_number: string;
  provider_id: string | null;
  status: string | null;
  show_pricing: boolean;
  show_online_leasing: boolean;
  leasing_fields: Record<string, string | number | boolean> | null;
};

type OpenedPricingTransaction = {
  transaction_id: string;
  transaction_uuid: string;
  transaction_url: string;
  transaction_ingest_url: string;
  status: string;
  expires_in: number;
};
```

Commands use `Partial<PricingEntry>` so only required fields need to be set.

### Deno Runtime Notes

- **Deno version:** app-smctl uses Deno 2.x (check `.tool-versions` for exact version).
- **Import map:** `import_map.json` at repo root — all imports resolve through it.
- **Config:** `deno.jsonc` specifies `importMap: "import_map.json"`.
- **Test runner:** `deno test` with `--allow-read --allow-env --allow-import`.
- **No npm: specifiers** — use the CDN URLs in the import map.
- **File naming:** `snake_case.ts` for all files.

### Shell Script Rules

- Start with `set -euo pipefail`.
- Must pass `shfmt` (via `./fmt.sh`).
- Must pass `shellcheck` (via lint step in CI).
