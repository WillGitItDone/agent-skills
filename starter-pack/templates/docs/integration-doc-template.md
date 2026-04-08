# [PMS Name] Integration Documentation

<!--
  METADATA — Fill in all fields. Keep this block at the top of every integration doc.
  Status values: Draft 📝 | In Progress 🙌 | In Review 👀 | Completed 🏁
  Audience values: Internal, External, or Both
-->

| Field            | Value                          |
|------------------|--------------------------------|
| **Status**       | Draft 📝                       |
| **Owner**        | [Name]                         |
| **Audience**     | Internal                       |
| **Market**       | Multifamily / Senior Living / Self-Storage / Build-to-Rent |
| **Category**     | Integration Setup Guide        |
| **Last Updated** | YYYY-MM-DD                     |

---

## Quick Reference

<!--
  A scannable summary for experienced team members. Should answer:
  "What do I need and what are the steps, at a glance?"
  Keep this to ~10 bullet points max.
-->

1. **Required credentials:** [list them]
2. **Feed naming:** `[Asset Name] - [PMS Name] [Process Type] [Infrastructure]`
3. **Pricing strategy:** Flat / Revenue Management / Both
4. **Process type:** Standard Poll / Custom Push / Custom-Scheduled Push
5. **Poll frequency:** Hourly / Daily / Custom
6. **Key steps:**
   1. Request credentials from [PMS] team
   2. Test credentials in Postman
   3. Create ATLAS feed
   4. Match units (Provider IDs)
   5. Create backend task (if custom)
   6. Verify feed + configure Online Leasing

---

## 1. Overview

<!--
  2-3 paragraphs max. Cover:
  - What the PMS is and who uses it
  - What our integration does (pricing, availability, status, content)
  - Any important historical context (mergers, deprecated options, etc.)
-->

[PMS Name] is a property management system that primarily supports **[market segment]** properties. Our integration synchronizes **[pricing / availability / status / content]** data between [PMS Name] and Engrain's SightMap products.

> **📊 Engrain [PMS Name] Stats** (as of MM/YYYY)
>
> - Total assets leveraging [PMS Name]: X (~X% of total)
> - Total [PMS Name] feeds: X (~X% of total)

> **⚠️ Important Notes**
>
> - [Any deprecated options, known limitations, or critical callouts]

---

## 2. Credentials & Access

### Customer-Facing Guide

<!--
  Every integration should have a corresponding external guide that the customer
  follows to grant Engrain access. This guide is the customer-side counterpart
  to Step 1 below — the customer follows their guide, and Engrain receives the
  credentials needed to begin setup.

  External guides follow a standard structure: Intro → Steps → Get Help
  They are maintained as versioned .docx files and should never contain internal
  jargon (ATLAS, feeds, Provider IDs, etc.).

  If no external guide exists for this PMS, flag it here and create one.
-->

| Item                           | Value                                          |
|--------------------------------|------------------------------------------------|
| **External Guide**             | [File name or "⚠️ Needs to be created"]        |
| **Guide Version**              | [e.g., v2.0]                                   |
| **Included in Omnibus Guide?** | Yes / No                                       |

### Required Credentials

<!--
  Table format for scanability. Include every credential needed.
-->

| Credential       | Description                              | Source                    |
|------------------|------------------------------------------|---------------------------|
| [Credential 1]   | [What it is and format]                  | [Where to get it]         |
| [Credential 2]   | [What it is and format]                  | [Where to get it]         |

> **🔒 Credential Storage**
>
> Credentials are stored in `[file path or system]` within the `[repository]` repo.

### Email Template for Requesting Credentials

<!--
  Use this exact table format. Customize items in [brackets].
  Always CC dataintegrations@engrain.com.
  If the customer is expected to self-serve (e.g., AppFolio Stack Marketplace),
  replace this section with those instructions instead.
-->

