# Microsoft Purview Information Protection (Preview)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party (Office Management API) · **Free ingestion:** No · **Status:** Preview

> [!IMPORTANT]
> This is the **Microsoft Purview Information Protection (Preview)** connector. It is a **different connector** than [Microsoft Purview (Data Map / Discovery)](microsoft-purview-data-map.md). It also **replaces the retired Azure Information Protection (AIP) connector** — do not enable both. Enable both *Purview* connectors for full data-protection coverage:
>
> | Connector | Source | Table | What it covers |
> |:----------|:-------|:------|:---------------|
> | **Microsoft Purview Information Protection (Preview)** *(this page)* | Sentinel Data connectors &rarr; Connect | `MicrosoftPurviewInformationProtection` | Sensitivity-label activity from MIP clients/scanners |
> | **Microsoft Purview** | Purview Data Map account &rarr; Diagnostic settings | `PurviewDataSensitivityLogs` | Data discovery / classification scan results |

---

## Contents

- [Microsoft Purview Information Protection (Preview)](#microsoft-purview-information-protection-preview)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Setup](#setup)
    - [Licensing](#licensing)
  - [Tables and Rationale](#tables-and-rationale)
  - [Example Detections](#example-detections)
    - [Data Protection](#data-protection)
    - [Insider Threat Correlation](#insider-threat-correlation)
  - [MITRE Detection Strategies](#mitre-detection-strategies)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Notes](#notes)
  - [Tools](#tools)
  - [References](#references)
    - [Official Documentation](#official-documentation)
    - [Community \& Third-Party Resources](#community--third-party-resources)

---

## Overview

Microsoft Purview Information Protection extends Microsoft Information Protection (MIP) sensitivity labelling and protection across documents, emails, files, and SaaS workloads. The **Microsoft Purview Information Protection (Preview)** Sentinel connector brings **sensitivity-label activity** from **MIP labelling clients and scanners** (Office, Information Protection client, Purview unified labelling scanner, MIP SDK apps) into your SIEM via the **Office Management API**, surfacing them in the `MicrosoftPurviewInformationProtection` table.

This connector addresses the question: *"Was sensitive data involved in this incident?"* — a question that identity and endpoint logs alone cannot answer.

> [!IMPORTANT]
> This connector **replaces the retired Azure Information Protection (AIP) connector**. If you previously ingested `InformationProtectionLogs_CL`, migrate detections to `MicrosoftPurviewInformationProtection` and disable the AIP connector to avoid duplicate ingestion.

### Setup

Enable from the **Sentinel Data connectors** page:

1. Microsoft Sentinel → Configuration → **Data connectors**
2. Search **Microsoft Purview Information Protection (Preview)** → **Open connector page**
3. Click **Connect** (requires *Microsoft Sentinel Contributor* on the workspace and *Global Reader* / appropriate Office permissions on the tenant)
4. Apply (or wait for) sensitivity labels from MIP clients so events flow

### Licensing

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft 365 E5 Compliance** | Full Purview suite — Information Protection, DLP, Insider Risk |
| **Microsoft 365 E5** | Includes E5 Compliance |
| **Microsoft 365 E7** | Includes E5 Compliance |
| **Microsoft Purview Information Protection (standalone)** | Information Protection labelling and protection |

> [!NOTE]
> `MicrosoftPurviewInformationProtection` is **not** on Sentinel's [free data sources](https://learn.microsoft.com/azure/sentinel/billing#free-data-sources) list — it incurs standard Log Analytics ingestion cost. Evaluate whether the detection value justifies the ingestion cost for your environment.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **MicrosoftPurviewInformationProtection** | Sensitivity label application, modification, and removal events from MIP clients/scanners — which document, by which user, which label | Analytics: 90d / Lake: 365d | Tracks data classification lifecycle — detects label downgrade (removing protection) and bulk label changes that may indicate data staging for exfiltration. MCSB DP-1. | Proves whether sensitive data was properly labelled at the time of a breach — answers "was confidential data involved?" in incident investigations. Also proves intentional label downgrade as evidence of insider threat. | Sensitivity label downgraded from Confidential → Public on multiple files (T1565) |

> [!NOTE]
> DLP policy matches for Exchange, SharePoint, OneDrive, Teams, and endpoints appear in `OfficeActivity` (Tier 1) or are surfaced as Defender XDR alerts in the `AlertInfo` table (Tier 1) — they are **not** in `MicrosoftPurviewInformationProtection`. Verify your DLP alert routing.

---

## Example Detections

### Data Protection

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Bulk sensitivity label downgrade | MicrosoftPurviewInformationProtection | [T1565](https://attack.mitre.org/techniques/T1565/) | [DET0059](https://attack.mitre.org/detectionstrategies/DET0059/) — Detection Strategy for Data Manipulation | User downgrading labels on many documents in a short timeframe — potential data staging |
| Sensitivity label removal | MicrosoftPurviewInformationProtection | [T1565](https://attack.mitre.org/techniques/T1565/) | [DET0059](https://attack.mitre.org/detectionstrategies/DET0059/) — Detection Strategy for Data Manipulation | Removal of protection labels — may indicate preparation for exfiltration |
| First-time labelling failure spike | MicrosoftPurviewInformationProtection | — | — | Spike in label-apply failures may indicate client-side tampering or policy misconfiguration |

### Insider Threat Correlation

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Label downgrade + mass download | MicrosoftPurviewInformationProtection + CloudAppEvents | [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) — Multi-Platform Cloud Storage Exfiltration Behavior Chain | User downgrades labels then downloads the same files — strong insider threat indicator |
| DLP policy match + external email | OfficeActivity + EmailEvents | [T1048.003](https://attack.mitre.org/techniques/T1048/003/) | [DET0149](https://attack.mitre.org/detectionstrategies/DET0149/) — Detection of Exfiltration Over Unencrypted Non-C2 Protocol | DLP detected sensitive content + the same user sent external email with attachments |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page.

| Technique | Detection Strategy |
|:----------|:-------------------|
| [T1565](https://attack.mitre.org/techniques/T1565/) | [DET0059](https://attack.mitre.org/detectionstrategies/DET0059/) &mdash; Detection Strategy for Data Manipulation |
| [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) &mdash; Multi-Platform Cloud Storage Exfiltration Behavior Chain |
| [T1048.003](https://attack.mitre.org/techniques/T1048/003/) | [DET0149](https://attack.mitre.org/detectionstrategies/DET0149/) &mdash; Detection of Exfiltration Over Unencrypted Non-C2 Protocol |

> [!NOTE]
> This page intentionally omits the third MITRE-evidence column. Purview Information Protection surfaces label lifecycle events through service-native telemetry, not the raw mail, endpoint, or file-system channels MITRE strategies may cite.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **DP-1** Discover, classify, and label sensitive data | Purview is the primary data classification platform — logs track classification lifecycle |
| **DP-2** Monitor anomalies and threats that target sensitive data | DLP and sensitivity events detect abnormal data handling patterns |
| **LT-3** Enable logging for security investigation | Purview logs provide the data protection layer of forensic evidence |
| **IR-4** Detection and analysis | Correlating data sensitivity with identity/endpoint events enriches incident triage |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 SC-28 (data-at-rest protection) and SI-4 (system monitoring), CIS Controls v8 3.1 (data classification) and 3.14 (DLP), and ASD ACSC enterprise network logging priority #1 (critical data holdings) and #8 (data repositories).

---

## Notes

- This connector is in **Preview** — schema and behaviour may change. Validate KQL detections after Microsoft schema updates
- This connector **replaces the retired Azure Information Protection (AIP) connector**. Disable AIP if previously enabled to avoid duplicate ingestion in `InformationProtectionLogs_CL`
- DLP policy matches are **not** in this table — they appear in `OfficeActivity` (Tier 1) or as Defender XDR alerts in `AlertInfo` (Tier 1). Plan your DLP alert routing accordingly
- Pair with the **Microsoft Purview (Data Map / Discovery)** connector for end-to-end coverage: that connector tells you *where* sensitive data lives; this connector tells you *what users do* with labelled documents
- The highest detection value comes from **correlating** Purview IP events with identity and endpoint tables — label downgrade + mass download + unusual sign-in = strong insider threat signal
- Ensure your organisation has a deployed **sensitivity label taxonomy** before enabling this connector — without labels applied, the table will be sparse

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor Purview table ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Microsoft Purview Information Protection** | Solution | Data connector + workbook + analytic-rule templates for sensitivity-label events | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect Microsoft Purview Information Protection to Microsoft Sentinel | Connector setup guide — sensitivity-label activity from MIP clients and scanners | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/connect-microsoft-purview) |
| MicrosoftPurviewInformationProtection table reference | Schema reference for the sensitivity-label events table | [learn.microsoft.com](https://learn.microsoft.com/azure/azure-monitor/reference/tables/microsoftpurviewinformationprotection) |
| Microsoft Purview with Microsoft Sentinel data lake | Overview of the modern Purview ↔ Sentinel integration — data lake onboarding, data risk graph for Insider Risk Management, and per-solution prerequisites | [learn.microsoft.com](https://learn.microsoft.com/purview/purview-sentinel) |

### Admin portal

- [Microsoft Purview portal](https://purview.microsoft.com/) — manage Information Protection labels, DLP policies, and review activity that flows to Sentinel.
  - Quick links via [cmd.ms](https://cmd.ms/) (see [References §14.6](../references.md#14-admin-portals)): [`pu.cmd.ms`](https://pu.cmd.ms/) (Purview root), [`puinfoprot.cmd.ms`](https://puinfoprot.cmd.ms/) (Information Protection), [`pudlp.cmd.ms`](https://pudlp.cmd.ms/) (Data Loss Prevention), [`puactexp.cmd.ms`](https://puactexp.cmd.ms/) (Activity Explorer).

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Microsoft Purview Information Protection connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftpurviewinformationprotection.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — data repositories are Enterprise Networks priority #8 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
