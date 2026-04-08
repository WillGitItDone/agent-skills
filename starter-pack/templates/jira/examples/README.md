# Jira Ticket Examples — AI Reference

> **For AI agents:** Study these examples to learn Engrain's ticket-writing style.
> Match the tone, detail level, and terminology — don't copy verbatim.
> Use the templates in `templates/jira/` for structure, and these examples for taste.
>
> **All ticket types use the same 6 sections:**
> **Title → User Story → Context → Specifications → Not in Scope → Acceptance Criteria**

---

## Writing Principles

<!-- Fill in your team's implicit rules — things the templates don't capture -->

1. **Use Engrain terminology** — Asset (not property), PMS (not integration system), Feed (not data sync), Consumer (not API client). See `data-lake/_context.md`.
2. **Right-size the detail** — [How verbose should context be? How technical? Add guidance here.]
3. **ACs are testable** — Every acceptance criterion should be verifiable by QA without asking the author for clarification.
4. **Link, don't duplicate** — Reference Figma, Notion docs, or other tickets rather than copying content into the ticket.
5. **Name the data hierarchy** — When relevant, specify where in Account → Asset → Building → Floor → Unit the work applies.
6. **Specifications carry the weight** — This is where the real detail lives: implementation notes, repro steps, API endpoints, design refs, dependencies. Tailor the content to the ticket type.
7. **Not in Scope prevents scope creep** — Always include at least one item. It shows you've thought about boundaries and sets clear expectations.
8. **[Add your own]** — What other principles matter to your team?

---

## Story Examples

### ✅ Example 1: Feature Story — SM-3160

<!-- Source: SM-3160 | Type: Story | Project: SightMap | Points: 13 -->
<!-- Reporter: Nathan Mojica | Assignee: Matt Bakken | Priority: Highest -->

**Title:** Create a 'Canopy' page/interface in the Customer Facing UI

**User Story:**
As a Unit Map user, I want an interface where I can view all of the 'point of interest' nodes that I have plotted on each of my maps.

As an Engrain employee, I want an interface that shows all of the (non-unit) nodes coming through the 'Locations' endpoint of the UM REST API for a specific unit map.

**Context:**

*References:*
- Design: https://www.figma.com/design/jU9abO2adJuDf5TEsnFbYG/Customer-Map-Manager-App?node-id=1-740&t=SRBcTW8kkC7x4hrP-1
- Link to the Customer UI: https://sightmap.com/customer/assets

*Setup Example:*
*NOTE: This is an example in PROD, but we will have a DEV/Local example to match this soon (it is being worked on now).
- Asset: https://sightmap.com/manage/assets/multifamily/7779
- Unit Maps (see the one tagged as "pathfinding"): https://sightmap.com/manage/assets/multifamily/7779/unit-map/unit-maps
  - IE. "50785" is the one tagged with "pathfinding".
  - This can also be seen from making a call to "Get: List Unit Maps" (See DOCS HERE) *make sure to reference the asset ID "7779".
- So when a user loads the customer UI, and selects asset "7779", and goes to the "Canopy" tab → the Unit Map "50785" should load.
- By querying the DB on "50785" Unit Map, you will be returned a list of nodes.
  - In this case there are: 23 amenity nodes, 11 emergency nodes, 3 maintenance nodes, 2 technology nodes, and 2 utility nodes. So we would expect to see 41 nodes plotted on the map (across all floors).
  - And in the side legend, we would expect to see the "Categories" for "Amenity", "Emergency", "Maintenance", "Technology", and "Utility" — with counts next to how many nodes are in each category on the current floor. Then within the categories, you will see the individual node names with counts of how many nodes on the current floor have that name.

**Specifications:**

*Placement:*
- We will need to add a new tab to the customer UI.
- After an asset is selected, and a user lands on the 'Units' screen — they will see a new tab at the end of the top bar for "Canopy".
- If the "Canopy" option is selected — then everything below the header will be taken over by the new Canopy application.

*Start Up / Layout:*
- When the "Canopy" tab is selected, and the UI loads in that tab of the Customer UI the screen will be split into two sides:
  - 1/4 of the screen (left side) will show a legend
  - 3/4 of the screen (right side) will show a Unit Map
- The Unit Map that is loaded in the right side of the screen will be whatever unit map on that asset has the 'Unit Map Tag' of "pathfinding".
  - If no Unit Map on that asset has the tag, then we should show an error screen saying there is no map to load. We can use this UI for now (HERE).
  - If multiple Unit Maps on that asset have the tag, then we should load in the first one that we find in the list (this should be an edge case).
  - The unit map will also need a floor switcher UI in the upper right corner.
- On the Unit Map there will be nodes plotted, that correspond to the Shade nodes plotted on the selected Unit Map (important note: This should be pulled from the Shade data in the DB, not from the UM REST API).
  - The only nodes considered should be the ones that have tags that match one of the following: `"key": "engrain:administrative"`, `"key": "engrain:amenity"`, `"key": "engrain:emergency"`, `"key": "engrain:maintenance"`, `"key": "engrain:technology"`, `"key": "engrain:transitional"`, `"key": "engrain:utility"`.
  - If they don't have this tag, then they should be ignored. If they do have one of the above tags they should be consumed.
  - For the nodes that are consumed, the `"key": "engrain:[]"` will be their category — ie. `"engrain:maintenance"` will be a node in the "Maintenance" category.
  - For the nodes that are consumed, the `"key": "name"` will be their name/type — ie. `"engrain:maintenance"` and `"name: boiler_room"` will be a node in the "Maintenance" category with a name/type of "Boiler Room".
- Then on the left side legend, it will list all of the categories of nodes (with a count of how many nodes of that category are shown on the current floor). Then within the categories it will show nested node types (with a count of how many nodes of that category are shown on the current floor).

*Functionality / Display:*
- Each 'Category' of nodes will have its own color coordination, and all nodes of that category will show with that color on the map and in the legend. IE. technology can be yellow, so all technology nodes show as yellow.
  - NOTE: We can preset these for our 7 categories, or dynamically show them based on what is available.