| Field       | Value |
|-------------|-------|
| **To**      | [PMS integration team email] |
| **Cc**      | dataintegrations@engrain.com |
| **Subject** | [Client Name] - [Property Name] [PMS Name] / Engrain Integration |
| **Body**    | Hey Team,<br><br>Our mutual client, [Client Name], is interested in setting up an integration between our systems for [Property Name]. Are you able to provide the following so we can get started?<br><br>[List required credentials]<br><br>Thank you, |

---

## 3. Integration Details

### General Details

| Setting                         | Value / Standard                        |
|---------------------------------|-----------------------------------------|
| **Process Type**                | Standard Poll / Custom Push / Custom-Scheduled Push |
| **Pricing Strategy**            | Flat Pricing / Revenue Management / Both |
| **Feed Naming Convention**      | `[Asset Name] - [PMS Name] [details]`  |
| **Poll Frequency**              | [Engrain standard for this PMS]         |
| **Days Out / Days Back**        | [Value] — [Engrain Standard]            |
| **Execution Failures Allowed**  | [Value] — [Engrain Standard]            |
| **No Availability Handling**    | [Post with no availability / other]     |
| **Run Schedule (if push)**      | [Time local] / [Time UTC]               |

### Data Flow

<!--
  Describe the integration pipeline: how data moves from PMS → Engrain.
  Use a numbered list showing: Import → Process → Push.
  Include code snippets if they help clarify the data shape.
-->

1. **Import (Loader):** [How the integration pulls data from the PMS API]
2. **Process (Reader):** [How data is filtered, matched, and transformed]
3. **Push (Writer):** [What data is written to ATLAS and in what shape]

<!--
  Optional: include the data structure being pushed
-->

```
Example data structure pushed to ATLAS:
{
  "id": "unit_id",
  "unit_number": "101",
  "rent_matrix": [
    { "price": 1500, "available_on": "2026-04-01", "lease_term": null }
  ]
}
```

---

## 4. Data Logic

### Status Assignment

<!--
  Map PMS data conditions to the SightMap status displayed on the map.
  This table is CRITICAL for troubleshooting and should always be complete.
-->

| SightMap Status | PMS Condition (Simplified)             | Data Fields Used                |
|-----------------|----------------------------------------|---------------------------------|
| **Available**   | [condition]                            | [fields]                        |
| **Reserved**    | [condition]                            | [fields]                        |
| **On Hold**     | [condition]                            | [fields]                        |
| **Sold**        | [condition]                            | [fields]                        |

> **💡 Special Rules**
>
> - [Document any special business logic, e.g., "Couple Rule" for senior living]
> - [Document how unavailable units are handled, e.g., price <$1 = unavailable]

### Pricing Logic

<!--
  How is the displayed price derived? Which field(s) are used?
  Does the integration support amenity pricing add-ons?
-->

- **Price source field:** [field name from PMS API]
- **Amenity pricing:** Supported / Not supported
- **Revenue management:** Supported / Not supported
  - [If supported, describe how lease terms and move-in dates are handled]

### Configuration Flags

<!--
  Only include this section if the integration has configurable behavior.
  Table format matching the Sherpa pattern.
-->

| Flag                  | Type    | Default | Description                                           |
|-----------------------|---------|---------|-------------------------------------------------------|
| [flag_name]           | boolean | false   | [What it does and when to enable it]                  |

---

## 5. Setup Process

<!--
  Numbered steps. Each step should be self-contained and actionable.
  Avoid person-specific references — use role names (e.g., "ATLAS Data Team", "Backend Team").
-->

### Step 1: Request & Test Credentials

1. Send the email template from Section 2 to the [PMS Name] integrations team.
2. Once credentials are received, test in Postman using the [PMS Name] collection.
3. Verify data is returned for the target property.

### Step 2: Create the ATLAS Feed

1. Navigate to the ATLAS Asset.
2. Create a new feed using the naming convention: `[Asset Name] - [PMS Name] [details]`.
3. Configure feed settings per the table in Section 3.
4. Enter the required credentials.

