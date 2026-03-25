# XDR Ingestion Calculator — Walkthrough

**Tool type:** PowerShell Script · **Source:** [GitHub — mathijsvermaat/DefenderIngestToSentinel](https://github.com/mathijsvermaat/DefenderIngestToSentinel)

This guide walks you through using the XDR tables to Sentinel ingestion calculator to estimate daily ingestion volumes from the Defender Advanced Hunting API **before** enabling the Defender XDR connector in Sentinel.

---

## Contents

- [When to Use This Script](#when-to-use-this-script)
- [Prerequisites](#prerequisites)
- [Step 1 — Create the App Registration](#step-1--create-the-app-registration)
- [Step 2 — Install the Script](#step-2--install-the-script)
- [Step 3 — Configure the Script](#step-3--configure-the-script)
- [Step 4 — Run the Script](#step-4--run-the-script)
- [Step 5 — Interpret the Output](#step-5--interpret-the-output)
- [Step 6 — Estimate Data Lake Cost](#step-6--estimate-data-lake-cost)
- [Accuracy and Limitations](#accuracy-and-limitations)
- [Troubleshooting](#troubleshooting)

---

## When to Use This Script

Use this script when you have **not yet enabled** the Defender XDR connector in Sentinel and want a data-driven cost estimate before committing. The script queries the Defender Advanced Hunting API directly, samples real records, and extrapolates daily/monthly ingestion per table.

If you **already have** the Defender XDR connector enabled, use the [Workspace Usage Report](workspace-usage-report.md) workbook instead — it shows actual ingestion data.

> [!TIP]
> This is particularly useful for budget approval conversations. Run the script, export the CSV, and use it to justify (or defer) specific Defender XDR tables.

---

## Prerequisites

| Requirement | Details |
|:------------|:--------|
| **PowerShell** | 5.1+ (Windows) or 7.x (cross-platform) |
| **MSAL.PS module** | Install via `Install-Module MSAL.PS -Scope CurrentUser` |
| **Azure AD app registration** | With `AdvancedHunting.Read.All` application permission (admin consent granted) |
| **Network access** | Outbound to `https://api.security.microsoft.com/` |
| **Writable output directory** | Defaults to `C:\MDE_IngestionEstimate` — configurable in the script |

---

## Step 1 — Create the App Registration

1. Go to **Microsoft Entra ID** > **App registrations** > **New registration**
2. Name it something descriptive (e.g., `Sentinel-IngestionEstimator-ReadOnly`)
3. Set **Supported account types** to *Accounts in this organizational directory only*
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID**
6. Go to **Certificates & secrets** > **New client secret** — note the secret value
7. Go to **API permissions** > **Add a permission**:
   - Select **APIs my organization uses**
   - Search for **Microsoft Threat Protection**
   - Select **Application permissions** > `AdvancedHunting.Read.All`
8. Click **Grant admin consent** for your tenant

> [!WARNING]
> Store the client secret securely. Do not commit it to source control. Consider using Azure Key Vault or Windows Credential Manager for production use.

---

## Step 2 — Install the Script

```powershell
# Clone the repository
git clone https://github.com/mathijsvermaat/DefenderIngestToSentinel.git
cd DefenderIngestToSentinel

# Install the MSAL.PS module (if not already installed)
Install-Module MSAL.PS -Scope CurrentUser
```

---

## Step 3 — Configure the Script

Open `GetNativeDefenderTablesSizeForLAingest.ps1` and edit the configuration block:

```powershell
$TenantId    = "your-tenant-id"
$ClientId    = "your-client-id"
$plainSecret = "your-client-secret"    # Will be converted to SecureString by the script
$OutputPath  = "C:\MDE_IngestionEstimate"
```

### Customise the table list (optional)

The default tables cover the most common Defender XDR data:

```
DeviceInfo, DeviceNetworkEvents, DeviceFileEvents, DeviceProcessEvents,
DeviceRegistryEvents, DeviceLogonEvents, DeviceImageLoadEvents,
DeviceEvents, DeviceNetworkInfo, AlertInfo, AlertEvidence
```

You can modify the `$Tables` array to add or remove tables based on which ones you plan to enable in the Sentinel connector. For example, if you only want to estimate endpoint tables:

```powershell
$Tables = @(
    "DeviceProcessEvents",
    "DeviceNetworkEvents",
    "DeviceFileEvents"
)
```

---

## Step 4 — Run the Script

```powershell
.\GetNativeDefenderTablesSizeForLAingest.ps1
```

The script will prompt you for three inputs:

| Prompt | Recommended Value | Notes |
|:-------|:------------------|:------|
| **Lookback days** | 7–14 | Longer periods smooth out daily variance (weekdays vs. weekends) |
| **Sample size** | 10000 | Increase for more accuracy if API performance allows (max 100000) |
| **Sampling method** | `sample` (default) | `sample` = random selection (more representative); `take` = first N rows |

---

## Step 5 — Interpret the Output

The script produces two outputs:

### Console table

A sorted table showing per-table estimates, ordered by highest ingestion:

| Column | Description |
|:-------|:------------|
| `TableName` | The Defender XDR table name |
| `EventsInLookback` | Total events in the lookback period |
| `AvgRecordSizeKB` | Average record size based on sampled CSV export |
| `EstDailyEvents` | Estimated daily event count |
| `EstDailyMBIngested` | Estimated daily ingestion in MB |
| `EstDailyGBIngested` | Estimated daily ingestion in GB |
| `EstTotalGBInLookback` | Total estimated ingestion for the lookback period |

### CSV file

Exported to `$OutputPath\MDE_IngestionEstimate.csv` with the same columns plus a totals row, suitable for sharing with stakeholders or importing into Excel.

---

## Step 6 — Estimate Data Lake Cost

Once you have the daily ingestion estimates, you can calculate Data Lake retention cost:

1. Sum the `EstDailyGBIngested` for all tables you plan to send to Sentinel
2. Multiply by 365 to get the annual Lake volume
3. Apply the [Sentinel Data Lake pricing](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers) rate

**Example:**

| Total daily ingestion | Annual Lake volume | Lake price/GB/month | Annual Lake cost |
|:----------------------|:-------------------|:--------------------|:-----------------|
| 5 GB/day | 1,825 GB | Check current pricing | Daily GB × 365 × price/GB/month × 12 |

> [!NOTE]
> Remember: Analytics-tier ingestion for Defender XDR tables is **free** with E5 Security. Only the **Data Lake** (long-term retention beyond the Analytics period) incurs cost. See [Estimating Data Lake Retention Cost](../connectors/microsoft-defender-xdr.md#estimating-data-lake-retention-cost) for the full cost model.

---

## Accuracy and Limitations

The script estimates are based on sampled CSV sizes and event counts. Observed accuracy compared to actual Sentinel ingestion:

| Factor | Impact |
|:-------|:-------|
| **Typical variance** | ±10% compared to actual Sentinel ingestion |
| **Worst case** | 10–20% variance for tables with highly variable record sizes |
| **CSV inflation** | CSV adds quotes, commas, headers — tends to slightly overestimate |
| **Enrichment** | Sentinel connectors may add columns at ingestion time |
| **Workload patterns** | Spiky telemetry (weekday vs. weekend) benefits from longer lookback |

> [!IMPORTANT]
> Use this script for **planning and sizing**. After enabling the connector, validate with the [Workspace Usage Report](workspace-usage-report.md) workbook for a few days to confirm actual volumes.

---

## Troubleshooting

| Problem | Likely Cause | Solution |
|:--------|:-------------|:---------|
| `API call failed` warnings | Missing permissions or incorrect credentials | Verify `AdvancedHunting.Read.All` permission and admin consent; check TenantId/ClientId/secret |
| No data found for table | Tenant doesn't produce that table in the lookback period | Use a longer lookback or remove the table from `$Tables` |
| CSV export errors / access denied | Output directory not writable | Ensure `$OutputPath` exists and you have write permissions |
| Sampling too slow / timeouts | Large sample size across many tables | Reduce sample size or number of tables |
| Empty results for all tables | App registration not consented | Go to Entra ID > App registrations > your app > API permissions and grant admin consent |

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)