- In the legend, only the categories that have nodes on the map should be displayed. So if all map nodes are "Amenity" or "Technology" that will be the only categories shown.
- On the "Canopy" page there are 3 major pieces of functionality:
  - **#1.) Filtering:** Any "Category" or "Type" can be hidden — by clicking the "eye" icon next to it. To unhide, click the eye icon again.
  - **#2.) Highlighting:** Clicking any node on the legend will highlight all instances of that node on the floor: this can be done on the Category or Type level.
  - **#3.) Selecting:** Clicking any node in the map will highlight just that node and it will show that node's full metadata (anything we store from the shade data) in a section on the left hand side of the application / where it takes over the legend.

**Not in Scope:**
- Editing or modifying node data from the Canopy interface — this is read-only.
- Nodes without one of the 7 recognized `engrain:*` tag categories.
- Fetching node data from the UM REST API — data must be pulled from Shade data in the DB.
- Handling assets that do not have Unit Maps.

**Acceptance Criteria:**
- [ ] Given an asset is selected in the Customer UI, when the user clicks the "Canopy" tab, then the screen splits into a 1/4 legend (left) and 3/4 Unit Map (right).
- [ ] Given the selected asset has a Unit Map tagged "pathfinding", when the Canopy tab loads, then that Unit Map is displayed with a floor switcher in the upper right corner.
- [ ] Given the selected asset has no Unit Map tagged "pathfinding", when the Canopy tab loads, then an error screen is displayed indicating there is no map to load.
- [ ] Given a Unit Map is loaded, when Shade nodes with recognized `engrain:*` tags exist, then those nodes are plotted on the map with category-specific colors.
- [ ] Given nodes are plotted on the map, when viewing the legend, then only categories with nodes on the current floor are listed with accurate counts per category and per type.
- [ ] Given the legend is displayed, when the user clicks the "eye" icon next to a Category or Type, then those nodes are hidden from the map and legend; clicking again unhides them.
- [ ] Given the legend is displayed, when the user clicks a Category or Type name, then all matching nodes on the current floor are highlighted.
- [ ] Given nodes are plotted on the map, when the user clicks a node on the map, then that node is highlighted and its full metadata is displayed in the left panel, replacing the legend.
- [ ] Given the user switches floors via the floor switcher, then the map and legend update to reflect only the nodes and counts for the newly selected floor.

> 💡 **Why this works:**
> - **Dual user stories** — captures both the external user need (viewing POI nodes) and the internal employee need (verifying Locations endpoint data). This is a good pattern when a feature serves multiple audiences.
> - **Context provides a concrete walkthrough** — the Setup Example with asset 7779, unit map 50785, and exact node counts (23 amenity, 11 emergency, etc.) gives the developer a real test case to validate against. This is extremely valuable.
> - **Specifications are organized by concern** — Placement → Start Up/Layout → Functionality/Display follows the user's mental model from "where is this?" to "what does it do?".
> - **Data source is explicit** — "pulled from the Shade data in the DB, not from the UM REST API" prevents a wrong implementation path. Callouts like this save entire sprint cycles.
> - **Tag mapping is spelled out** — the 7 `engrain:*` tag keys and how they map to categories/names removes all ambiguity about data parsing.
> - **Three interaction modes are numbered** — Filtering, Highlighting, and Selecting are clearly separated with distinct behaviors, making them independently testable.
> - **Not in Scope was missing** — added to clarify this is read-only and DB-sourced. Without it, a developer might reasonably ask "can users edit nodes?" or "should I hit the API?"
> - **ACs were missing** — derived from the specifications to create testable Given/When/Then statements covering the happy path, error state, and all three interaction modes.

---

### ✅ Example 2: Integration Story — TT-892

<!-- Source: TT-892 | Type: Story | Project: TouchTour Flex | Points: 3 -->
<!-- Reporter: Alex LeVangie | Assignee: Evan Mora | Labels: BackEnd, multifamily -->
<!-- Related: TT-858 -->

**Title:** Create nightly sync for pricing disclaimer data

**User Story:** As a user making pricing disclaimer changes in Atlas to a property that has a TouchTour with a configured pricing disclaimer, I would like to know my changes will be synced overnight to TouchTour core.

**Context:**
In theory, pricing disclaimer changes made in Atlas should be updated in the core CMS by whoever is making the changes, but in the event one is missed, given disclaimers are so important, we would like to have a nightly sync to handle any human error. This sync should run every night to update ONLY the properties that have a Pricing Disclaimer selected as active in the Core CMS. For properties that do not have a disclaimer or do not have a disclaimer from Atlas selected, the sync does not need to occur. For all properties that do have a pricing disclaimer selected from Atlas, we simply want to update the Pricing Disclaimer title, short text, long text, and subtext from Atlas to ensure all data is accurate and up to date.

**Specifications:**

*Feature Visibility / UI Elements*
- No new UI elements are required for this feature.
- Pricing Disclaimer fields (Title, Short Text, Long Text, Subtext) continue to display in the Core CMS as read-only when sourced from Atlas (current behavior).

*Behavior*
- A nightly automated sync runs on a scheduled basis to update Pricing Disclaimer data from Atlas into TouchTour Core.
- The nightly sync:
  - Executes once per night at the configured system schedule.
  - Targets only properties that have an active Pricing Disclaimer selected from Atlas in the Core CMS.
- For each eligible property, the system retrieves the latest Pricing Disclaimer data from Atlas and updates the following fields in Core CMS:
  - **Pricing Disclaimer Title**
  - **Short Text**
  - **Long Text**
  - **Subtext**
- The sync updates content only; it does not change which Pricing Disclaimer is selected for the property.

*Persistence*
- After the nightly sync completes, updated Pricing Disclaimer values persist in Core CMS and are reflected consistently:
  - On subsequent CMS visits
  - On the front-end TouchTour experience
- Manual changes in Atlas made prior to the nightly run are reflected in Core CMS after the next successful sync.

*Data Requirements*
- The system must use the stored Pricing Disclaimer ID (External ID) to retrieve the correct disclaimer from Atlas.
- The sync process must not overwrite or clear Pricing Disclaimer data for properties that are not eligible for the sync.
- Existing property-to-disclaimer associations remain intact; only the disclaimer text fields are refreshed to match Atlas.

