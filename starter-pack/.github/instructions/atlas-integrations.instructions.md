---
applyTo: "repos/atlas-integrations/**"
last_verified: 2026-04-30
staleness_warning_days: 90
---

# Atlas Integrations Instructions

**Always read this before working on `atlas-integrations`.**

## Repo Overview

- **Purpose**: Kubernetes CronJobs for non-standard PMS integrations
- **Default branch**: `main`
- **Deploy mechanism**: Push to `deploy/*` branch triggers Bitbucket pipeline
- **Structure**: `containers/` (Docker images) + `deployments/` (K8s configs per client)
- **Reviewers**: Bryan and Kam must be tagged on every PR
  - Bryan Spitler: `{f509f98c-973e-4c21-9798-420534e316c3}`
  - Kam Deno: `{7598051c-f841-4e4c-ba40-46e68b460dee}`

## PR & Review Workflow

1. **The engineer writes container/deployment code** and pushes to a `deploy/*` branch.
2. **Rebase before opening the PR** — this repo has many contributors and drifts
   fast. Always run `git fetch origin main && git rebase origin/main` and
   force-push before creating the PR. Never open a PR that is behind `main`.
3. **Create a PR** targeting `main`, tagging **Bryan and Kam** as reviewers.
4. **For new integrations**, send an email to Bryan and Kam with:
   - Documentation for the integration
   - Link to the PR
   - Any next steps needed (e.g., outbound link setup)
5. **Deploy branches run the pipeline** (push to K8s), but do **not** update `main`.
   A merged PR is required to keep `main` in sync.

## Pipeline Behavior

The pipeline (`bitbucket-pipelines.yml`) runs two steps on `deploy/*` branches:

1. **`deploy-containers`** — Diffs `containers/` against `origin/main`. Rebuilds only changed containers.
2. **`deploy-configurations`** — Diffs `deployments/` against `origin/main`. Deploys only changed configs.

### Critical: Never merge the PR before the pipeline succeeds

The pipeline detects changes by diffing the deploy branch against `origin/main`.
If you merge the PR to `main` before the pipeline runs (or while it's running),
the diff will show **no changes** — because `main` already contains the commit.
The `deploy-containers` and `deploy-configurations` steps will skip with
"No changes to deploy", and nothing gets built or deployed.

**Order of operations:**
1. Push to `deploy/*` branch
2. Wait for the pipeline to **succeed** (container built + deployed)
3. Verify the change is working (check cron job logs, etc.)
4. **Then** merge the PR to keep `main` in sync

If you accidentally merge first, create a new deploy branch with a trivial
change (e.g., trailing newline) to the affected file to trigger the pipeline.

### Critical: Do not set `close_source_branch` on PRs before pipeline succeeds

When creating PRs via the Bitbucket API with `"close_source_branch": true`, the
source branch is deleted immediately on merge. If the pipeline hasn't run yet (or
needs to be rerun), the deleted branch causes the pipeline to fail with
"Remote branch not found". Omit `close_source_branch` or set it to `false` until
the pipeline has succeeded, then merge with branch deletion.

### Spotting a skipped deploy

If `deploy-containers` completes in ~1 second, it means **nothing was built** —
the diff detected no changes. A real Docker build + push takes significantly longer.
This is a sign the PR was merged before the pipeline ran.

### Critical: Always branch from `main`

When creating a new deployment that uses an **existing container image**, branch from `main` — not from another deploy branch. If you branch from another deploy branch, the pipeline will see inherited container files as "changed" and try to rebuild them, which can fail if the base image tag has been cleaned up.

**Wrong:**
```bash
git checkout -b deploy/new-client origin/deploy/other-client  # inherits container diffs
```

**Right:**
```bash
git checkout main && git pull origin main
git checkout -b deploy/new-client  # only deployment files will diff
```

## Deployment Structure

Each deployment follows this structure:

```
deployments/<client>/<integration_type>/
├── .env                  # API keys and secrets (K8s secret)
├── config/
│   └── assets.csv        # Asset configuration (K8s configmap)
├── cron-job.yaml         # K8s CronJob spec
├── deploy.sh             # Deployment script (must be executable)
└── docker-compose.yml    # Local testing
```

### Naming Convention

- **Directory**: `deployments/<client>/<integration_type>/` (snake_case)
- **K8s resource name**: `<client>-<integration-type>` (kebab-case)
- **Example**: `deployments/equity/eliseai_expenses/` → K8s name `equity-eliseai-expenses`

## Container Images

Container images are at `docker.engrain.io/atlas-integrations/<path>`.
Each container Dockerfile uses a base smctl image: `FROM docker.engrain.io/library/smctl:build-<number>`.

### smctl Build Numbers

Build numbers correspond to **Bitbucket pipeline runs** in the `app-smctl` repo,
not Git tags or releases. A build can come from `main` or a **feature branch**.

When updating a container to a specific build number:
1. **Verify the source branch** — check the app-smctl pipeline to confirm whether
   the build was from `main` or a feature branch. Use the Bitbucket API:
   ```bash
   curl -s -u "$BITBUCKET_USERNAME:$BITBUCKET_API_TOKEN" \
     "https://api.bitbucket.org/2.0/repositories/engrain/app-smctl/pipelines/?sort=-created_on&pagelen=5" \
     | jq '.values[] | {build_number, branch: .target.ref_name, commit: .target.commit.hash[0:8]}'
   ```
2. **Feature branch builds are valid** — the Docker image contains the compiled
   binary regardless of branch. But note that the smctl code isn't on `main` yet,
   so a future rebuild from `main` could regress.
3. **Follow up** — if using a feature branch build, ensure there's a PR to merge
   that branch into `main` in app-smctl.

### Standard (shared) containers

Located at `containers/std/`. Reused across clients:

