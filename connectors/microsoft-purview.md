# Microsoft Purview (Information Protection & DLP)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No · **Conditional:** Requires Microsoft Purview licensing

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)

---

## Overview

Microsoft Purview provides data governance, information protection, data loss prevention (DLP), and insider risk management capabilities. The Sentinel connector brings **sensitivity labelling events** and **DLP policy matches** into your SIEM, enabling correlation of data protection events with identity and endpoint telemetry.

This connector addresses the question: *"Was sensitive data involved in this incident?"* — a question that identity and endpoint logs alone cannot answer.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft 365 E5 Compliance** | Full Purview suite — Information Protection, DLP, Insider Risk |
| **Microsoft 365 E5** | Includes E5 Compliance |
| **Microsoft Purview (standalone)** | Information Protection and DLP for specific workloads |

> [!NOTE]
> Purview tables are **not** a free data source. Evaluate whether the detection value justifies the ingestion cost for your environment.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **MicrosoftPurviewInformationProtection** | Sensitivity label application, modification, and removal events — which document, by which user, which label | Analytics: 90d / Lake: 365d | Tracks data classification lifecycle — detects label downgrade (removing protection) and bulk label changes that may indicate data staging for exfiltration. MCSB DP-1. | Proves whether sensitive data was properly labelled at the time of a breach — answers "was confidential data involved?" in incident investigations. Also proves intentional label downgrade as evidence of insider threat. | Sensitivity label downgraded from Confidential → Public on multiple files (T1565) |
| **PurviewDataSensitivityLogs** | Data sensitivity scan results — which data stores contain sensitive information types (SSN, credit card, etc.) | Analytics: 90d / Lake: 365d | Maps sensitive data locations across the estate — identifies crown jewels. | Post-breach data classification — proves which sensitive information types existed in compromised data stores, directly informing breach notification requirements | Sensitive data type discovered in compromised storage account |

> [!NOTE]
> DLP policy matches for Exchange, SharePoint, OneDrive, Teams, and endpoints may appear in `OfficeActivity` (Tier 1) or in dedicated Purview tables depending on configuration. Verify your DLP alert routing.

---

## Example Detections

### Data Protection

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Bulk sensitivity label downgrade | MicrosoftPurviewInformationProtection | T1565 | User downgrading labels on many documents in a short timeframe — potential data staging |
| Sensitivity label removal | MicrosoftPurviewInformationProtection | T1565 | Removal of protection labels — may indicate preparation for exfiltration |
| Sensitive data in unexpected location | PurviewDataSensitivityLogs | T1074 | Credit card numbers or PII discovered in a storage account not designated for sensitive data |

### Insider Threat Correlation

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Label downgrade + mass download | MicrosoftPurviewInformationProtection + CloudAppEvents | T1530 | User downgrades labels then downloads the same files — strong insider threat indicator |
| DLP policy match + external email | OfficeActivity + EmailEvents | T1048.003 | DLP detected sensitive content + the same user sent external email with attachments |

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

- Purview tables incur ingestion cost — start with `MicrosoftPurviewInformationProtection` for label tracking and evaluate `PurviewDataSensitivityLogs` based on your data classification maturity
- Purview DLP alerts can also be routed to Defender XDR, where they appear as alerts in the `AlertInfo` table (Tier 1) — this may reduce the need for direct Purview table ingestion
- The highest detection value comes from **correlating** Purview events with identity and endpoint tables — label downgrade + mass download + unusual sign-in = strong insider threat signal
- Ensure your organisation has a deployed **sensitivity label taxonomy** before enabling this connector — without labels applied, the tables will be sparse

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor Purview table ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Microsoft Purview Information Protection** | Solution | Provides the Purview Information Protection connector for DLP and sensitivity label events | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect Microsoft Purview Information Protection to Microsoft Sentinel | Connector setup guide — DLP alerts, sensitivity labels, and data governance events | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-purview-information-protection) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Microsoft Purview Information Protection connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftpurviewinformationprotection.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — data repositories are Enterprise Networks priority #8 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
