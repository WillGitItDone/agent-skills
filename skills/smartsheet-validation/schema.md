# Smartsheet Fee Schema — Valid Values and Format Constraints

> Sourced from `Fee_Validation.py`.
>
> **Important:** These rules are for **self-evaluation of your own recommendations
> only**. Never use them to independently judge whether a customer's data is valid
> or invalid — that is exclusively determined by the output of `Fee_Validation.py`.
> Use this file to ensure that any value you suggest to a customer would itself pass
> validation.

---

## Value Type (Required)

| Value | When to use |
|-------|-------------|
| `amount` | Fee has a flat dollar amount |
| `range` | Fee varies between a numeric min and max dollar amount |
| `text` | Fee amount is described in plain text (e.g., "Varies", "$500–one month's rent") |
| `percentage` | Fee is a percentage of another value (e.g., rent) |
| `stepped` | Fee varies by step/tier (stepped amounts required) |

---

## Frequency (Required)

| Value |
|-------|
| `one_time` |
| `hourly` |
| `daily` |
| `weekly` |
| `monthly` |
| `quarterly` |
| `annually` |
| `per_lease` |
| `per_occurrence` |
| `per_installment` |

---

## Due At Timing (Required)

Only applies to fees with `Frequency = one_time`.

| Value |
|-------|
| `application` |
| `move_in` |
| `move_out` |

---

## Expense Type (Required)

> **Do not list the full Expense Type enum in customer emails** — it's too long
> and overwhelming. Instead, use context from the row (fee label, frequency,
> expense category) to narrow it down to 2–4 plausible options and offer those.

| Category | Valid Values |
|----------|-------------|
| Access | `access_device`, `access_device_replacement`, `lock_change` |
| Admin / Leasing | `admin`, `application`, `holding`, `move_in`, `move_out`, `screening`, `subletting`, `transfer` |
| Contracting | `contracting_other` |
| Deposits | `deposit` |
| Insurance | `insurance_other`, `renters_insurance` |
| Inspections / Legal | `inspection`, `legal_fees`, `legal_other` |
| Penalties | `insufficient_funds`, `late_payment`, `penalties_other`, `violation` |
| Community / Amenity | `amenity`, `cleaning`, `community_other`, `maintenance`, `packages` |
| Utilities | `bundled_utilities`, `cable`, `electricity`, `gas`, `internet`, `pest_control`, `trash`, `utilities_admin`, `utilities_other`, `water` |
| Pets (Cat) | `pet_deposit_cat`, `pet_rent_cat`, `other_cat` |
| Pets (Dog) | `pet_deposit_dog`, `pet_rent_dog`, `other_dog` |
| Pets (Other) | `pet_deposit_other`, `pet_rent_other`, `pets_other` |
| Parking | `assigned_parking`, `ev_parking`, `motorcycle_parking`, `parking_other`, `private_garage`, `unassigned_parking` |
| Spaces / Storage | `bicycle_storage`, `clubhouse`, `guest_suite`, `spaces_other`, `storage_other`, `storage_unit` |
| Government | `government` |

---

## Format Constraints

> Use these to self-check your recommendations before suggesting them to customers.

### Numeric Amount Fields

Applies to: **Amount (Required)**, **Min Amount (Required)**, **Max Amount (Required)**,
**Percentage Amount (Required)**, **Value Cap**, **Stepped Amount** columns.

- Must be a plain number matching `^-?\d+(\.\d{1,2})?$`
  - ✅ `35`, `35.5`, `35.50`, `-10`
  - ❌ `$35`, `35/applicant`, `35.505`, `varies`, `one month's rent`
- At most 2 decimal places
- No dollar signs, no text, no slashes, no descriptors

### Numeric Range Rules

| Rule | Details |
|------|---------|
| Percentage Amount | Maximum value: 1000 |
| Limit | Maximum value: 100; must be a plain number (not text like "Max 2 Pets") |
| Value Cap | Must be > 0 |
| Max Amount | Must be ≥ Min Amount |
| Amount / Stepped Amounts | Must be ≤ Value Cap (if Value Cap is set) |

### String Length Limits

| Field | Max characters |
|-------|---------------|
| Label (Required) | 50 |
| Text Amount (Required) | 150 |
| Tooltip Label | 255 |
| Disclaimer | 255 |

### Boolean Fields

Applies to: **Is Required**, **Is Enabled (Required)**, **Is Included**, **Is Refundable**,
**Is Taxable**, **Is Third Party**, **Is Prorated**.

- Must be `True` or `False`
- **Is Prorated = True** is only valid when **Frequency = `monthly`**

### Conditional Field Requirements

| Field | Condition |
|-------|-----------|
| Due At Timing (Required) | Only required (and only valid) when Frequency = `one_time` |
