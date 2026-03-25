# Defender AMA Coverage — Walkthrough

**Tool type:** Workbook · **Source:** [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage)

This guide walks you through using the Defender AMA Coverage workbook to validate Azure Monitor Agent (AMA) deployment, check security event and syslog ingestion coverage, and identify gaps in your endpoint telemetry.

---

## Contents

- [When to Use This Workbook](#when-to-use-this-workbook)
- [Prerequisites](#prerequisites)
- [Step 1 — Deploy the Workbook](#step-1--deploy-the-workbook)
- [Step 2 — Configure Filters](#step-2--configure-filters)
- [Step 3 — Review Summary Tiles](#step-3--review-summary-tiles)
- [Step 4 — Analyse Coverage Categories](#step-4--analyse-coverage-categories)
- [Step 5 — Check DCR Associations](#step-5--check-dcr-associations)
- [Step 6 — Identify and Remediate Gaps](#step-6--identify-and-remediate-gaps)
- [Alternative — Run the KQL Query in Defender Portal](#alternative--run-the-kql-query-in-defender-portal)
- [Important Notes](#important-notes)

---

## When to Use This Workbook

Use this workbook to answer these operational questions:

- Which servers are onboarded to MDE but **missing AMA**?
- Which servers have AMA installed but are **not sending SecurityEvent or Syslog** data to Sentinel?
- Are my **Data Collection Rules (DCRs)** correctly associated with the right machines?
- What is the overall **coverage health** of my endpoint telemetry pipeline?

> [!TIP]
> Run this check after deploying AMA to new servers, after enabling the [Windows Security Events](../connectors/windows-security-events.md) or [Syslog](../connectors/syslog-linux.md) connectors, or as a periodic operational health check.

---

## Prerequisites

| Requirement | Details |
|:------------|:--------|
| **Microsoft Sentinel workspace** | With the Defender XDR connector enabled (DeviceInfo table required) |
| **Defender for Endpoint integration** | Servers must be onboarded to MDE |
| **AMA deployed** | On target Windows and/or Linux machines |
| **Log Analytics tables available** | `DeviceInfo`, `Heartbeat`, `SecurityEvent` (Windows), `Syslog` (Linux) |
| **Access** | At least Microsoft Sentinel Reader role |

> [!WARNING]
> This workbook assumes Microsoft Defender XDR data is ingested into Sentinel. Without ingestion, device name normalisation and correlation may be inconsistent. See the [alternative approach](#alternative--run-the-kql-query-in-defender-portal) if you haven't enabled the connector yet.

---

## Step 1 — Deploy the Workbook

1. Open **Microsoft Sentinel** in the Azure portal
2. Go to **Workbooks** under *Threat management*
3. Click **Add workbook** > **Advanced Editor**
4. Paste the JSON content from the [Defender_vs_AMA.json](https://github.com/mathijsvermaat/Defender-AMA-coverage) file in the repository
5. Click **Apply** and then **Save**
6. Give it a descriptive name (e.g., `Defender AMA Coverage`)

---

## Step 2 — Configure Filters

The workbook provides several filters at the top. Set them according to your review scope:

| Filter | Default | Description |
|:-------|:--------|:------------|
| **Workspace** | Current workspace | Select the workspace to analyse |
| **Time range** | 7 days | How far back to look for heartbeats and log ingestion |
| **OS platform** | All | Filter by Windows, Linux, or both |
| **AMA status** | All | Filter to show All, Yes (AMA present), or No (AMA missing) |
| **Exclude Workstations** | Yes | Excludes workstations and mobile devices to focus on server infrastructure |
| **Exclude Compliant** | MDE + AMA | Hides fully compliant machines so you can focus on gaps that need remediation |

> [!TIP]
> Start with the **Exclude Compliant = MDE + AMA** default to immediately see which machines need attention. Switch to *None* when you want the full picture.

---

## Step 3 — Review Summary Tiles

The top section of the workbook shows summary tiles with device counts:

| Tile | What it Tells You |
|:-----|:------------------|
| **Total devices** | All MDE-onboarded devices matching your filters |
| **MDE + AMA** | Devices with both Defender and AMA — fully covered |
| **MDE Only** | Devices with Defender but **missing AMA** — SecurityEvent/Syslog not flowing |
| **AMA Only** | Devices with AMA but **not in MDE** — endpoint detection gap |

Focus your remediation on the **MDE Only** category — these servers are protected by Defender but not sending native OS logs to Sentinel.

---

## Step 4 — Analyse Coverage Categories

Below the summary tiles, the workbook shows detailed tables for each category:

### MDE + AMA (Compliant)

These machines are fully covered. Verify that:
- The **Last Heartbeat** timestamp is recent (within the time range)
- **SecurityEvent** (Windows) or **Syslog** (Linux) shows recent ingestion timestamps
- If log timestamps are stale despite AMA being present, the DCR may be misconfigured

### MDE Only (AMA Missing)

These machines need AMA deployment:
1. Note the device names and OS platform
2. Deploy AMA via Azure Policy, Azure Arc, or manual installation
3. Associate the appropriate DCR for SecurityEvent or Syslog collection
4. Re-check the workbook after deployment to confirm coverage

### AMA Only (MDE Missing)

These machines are sending logs but lack endpoint protection:
1. Verify whether the machine should be onboarded to MDE
2. If yes, onboard via Defender for Endpoint or Defender for Servers
3. If the machine is intentionally excluded (e.g., a legacy system), document the exception

---

## Step 5 — Check DCR Associations

The workbook includes a **DCR Association** view that shows which Data Collection Rules are linked to each machine.

### What to verify

| Check | Expected State | Action if Failed |
|:------|:---------------|:-----------------|
| DCR is associated with the machine | Each AMA machine should have at least one DCR | Associate a DCR via Azure Policy or manual assignment |
| Correct DCR type | Windows servers → SecurityEvent DCR; Linux servers → Syslog DCR | Reassign the correct DCR |
| DCR preset matches intended tier | Common preset for most servers; All Events for DCs and high-value assets | Update the DCR preset — see [Windows Security Events](../connectors/windows-security-events.md) or [Syslog](../connectors/syslog-linux.md) tier guidance |

### Merged View

The Merged View tab combines AMA-enabled and Defender devices with their associated DCRs in a single table. Use this for:
- Exporting to Excel for offline review or reporting
- Cross-referencing DCR assignments with server roles
- Sharing coverage status with management or audit teams

---

## Step 6 — Identify and Remediate Gaps

After reviewing the workbook, use this remediation checklist:

| Gap | Priority | Remediation |
|:----|:---------|:------------|
| Server in MDE but no AMA | **High** | Deploy AMA and associate SecurityEvent/Syslog DCR |
| AMA present but no recent logs | **High** | Check DCR configuration, verify the DCR is associated, check AMA agent health |
| Server in AMA but not in MDE | **Medium** | Onboard to Defender or document exception |
| DCR associated but wrong preset | **Low** | Update DCR to match the intended tier (Minimal/Common/Full) |
| Stale heartbeat (>24h) | **Medium** | Check if server is powered off, network issues, or AMA agent health |

> [!IMPORTANT]
> Repeat this review periodically — new servers may be deployed without AMA, or DCR associations may drift. Consider setting up an Azure Policy to automatically deploy AMA and associate DCRs on new machines.

---

## Alternative — Run the KQL Query in Defender Portal

If you have **not yet enabled** the Defender XDR connector in Sentinel (and therefore don't have the `DeviceInfo` table available), you can run the underlying KQL query directly in the Defender portal:

1. Go to [https://security.microsoft.com](https://security.microsoft.com/)
2. Navigate to **Advanced hunting**
3. Copy the KQL query from [Defender_AMA_coverage.kql](https://github.com/mathijsvermaat/Defender-AMA-coverage) in the repository
4. Run the query

> [!NOTE]
> When running the KQL query directly, AMA extension status is **not** available (that data comes from the `Heartbeat` table in Log Analytics). The query only shows Defender-onboarded devices and their log ingestion status based on Advanced Hunting data.

---

## Important Notes

- **OS name limitation:** Some AMA versions only report the generic OS name (e.g., `Windows` instead of `Windows Server 2025`). Use additional metadata or naming conventions for accurate server filtering.
- **Workstation exclusion:** The default filter excludes workstations and mobile devices. If you need to validate AMA on workstations, toggle the **Exclude Workstations** filter to *No*.
- **Time range:** A 7-day time range is recommended for operational checks. Use 30 days for a broader trend view, but note that machines powered off for more than 7 days may appear as stale.

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)