*API Reference*
- Use `GET /v1/assets/{asset}/multifamily/pricing-disclaimers/{pricing-disclaimer}` to minimize response size (disclaimer ID is already stored).

**Not in Scope:**
- Properties that do not have a Pricing Disclaimer selected in Core CMS are excluded from the nightly sync.
- Properties that have a Pricing Disclaimer not sourced from Atlas are excluded from the nightly sync.
- This sync does not create, remove, or reassign Pricing Disclaimers; it only refreshes content for existing Atlas-linked disclaimers.

**Acceptance Criteria:**
- [ ] Given a property with an active Atlas-sourced Pricing Disclaimer in Core CMS, when the nightly sync runs, then the Pricing Disclaimer Title, Short Text, Long Text, and Subtext are updated to match Atlas.
- [ ] Given a property without a Pricing Disclaimer selected in Core CMS, when the nightly sync runs, then that property is skipped with no changes.
- [ ] Given a property with a non-Atlas Pricing Disclaimer, when the nightly sync runs, then that property is skipped with no changes.
- [ ] Given the nightly sync has completed, when a user visits the Core CMS, then the updated disclaimer values are displayed.
- [ ] Given the nightly sync has completed, when a renter views the front-end TouchTour experience, then the updated disclaimer values are reflected.
- [ ] Given the sync runs, when processing eligible properties, then existing property-to-disclaimer associations remain intact and only text fields are refreshed.

> 💡 **Why this works:**
> - **Context explains the WHY** — the "human error safety net" framing gives the developer clear motivation and lets them make smart implementation decisions.
> - **Specifications are organized by concern** — Feature Visibility, Behavior, Persistence, and Data Requirements each get their own subsection, making the ticket scannable.
> - **Not in Scope is extracted from the original ACs** — the original ticket embedded scope limitations inside Acceptance Criteria. Pulling them out makes boundaries explicit.
> - **API endpoint is called out** — the specific `GET` call with rationale ("minimize response size") saves the developer research time.
> - **ACs are reformatted to Given/When/Then** — the original ticket used detailed bullets as ACs; reformatting into testable Given/When/Then statements makes QA verification unambiguous.
> - **Note:** The original ticket's "Acceptance Criteria" section was really a mix of specifications and scope limitations. Reorganizing into our 6-section format separated these concerns cleanly.

---

### ✅ Example 3: Enhancement Story (UI + Integration) — TT-858

<!-- Source: TT-858 | Type: Enhancement | Project: TouchTour Flex | Points: 8 -->
<!-- Reporter: Alex LeVangie | Assignee: Evan Mora | Labels: multifamily -->
<!-- Related: TT-892, TT-845 -->

**Title:** Call SM API for Disclaimer Data

**User Story:** As an implementations specialist, I would like to be able to manually sync TouchTour Core's pricing disclaimers with Atlas so that I do not need to manually copy over text from one platform to the other.

**Context:**
In an effort to create automated parity between Atlas and TouchTour Core, we would like to utilize the SM API for populating data into TT Core as well as create an automatic sync. SM already allows for users to call for Pricing Disclaimers.

Since multiple disclaimers can exist in Atlas, we will need to display the disclaimer name(s) in a dropdown for users to select and then populate the associated Short Text, Long Text, and Subtext based on the selection. The corresponding fields should be READ ONLY. The dropdown should also include an indicator for the source, either 'Atlas' or 'TouchTour' in parenthesis.

When we get the response from SM, and a CMS user has saved the disclaimer, we will need to save the Disclaimer ID that was selected. The Atlas pricing disclaimer ID will be saved in our database as the External ID and all subsequent calls made to refresh data should use that ID.

We will need to create a solution so that all properties that have a disclaimer set don't lose any data.

*API References:*
- List disclaimers: `GET /v1/assets/{asset}/multifamily/pricing-disclaimers`
- Get specific disclaimer: `GET /v1/assets/{asset}/multifamily/pricing-disclaimers/{pricing-disclaimer}`

*Related Tickets:*
- TT-892: Create nightly sync for pricing disclaimer data (the automated counterpart to this manual sync)
- TT-845

**Specifications:**

*Feature Visibility / UI Elements*
- A Manual Sync capability is available within the Property section.
- A Pricing Disclaimer dropdown is displayed and populated with the available disclaimer name(s) retrieved from SM API for the property's mapped asset.
- The following fields are displayed and are read-only:
  - Pricing Disclaimer Short Text
  - Pricing Disclaimer Long Text
  - Pricing Disclaimer Subtext

*Behavior*
- When the user opens the Pricing Disclaimer configuration for a property, the system retrieves the available disclaimers from SightMap using:
  - `GET /v1/assets/{asset}/multifamily/pricing-disclaimers`
- When the user selects a disclaimer from the dropdown, the system populates the selected disclaimer details which were provided in the initial GET call.
- After a disclaimer is selected, the system populates the read-only Short Text, Long Text, and Subtext fields with the values returned from SightMap.
- When the user clicks Save, the system persists the selection by saving the selected Pricing Disclaimer ID to the property configuration.
- On subsequent visits, if the property already has a saved disclaimer ID, the system pre-selects that disclaimer in the dropdown (when available) and displays the corresponding read-only text.

*Persistence*
- After saving, the selected disclaimer remains associated to the property across page refresh, logout/login, and subsequent sessions.
- The displayed Short Text / Long Text / Subtext continue to reflect the currently saved disclaimer selection.
- When loading a front end instance, the selected and saved disclaimer text(s) render in UI.

*Data Requirements*
- TouchTour Core must store the selected Pricing Disclaimer ID using the existing database field(s) (e.g., Pricing Disclaimer ID).
- The system must not clear or overwrite existing saved disclaimer selections during release/deployment:
  - Properties that already have a disclaimer set must retain their saved disclaimer ID and any existing data associations.
- If the system uses Pricing Disclaimer External ID, it must be populated consistently based on the SightMap response (when applicable) without breaking existing records that already have values stored.

