# Microsoft Purview (Data Map / Discovery)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party (Diagnostic Settings) · **Free ingestion:** No

> [!IMPORTANT]
> This is the **Microsoft Purview** connector for the **Purview Data Map / Governance** account. It is a **different connector** than [Microsoft Purview Information Protection (Preview)](microsoft-purview-information-protection.md). Enable both for full data-protection coverage:
>
> | Connector | Source | Table | What it covers |
> |:----------|:-------|:------|:---------------|
> | **Microsoft Purview** *(this page)* | Purview Data Map account &rarr; Diagnostic settings | `PurviewDataSensitivityLogs` | Data discovery / classification scan results |
> | **Microsoft Purview Information Protection (Preview)** | Sentinel Data connectors &rarr; Connect | `MicrosoftPurviewInformationProtection` | Sensitivity-label activity from MIP clients/scanners |

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
- [MITRE Detection Strategies](#mitre-detection-strategies)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)

---

## Overview

Microsoft Purview (Data Map / Governance) is the platform that **scans and classifies** the data estate — Azure SQL, Azure Storage, ADLS, Power BI, AWS S3, on-premises sources, and more — to discover where sensitive information types live (SSN, credit card, PII, custom classifiers) and which sensitivity labels are applied to assets.

The **Microsoft Purview** connector streams these scan results into Sentinel via **Diagnostic settings** on the Purview account, surfacing them in the `PurviewDataSensitivityLogs` table. This answers the question: *"Where does our sensitive data live, and was any of it in the blast radius of this incident?"*

### Setup

Configure on the **Purview account** in the Azure portal:

1. Navigate to your Microsoft Purview account → **Diagnostic settings**
2. **+ Add diagnostic setting**
3. Under **Logs**, select **`DataSensitivityLogEvent`**
4. Under **Destination details**, **Send to Log Analytics workspace** (the workspace enabled for Sentinel)
5. Save, then run a Purview **scan** so events flow

### Licensing

| License | What it unlocks |
|:--------|:----------------|
| **Pay-as-you-go Purview Data Map** | Per-asset metering for scanning Azure, AWS, on-premises sources |
| **Microsoft 365 E5 Compliance** | Includes Purview governance entitlements; complements information protection capabilities |

> [!NOTE]
> `PurviewDataSensitivityLogs` is **not** on Sentinel's [free data sources](https://learn.microsoft.com/azure/sentinel/billing#free-data-sources) list — it incurs standard Log Analytics ingestion cost. Volume depends on how often scans run and how many sources are scanned.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **PurviewDataSensitivityLogs** | Scan results — assets discovered, classifications detected, sensitivity labels applied, source type/region | Analytics: 90d / Lake: 365d | Maps sensitive data locations across the estate — identifies the crown jewels and supports breach impact scoping. MCSB DP-1. | Post-breach data-classification evidence — proves which sensitive information types existed in compromised data stores at the time of an incident, directly informing breach notification scope | Sensitive data type (e.g. credit card, SSN) discovered in storage account not designated for sensitive data |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Sensitive data in unexpected location | PurviewDataSensitivityLogs | [T1074](https://attack.mitre.org/techniques/T1074/) | [DET0014](https://attack.mitre.org/detectionstrategies/DET0014/) — Detection of Data Staging Prior to Exfiltration | Credit card numbers or PII discovered in a storage account, container, or SQL database not designated for sensitive data |
| New high-sensitivity classifier match | PurviewDataSensitivityLogs | — | — | First detection of a custom or high-risk classifier (e.g. trade secrets, source code) — triggers data-owner review |
| Crown jewels touched in incident | PurviewDataSensitivityLogs + StorageBlobLogs / AKSAudit / SigninLogs | [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) — Multi-Platform Cloud Storage Exfiltration Behavior Chain | Correlate compromised resource (from incident) against assets known to contain sensitive data — fast blast-radius answer |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page.

| Technique | Detection Strategy |
|:----------|:-------------------|
| [T1074](https://attack.mitre.org/techniques/T1074/) | [DET0014](https://attack.mitre.org/detectionstrategies/DET0014/) &mdash; Detection of Data Staging Prior to Exfiltration |
| [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) &mdash; Multi-Platform Cloud Storage Exfiltration Behavior Chain |

> [!NOTE]
> This page intentionally omits the third MITRE-evidence column. Purview Data Map identifies data sensitivity and location through service-native metadata, not the raw storage or identity channels cited by MITRE strategies.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **DP-1** Discover, classify, and label sensitive data | Direct mapping — Purview Data Map is the discovery and classification platform |
| **DP-2** Monitor anomalies and threats targeting sensitive data | Classification context enables data-aware detections in correlation with workload telemetry |
| **AM-1** Track asset inventory | Purview asset inventory complements infrastructure inventory with data-store discovery |
| **LT-3** Enable logging for security investigation | Provides the data-classification layer of forensic evidence |

---

## Notes

- Diagnostic logs flow only after a **full scan** is run, or when a **change is detected** during an incremental scan — typically 10–15 minutes after the scan completes
- Highest detection value comes from **correlating** `PurviewDataSensitivityLogs` with workload data-plane logs (e.g. `StorageBlobLogs`, `SigninLogs`, `AKSAudit`) to scope blast radius for breached resources
- Pair with the **Microsoft Purview Information Protection (Preview)** connector for end-to-end coverage: this connector tells you *where* sensitive data lives; the IP connector tells you *what users do* with labelled documents
- Run scans on a cadence that matches data-change frequency — over-scanning increases ingestion cost without proportional detection value

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor `PurviewDataSensitivityLogs` ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Microsoft Purview** | Solution | Data connector + workbook + analytic-rule templates ("Sensitive Data Discovered in the Last 24 Hours") | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Integrate Microsoft Sentinel and Microsoft Purview | Setup guide — Diagnostic settings, workbook, analytic rules | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/purview-solution) |
| PurviewDataSensitivityLogs table reference | Schema reference for the scan-result table | [learn.microsoft.com](https://learn.microsoft.com/azure/azure-monitor/reference/tables/purviewdatasensitivitylogs) |
| Microsoft Sentinel pricing — Free data sources | Authoritative free-data list (Purview tables are not included) | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/billing#free-data-sources) |

### Admin portal

- [Microsoft Purview portal](https://purview.microsoft.com/) — manage the Purview Data Map and review classification/sensitivity activity that flows to Sentinel.
  - Quick links via [cmd.ms](https://cmd.ms/) (see [References §14.6](../references.md#14-admin-portals)): [`pu.cmd.ms`](https://pu.cmd.ms/) (Purview root), [`puudg.cmd.ms`](https://puudg.cmd.ms/) (Unified Data Governance).

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
