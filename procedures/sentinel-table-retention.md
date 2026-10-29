# Sentinel Table Retention Workbook — Walkthrough

**Tool type:** Workbook · **Source:** [GitHub — mathijsvermaat/Sentinel-Table-Retention-Workbook](https://github.com/mathijsvermaat/Sentinel-Table-Retention-Workbook) · **Documented version:** 1.1

Use this workbook to review table settings, forecast Data Lake storage costs, apply explicitly approved total-retention increases to one or many tables, and verify the results. It runs through native Azure Workbooks functionality using your portal identity, without a helper service or separate script.

The workbook builds on the original workbook covered by [Retention Insights](retention-insights.md). Keep both available: Retention Insights covers broader archive, data-plan, and search/restore scenarios; this workbook provides a focused **Tables, Costs, and Verify** workflow for Data Lake-integrated workspaces. It does not replace those other capabilities.

---

## Contents

- [When to Use This Tool](#when-to-use-this-tool)
- [Prerequisites](#prerequisites)
- [Step 1 — Import the Workbook](#step-1--import-the-workbook)
- [Step 2 — Set the Workspace and Retention Target](#step-2--set-the-workspace-and-retention-target)
- [Step 3 — Review Tables and Eligibility](#step-3--review-tables-and-eligibility)
- [Step 4 — Forecast Lake Storage Costs](#step-4--forecast-lake-storage-costs)
- [Step 5 — Review and Confirm Each Batch](#step-5--review-and-confirm-each-batch)
- [Step 6 — Verify Every Expected Table](#step-6--verify-every-expected-table)
- [Interpret the Results](#interpret-the-results)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)
- [Accuracy and Limitations](#accuracy-and-limitations)
- [Related Tools](#related-tools)
- [Further Reading](#further-reading)

---

## When to Use This Tool

Use the workbook when you need to:

- Apply an approved total-retention target to several eligible tables without editing each table separately.
- Compare the estimated monthly Lake storage impact of targets such as 180, 270, or 365 days.
- Review retention after connector onboarding or during a periodic policy review.
- Verify current table settings and investigate supporting Azure Activity Log events after a change.

Define the requirement first using the [Retention guidance](../guidance/retention.md). The workbook does not choose a retention policy, assess regulatory compliance, or continuously enforce a desired state. The model's 365-day baseline is a planning recommendation, not a universal legal requirement.

Use other tooling for Analytics-retention changes, tier changes, retention reductions, or search/restore operations. The workbook only prepares increases to **total retention**, based on the selected settings snapshot.

## Prerequisites

| Requirement | Details |
|:------------|:--------|
| **Workspace** | A Microsoft Sentinel Data Lake-integrated Log Analytics workspace connected to the Defender portal. The workbook does not enable integration. |
| **Table settings access** | Azure RBAC permissions to read table settings and, for updates, configure them. See [Microsoft's table settings permissions](https://learn.microsoft.com/en-us/azure/sentinel/manage-table-tiers-retention). Defender portal access alone does not grant permission to execute the workbook's ARM actions. |
| **Workspace queries** | Query access for the selection, preview, and review queries. |
| **Cost forecasts** | Read access to the workspace's `Usage` table and a representative observation window. Missing volume produces no estimate, not a zero cost. |
| **Activity history** | Activity Log read access. This is separate from permission to read or update tables. |
| **Storage rate** | Your regional or contracted Lake storage rate per billed GB-month, in the selected currency. |
| **Approved scope** | Table names, the retention purpose, the intended target, and approval for the potential cost increase. |

> [!WARNING]
> Confirming an update changes Azure resource settings and can increase storage costs. Start with a small, noncritical selection and verify it before proceeding more broadly. No deployment-write permission or helper identity is needed for the retention update itself.

## Step 1 — Import the Workbook

1. Download [SentinelDataLakeRetention.json](https://github.com/mathijsvermaat/Sentinel-Table-Retention-Workbook/blob/main/SentinelDataLakeRetention.json) using **Raw** or **Download raw file** on GitHub.
2. In Microsoft Defender, open **Microsoft Sentinel > Threat management > Workbooks** and add a workbook. Azure Monitor Workbooks is also supported.
3. Select **Edit > Advanced editor** and replace the definition with the downloaded JSON.
4. Select **Apply**, then **Done Editing**.
5. Select the subscription and workspace, confirm the table inventory loads, and save a copy in your environment.

Importing or saving the workbook does not apply retention changes. Updates require a separate review and explicit confirmation.

> [!NOTE]
> When upgrading an existing copy, reimport the JSON, close any old confirmation pane, and reselect the tables. Select **Detailed guidance > Show** to inspect the workbook's version information and additional help.

## Step 2 — Set the Workspace and Retention Target

| Setting | What to enter |
|:--------|:--------------|
| **Subscription / Workspace** | The single workspace whose tables you intend to manage. |
| **Target total retention (days)** | The approved target. Default: **365**. Input accepts **30–4,383 whole days**, subject to table-specific service restrictions. |
| **Detailed guidance** | Select **Show** for explanations, calculation assumptions, and version information. |

**Total retention includes Analytics retention.** With 90 days of Analytics retention and 365 days total, the additional period beyond Analytics is 275 days, not 365 days. Extending total retention on a mirrored Analytics table is not a switch to Lake-only storage.

The workbook does not alter Analytics retention or the table plan. Check those separately against the approved policy.

> [!IMPORTANT]
> The target is shared across the workbook views. Cost scenarios can change it. Restore the approved target before preparing changes or comparing verification results.

## Step 3 — Review Tables and Eligibility

1. Open **Tables** and refresh the inventory.
2. Search for the intended tables and select their rows.
3. Review the exact table names, Analytics retention, total retention, plan, subtype, inheritance, and provisioning state.
4. Review the decisions and **Selection readiness** summary before preparing a change.

| Decision | Meaning and action |
|:---------|:-------------------|
| **INCREASE** | The table is eligible and its current total retention is below the target. Review the proposed value. |
| **SKIPPED** | No increase is needed or the table is unsupported. Read the reason; tables already at or above the target are left alone. |
| **BLOCKED** | Invalid input, missing metadata, or stale/conflicting selected rows prevent preparation. Resolve the reason, refresh, and reselect. |

The write workflow excludes search-result and restored tables, unsupported plans, and tables not in a succeeded provisioning state. It operates on tables available through the selected workspace's Tables API; XDR-only tables outside that workspace are not listed.

> [!WARNING]
> Search filters the display; it does not clear earlier selections. Check the names in the preview, not just the visible search results. The **Costs** and **Verify** views have independent selections.

## Step 4 — Forecast Lake Storage Costs

1. Open **Costs** and select the tables to forecast; the Tables selection is not copied automatically.
2. Choose **7, 30, or 90 full UTC days** as the volume observation window. The default is 30.
3. Choose **USD** or **EUR** and enter the matching storage rate per billed GB-month. Use a dot decimal, such as `0.03`.
4. Compare the current, forecast, and additional monthly storage estimates for the intended target.
5. Inspect all excluded tables and coverage notes before treating the summary as a budget estimate.

| Result | Interpretation |
|:-------|:---------------|
| **Est. current Lake spend** | Modelled monthly storage at the current settings, not actual invoiced spend. |
| **Forecast Lake spend** | Modelled monthly storage at the proposed settings. |
| **Monthly difference** | Forecast minus estimated current spend. |
| **PARTIAL SUBTOTAL** | Only tables with valid estimates are included. Review **Estimated** and **Without estimate** counts and each excluded row's reason. |
| **NO ESTIMATE** | Inputs or volume coverage are insufficient. Blank monetary values must not be interpreted as free storage. |

The calculation uses observed volume, not measured physical Lake occupancy:

```text
Observed GB = sum(Usage.Quantity in MBytes) / 1000
Average GB/day = observed GB / full UTC observation days
Proposed total retention = max(current total retention, target)
Paid Lake days = max(total retention - applicable Analytics allowance, 0)
Monthly Lake storage estimate = average GB/day x paid Lake days / 6 x storage rate
```

For mirrored Analytics tables, the allowance is their Analytics retention. For Lake-only tables, it is zero. The divisor six is the uniform storage billing compression factor documented in [Microsoft Sentinel pricing and billing](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers). Enter the rate per **billed** GB-month; do not divide the rate by six again.

Example: 60 GB observed over 30 days, 90 days Analytics retention, and an illustrative rate of **EUR 0.03 per billed GB-month**:

| Target total retention | Paid Lake days | Estimated monthly Lake storage |
|:-----------------------|:---------------|:-------------------------------|
| 180 days | 90 | EUR 0.90 |
| 270 days | 180 | EUR 1.80 |
| 365 days | 275 | EUR 2.75 |

> [!NOTE]
> These are steady-state storage estimates, not the next invoice or the complete Sentinel bill. Data accumulates gradually. Ingestion, processing, queries, Analytics storage, tax, and changes to discounts are excluded. Currency selection changes the denomination only; it performs no exchange-rate conversion. Cost planning never applies changes.

## Step 5 — Review and Confirm Each Batch

1. Return to **Tables** and restore the approved target if cost modelling changed it.
2. Refresh the inventory, reselect the intended tables, and recheck readiness.
3. Select a prepared-change row, then **Review retention change**.
4. Check the workspace, exact table names, target, batch number, and request body.
5. Confirm only that reviewed batch, then proceed to read-back before further changes.

Each prepared row contains up to **20 tables**. A selection of 45 eligible tables produces batches of 20, 20, and 5, each requiring confirmation. Up to **800 selected tables** can be prepared at once; later batches are not silently omitted.

Every selection uses `POST /batch?api-version=2020-06-01`. Each inner request is a table `PATCH` using API version `2026-03-01`, containing only:

```json
{
  "properties": {
    "totalRetentionInDays": 365
  }
}
```

Schema, subtype, table plan, and Analytics-retention fields are not submitted.

> [!WARNING]
> An open confirmation pane is a snapshot, not a lock or live preview. Close it and review a newly prepared change if the workspace, selection, or target changes. Avoid concurrent administration: increase-only eligibility is evaluated against the snapshot, so a stale request can overwrite a newer retention setting. Batches are not atomic; there is no automatic retry or rollback.

## Step 6 — Verify Every Expected Table

1. Refresh **Read back this change** after the action completes, before refreshing the inventory.
2. Confirm that every expected table is present and total retention matches the reviewed target.
3. Check that provisioning state is **Succeeded** and Analytics retention, plan, and subtype remain unchanged. Review inheritance against the intended explicit total-retention override.
4. Refresh the same tables in Defender and confirm the settings there.
5. Use **Verify** for a separately selected set of tables and supporting recent Azure Activity Log events. Restore the intended target if a cost scenario changed it.
6. Investigate missing rows or failures. Refresh the inventory and reselect only tables still needing an increase before preparing another batch.

> [!IMPORTANT]
> An outer HTTP 200 response can contain individual failures. The workbook does not display the action's per-request write responses as an execution report. Read-back is a fresh GET: an empty or partial result is not success, and a matching current value does not prove which request caused it.

The activity view defaults to seven days, with 1-, 7-, 30-, and 90-day options. It shows the recorded operation, status, initiator, available error details, and correlation ID. Events may take 3–20 minutes to appear.

**View event JSON** opens the returned record; redact identity and network details before sharing it. **Open Azure Activity Log** opens the workspace's history, not an event-specific link. Use the event time and correlation ID to find the original record. Azure may omit old/new retention values, and a table-write event can concern properties other than retention.

## Interpret the Results

A completed retention change requires read-back for all expected tables, successful provisioning, and agreement with the approved settings. Record the reviewed table list, target, date, and any exceptions with the assessment or change record.

Installing the workbook is not evidence that a retention policy has been applied. Configuring 365 days today also does not prove that 365 days of historical data are available. Longer retention cannot restore deleted data or backfill data from before Lake onboarding.

## Common Scenarios

| Scenario | Approach |
|:---------|:---------|
| **New connector tables need the agreed baseline** | Confirm which tables belong to the connector, review current settings, forecast storage, then extend eligible tables and verify. |
| **Selected investigation evidence needs longer retention** | Group tables by approved target and run separate selections for different policies; do not apply a blanket extension. |
| **Quarterly policy review** | Compare current table settings with documented targets, including exceptions. Use other tooling for any required reductions or tier changes. |
| **Some tables in a batch did not change** | Investigate read-back and activity, refresh, and retry only the remaining eligible tables after resolving the cause. |
| **Archive, plan, or search/restore analysis is required** | Use [Retention Insights](retention-insights.md) for its broader workflow, checking applicability to the workspace's current storage and billing model. |

## Troubleshooting

| Symptom | Action |
|:--------|:-------|
| No workspace or table inventory | Check the selected subscription and signed-in identity's access. Reimport the current workbook if necessary. |
| No prepared change | Review readiness and per-table decisions. Tables may already meet the target or be ineligible; refresh and reselect. |
| Wrong or unexpected tables in the preview | Search does not clear selection. Clear/reselect and check every table name before confirmation. |
| No estimate or a partial subtotal | Check query permissions, `Usage` coverage, units, observation window, and the positive dot-decimal storage rate. Inspect excluded rows. |
| No recent activity | Check the lookback and Activity Log permissions, and allow for event arrival delay. Current table settings and activity have independent read permissions. |
| History continuation warning | Only the first returned API page is displayed. Shorten the lookback or inspect Azure Activity Log for the remaining history. |
| Missing or mismatched read-back rows | Do not mark the change complete. Investigate missing tables, read failures, provisioning state, and possible concurrent changes. |

## Accuracy and Limitations

- One workspace is managed at a time; the workbook is not a cross-workspace policy engine.
- Table-specific service restrictions still apply even when the target passes input validation.
- Estimates assume the observed daily average continues, using every day in the observation window, not only active days. Partial or stale activity is flagged; Lake-only volume coverage may be incomplete.
- Missing volume is unknown, not zero stored data. A partial subtotal excludes unestimated tables and is not the full selection's cost.
- Current settings and Activity Log are complementary evidence, not an immutable before/after transaction record or proof of historical data availability.
- Workbook defaults do not replace risk, privacy, legal, or budget approval. Review the [Retention guidance](../guidance/retention.md) and [Budget and Cost Planning](../guidance/budget-and-cost-planning.md) before extending retention.

## Related Tools

| Tool | Complementary purpose |
|:-----|:----------------------|
| [Retention Insights](retention-insights.md) | The original broader archive, data-plan, search/restore, and cost-analysis workflow. |
| [Workspace Usage Report](workspace-usage-report.md) | Review ingestion volumes, free-source benefits, and workspace usage alongside the Lake-storage forecast. |

## Further Reading

- [Beyond One Table at a Time: Managing Microsoft Sentinel Data Lake Retention with a Workbook](https://www.linkedin.com/pulse/beyond-one-table-time-managing-microsoft-sentinel-data-vermaat-gqgue/) — background, retention terminology, worked cost example, and the reasoning behind the review-and-verify workflow.
- [Workbook repository](https://github.com/mathijsvermaat/Sentinel-Table-Retention-Workbook) — current JSON, version information, operational guidance, and technical details.

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)