**Not in Scope:**
- Manual editing of disclaimer text in TouchTour Core — fields remain read-only.
- Automatic/background sync behavior — covered separately in TT-892.
- This feature supports selection of a single Pricing Disclaimer per property; multi-disclaimer selection is not included.

**Acceptance Criteria:**
- [ ] Given a property with a mapped asset in Atlas, when the user opens Pricing Disclaimer configuration, then a dropdown is populated with available disclaimer names from the SM API, each showing a source indicator ('Atlas' or 'TouchTour').
- [ ] Given the dropdown is displayed, when the user selects a disclaimer, then the Short Text, Long Text, and Subtext fields populate as read-only with the values from SightMap.
- [ ] Given a disclaimer is selected, when the user clicks Save, then the Pricing Disclaimer ID is persisted to the property configuration as the External ID.
- [ ] Given a property already has a saved disclaimer ID, when the user revisits the Pricing Disclaimer configuration, then the dropdown pre-selects that disclaimer and displays the corresponding read-only text.
- [ ] Given a property has an existing disclaimer set, when a release/deployment occurs, then the saved disclaimer ID and all data associations are retained without being cleared or overwritten.
- [ ] Given a disclaimer is saved, when the front-end TouchTour instance loads, then the selected disclaimer text renders in the UI.

> 💡 **Why this works:**
> - **User story names the persona** — "implementations specialist" is specific, not generic "user." This tells the developer exactly who benefits and why the workflow matters.
> - **Context tells the full story** — explains the parity goal between Atlas and TT Core, the dropdown/source indicator requirement, and the External ID persistence pattern. A developer reading this understands the entire system flow.
> - **API endpoints are embedded in Behavior specs** — each user action maps to a specific API call, making the integration path unambiguous.
> - **Data migration safety is explicit** — "must not clear or overwrite existing saved disclaimer selections during release/deployment" is the kind of requirement that prevents production incidents. Critical for any ticket touching existing data.
> - **Not in Scope cross-references TT-892** — "Automatic/background sync behavior — covered separately in TT-892" shows how related tickets should reference each other to prevent duplicate work.
> - **Same restructuring pattern as TT-892** — the original ticket again embedded scope limitations and specifications inside "Acceptance Criteria." Both TT-858 and TT-892 demonstrate that this is a common pattern to watch for and reorganize.

---

### ✅ Example 4: CLI + External API Integration Story — SM-3111

<!-- Source: SM-3111 | Type: Story | Project: SightMap | Points: 13 -->
<!-- Reporter: Nathan Mojica | Assignee: Narayan Magar | Priority: High -->
<!-- ⚠️ Credentials sanitized — original ticket contained API password and client_secret -->

**Title:** Write an SMCTL command to push expense data to Blue Moon's API

**User Story:** As an Engrain integrations team member, I want an SMCTL command that pushes expense data to the Blue Moon API daily so that Greystar's Blue Moon contracts include accurate, up-to-date expense disclosures without manual data entry.

**Context:**
Blue Moon generates contracts for Greystar, and currently they don't include any expense data. Greystar has asked us to work with Blue Moon to provide the expense data, but Blue Moon is unable to fetch from our API — they can only receive information. So we need to push data to their API, so they can use it in the contracts. The goal of this ticket is to set up an SMCTL command to push our expense data into the Blue Moon API (daily).

*Reference Information:*
- Blue Moon's 'Beta' API Documentation: (Attached)
- Blue Moon API Collection: Blue Moon.postman_collection.json
- Blue Moon Form (Our Data Will Fill Out): Greystar Fee Disclosure Layout 1.14.26.pdf
- Blue Moon Test Properties (with Serial Numbers/Property IDs) for 'Beta' Testing: https://docs.google.com/spreadsheets/d/1FlHrF7mAQtwWLLQPbqVmMkkrUiknazKCzmDqGjvOHKk/edit?gid=1343594028#gid=1343594028

*Things To Know:*
- For testing and setup, we will be using Blue Moon's 'Beta' API and the list of test properties meant for 'Beta' testing. But when we finalize this SMCTL command we will switch to Blue Moon's PROD instance.
- The best two properties to start testing with are: PropertyID 110092 / Serial No: CA19072601, and Property ID: 110094 / Serial No: CO19072601.
- IMPORTANT: A single Greystar property could have multiple Blue Moon instances (due to campuses, or phases properties, etc) — so we need to think about how we make sure we push that same expense data to all Blue Moon instances involved.
  - For the initial setup we can just go off of the IDs in the sheet, but we will likely have to update this to consume 'blueMoonID' and 'BlueMoonSerialNo' from the Greystar SF API and write it to our 'provider_references' field for every expense on that asset.
  - So maybe we need to make the new Blue Moon Property ID column on the CSV file of the SMCTL command allow for multiple IDs?

**Specifications:**

*API Workflow:*

Step 1 — Getting a Bearer Token:
- Call: `POST https://beta-api.bluemoonforms.com/oauth/token`
- You need to get a unique Bearer token for each property; the token lasts for 15 days and has a refresh code in the response.
- Example body payload:
  ```json
  {
    "username": "engrain@[Serial Number for Property]",
    "password": "[REDACTED]",
    "grant_type": "password",
    "scope": ["full"],
    "client_id": "[REDACTED]",
    "client_secret": "[REDACTED]"
  }
  ```

Step 2 — Pushing Expense Data:
- Call: `POST https://beta-api.bluemoonforms.com/api/default/lease/fee-disclosure`
- You need to put: `Authorization: Bearer [Bearer Token]` in the headers.
- Body Disclaimer: Every line in the form we are filling out has the same structured set of 5 fields → `fee_disclosure_item_definition`, `fee_disclosure_amount`, `fee_disclosure_timing`, `fee_disclosure_frequency_method`, `fee_disclosure_charge_type`. The only difference is the numerical suffix at the end ie. `fee_disclosure_timing_1` is the timing for line 1, while `fee_disclosure_timing_2` is the timing for line 2.
- Example body payload:
  ```json
  {
    "propertyNumber": 110092,
    "custom": {
      "fee_disclosure_item_definition_1": "Application Fee - Fee for processing application.",
      "fee_disclosure_amount_1": "50.00",
      "fee_disclosure_timing_1": "At Move-In",
      "fee_disclosure_frequency_method_1": "One-Time/ Per Applicant",
      "fee_disclosure_charge_type_1": "Required"
    }
  }
  ```
  This populates line one of the form for the specific asset in the call "110092".

