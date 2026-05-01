---
name: salesforce-analytics
description: >
  Analyze Salesforce support tickets for actionable product insights. Queries the
  Salesforce Cases API (READ-ONLY) and produces a structured report with theme
  clustering, sub-type analysis, repeat offenders, churn risk flags, and specific
  action recommendations. GET-only — no POST, PUT, PATCH, or DELETE calls are ever made.
version: 1.3.0
requires:
  env:
    - SALESFORCE_USERNAME
    - SALESFORCE_CONSUMER_KEY
    - SALESFORCE_CONSUMER_SECRET
    - SALESFORCE_SECURITY_TOKEN
  bins:
    - python3
---

# Salesforce Analytics Skill

You analyze Engrain's Salesforce support tickets to surface product insights.

## ⚠️ CRITICAL SAFETY RULE

**This skill is READ-ONLY.** You must NEVER:
- Create, update, or delete any Salesforce record
- Use POST, PUT, PATCH, or DELETE HTTP methods against Salesforce
- Modify any Case, Contact, Account, or any other Salesforce object
- Execute anonymous Apex or DML operations

You ONLY use:
- `GET` requests to the Salesforce REST API
- `SOQL SELECT` queries via `/services/data/vXX.0/query?q=SELECT...`

If any operation would modify data, **refuse and explain why.**

---

## Process

### Step 1: Ask for Time Window and Product Filter

Ask the user which period they want to analyze:
- **Last week** (7 days)
- **Last month** (30 days)
- **Last quarter** (90 days)
- **Last year** (365 days)

Then ask which product to filter by:
- **All** (no filter — show everything)
- **SightMap**
- **UnitMap**
- **TouchTour**
- **SPACES**
- **Asset Intelligence**

If the user already specified either when invoking the skill, skip that question.

#### Product Filter Logic

After fetching all tickets, filter to only tickets that mention the selected product
in the Subject OR Description (case-insensitive). Use these keyword patterns:

| Product | Keywords to match (subject OR description) |
|---------|---------------------------------------------|
| All | No filtering — include every ticket |
| SightMap | sightmap, sight map, sight-map, sm, engrain map |
| UnitMap | unitmap, unit map, unit-map |
| TouchTour | touchtour, touch tour, touch-tour, tt, kiosk, ipad |
| SPACES | spaces, coworking, co-working, flex space |
| Asset Intelligence | asset intelligence, asset iq, power bi, analytics dashboard |

**Important:** When a product filter is active:
- Apply the filter BEFORE classification into decision buckets
- Adjust the header to show: `PM DECISION BRIEF — [Product] — Last [period] ([N] tickets)`
- If very few tickets match (<20), note this and suggest broadening to "All"
- Cancellation analysis should still flag the filtered product specifically

### Step 2: Authenticate with Salesforce

Run the authentication script to get an access token:

```bash
source ~/.config/engrain/salesforce.env
python3 ~/.copilot/skills/salesforce-analytics/sf_query.py auth
```

This uses the OAuth2 Username-Password flow (read-only connected app).

### Step 3: Query Support Tickets

Use the query script to pull Cases from the selected time window:

```bash
python3 ~/.copilot/skills/salesforce-analytics/sf_query.py query \
  --days <N> \
  --fields "Id,Subject,Description,Status,Priority,CreatedDate,CaseNumber,Account.Name,ContactEmail,Type,Reason"
```

The script handles pagination automatically (Salesforce limits to 2000 records per
query). It outputs JSON to stdout.

### Step 4: Analyze — PM Decision Framework

Do NOT just cluster tickets by topic. Classify every ticket by **what PM decision
it informs**. The goal is to answer: "What should we build, fix, investigate, or
escalate based on this data?"

#### Decision Buckets

Classify every ticket into exactly ONE of these buckets (first match wins):

| Bucket | What it means | Keywords (subject + description) |
|--------|---------------|----------------------------------|
| **Feed Reliability** | Product is broken for the client RIGHT NOW | feed suspend, feed error, feed fail, suspended |
| **Preventable Churn** | Client leaving — potentially saveable | cancel, cancellation, deactivat (but NOT "sold", "sale", "change of management") |
| **Organic Churn** | Client leaving — not our fault | cancel + (sold, sale, change of management, new management) |
| **Data Accuracy** | Wrong info on a LIVE client page | wrong, incorrect, inaccurate, mismatch, not matching, showing wrong |
| **Self-Serve Gap** | Client asked support to do something they should be able to do themselves | (update, change, add, remove, edit) AND (price, pricing, rent, unit, floor plan, color, brand, logo, photo, image) |
| **Onboarding Friction** | New client/asset stuck in pipeline | onboard, new asset, new property, setup, activation, go live, go-live, kickoff |
| **Operational Noise** | Everything else (routine work, questions, spam) | (default bucket) |

#### For Each Bucket, Extract:

