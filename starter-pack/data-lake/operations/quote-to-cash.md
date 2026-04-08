---
title: Quote-to-Cash Operations
labels: [operations, billing, revops, salesforce, netsuite, process]
owner: Revenue Operations
updated: 2026-03-10
notion_link: https://notion.so/Engrain-Revenue-Cloud-RCA-Operations-Hub-28e3924d726780ffb4dedf9f7fd39c6d
---

# Quote-to-Cash Operations

> How Engrain's revenue flows from sale to cash collection — Salesforce RCA → Continuous → NetSuite.

## Overview

Engrain replaced a dual-system model ("two brains" where Salesforce and NetSuite each thought they owned pricing) with a unified Quote-to-Cash pipeline. **Salesforce** is the single source of truth for *what was sold*. **NetSuite** is the single source of truth for *how much money was collected*. **Continuous** bridges them automatically.

## System Architecture

| Functional Area | System of Record | Primary Activity |
|----------------|-----------------|------------------|
| **Subscription Management** | Salesforce RCA | Quotes, Renewals, Amendments (Cancel/Replace), Product Catalog |
| **Financials** | NetSuite | Invoicing, AR, Revenue Recognition (ASC 606), General Ledger |
| **Data Synchronization** | Continuous | Converts SF Orders → NS Sales Orders + Revenue Arrangements |

## The Pipeline

### 1. The Setup (Salesforce RCA)

Everything begins with a **Quote** in Salesforce, built by Sales or Customer Success.

- **Automated pricing** — system applies correct price based on Property attributes (e.g., unit count) and Start Date. No manual proration calculations.
- **Approvals** — discounts or non-standard terms lock the Quote and alert management before it can be sent.
- **Signature** — contracts sent via DocuSign directly from Salesforce. Customer signature triggers Closed Won + job started + invoiced automatically.

### 2. The Bridge (Continuous)

Continuous runs in the background — no one logs into it directly.

- **Handshake** — picks up the SF Order, validates Customer and Products exist, translates data into finance language (GL accounts, billing rules).
- **Error gating** — if data is missing (e.g., bad zip code), sync stops and alerts the Admin dashboard. Bad data never reaches accounting.

### 3. The Money (NetSuite)

NetSuite acts as the financial engine, receiving clean data from Continuous.

- **Invoicing** — auto-generates Sales Orders. A nightly scheduler (Autoloader) creates Invoices based on billing rules from Salesforce.
- **Revenue Recognition** — creates Revenue Arrangements immediately for ASC 606 compliance. Revenue recognized over subscription life (e.g., monthly for 12 months) or at the right time for one-time fees, hardware, installation, or CS products.

### 4. The Lifecycle (Back to Salesforce)

The critical shift in the new model:

- **Asset Generation** — when a deal closes, Salesforce auto-creates **Assets** on the customer account representing the active subscription.
- **Renewals & Changes** — all managed from the Asset in Salesforce via "Cancel/Replace" or "Renewal" actions. History lives with the customer record.

## Role Guidance

| Role | Primary System | Key Rule |
|------|---------------|----------|
| Sales / Account Management | Salesforce | If it isn't in Salesforce, it doesn't exist. Check Invoice Balance field in SF instead of emailing Finance. |
| Finance | NetSuite | Focus on collecting cash and managing revenue schedules. Don't fix orders manually. |

## Critical Rules

1. **Strict click sequences** — Revenue Cloud requires precise workflow adherence. The sequence of clicks is critical for data to flow correctly.
2. **No "two brains"** — pricing and proration live exclusively in Salesforce. Never manually alter prorations in NetSuite.
3. **Amendments = Cancel/Replace** — never "edit" active subscriptions mid-term. Execute Cancel/Replace from the Asset record in Salesforce.
4. **Property-level integrity** — every Quote Line maps 1:1 to a Property. Property attributes drive pricing tiers and must be accurate before quoting.

## Documentation Map

Key sub-topics documented in Notion (not yet distilled into Data Lake):

| Topic | Domain | Status |
|-------|--------|--------|
| Quote creation & configuration | operations | 🔲 Pending |
| Quote approvals | operations | 🔲 Pending |
| Renewals process | operations | 🔲 Pending |
| Cancellations & transfers | operations | 🔲 Pending |
| DocuSign integration | operations | 🔲 Pending |
| Continuous sync logic & troubleshooting | technical | 🔲 Pending |
| NetSuite ARM (revenue recognition) | operations | 🔲 Pending |
| Invoice splitting | operations | 🔲 Pending |
| Tax exemption management | operations | 🔲 Pending |
| Pricing protocol | reference | 🔲 Pending |
| Defect reporting | operations | 🔲 Pending |

## Related

- [[products/]] — SightMap product documentation
- [[integrations/]] — PMS integration context (distinct from revenue integrations)
- [[reference/]] — Pricing details (when distilled)

---

*Last updated: 2026-03-10 | Owner: Revenue Operations*