*Field Mapping Logic:*
- All values passed to the API are strings.
- Each of the 5 fields per expense line has its own mapping from SightMap DB:
  - `fee_disclosure_item_definition` → `[label]-[tooltip label]`
  - `fee_disclosure_amount` → `[amount]` OR `[min_amount]-[max_amount]` OR `[text_amount]` OR `[percentage_amount]`
  - `fee_disclosure_timing` → `[due_at_timing]`
  - `fee_disclosure_frequency_method` → `[frequency]/[provider_method]`
  - `fee_disclosure_charge_type` → derived from `[is_required]`:
    - "Required" if `is_required` is TRUE
    - "Optional" if `is_required` is FALSE
    - "Situational" if `classification_expense_calculator` = "other"
- If an asset has 20 expenses, we should write each of them to the Blue Moon API with an input for each of the 5 fields for each expense.

*SMCTL Command Details:*
- We are adding this onto our existing SMCTL command that ingests expense data from the Greystar Salesforce API. (SEE PR HERE).
- Add two new fields to the CSV file for `blue_moon_property_id` and `blue_moon_serial_number`.
- The command will now do the following for each property:
  1. Hit the Greystar Salesforce API and ingest/transform the expense data.
  2. Push that updated expense data for that property into the SightMap API.
  3. Get the bearer token for that property (via the Blue Moon API), and use that to make the POST call to push the expense data into the Blue Moon API for that specific property.
  4. Move on to the next property in the list.

**Not in Scope:**
- Production deployment — initial setup targets Blue Moon's Beta API only; PROD switch is a follow-up.
- Consuming `blueMoonID` / `BlueMoonSerialNo` from the Greystar SF API and writing to `provider_references` — noted as a future enhancement for multi-instance properties.
- Creating or modifying expense data — this command only reads from SightMap and pushes to Blue Moon.
- Blue Moon form layout changes or new field types beyond the 5 defined disclosure fields.

**Acceptance Criteria:**
- [ ] Given the SMCTL command is run with a CSV containing `blue_moon_property_id` and `blue_moon_serial_number`, when processing a property, then the command first ingests expense data from Greystar Salesforce, pushes it to the SightMap API, then authenticates with Blue Moon and pushes the expense data to the Blue Moon API.
- [ ] Given a property has expenses in SightMap, when the command pushes to Blue Moon, then each expense is mapped to the 5 disclosure fields (`fee_disclosure_item_definition`, `fee_disclosure_amount`, `fee_disclosure_timing`, `fee_disclosure_frequency_method`, `fee_disclosure_charge_type`) with correct numerical suffixes per line.
- [ ] Given an expense has `is_required` = TRUE, when mapped to `fee_disclosure_charge_type`, then the value is "Required"; FALSE → "Optional"; `classification_expense_calculator` = "other" → "Situational".
- [ ] Given a property has a `blue_moon_serial_number` in the CSV, when authenticating with Blue Moon, then a Bearer token is obtained using that serial number and used for the subsequent POST call.
- [ ] Given multiple properties are listed in the CSV, when the command runs, then each property is processed sequentially (Salesforce → SightMap → Blue Moon) before moving to the next.
- [ ] Given the command is run against test properties (110092/CA19072601 and 110094/CO19072601), when the POST completes, then the expense data is visible in Blue Moon's Beta environment.

> 💡 **Why this works:**
> - **User Story was missing — generated from context.** The original ticket had no "As a..." statement. For CLI/integration work, the persona is often an internal team member, not an end user. The generated story names the integrations team and the business value (Greystar contracts).
> - **Credentials sanitized** — the original ticket contained a plaintext password and client_secret. Examples files should NEVER contain real credentials; always replace with `[REDACTED]`.
> - **Multi-step API workflow is numbered** — Step 1 (auth) → Step 2 (push) with exact endpoints and example payloads makes implementation straightforward. The developer can test each step independently.
> - **Field mapping is a lookup table** — the 5-field mapping with source DB fields and the charge_type branching logic is the kind of spec that eliminates back-and-forth questions during development.
> - **Context flags a known complexity** — the "multiple Blue Moon instances per Greystar property" note is called out as IMPORTANT with a proposed approach (CSV multi-ID column). This is exactly the kind of edge case that should be surfaced early, not discovered mid-sprint.
> - **Not in Scope draws a clear Beta/Prod boundary** — explicitly stating that production deployment is out of scope prevents the developer from over-engineering for prod concerns in the initial build.
> - **Heaviest ticket so far (13 points)** — demonstrates that larger stories need proportionally more specification detail, more ACs, and more explicit scope boundaries.

---

### ✅ Example 5: Design/UX Enhancement — SM-3210

<!-- Source: SM-3210 | Type: Enhancement | Project: SightMap | Points: 3 -->
<!-- Reporter: William Fagan | Assignee: Andre Dugal | Priority: Medium -->
<!-- Related: SM-3188 -->

**Title:** Design Asset dashboard "Accounts" section with relationship roles (Owner, Manager, Licensee) + interim "Other"

**User Story:** As an Atlas user, I want to see which Accounts are related to an Asset and what their relationship is (Owner / Manager / Licensee / Other), so I can quickly understand property context.

**Context:**
We need to associate an Asset to an Account in three distinct ways so Atlas users (and future logic) can understand the relationship:

- **Owner:** Account that owns the physical property (1 per Asset)
- **Manager:** Account that manages the property (1 per Asset)
- **Licensee:** Account that pays for the SightMap license (1 per Asset)

Today: the Asset dashboard already has an Accounts section that lists all linked accounts without role context.

Near-term constraint (do not break existing behavior):
- Until account cleanup is complete, the Accounts section must continue to show all linked accounts.
- Any linked accounts that are not one of the 3 defined roles must be displayed as "Other" (these will eventually become "Vendors" in a separate section/ticket).

Attached are some quick mockups for initial layout ideas.

*Related:* SM-3188

**Specifications:**