**Feed Reliability:**
- Unresolved count and % (status = Intake, Pending, or Client Responded)
- Repeat offenders: assets with 2+ tickets in the window (parse asset name from "Feed suspended for [name]")
- Unique accounts affected
- PMS systems mentioned (RealPage, Yardi, Entrata, ResMan, AppFolio, MRI, Rent Manager)

**Preventable Churn:**
- Products being cancelled (SightMap, TouchTour, Asset IQ/Intelligence, Parking & Rentable Items, UnitMap)
- Accounts with 3+ cancellations (these are relationship risks)
- If one product is being cancelled by multiple unrelated accounts, flag as product-market signal

**Data Accuracy:**
- Count unique accounts affected
- Include 3-5 example subjects with account names
- This is HIGHER priority than self-serve gap (wrong live data = lost leases)

**Self-Serve Gap:**
- Break down by sub-type: Pricing updates, Unit changes, Map/floor plan edits, Photo/media, Branding
- Identify top 5 accounts by volume (these are your beta candidates)
- Calculate cost: tickets × 15 min avg handle time = agent-hours/week and annualized

**Onboarding Friction:**
- Stuck count (Pending, Intake, Client Responded)
- % that completed (Solved) vs. stuck
- Account concentration (is one account dominating the pipeline?)

**Queue Health (always include):**
- Resolution rate: Solved / total
- Untriaged: Intake / total
- Pending: Pending / total
- Daily volume: total / days in window

#### Feature Requests

In addition to the decision buckets, separately extract **feature requests** — tickets
where clients explicitly ask for new capabilities that don't exist today.

**Detection:** Match tickets containing language like:
- "would like", "want to", "wish", "can we", "could we", "is it possible"
- "ability to", "option to", "feature", "requesting", "request to add"
- "love to have", "any way to", "new feature", "enhancement"
- Also check if the Type or Reason field = "Feature Request" or "Enhancement"

**Exclude** tickets that match cancellation, feed error, or other operational buckets
(these are problems, not requests for new capability).

**Cluster by theme:**

| Theme | Keywords |
|-------|----------|
| Self-service portal/editor | portal, editor, self-serve, log in, dashboard, manage, make changes myself |
| Virtual tours/3D/video | virtual tour, 3d, video, matterport, tour link |
| Unit finishes/amenities detail | finish, amenity, detail, upgrade, feature unit |
| Pricing display enhancements | price, pricing, rent, specials, concession |
| Custom branding/styling | brand, color, style, theme, logo, custom |
| Photo/media management | photo, image, gallery, picture, upload image |
| Map interactivity | click, hover, popup, tooltip, interactive, zoom |
| API/integration | api, integrate, connect, sync, webhook |
| Filtering/search | filter, search, sort |
| Reporting/analytics | report, analytic, data, insight, metric |

For each theme, provide:
- Count of requests
- 1-2 example ticket subjects with account names
- If 3+ accounts request the same theme, flag as validated demand signal

---

### Step 5: Present as PM Decision Brief

Output using this exact structure. The report has three parts:
1. **5 Key Takeaways** — the biggest signals from the data, ranked by impact
2. **Feature Requests** — what clients are explicitly asking for
3. **5 Decisions** — actionable next steps this data supports

**Selecting the 5 Takeaways:** After classifying all tickets into decision buckets,
rank the buckets by which ones carry the most actionable signal. Pick the top 5 most
impactful findings. These rules guide selection:

- **Always include** Self-Serve Gap, Feed Reliability, and Churn if they have meaningful volume (>5% of tickets)
- **Combine** Data Accuracy + Onboarding into a single takeaway if either is small (<3% of volume)
- **Always include** Queue Health as a takeaway if resolution rate is below 50% or untriaged is above 20%
- **Always include** an account-concentration takeaway if any single account appears in 3+ buckets (e.g., Greystar shows up in churn + feed + self-serve = retention emergency)
- If all buckets are small, merge the smallest two and elevate the most surprising finding

Each takeaway should have a bold headline that states the insight (not just the category name).

