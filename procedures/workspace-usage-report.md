# Workspace Usage Report — Walkthrough

**Tool type:** Workbook · **Source:** [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) (search "Workspace Usage Report")

This guide walks you through using the Workspace Usage Report workbook to validate your Sentinel data connector configuration, check ingestion volumes, and verify retention settings.

---

## Contents

- [Prerequisites](#prerequisites)
- [Opening the Workbook](#opening-the-workbook)
- [Check Free Data Connectors](#check-free-data-connectors)
- [Check Connectors with Ingestion Benefit](#check-connectors-with-ingestion-benefit)
- [Check Remaining Connector Ingestion](#check-remaining-connector-ingestion)
- [Check Retention Settings](#check-retention-settings)
- [Interpret the Results](#interpret-the-results)
- [Common Scenarios](#common-scenarios)

---

## Prerequisites

- **Access:** At least **Microsoft Sentinel Reader** role on the Sentinel workspace
- **Workbook installed:** Install the "Workspace Usage Report" from the Sentinel Content Hub if you haven't already
- **Data flowing:** The workbook requires at least a few days of ingestion data to show meaningful results

---

## Opening the Workbook

1. Navigate to **Microsoft Sentinel** in the Azure portal
2. Select your workspace
3. Go to **Workbooks** in the left navigation under *Threat management*
4. Select the **My workbooks** or **Templates** tab
5. Search for **Workspace Usage Report** and open it
6. Set the **TimeRange** parameter at the top of the workbook (recommended: **Last 30 days** for a representative view)

---

## Check Free Data Connectors

Free data connectors do not count towards your Sentinel commitment tier or pay-as-you-go billing. Use this check to confirm they are properly configured.

### What to look for

1. In the workbook, locate the ingestion breakdown by **solution** or **data type**
2. Identify the following free tables:

   | Table | Connector | Expected Status |
   |:------|:----------|:----------------|
   | **SigninLogs** | Microsoft Entra ID | Free data source |
   | **AuditLogs** | Microsoft Entra ID | Free data source |
   | **AADNonInteractiveUserSignInLogs** | Microsoft Entra ID | Free data source |
   | **AADRiskyUsers** | Microsoft Entra ID Protection | Free data source |
   | **AADRiskyServicePrincipals** | Microsoft Entra ID Protection | Free data source |
   | **OfficeActivity** | Office 365 | Free data source |
   | **AzureActivity** | Azure Activity Logs | Free data source |

3. Confirm these tables show **active ingestion** (non-zero GB/day)
4. If any free table shows zero ingestion, the connector may not be enabled — check the **Data connectors** page

> [!TIP]
> Free data connectors should always be enabled. There is no cost to ingest this data into the Analytics tier, so there is no reason to leave them off.

---

## Check Connectors with Ingestion Benefit

Some connectors include a free ingestion allowance as part of a Microsoft license. Use this check to validate you are benefiting from these grants.

### Microsoft Defender XDR (E5 data grant)

1. In the workbook, filter or locate the **Defender XDR tables** (DeviceEvents, AlertInfo, EmailEvents, IdentityLogonEvents, CloudAppEvents, etc.)
2. Verify that ingestion is flowing to the **Analytics tier**
3. The E5 Security data grant covers Analytics-tier ingestion for these tables at no extra cost

   > [!IMPORTANT]
   > The E5 grant only covers the **Analytics tier**. Sending Defender XDR data to the **Data Lake** (long-term retention) is **not free** and incurs Lake retention charges. See [Estimating Data Lake Retention Cost](../connectors/microsoft-defender-xdr.md#estimating-data-lake-retention-cost) for guidance.

4. Note the **daily ingestion volume in GB** for each Defender XDR table — you will need this to estimate Lake retention cost

### Defender for Servers P2 (500 MB/day ingestion benefit)

1. Locate **SecurityEvent** / **WindowsEvent** (Microsoft-SecurityEvent stream) and **LinuxAuditLog** tables in the workbook
2. Check the daily ingestion volume per table
3. The [Defender for Servers P2 ingestion benefit](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) provides a **pooled daily allowance of 500 MB × number of AMA-covered servers**, applied across eligible security tables only (SecurityEvent, WindowsEvent [Microsoft-SecurityEvent stream], LinuxAuditLog, SecurityAlert, WindowsFirewall, ProtectionStatus, and a few others). Individual servers can ingest more, as long as the pooled allowance isn’t exceeded
4. Compare your actual daily ingestion against the expected pooled allowance (number of P2-covered servers × 500 MB)

   > [!NOTE]
   > The allowance is pooled across the subscription / workspace, not enforced per machine. The general `Syslog` table, `CommonSecurityLog`, `W3CIISLog`, and non-SecurityEvent `WindowsEvent` channels (PowerShell, Sysmon, AppLocker) are **not** eligible for this benefit. See the [Windows Security Events](../connectors/windows-security-events.md) connector page for tier sizing guidance.

---

## Check Remaining Connector Ingestion

For tables that are not free and do not have an ingestion benefit, you need to monitor volumes to stay within your commitment tier or understand pay-as-you-go costs.

1. Review the ingestion summary across all tables in the workbook
2. Identify tables with the **highest daily ingestion** — these are your cost drivers
3. Common high-volume tables to watch:
   - **SecurityEvent** / **WindowsEvent** — can be high-volume on domain controllers
   - **Syslog** — varies significantly by Linux server role
   - **CommonSecurityLog** / **ASimDnsActivityLogs** — if you have Tier 2/3 connectors enabled
4. Compare total daily ingestion against your **commitment tier** (if applicable) to identify overage risk

> [!TIP]
> Use the workbook's time-range selector to compare ingestion trends over different periods. A 7-day vs. 30-day comparison helps spot anomalies or sudden spikes.

---

## Check Retention Settings

The workbook also allows you to verify that retention policies are applied correctly.

1. Look for the **retention** or **data lifecycle** section in the workbook
2. Verify that each table has the expected retention configuration:

   | Setting | Expected Value | Purpose |
   |:--------|:---------------|:--------|
   | **Interactive retention (Analytics)** | 90 days | Active detection, hunting, incident response |
   | **Total retention (Lake)** | 365 days | Extended forensic investigation, compliance |

3. If any table shows a retention period shorter than expected, update the table-level retention in **Settings > Table management** in your Log Analytics workspace

> [!WARNING]
> Retention settings are configured at the **table level**, not at the connector level. Enabling a connector does not automatically set the correct retention. Always verify after deploying a new connector.

---

## Interpret the Results

After reviewing each section, use this checklist:

| Check | Status | Action if Failed |
|:------|:-------|:-----------------|
| Free connectors ingesting data | ✅ / ❌ | Enable the connector in **Data connectors** |
| E5 grant tables flowing to Analytics | ✅ / ❌ | Enable the Defender XDR connector and select all relevant tables |
| P2 ingestion benefit within budget | ✅ / ❌ | Review DCR preset tier (Minimal → Common) or server count |
| High-volume tables identified | ✅ / ❌ | Consider adjusting DCR preset or filtering noisy event IDs |
| Retention correctly configured | ✅ / ❌ | Update table retention in Log Analytics workspace settings |

---

## Common Scenarios

### Scenario 1: Free connector shows zero ingestion

The connector is likely not enabled, or the diagnostic settings (for Azure Activity) are not configured. Go to **Data connectors**, find the connector, and follow the configuration steps.

### Scenario 2: Defender XDR tables show unexpectedly high ingestion

Review which tables are enabled in the Defender XDR connector settings. Consider whether all tables are needed — for example, `DeviceFileEvents` and `DeviceRegistryEvents` can be high-volume but are covered by MDE, so you may choose to exclude them initially.

### Scenario 3: SecurityEvent ingestion exceeds P2 allowance

You may have domain controllers or file servers producing more than 500 MB/day. Options:
- Move from **All Events** to **Common** preset on high-volume servers
- Use a **Custom DCR** to filter specific high-volume event IDs (e.g., 5156 on servers with heavy network traffic)
- Review the [Windows Security Events tier guidance](../connectors/windows-security-events.md) for optimisation strategies

### Scenario 4: Retention not set after deploying a new connector

This is expected — retention is not automatically configured when you enable a connector. Navigate to **Log Analytics workspace > Settings > Tables**, find the relevant table, and set the interactive and total retention periods.

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)