*UI Mockup Requirements:*
- The section is titled "Accounts".
- Display rows for the following relationship types, in this order:
  1. Owner
  2. Manager
  3. Licensee
  4. Other
- Each row shows:
  - Relationship label
  - Account name (and existing affordances, e.g., link to account details, if that exists today)

**Not in Scope:**
- Implementation/development of the new Accounts section — this ticket is for design deliverable only.
- A separate "Vendors" section for non-role accounts — that will be a follow-up ticket after account cleanup is complete.
- Editing or assigning relationship roles from the Asset dashboard — this is read-only display.
- Backend data model changes for the Owner/Manager/Licensee relationships.

**Acceptance Criteria:**
- [ ] Given the design is delivered, when reviewed, then it clearly labels each linked account by Owner / Manager / Licensee / Other.
- [ ] Given the design is delivered, when reviewed, then it preserves the ability to display all currently linked accounts (no functional regression), with non-role accounts shown as "Other".
- [ ] Given the design is delivered, when reviewed, then the relationship types are displayed in the specified order: Owner → Manager → Licensee → Other.
- [ ] Given the design is delivered, when reviewed, then each row shows the relationship label and account name with existing affordances (e.g., link to account details).

> 💡 **Why this works:**
> - **Design tickets use the same 6-section format** — the deliverable is a mockup, not code, but the structure still applies. Specifications describe what the mockup must show; ACs define what "done" looks like for a design review.
> - **Context explains the "why" and the constraint** — the 3 role types are defined with cardinality (1 per Asset), and the "Other" bucket is explicitly framed as interim until account cleanup. This prevents the designer from over-investing in the "Other" UX.
> - **Near-term constraint is called out separately** — "do not break existing behavior" + "continue to show all linked accounts" is a guardrail that keeps the design backward-compatible. Critical for any redesign of existing UI.
> - **Not in Scope was missing — generated to separate design from dev.** Without it, there's ambiguity about whether this ticket includes implementation. Explicitly stating "design deliverable only" and excluding backend changes makes the 3-point estimate make sense.
> - **Ordered list in Specifications** — the 1→2→3→4 display order is a specific design requirement, not a suggestion. Capturing it in Specifications ensures the designer doesn't make arbitrary layout choices.
> - **Lightest well-structured ticket** — at 3 points for a design task, this shows the format works for non-engineering deliverables too. The sections are proportionally shorter but all present.

---

### ✅ Example 6: Full-Stack Story (DB + API + UI) — SM-3188

<!-- Source: SM-3188 | Type: Story | Project: SightMap | Points: 8 -->
<!-- Reporter: William Fagan | Assignee: Narayan Magar | Priority: Medium -->
<!-- Related: SM-3210 (design), PDR-113 -->

**Title:** Add the ability to assign owner accounts to assets in Atlas & the SM API

**User Story:** As an Atlas user, I want to see which Account owns an Asset, so I can clearly understand property ownership today and support future relationship-based logic.

**Context:**
We need to associate an Asset to an Account in three distinct ways so Atlas users (and future logic) can understand the relationship:

- **Owner:** Account that owns the physical property (1 per Asset)
- **Manager:** Account that manages the property (1 per Asset) *(separate ticket)*
- **Licensee:** Account that pays for the SightMap license (1 per Asset) *(separate ticket)*

This ticket introduces the Owner relationship only, and focuses on read + display.

*Related:* SM-3210 (design mockup), PDR-113

**Specifications:**

*Overview*
- Add an explicit, nullable owner reference on assets so Atlas can represent ownership unambiguously.
- Non-breaking migration: existing assets remain valid (owner defaults to null until backfilled).
- Conventions: use `account_owner_id` at the DB level; expose `account_owner_id` in the API; tag owner account at the UI level.

*Data (DB)*
- Add nullable column: `assets.account_owner_id`.
- Ensure migration is safe and deployable without backfill.

*API*
- `GET View an asset`: include `account_owner_id` in the response payload.
- `PUT Update an asset`: include `account_owner_id` in the request payload.
- Assets Report: include a new field sourced from the same column and named consistently with the API.

*UI (Atlas)*
- Asset Dashboard: display an "Owner" tag next to the correct Account name for the asset.
- Null state: show no "Owner" tag.

**Not in Scope:**
- Manager and Licensee relationships — each will be a separate ticket following the same pattern.
- Backfilling `account_owner_id` for existing assets — migration sets the column to null; backfill is a follow-up.
- Editing owner from the Asset Dashboard UI — this ticket covers display only; assignment is done via the API's `PUT Update an asset`.
- Validation rules or business logic enforcing that an owner must be set.

**Acceptance Criteria:**
- [ ] Given the migration has run, when inspecting the database, then `assets.account_owner_id` exists as a nullable column.
- [ ] Given an asset with an `account_owner_id` set, when calling `GET View an asset`, then the response payload includes `account_owner_id`.
- [ ] Given a valid account ID, when calling `PUT Update an asset` with `account_owner_id`, then the owner is saved and persisted.
- [ ] Given the Assets Report is generated, when reviewing the output, then a new field for `account_owner_id` is included and named consistently with the API.
- [ ] Given an asset with an owner set, when viewing the Asset Dashboard in Atlas, then an "Owner" tag is displayed next to the correct Account name.
- [ ] Given an asset without an owner set, when viewing the Asset Dashboard in Atlas, then no "Owner" tag is displayed.
- [ ] Given the above scenarios, when tested, then both "asset with owner" and "asset without owner" cases pass.

