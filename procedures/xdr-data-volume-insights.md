# XDR Data Volume Insights — Walkthrough

**Tool type:** KQL Query · **Source:** Run directly in Sentinel Log Analytics

This KQL query shows all M365 XDR tables (Defender XDR + Entra ID) with their size in GB, event count, daily average, and estimated cost if they were billable. Use it to quantify the cost of sending the raw data to Sentinel Analytics or Data Lake tier.

---

## Contents

- [XDR Data Volume Insights — Walkthrough](#xdr-data-volume-insights--walkthrough)
  - [Contents](#contents)
  - [When to Use This Query](#when-to-use-this-query)
  - [Prerequisites](#prerequisites)
  - [Step 1 — Run the Query](#step-1--run-the-query)
  - [Step 2 — Interpret the Output](#step-2--interpret-the-output)
    - [What to look for](#what-to-look-for)
  - [Step 3 — Use the Results](#step-3--use-the-results)
    - [Analytics and Data Lake cost estimation](#analytics-and-data-lake-cost-estimation)
    - [Ingestion validation](#ingestion-validation)
  - [Customisation](#customisation)
    - [Adjust the price](#adjust-the-price)
    - [Change the lookback window](#change-the-lookback-window)
    - [Add more tables](#add-more-tables)
  - [Related Tools](#related-tools)

---

## When to Use This Query

Use this query when you want to:

- **Quantify log volume of XDR tables for ingestion in Data Lake** — show stakeholders the data volume when sending the data straight to Data Lake
- **Quantify the E5 benefit** — show stakeholders the dollar value of free ingestion they receive
- **Identify high-volume tables** — understand which Defender products generate the most data
- **Estimate Data Lake cost** — if considering moving tables from Analytics to Data Lake tier, this gives a baseline
- **Validate ingestion** — confirm that all expected Defender XDR tables are actively receiving data

You can use the [XDR Ingestion Calculator](xdr-ingestion-calculator.md) as well which will export the results to CSV and does some calculations but needs an App registration while the KQL can be ran from Hunting > Advanced Hunting in the Defender Portal. 

---

## Prerequisites

| Requirement | Details |
|:------------|:--------|
| **Defender XDR** | Microsoft 365 E5, E7, A5, F5, and G5, and Microsoft 365 E5, A5, F5, and G5 Security customers |

Microsoft 365 E5, A5, F5, and G5, and Microsoft 365 E5, A5, F5, and G5 Security customers can receive a data grant of up to 5MB per user per day to ingest Microsoft 365 data. This offer includes the following data sources:

- Microsoft Entra ID (formerly Azure AD) sign-in and audit logs
- Microsoft Defender for Cloud Apps Guard shadow IT discovery logs
- Microsoft Purview Information Protection logs
- Microsoft 365 advanced hunting data

---

## Step 1 — Run the Query

Navigate to https://security.microsoft.com > Hunting > Advanced Hunting and paste the following query:

```kql
// M365 E5 Benefit - Table Sizes by Product
// Shows all M365 E5 benefit-eligible tables (Defender XDR + Entra ID) with
// size in GB, event count, and estimated cost if they were billable.
// M365 E5 customers get these for free - this shows the benefit value.
// =====================================================================

let Price = 3.0;
union withsource=TableName
    // Entra ID (formerly Azure AD)
    SigninLogs, AuditLogs, AADNonInteractiveUserSignInLogs,
    AADServicePrincipalSignInLogs, AADManagedIdentitySignInLogs,
    AADProvisioningLogs, ADFSSignInLogs,
    // Defender for Endpoint (MDE)
    DeviceEvents, DeviceFileEvents, DeviceLogonEvents, DeviceNetworkEvents,
    DeviceProcessEvents, DeviceRegistryEvents, DeviceImageLoadEvents,
    DeviceNetworkInfo, DeviceInfo, DeviceFileCertificateInfo,
    // Defender for Identity (MDI)
    IdentityLogonEvents, IdentityQueryEvents, IdentityDirectoryEvents,
    // Defender Alerts
    AlertEvidence,
    // Defender for Office 365 (MDO)
    EmailEvents, EmailUrlInfo, EmailAttachmentInfo, EmailPostDeliveryEvents,
    // Defender for Cloud Apps (MCA)
    CloudAppEvents
| where TimeGenerated > ago(30d)
| summarize 
    TotalEvents = count(),
    SizeInGB = round(sum(estimate_data_size(*)) / 1000.0 / 1000.0 / 1000.0, 2),
    SizeInMB = round(sum(estimate_data_size(*)) / 1000.0 / 1000.0, 2),
    FirstEvent = min(TimeGenerated),
    LastEvent = max(TimeGenerated)
    by TableName
| extend 
    DailyAvgMB = round(SizeInMB / 30.0, 2),
    IfBillableCostUSD = round(SizeInGB * Price, 2),
    DefenderProduct = case(
        TableName has "Signin" or TableName has "Audit" or TableName startswith "AAD" or TableName == "ADFSSignInLogs", "Microsoft Entra ID",
        TableName startswith "Device", "Microsoft Defender for Endpoint (MDE)",
        TableName startswith "Identity", "Microsoft Defender for Identity (MDI)",
        TableName startswith "Email", "Microsoft Defender for Office 365 (MDO)",
        TableName startswith "CloudApp", "Microsoft Defender for Cloud Apps (MCA)",
        TableName startswith "Alert", "Microsoft 365 Defender (Alerts)",
        "Other M365 E5 Benefit"
    )
| project 
    DefenderProduct, TableName, SizeInGB, SizeInMB, DailyAvgMB,
    TotalEvents, IfBillableCostUSD,
    FirstEvent, LastEvent
| order by DefenderProduct asc, SizeInGB desc
```

> [!TIP]
> The `Price` variable defaults to **$3.00/GB** (Pay-As-You-Go Analytics tier pricing). Adjust this to your actual commitment tier rate if you want a more accurate cost comparison.

---

## Step 2 — Interpret the Output

The query returns one row per table, grouped by Defender product:

| Column | Description |
|:-------|:------------|
| **DefenderProduct** | Which Defender workload the table belongs to (MDE, MDO, MDI, MCA, Entra ID, Alerts) |
| **TableName** | The Log Analytics table name |
| **SizeInGB** | Total data volume over the last 30 days in GB |
| **SizeInMB** | Same value in MB (useful for low-volume tables) |
| **DailyAvgMB** | Average daily ingestion in MB (SizeInMB ÷ 30) |
| **TotalEvents** | Total number of events over 30 days |
| **IfBillableCostUSD** | What the ingestion would cost at the configured price per GB — this is your **E5 benefit value** |
| **FirstEvent / LastEvent** | Timestamps of the earliest and most recent event — useful for confirming data freshness |

### What to look for

- **Tables with 0 events or missing from results** — the table may not be enabled in the connector. Check the Defender XDR connector configuration
- **IfBillableCostUSD total** — sum this column to get the total E5 benefit value. This is the amount you would pay without the E5 grant
- **DailyAvgMB** — use this for capacity planning if considering Data Lake retention
- **Large gaps between FirstEvent and LastEvent** — indicates the table has been ingesting consistently

---

## Step 3 — Use the Results

### Analytics and Data Lake cost estimation

If you are considering sending the data to the Log Analytics tier or enabling [Data Lake retention](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers) for specific tables, multiply the **DailyAvgMB** by the applicable pricing and your desired retention period to estimate annual cost.

### Ingestion validation

Compare the results against the list of tables you expect to see. If a Defender product is licensed but its tables are missing, the connector is misconfigured.

---

## Customisation

### Adjust the price

Change the `let Price = 3.0;` line to match your commitment tier rate:

| Tier | Approximate price/GB |
|:-----|:---------------------|
| Pay-As-You-Go | $3.00 |
| 100 GB/day | $2.30 |
| 200 GB/day | $2.12 |
| 500 GB/day | $1.95 |

### Change the lookback window

Replace `ago(30d)` with a different duration (e.g., `ago(7d)` for a quick check) and adjust the `/ 30.0` divisor for DailyAvgMB accordingly.

### Add more tables

If your environment has additional E5 benefit-eligible tables (e.g., `AADRiskyUsers`, `AADUserRiskEvents`), add them to the `union` statement.

---

## Related Tools

| Tool | Purpose |
|:-----|:--------|
| [Workspace Usage Report](workspace-usage-report.md) | Broader ingestion monitoring across all Sentinel tables (not just E5 benefit) |
| [XDR Ingestion Calculator](xdr-ingestion-calculator.md) | Estimate XDR ingestion volumes from the Advanced Hunting API **before** enabling the connector |