### Step 3: Match Units (Provider IDs)

1. Export the unit schedule from ATLAS.
2. [Describe how to extract unit IDs from the PMS — API call, CSV export, etc.]
3. Match PMS unit IDs to ATLAS unit IDs using VLOOKUP or equivalent.
4. Set Provider IDs in ATLAS (or prepare CSV for backend team).

### Step 4: Backend Task (Custom Integrations Only)

<!--
  Only include this step if the integration requires backend dev work.
  For standard ATLAS integrations, skip this step.
-->

1. Create a Jira ticket assigned to the Backend Team with:
   - Link to the relevant Bitbucket model/config file
   - Config snippet (from Section 3 / configuration flags)
   - Unit mapping CSV (provider_id ↔ unit_id)
2. Notify the Senior Traffic Manager.

### Step 5: Verify & Finalize

1. Confirm the feed is receiving data in ATLAS.
2. Verify no unmatched units (or document expected unmatched units).
3. Verify Provider IDs are correct.
4. [If applicable] Configure Online Leasing (see Section 6).
5. Refresh pricing filters.

---

## 6. Online Leasing (OLL)

<!--
  If this PMS supports Online Leasing, document the setup.
  If not, state why (e.g., "Senior Living properties handle applications through
  specialized processes rather than automated online leasing flows").
-->

### OLL Configuration

| Setting                          | Value                                |
|----------------------------------|--------------------------------------|
| **Pricing Strategy**             | [Match feed]                         |
| **Days Out**                     | [90, or as requested]                |
| **Default Lease Term**           | [Value, or blank for best-price]     |
| **Apply Label**                  | Apply                                |
| **Show Days Out From Avail Date**| ✅                                   |
| **Open in New Browser Window**   | ✅                                   |
| **Show Move-In Date Calendar**   | ✅                                   |

### OLL URL Template

```
[BASE_URL]?param1={{leasing_fields.unit_id}}&param2={{move_in_date|date("m/d/Y")}}
```

> **🔗 Example:** [Link to a working example in ATLAS, if available]

---

## 7. Content Automations

<!--
  Does this PMS support any of Engrain's content automations?
  (Floor plan images, unit amenities, etc.)
  If none, state: "There are currently no supported automations for [PMS Name]."
-->

| Automation          | Supported | Notes                                     |
|---------------------|-----------|-------------------------------------------|
| Floor Plan Images   | Yes / No  | [details]                                 |
| Unit Amenities      | Yes / No  | [details]                                 |

---

## 8. Tools & Troubleshooting

### API Endpoints Used

| Endpoint / URL                         | Purpose                                      |
|----------------------------------------|----------------------------------------------|
| [endpoint name or URL]                 | [What we use this endpoint for]              |

### Common Errors

<!--
  Write errors in plain language. Include the fix.
  If there's a templated email for the error, include it.
-->

| Error / Symptom                       | Cause                          | Fix                                       |
|---------------------------------------|--------------------------------|-------------------------------------------|
| [Error description]                   | [Root cause]                   | [How to resolve]                          |

### Engrain Tools & Scripts

- [List any internal scripts, smctl commands, or tools that help with this integration]

### PMS Support Contact

| Contact               | Details                                   |
|-----------------------|-------------------------------------------|
| **Support Email**     | [email]                                   |
| **Alternate Contact** | [name, email]                             |
| **Support Portal**    | [URL, if applicable]                      |

---

## 9. FAQs

<!--
  Rules for maintaining this section:
  1. Check that your question isn't already answered (even if worded differently).
  2. Use the Q:/A: format below — copy an existing entry to preserve formatting.
  3. Reach out to the doc owner to get questions added if you don't have edit access.
-->

- **Q:** [Question]

  **A:** [Answer]

---

## Revision History

| Version | Date       | Summary           | Author       | Approved By  |
|---------|------------|--------------------|--------------|--------------|
| 1.0     | YYYY-MM-DD | Initial creation.  | [Name]       | [Name]       |
