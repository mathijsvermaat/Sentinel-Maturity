# Retention Insights — Walkthrough

**Tool type:** Workbook · **Source:** Azure Sentinel Github ([ArchivingBasicLogsRetention.json](https://github.com/Azure/Azure-Sentinel/blob/master/Workbooks/ArchivingBasicLogsRetention.json)) · **Template origin:** `sentinel-ArchivingBasicLogsRetention` (Sentinel Content Hub)

This guide walks you through using the Retention Insights workbook to review table-level retention settings, understand archiving options, evaluate Basic Logs candidates, and estimate the cost impact of changing data plans across your Sentinel workspace.

---

## Contents

- [Retention Insights — Walkthrough](#retention-insights--walkthrough)
  - [Contents](#contents)
  - [Prerequisites](#prerequisites)
  - [Import the Workbook](#import-the-workbook)
  - [Configure Workspace and Pricing](#configure-workspace-and-pricing)
    - [Select the Workspace](#select-the-workspace)
    - [Set Regional Pricing](#set-regional-pricing)
  - [Data Archive Tab](#data-archive-tab)
    - [Review Current Retention Settings](#review-current-retention-settings)
    - [Identify Tables Without Archiving](#identify-tables-without-archiving)
    - [Update Table Retention from the Workbook](#update-table-retention-from-the-workbook)
  - [Basic Logs Tab](#basic-logs-tab)
    - [Understand Which Tables Support Basic Logs](#understand-which-tables-support-basic-logs)
    - [Evaluate Basic Logs Candidates](#evaluate-basic-logs-candidates)
  - [Search and Restore Tab](#search-and-restore-tab)
  - [Cost Estimation Tab](#cost-estimation-tab)
    - [Estimate Data Archive Costs](#estimate-data-archive-costs)
    - [Estimate Basic Logs Savings](#estimate-basic-logs-savings)
    - [Build a Cost Comparison](#build-a-cost-comparison)
  - [Common Scenarios](#common-scenarios)
    - [Scenario 1: All tables show default retention with no archiving](#scenario-1-all-tables-show-default-retention-with-no-archiving)
    - [Scenario 2: High-volume custom tables driving up costs](#scenario-2-high-volume-custom-tables-driving-up-costs)
    - [Scenario 3: Customer asks "what does 1-year retention cost?"](#scenario-3-customer-asks-what-does-1-year-retention-cost)
    - [Scenario 4: Evaluating whether to move Defender XDR tables to the Data Lake tier](#scenario-4-evaluating-whether-to-move-defender-xdr-tables-to-the-data-lake-tier)
    - [Scenario 5: Workspace retention is below 90 days](#scenario-5-workspace-retention-is-below-90-days)

---

## Prerequisites

- **Access:** At least **Log Analytics Reader** role on the workspace; **Log Analytics Contributor** if you want to update table settings directly from the workbook
- **Data flowing:** The workbook queries the `Usage` table, which requires at least **one hour** of ingestion data for newly created tables to appear
- **Regional pricing:** Have the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) open to look up prices for your region — the workbook defaults are indicative (USD) and must be adjusted

---

## Import the Workbook

The workbook is provided as a JSON template. To import it into your Sentinel workspace:

1. Navigate to **Microsoft Sentinel** in the Azure portal
2. Select your workspace
3. Go to **Workbooks** under *Threat management*
4. Click **+ Add workbook**
5. In the workbook editor, click the **Advanced Editor** button (`</>` icon) in the toolbar
6. Delete the default content and paste the contents of [`RetentionInsights.json`](../RetentionInsights.json)
7. Click **Apply**, then **Done editing**
8. Optionally click **Save** to persist it as a personal workbook in your workspace

> [!TIP]
> If you already have the "Archiving, Basic Logs and Retention" workbook from the Sentinel Content Hub installed, this customised version adds cost estimation capabilities and refined table views. You can run them side by side.

<!-- Screenshot placeholder: workbook import via Advanced Editor -->

---

## Configure Workspace and Pricing

### Select the Workspace

At the top of the workbook you will see three parameters:

| Parameter | What to set |
|:----------|:------------|
| **Subscription** | Select the Azure subscription that contains your Sentinel workspace |
| **Workspace** | Select the Log Analytics workspace attached to Sentinel |
| **Time Range** | Recommended: **Last 30 days** for a representative ingestion baseline |

Once selected, the workbook queries the ARM API to retrieve your workspace settings and displays a **Current Workspace Settings** tile showing:

- **Workspace Retention (days)** — the default interactive retention period
- **Workspace Plan** — the pricing tier (e.g., `pergb2018`)
- **Workspace Daily Quota (GB)** — any daily cap configured (or "None")

> [!WARNING]
> If the Workspace Retention shows less than **90 days**, a warning banner appears. Microsoft Sentinel includes 90 days of free interactive retention — make sure your workspace is configured to take advantage of this.

<!-- Screenshot placeholder: top parameter bar with subscription, workspace, and time range -->

### Set Regional Pricing

Expand the **Update Pricing Based on your Region** section. The workbook uses five pricing parameters for all cost calculations:

| Parameter | Description | Default | Where to find |
|:----------|:------------|:--------|:--------------|
| **Ingestion Price** | Combined Sentinel + Log Analytics ingestion cost per GB | $4.00 | [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) — add Sentinel *and* Log Analytics line items for your region |
| **Basic Logs Price** | Ingestion cost per GB for tables on the Basic Logs plan | $0.50 | Azure Pricing Calculator — look for "Basic Logs" under Log Analytics |
| **Data Archive Price** | Monthly storage cost per GB for archived data | $0.026 | Azure Pricing Calculator — look for "Data Archive" under Log Analytics |
| **Workspace Retention Price** | Monthly storage cost per GB beyond the free 90-day interactive window | $0.10 | Azure Pricing Calculator — look for "Interactive Retention" beyond included period |
| **Workspace Retention Period (Months)** | Auto-populated from your workspace settings; override to model longer retention | Auto | Adjust to simulate "what-if" scenarios |

> [!IMPORTANT]
> The **Ingestion Price** is the *combined* cost. For example, if your region charges $2.00 for Sentinel ingestion and $2.30 for Log Analytics ingestion, enter **4.30** as the value. Factor in any commitment tier discounts you have negotiated.

<!-- Screenshot placeholder: pricing parameter inputs expanded -->

```
Example pricing for West Europe (pay-as-you-go, March 2026):
────────────────────────────────────────────────────────────
Sentinel ingestion:           $2.00 / GB
Log Analytics ingestion:      $2.30 / GB
────────────────────────────────────────────
Combined Ingestion Price:     $4.30

Basic Logs Price:             $0.50 / GB
Data Archive Price:           $0.026 / GB / month
Workspace Retention Price:    $0.10 / GB / month (beyond 90 days)
```

---

## Data Archive Tab

The **Data Archive** tab is the default view. It shows every table in your workspace with its current retention configuration.

### Review Current Retention Settings

The main grid displays one row per table with the following columns:

| Column | What it shows |
|:-------|:--------------|
| **TableName** | The Log Analytics table name |
| **TableType** | Microsoft, CustomLog, SearchResults, etc. |
| **TablePlan** | Analytics or Basic |
| **InteractiveRetention** | Interactive (hot) retention period in days |
| **ArchiveRetention** | Archive (cold) retention period in days |
| **TotalRetention** | Interactive + Archive combined |
| **LAW Table Size** | Total data volume for the selected time range (GB) |
| **Is Archived** | Yes / No — whether archive retention is configured |
| **IsBillable** | Whether the table counts towards your ingestion billing |
| **lastPlanModifiedDate** | When the table plan was last changed |

Use the **Filter by Table Plan and Archive Tier** dropdown to narrow the view:

| Filter | What it shows |
|:-------|:--------------|
| **All** | Every table (Analytics + Basic) |
| **Basic Logs** | Only tables on the Basic plan |
| **Analytic Logs** | Only tables on the Analytics plan |
| **Archived Tables** | Tables with archive retention > 0 days |
| **Default Retention Tables** | Tables still at workspace default (no custom archive) |

> [!TIP]
> Start with the **Default Retention Tables** filter to quickly find tables that have no archiving configured — these are your first candidates for extended retention.

<!-- Screenshot placeholder: Data Archive tab grid with filter dropdown -->

### Identify Tables Without Archiving

1. Set the filter to **Default Retention Tables**
2. Sort by **LAW Table Size** (descending) to see the highest-volume tables first
3. For each table, ask:
   - Does this table need to be available for longer forensic investigation? (See the [Retention guidance](../guidance/retention.md) for framework-based retention requirements)
   - Is the table covered by a free ingestion benefit (E5 grant, P2 benefit)?
   - What would the annual archive cost be?

### Update Table Retention from the Workbook

Click on any table row in the grid to select it. A detail pane appears below showing the current settings for that specific table, along with links to update the retention settings directly in the Azure portal.

<!-- Screenshot placeholder: table detail pane after clicking a row -->

---

## Basic Logs Tab

The **Basic Logs** tab focuses on tables that can be switched from the Analytics plan to the Basic plan.

### Understand Which Tables Support Basic Logs

Not every table can use Basic Logs. The workbook automatically filters to eligible tables:

- **DCR-based custom log tables** (created via the Data Collection Rule API)
- **ContainerLog** and **ContainerLogV2** (Container Insights)
- **AppTraces** (Application Insights)

Tables that do **not** appear on this tab cannot be switched to Basic Logs (e.g., `SecurityEvent`, `SigninLogs`, Defender XDR tables).

> [!NOTE]
> Basic Logs tables have limitations: retention is fixed at **8 days**, alerts are not supported, and KQL query capabilities are restricted. Only use Basic Logs for high-volume, low-detection-value data where you do not need alerting.

### Evaluate Basic Logs Candidates

The grid shows the same table information as the Data Archive tab, filtered to Basic-eligible tables. For each table, compare:

- **Current plan** (Analytics) vs. what it would cost on Basic
- The volume of data flowing through the table (LAW Table Size)
- Whether you have any analytics rules or scheduled alerts that query this table

<!-- Screenshot placeholder: Basic Logs tab with eligible tables -->

---

## Search and Restore Tab

The **Search and Restore** tab shows any active Search Job or Restore Job tables in your workspace. These are temporary tables created when you:

- Run a [Search Job](https://learn.microsoft.com/en-us/azure/sentinel/search-jobs) to query archived data across long time spans
- [Restore](https://learn.microsoft.com/en-us/azure/sentinel/restore) archived data temporarily for interactive investigation

Use this tab to:

1. Review any currently active search or restore jobs
2. Check the size and retention of restored tables
3. Clean up restored tables that are no longer needed (restored tables incur ingestion cost)

<!-- Screenshot placeholder: Search and Restore tab -->

---

## Cost Estimation Tab

The **Cost Estimation** tab is the most powerful feature. It lets you model the financial impact of retention and plan changes using your actual ingestion data.

### Estimate Data Archive Costs

The top section shows **Estimated Data Retention Costs — Planning for Data Archiving**:

1. Enter a value in the **Total Retention in Days** field at the top — this is the target total retention you want to model (e.g., `365` for one year, `730` for two years)
2. The grid shows every table with:
   - Current interactive and archive retention settings
   - **Estimated Data Archive Cost** — calculated as: `Table Size (GB) × (Total Retention Days / 30) × Archive Price`
   - **Estimated Workspace Retention Cost** — the cost of interactive retention beyond the free 90-day window

```
Cost formula — Data Archive:
─────────────────────────────────────────────────────────────
Archive Cost  =  Table Size (GB)  ×  (Retention Days / 30)  ×  Archive Price per GB/month

Example: DeviceProcessEvents at 15 GB/month, 365-day archive, $0.026/GB/month
         = 15 × (365 / 30) × 0.026
         = 15 × 12.17 × 0.026
         = $4.75 / month
```

> [!TIP]
> Sort the grid by **Estimated Data Archive Cost** (descending) to see which tables are the most expensive to archive. This helps you prioritise which tables truly need long-term retention and which can stay at the default.

<!-- Screenshot placeholder: Cost Estimation tab — archive cost grid -->

### Estimate Basic Logs Savings

The bottom section shows **Estimated Data Ingestion Costs — Planning for Basic Logs**:

1. The grid lists every table eligible for Basic Logs
2. Two cost columns are shown side by side:
   - **Estimated Ingestion Cost** — what the table costs today on the Analytics plan (`Table Size × Ingestion Price`)
   - **Estimated Basic Logs Cost** — what the table would cost on Basic Logs (`Table Size × Basic Logs Price`)
3. The difference between these two columns is your potential saving

```
Cost formula — Basic Logs Saving:
─────────────────────────────────────────────────────────────
Ingestion Cost (Analytics)  =  Table Size (GB)  ×  Ingestion Price
Basic Logs Cost             =  Table Size (GB)  ×  Basic Logs Price
Monthly Saving              =  Ingestion Cost  -  Basic Logs Cost

Example: Custom_Firewall_CL at 500 GB/month
         Analytics:   500 × $4.30  = $2,150 / month
         Basic Logs:  500 × $0.50  = $250 / month
         Saving:                     $1,900 / month
```

> [!WARNING]
> Before switching a table to Basic Logs, verify that **no analytics rules, scheduled alerts, or automation rules** reference that table. Basic Logs tables cannot be queried by scheduled rules.

<!-- Screenshot placeholder: Cost Estimation tab — Basic Logs comparison grid -->

### Build a Cost Comparison

To build a complete cost picture for a customer conversation:

1. **Set regional pricing** — update all five pricing parameters for the customer's Azure region
2. **Adjust retention period** — enter the desired total retention in days (e.g., 365)
3. **Export the Data Archive grid** — click the **Export to Excel** button to save the archive cost estimates
4. **Export the Basic Logs grid** — export the Basic Logs cost comparison
5. **Combine in a presentation** — use both exports to build a cost optimisation proposal:

   | Optimisation | Tables Affected | Monthly Saving |
   |:-------------|:----------------|:---------------|
   | Switch custom log tables to Basic Logs | `Custom_Firewall_CL`, `Custom_DNS_CL` | $X,XXX |
   | Archive high-volume Defender XDR tables to Data Lake | `DeviceNetworkEvents`, `DeviceFileEvents` | $X,XXX |
   | Extend retention beyond 90 days for compliance tables | `SigninLogs`, `AuditLogs` | +$XXX (needed for compliance) |

---

## Common Scenarios

### Scenario 1: All tables show default retention with no archiving

This is the most common finding in new or unoptimised workspaces. Use the **Default Retention Tables** filter on the Data Archive tab to see all affected tables, then review the [Retention guidance](../guidance/retention.md) for framework-based minimum retention requirements.

### Scenario 2: High-volume custom tables driving up costs

Switch to the Cost Estimation tab and compare the Ingestion Cost vs. Basic Logs Cost. If a custom table (e.g., verbose firewall logs, application traces) has high volume but is not used in analytics rules, it is a strong candidate for Basic Logs.

### Scenario 3: Customer asks "what does 1-year retention cost?"

1. Set the **Total Retention in Days** to `365`
2. Ensure pricing parameters match the customer's region
3. Export the archive cost estimation grid
4. Sum the **Estimated Data Archive Cost** column for all tables
5. Add the **Estimated Workspace Retention Cost** for tables with interactive retention beyond 90 days

### Scenario 4: Evaluating whether to move Defender XDR tables to the Data Lake tier

Use the workbook to see the current ingestion volume of XDR tables (e.g., `DeviceProcessEvents`, `DeviceNetworkEvents`). Then model the archive cost for 365-day retention in the Cost Estimation tab. Compare this against the E5 ingestion benefit — remember, the grant covers **Analytics tier only**. Moving to Data Lake removes the free ingestion but enables cheaper long-term storage.

See the [Microsoft Defender XDR connector page](../connectors/microsoft-defender-xdr.md#estimating-data-lake-retention-cost) for the full trade-off discussion, and the [Retention guidance](../guidance/retention.md) for the framework rationale behind 365-day retention.

### Scenario 5: Workspace retention is below 90 days

If the workbook shows a warning banner about retention below 90 days, the workspace is not taking advantage of the included free retention. Navigate to **Log Analytics workspace > Settings > Usage and estimated costs > Data Retention** and increase it to at least 90 days at no additional cost.

---

## Related Microsoft Learn Documentation

- [Manage data retention in a Log Analytics workspace](https://learn.microsoft.com/azure/azure-monitor/logs/data-retention-configure) — canonical table-level retention procedure (analytics + total retention)
- [Reduce costs for Microsoft Sentinel — pricing tier](https://learn.microsoft.com/azure/sentinel/billing-reduce-costs#set-or-change-pricing-tier) — commitment-tier and pre-purchase background used for cost estimation
- [Microsoft Sentinel data lake overview](https://learn.microsoft.com/azure/sentinel/datalake/sentinel-lake-overview) — context for evaluating data lake vs archive tier

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)