> 💡 **Why this works:**
> - **Organized by layer** — Data (DB) → API → UI is a natural top-down structure for full-stack work. Each developer (backend, frontend) can find their section instantly. This is the ideal pattern for vertically-sliced stories.
> - **Naming conventions are specified upfront** — "`account_owner_id` at the DB level; expose `account_owner_id` in the API; tag owner account at the UI level" eliminates naming inconsistency across layers before it starts.
> - **Non-breaking migration is explicit** — "existing assets remain valid (owner defaults to null until backfilled)" is a critical safety requirement. Calling it out in Overview means it won't be missed during code review.
> - **Context scopes to one of three roles** — listing all 3 relationship types but marking Manager and Licensee as "(separate ticket)" shows the developer the bigger picture while keeping this ticket focused. The AI should learn to do this when breaking epics into stories.
> - **Not in Scope was missing — generated from implicit boundaries.** The ticket mentions "read + display" but didn't explicitly exclude editing, backfill, or validation. Making these explicit prevents scope creep during development.
> - **ACs mirror the layer structure** — DB → API GET → API PUT → Report → UI (with owner) → UI (without owner) → Test coverage. This makes the ticket walkable as a checklist during development and review.
> - **Pairs with SM-3210** — this implementation story references the design ticket (SM-3210) we added as Example 5. Together they show how design → implementation ticket pairs should cross-reference each other.

---

## Epic Examples

### ✅ Example 1: Feature Epic

<!-- Paste a real or adapted epic. Same 6 sections. -->
<!-- Specifications should include story breakdown, goals, success metrics, risks. -->

```
[Paste epic here]
```

> 💡 **Why this works:**
> - [Annotate]

---

## Bug Examples

### ✅ Example 1: UI/Frontend Bug

<!-- A bug in SightMap embed, Atlas, or another client. -->
<!-- Specifications should include: steps to reproduce, expected vs actual, screenshots/logs. -->

```
[Paste bug here]
```

> 💡 **Why this works:**
> - [Annotate]

---

### ✅ Example 2: Data/API Bug — SM-3207

<!-- Source: SM-3207 | Type: Bug | Project: SightMap | Points: 1 -->
<!-- Reporter: Nathan Mojica | Assignee: Narayan Magar | Priority: High -->
<!-- Related: PDR-177 -->

**Title:** Expenses API: 'Per Installment' frequency maps to wrong calculator group

**User Story:** As a SightMap API consumer creating expenses with a 'Per Installment' frequency, I want the expense to be correctly mapped to the 'Monthly' calculator group so that student housing expenses display in the correct category on the SightMap Calculator front end.

**Context:**
Months ago we added a new frequency option for 'Per Installment'. 'Per Installment' is the student housing equivalent to 'Monthly' in multifamily. So we decided to map any 'Per Installment' expenses to display in the 'Monthly' box on the SM Calculator front end.

However, currently this only works if the expense is created from Atlas. If the expense is created from the API, then it maps to the incorrect category ('Other' instead of 'Monthly').

*Related:* PDR-177

**Specifications:**

*Steps to Reproduce:*
1. Create one expense from the API with a frequency of 'Per Installment'.
2. Create an identical expense for the same asset from Atlas with a frequency of 'Per Installment'.
3. The one created from Atlas will have 'Monthly' in its `Classification Expense Calculator` field, and the one created from the API will have 'Other' in its `Classification Expense Calculator` field.

*Additional Observations:*
- In Atlas, if you change the frequency for the API-created expense, and then change it back to 'Per Installment', then the `Classification Expense Calculator` field switches to 'Monthly'.
- So the only bug is that the `Classification Expense Calculator` field is getting incorrectly set for expenses with a frequency of 'Per Installment' that are created from the API.

*Expected Behavior:*
- `Classification Expense Calculator` = 'Monthly' — regardless of whether the expense is created via Atlas or the API.

*Actual Behavior:*
- Atlas-created: `Classification Expense Calculator` = 'Monthly' ✅
- API-created: `Classification Expense Calculator` = 'Other' ❌

**Not in Scope:**
- Changing how any other frequency values map to calculator groups.
- Retroactively fixing existing API-created expenses that already have the wrong mapping — a data backfill can be a separate ticket if needed.
- Changes to the Atlas expense creation flow (it already works correctly).

**Acceptance Criteria:**
- [ ] Given an expense is created via the SightMap REST API with a frequency of 'Per Installment', when the expense is saved, then the `Classification Expense Calculator` field is set to 'Monthly'.
- [ ] Given an expense created via the API with 'Per Installment' frequency, when viewed in Atlas, then it displays in the 'Monthly' calculator group — matching the behavior of Atlas-created expenses.
- [ ] Given an expense created via the API with 'Per Installment' frequency, when displayed on the SightMap Calculator front end, then it appears in the 'Monthly' box.

> 💡 **Why this works:**
> - **Title was improved** — the original title was a full sentence describing the symptom. Reformatted to `[Component]: [Brief description]` per our bug title convention, while preserving the original meaning.
> - **Repro steps are comparative** — "create one from API, create one from Atlas, compare" is a powerful debugging pattern. It isolates the variable (creation source) and makes the bug instantly reproducible.
> - **Expected vs Actual is explicit** — the side-by-side with ✅/❌ makes the defect crystal clear in seconds. Every bug ticket should have this.
> - **Context explains the design decision** — knowing that 'Per Installment' was intentionally mapped to 'Monthly' for student housing tells the developer this is a mapping bug, not a feature request. It also prevents someone from "fixing" it the wrong way.
> - **"Additional Observations" narrows the root cause** — the fact that toggling the frequency in Atlas fixes the API-created expense tells the developer the bug is in the API creation path, not the mapping logic itself. This saves significant debugging time.
> - **Not in Scope prevents over-engineering** — explicitly excluding retroactive data backfill and other frequency mappings keeps this as a clean 1-point fix.
> - **Small ticket, full structure** — even at 1 point, the 6-section format works. The sections are just shorter. This proves the format scales down as well as up (compare to the 13-point SM-3111).

---

### ✅ Example 3: Cross-Service Permissions Bug — SM-3200

<!-- Source: SM-3200 | Type: Bug | Project: SightMap | Points: 5 -->
<!-- Reporter: William Fagan | Assignee: Ryan Hein | Priority: High -->
<!-- Related: PDR-179, SM-2141 -->

**Title:** SightMap API: Asset assignment does not propagate to UnitMap API permissions

**User Story:** As an API consumer assigning assets to an account via the SightMap API, I want those assets to be immediately available through UnitMap API endpoints so that my workflows don't break due to stale permissions between the two APIs.

**Context:**
When an API consumer assigns Assets to an Account using the SightMap API, the assignment does not propagate to the UnitMap API. As a result, UnitMap requests do not include the newly assigned Assets.