| Container | Image Path | smctl Command |
|-----------|-----------|---------------|
| EliseAI Pricing | `std/eliseai/pricing` | `smctl eliseai import pricing` |
| Entrata Affordable Units | `std/entrata/affordable_units` | `smctl entrata import affordable-units` |
| Entrata Floor Plans | `std/entrata/floor_plans` | `smctl entrata import floor-plans` |
| Entrata Student Pricing | `std/entrata/student_pricing` | `smctl entrata import student-pricing` |
| Entrata Student Pricing (UAT) | `std/entrata/student_pricing_uat` | `smctl entrata import student-pricing` |
| Entrata Unit Amenities | `std/entrata/unit_amenities` | `smctl entrata import unit-amenities` |
| Let It Rain Pricing | `std/letitrain/pricing` | `smctl letitrain import pricing` |
| Matterport Virtual Tours | `std/matterport/virtual_tours` | `smctl matterport import virtual-tours` |
| MRI Pricing | `std/mri/pricing` | `smctl mri import pricing` |
| OneSite Floor Plans | `std/onesite/floor_plans` | `smctl onesite import floor-plans` |
| OneSite v2 Floor Plans | `std/onesite_v2/floor_plans` | `smctl onesite import floor-plans` |
| OneSite v2 Floor Plans (UAT) | `std/onesite_v2/floor_plans_uat` | `smctl onesite import floor-plans` |
| RentCafe Floor Plans | `std/rentcafe/floor_plans` | `smctl rentcafe import floor-plans` |
| RentCafe Unit Amenities | `std/rentcafe/unit_amenities` | `smctl rentcafe import unit-amenities` |
| RentCafe v2 Floor Plans | `std/rentcafe_v2/floor_plans` | `smctl rentcafe import floor-plans` |
| RentCafe v2 Floor Plans + Images (UAT) | `std/rentcafe_v2/floor_plans_unit_images_uat` | `smctl rentcafe import floor-plans` |
| RentCafe v2 Unit Amenities | `std/rentcafe_v2/unit_amenities` | `smctl rentcafe import unit-amenities` |
| Rent Manager Pricing | `std/rentmanager/pricing` | `smctl rentmanager import pricing` |
| SiteLink Pricing | `std/sitelink/pricing` | `smctl sitelink import pricing` |

### Client-specific containers

Located at `containers/<client>/`. Custom logic for one client:

| Container | Image Path |
|-----------|-----------|
| AMLI Pricing | `amli/pricing` |
| AppFolio Pricing | `appfolio/pricing` |
| AvalonBay Floor Plans | `avalonbay/floor_plans` |
| Bozzuto Floor Plans | `bozzuto/floor_plans` |
| Carlyle Mass Elemental | `carlyle/mass_elemental` |
| Cortland Pricing | `cortland/pricing` |
| Cortland Rentable Items | `cortland/rentable_items` |
| Equity Asset Intelligence | `equity/asset_intelligence` |
| Essex Floor Plans | `essex/floor_plans` |
| Greystar Expenses | `greystar/expenses` |
| Greystar Expenses BlueMoon | `greystar/expenses_bluemoon` |
| Greystar Expenses Colorado | `greystar/expenses_colorado` |
| Greystar Expenses (UAT) | `greystar/expenses_uat` |
| Greystar Pricing Disclaimers | `greystar/pricing_disclaimers` |
| Invitation Homes All-In Pricing | `invitationhomes/all_in_pricing` |
| Jonah Pricing | `jonah/pricing` |
| Merge Pricing | `merge_pricing` |
| Spectrum Pricing | `spectrum/pricing` |
| StoryPoint Pricing | `storypoint/pricing` |

## Creating a New Deployment

1. Branch from `main` (see above)
2. Create the deployment directory structure
3. Populate `.env` with API keys
4. Populate `config/assets.csv` with the correct columns for the container type
5. Adapt `cron-job.yaml` — update name, storage path, secret/configmap refs
6. Adapt `deploy.sh` — update `name` variable
7. Adapt `docker-compose.yml` — update image path
8. `chmod +x deploy.sh`
9. Fetch + rebase onto `origin/main` before pushing
10. Push to `deploy/<client>-<integration-type>` branch
11. Create PR targeting `main`, tag **Bryan and Kam** as reviewers
12. For new integrations, email Bryan and Kam with docs + PR link

## Code Style

- **Variable passing**: Always use the standard `--flag="$var"` pattern for
  passing smctl flags. Do **not** use conditional expansion (`${var:+--flag="$var"}`)
  even for optional flags — smctl commands treat empty strings as falsy
  (e.g., `if (!argv.outboundLinkId) { return; }`), so `--flag=""` safely
  no-ops. This matches how all other containers (Matterport, Entrata, etc.)
  pass flags and keeps the codebase consistent.
- **Config CSV column order**: IDs on the left (near property ID), `asset_name`
  always last. Example: `asset_id, pricing_process_id, eliseai_property_id, ..., manage_url, asset_name`

## smctl Flags: What's Pricing-Only

- **`--received-from`** sets the `X-Received-From` header on SightMap API
  requests. It is defined and used **exclusively in pricing commands**
  (sitelink, eliseai, appfolio, mri, entrata, cortland, amli, spectrum,
  letitrain, merge-pricing). Do **not** add it to non-pricing containers
  (floor plans, expenses, virtual tours, unit amenities) — those commands
  don't accept or forward it.

## CSV Columns by Integration Type

| Integration | Required Columns |
|-------------|-----------------|
| EliseAI Pricing | `asset_id`, `pricing_process_id`, `eliseai_property_id`, `on_notice_availability`, `manage_url`, `asset_name` |
| EliseAI Expenses | `asset_id`, `eliseai_property_id`, `manage_url`, `asset_name` |