```
══════════════════════════════════════════════════════════════════════
  PM DECISION BRIEF — [Product] — Last [period] ([N] tickets)
══════════════════════════════════════════════════════════════════════

━━━ TAKEAWAY 1: [Bold insight headline]
    [N] tickets ([pct]%) — [one-line description of what this means]

    [Relevant data for this bucket — use the same extraction rules
     from the bucket definitions above. Include sub-breakdowns,
     top accounts, repeat offenders, cost calculations, etc.]

    Impact: [Quantified consequence of inaction]

━━━ TAKEAWAY 2: [Bold insight headline]
    [N] tickets ([pct]%) — [one-line description]

    [Relevant data]

    Impact: [Quantified consequence]

━━━ TAKEAWAY 3: [Bold insight headline]
    [N] tickets — [one-line description]

    [Relevant data]

    [Flag product-market signals for churn, concentration risks, etc.]

━━━ TAKEAWAY 4: [Bold insight headline — can be account-specific]
    [Cross-bucket analysis for a single account if applicable]

    [Total tickets from this account, broken down by bucket]

    [Why this matters: revenue risk, relationship status]

━━━ TAKEAWAY 5: [Bold insight headline]
    [Relevant data — often Queue Health or a merged smaller bucket]

    [Key metrics: resolution rate, untriaged %, daily volume]

━━━ FEATURE REQUESTS: [N] tickets with explicit asks for new capability

    [Theme]: [N] requests
      → [Example ticket subject] — [Account]
      → [Example ticket subject] — [Account]

    [Theme]: [N] requests
      → [Example ticket subject] — [Account]
      → [Example ticket subject] — [Account]

    [Repeat for each theme with 1+ tickets. Order by count descending.
     Flag themes requested by 3+ unrelated accounts as validated demand.]

══════════════════════════════════════════════════════════════════════
  DECISIONS THIS DATA SUPPORTS
══════════════════════════════════════════════════════════════════════

  1. BUILD [what]
     Evidence: [specific numbers from above]
     ROI: [quantified impact]
     Start with: [most impactful sub-item]

  2. FIX [what]
     Evidence: [specific numbers]
     ROI: [what it protects]
     Specifically: [what to investigate]

  3. INVESTIGATE [what]
     Evidence: [pattern observed]
     Question: [the open question]
     Next step: [concrete action]

  4. ESCALATE [to whom, about what]
     [Account (count)] — [why it's urgent]

  5. MONITOR [what metric]
     [Current state] — [what to watch for]
```

**Rules for the Takeaways:**
- Each takeaway headline must state the insight, not just the category (e.g., "Feed Pipeline Is Broken — 84% Unresolved" not "Feed Reliability")
- Takeaways are ordered by impact, not by bucket order
- If an account appears across 3+ buckets, it gets its own takeaway (retention emergency)
- Every takeaway includes an "Impact" line quantifying the consequence of inaction

**Rules for the Feature Requests section:**
- Only include genuine asks for new capability — not bug reports or operational requests
- Cluster by theme using the theme table from Step 4
- Include 1-2 real ticket subjects with account names per theme
- Flag themes with 3+ requesting accounts as "validated demand"
- Order themes by request count descending

**Rules for the Decisions section:**
- Every decision must start with a verb: BUILD, FIX, INVESTIGATE, ESCALATE, or MONITOR
- Every decision must include Evidence (numbers), ROI or Impact, and a Next Step
- Order by urgency: revenue-protecting actions first, cost-saving second, monitoring last
- Name specific accounts, products, and metrics — never be vague
- If a product is being cancelled by 3+ unrelated accounts, always flag it as INVESTIGATE
- Feature request data can inform BUILD decisions (e.g., "25 requests for virtual tours" strengthens the case)

---

## Field Reference

Standard Salesforce Case fields to query:

| Field | Description |
|-------|-------------|
| Subject | Ticket title/summary |
| Description | Full ticket body |
| Status | Open, Closed, etc. |
| Priority | High, Medium, Low |
| Type | Question, Problem, Feature Request, etc. |
| Reason | More specific categorization |
| CreatedDate | When the ticket was created |
| Account.Name | Client company name |
| CaseNumber | Unique ticket identifier |

> **Note:** The exact fields available may differ. If a field returns an error,
> remove it from the query and note what's unavailable.

---

## Configuration

Credentials are stored at: `~/.config/engrain/salesforce.env`

This file is NEVER committed to any repository.

---

## Output Guidelines

- Frame everything around **decisions**, not topics. Not "here are your themes" but "here's what you should BUILD, FIX, INVESTIGATE, ESCALATE, or MONITOR"
- Present exactly **5 key takeaways** ranked by impact, not by bucket order
- Each takeaway headline must state the insight (e.g., "Feed Pipeline Is Broken — 84% Unresolved"), not just the category name
- If a single account spans 3+ buckets, dedicate a takeaway to that account as a retention emergency
- Include a dedicated **Feature Requests** section after the 5 takeaways, clustered by theme with real examples
- Include ticket counts, percentages, and specific account names throughout
- Quote 1-2 real ticket subjects as evidence where useful
- Calculate cost of inaction: agent-hours for self-serve gap, stale pages for feed issues, revenue risk for churn
- Identify concentration risk if one account dominates a category (>30%)
- If a product is being cancelled by 3+ unrelated accounts, always flag as product-market signal
- Name the responsible team for each action: Eng, CS, Product, or Ops
- Never say "Other/Uncategorized" — tickets that don't fit a decision bucket go in Operational Noise and get minimal coverage
- End with exactly **5 numbered decisions** using action verbs (BUILD, FIX, INVESTIGATE, ESCALATE, MONITOR)
- Feature request themes with 3+ requesting accounts should inform BUILD decisions