- Occurs specifically when Assets are added through the SightMap API and not via Atlas UI.

However, if an Atlas user navigates to the API Consumer page and toggles the Account's access, the UnitMap API immediately returns the expected Asset data. This strongly suggests a stale permission/asset-assignment cache or a missing sync/invalidation step when assignment happens via the SightMap API.

- The Atlas toggle appears to force a refresh/sync that makes UnitMap data consistent.

This leads us to believe that this is related to a previous bug (SM-2141).

*Impact:*
- Breaks workflows that rely on immediate consistency between SightMap assignment and UnitMap reads like floor plan automations.
- Creates support burden ("it works only after we toggle access in Atlas").

*Related:* PDR-179, SM-2141

**Specifications:**

*Steps to Reproduce:*
1. Create an API consumer.
2. Add an account to the API consumer.
3. Add an asset to that account through the SightMap API call: `PUT Assign Assets`.
4. Make a UnitMap API call (ex: `GET List References`) using the API consumer from step 1.
5. The API response is missing data from the asset added in step 3.
6. Observe: the UnitMap response does not include the Asset assigned in step 3.
7. In Atlas → API consumer page: click Disallow Assets, then Allow Assets for the same Account.
8. Repeat step 4.
9. Observe: the UnitMap response now includes the Asset from step 3.

*Expected Behavior:*
- After `PUT Assign Assets` in SightMap API, UnitMap endpoints return the newly assigned Assets without requiring Atlas UI toggling.

*Actual Behavior:*
- SightMap API: Asset assignment succeeds ✅
- UnitMap API: Newly assigned asset does not appear ❌
- Atlas toggle workaround: Asset appears after toggling Disallow/Allow ⚠️

*Suspected Root Cause:*
One of the following is likely happening when assignment occurs via SightMap API:
- Cache invalidation is not triggered for UnitMap's view of allowed assets / account-asset relationships.
- A sync/event is missing (Atlas toggle may emit an event or rebuild permissions; SightMap API path may not).
- Permissions materialization (or denormalized mapping table) is updated only by the Atlas toggle path.

**Not in Scope:**
- Changes to the Atlas UI toggle flow (it already works correctly and serves as the reference behavior).
- Broader refactoring of the permissions/cache layer between SightMap and UnitMap APIs — this fix should target the specific missing sync/invalidation step.
- Retroactively fixing any assets that are currently in a broken state — a one-time data reconciliation can be a separate ticket if needed.

**Acceptance Criteria:**
- [ ] Given an API consumer with an account, when assets are assigned via `PUT Assign Assets` in the SightMap API, then those assets are immediately available in UnitMap API responses (e.g., `GET List References`) without any Atlas UI interaction.
- [ ] Given assets are assigned via the SightMap API, when the same assets are queried via UnitMap API endpoints, then the behavior is consistent with assets assigned via Atlas UI.
- [ ] Given the fix is deployed, when tested across environments, then the behavior is consistent and repeatable across repeated calls.

> 💡 **Why this works:**
> - **Title was improved** — reformatted from a full sentence to `[Component]: [symptom]` convention. "SightMap API: Asset assignment does not propagate to UnitMap API permissions" is scannable in a Jira board.
> - **The workaround IS the diagnosis** — the Atlas toggle workaround (steps 7-9) is the most valuable detail in the ticket. It tells the developer exactly where to look: whatever Atlas toggle does (event, cache rebuild, permissions materialization), the SightMap API path needs to do the same thing.
> - **Suspected Root Cause is included** — listing 3 possible causes (cache invalidation, missing event, denormalized table) gives the developer a prioritized investigation path. Not all bug tickets need this, but for 5-point cross-service bugs it saves significant discovery time.
> - **Impact is quantified** — "Breaks workflows" and "Creates support burden" with specific examples justifies the High priority and helps stakeholders understand urgency.
> - **Cross-references previous bug** — linking SM-2141 gives the developer historical context and possibly a similar fix pattern to follow.
> - **Not in Scope protects against over-engineering** — explicitly stating this should target the specific missing sync step (not a broader permissions refactor) keeps a 5-point bug from becoming a 13-point epic.

---

## ❌ Anti-Patterns

### Bad Example 1: Vague Acceptance Criteria

```
❌ AC: "Map should work correctly"
✅ AC: "Given an asset with 3 buildings, when the user loads the SightMap embed, then all 3 buildings render with correct floor counts within 2 seconds"
```

**Why it fails:** [Explain]

---

### Bad Example 2: Missing Context

```
❌ "Add RealPage support"
✅ [Show what the full ticket should look like — all 6 sections filled in]
```

**Why it fails:** [Explain]

---

### Bad Example 3: Wrong Terminology

```
❌ "Update the property page to show apartment pricing"
✅ "Display unit-level pricing on the Asset detail view in Atlas"
```

**Why it fails:** [Wrong terms make tickets unsearchable and confusing across teams]

---

### Bad Example 4: Empty Not in Scope

```
❌ Not in Scope: N/A
✅ Not in Scope:
   - Migrating existing RealPage assets to the new feed format — separate epic
   - Updating the public API response schema — blocked until v3 planning
```

**Why it fails:** [Explain — every ticket has boundaries; stating them prevents mid-sprint surprises]

---

## Conventions Reference

<!-- Extract and document implicit rules as you add examples -->

| Convention | Value |
|---|---|
| Ticket sections (all types) | Title → User Story → Context → Specifications → Not in Scope → Acceptance Criteria |
| Story point scale | [e.g., Fibonacci: 1, 2, 3, 5, 8, 13] |
| Sprint length | [e.g., 2 weeks] |
| Default labels | [e.g., `sightmap`, `atlas`, `integration`, `tech-debt`] |
| AC format | Given/When/Then |
| Typical story size | [e.g., "If it's bigger than 8 points, break it down"] |
| Bug severity usage | [When to use Critical vs High vs Medium vs Low] |
| Jira project key(s) | [e.g., SM, ATLAS] |
| Link conventions | [How you reference Figma, Notion, other tickets] |

---

*Last updated: February 2026*
*Add real tickets as they're written. The more examples, the better the AI output.*
