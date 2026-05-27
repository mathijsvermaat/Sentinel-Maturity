# Microsoft Defender for Cloud Apps (Standalone)

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party · **Free ingestion:** No

---

## Contents

- [Microsoft Defender for Cloud Apps (Standalone)](#microsoft-defender-for-cloud-apps-standalone)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
  - [Example Detections](#example-detections)
  - [MITRE Detection Strategies](#mitre-detection-strategies)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Important Considerations](#important-considerations)
  - [Notes](#notes)
    - [Tools](#tools)
  - [References](#references)

---

## Overview

Microsoft Defender for Cloud Apps (MDCA) — formerly Cloud App Security — is Microsoft's CASB (Cloud Access Security Broker). While the Tier 1 Defender XDR connector already ingests `CloudAppEvents` for M365 E5 customers, the **standalone MDCA connector** provides additional telemetry not included in the XDR advanced hunting tables: shadow IT discovery, app governance alerts, and CASB policy matches.

This connector is most valuable for organisations that need visibility into unsanctioned cloud application usage (shadow IT), want to enforce DLP policies across SaaS applications, or need to monitor OAuth app consent and governance.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **M365 E5 / E5 Security** | Full MDCA capability including Cloud Discovery, session policies, and app governance |
| **MDCA standalone license** | Available as add-on for E3 customers — full CASB without E5 bundle |

> [!NOTE]
> `CloudAppEvents` from the XDR connector (Tier 1) covers M365 app activity. This standalone connector adds **Cloud Discovery logs** (shadow IT), **CASB governance alerts**, and **app governance signals** that are not available through XDR advanced hunting.

> [!NOTE]
> The Microsoft Defender for Cloud Apps → Microsoft Sentinel integration is currently labelled **(Preview)** by Microsoft. See the [Microsoft Sentinel integration (Preview)](https://learn.microsoft.com/defender-cloud-apps/siem-sentinel) Learn page. This is distinct from the generic **MDCA SIEM agent** (CEF forwarder for third-party SIEMs), which is being retired in November 2025 — the Sentinel integration remains supported.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **McasShadowItReporting** | Cloud Discovery logs — unsanctioned SaaS applications, traffic volume per app, user counts | Analytics: 90d / Lake: 365d | Identifies cloud applications being used without IT approval — data exfiltration vector through unsanctioned file sharing and collaboration apps. Supports ingestion-time DCR and Lake-only ingestion — consider Lake-only for high-volume shadow IT data. | Proves which unsanctioned applications were in use during a breach — establishes data exfiltration paths through shadow IT | High-volume uploads to unsanctioned file-sharing service (T1567) |
| **SecurityAlert** (MDCA) | CASB alerts — impossible travel, mass download, suspicious OAuth consent, anomalous activity | Analytics: 90d / Lake: 365d | Threat detection for SaaS application abuse — complements XDR alerts with CASB-specific detections | Details the specific CASB policy violation or anomaly detected — supports SaaS compromise investigation | Mass download from SharePoint by compromised account (T1530) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Shadow IT — high-risk app usage | McasShadowItReporting | [T1567](https://attack.mitre.org/techniques/T1567/) | [DET0548](https://attack.mitre.org/detectionstrategies/DET0548/) — Detection Strategy for Exfiltration Over Web Service | Users uploading data to unsanctioned, high-risk cloud storage or file-sharing applications |
| Mass download from SaaS | SecurityAlert (MDCA) | [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) — Multi-Platform Cloud Storage Exfiltration Behavior Chain | Single user downloading abnormal volumes of data from corporate SaaS applications |
| Suspicious OAuth app consent | SecurityAlert (MDCA) | [T1550.001](https://attack.mitre.org/techniques/T1550/001/) | [DET0185](https://attack.mitre.org/detectionstrategies/DET0185/) — Behavioral Detection Strategy for Use Alternate Authentication Material: Application Access Token (T1550.001) | OAuth application granted excessive permissions — potential consent phishing or malicious app |
| Impossible travel for SaaS access | SecurityAlert (MDCA) | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Detection of Valid Account Abuse Across Platforms | User accessing cloud apps from geographically impossible locations in a short timeframe |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page.

| Technique | Detection Strategy |
|:----------|:-------------------|
| [T1567](https://attack.mitre.org/techniques/T1567/) | [DET0548](https://attack.mitre.org/detectionstrategies/DET0548/) &mdash; Detection Strategy for Exfiltration Over Web Service |
| [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) &mdash; Multi-Platform Cloud Storage Exfiltration Behavior Chain |
| [T1550.001](https://attack.mitre.org/techniques/T1550/001/) | [DET0185](https://attack.mitre.org/detectionstrategies/DET0185/) &mdash; Behavioral Detection Strategy for Use Alternate Authentication Material: Application Access Token (T1550.001) |
| [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) &mdash; Detection of Valid Account Abuse Across Platforms |

> [!NOTE]
> This page intentionally omits the third MITRE-evidence column. Defender for Cloud Apps surfaces normalized CASB alerts and shadow IT telemetry, not the raw SaaS audit channels that MITRE strategies may reference.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **DP-2** Monitor anomalies and threats targeting sensitive data | Shadow IT discovery identifies unmonitored data flows to unsanctioned applications |
| **IM-1** Use centralized identity and authentication system | OAuth app governance monitors the health of application consent and delegated permissions |
| **NS-7** Simplify network security configuration | Cloud Discovery maps all SaaS traffic — identifies apps that should be blocked or routed through approved channels |

---

## Important Considerations

- **Overlap with XDR connector:** If you already have the Tier 1 XDR connector with `CloudAppEvents`, the standalone MDCA connector adds *Cloud Discovery* and *app governance* data — not a duplicate of CloudAppEvents
- **Cloud Discovery data sources:** Shadow IT discovery requires either a firewall/proxy log upload, Microsoft Defender for Endpoint integration, or Secure Web Gateway (Global Secure Access) integration
- **Volume:** Cloud Discovery logs can be high-volume in large organisations with diverse SaaS usage

---

## Notes

- Shadow IT discovery is one of the most overlooked security capabilities — many breaches involve data exfiltration through unsanctioned cloud services
- Consider pairing with Microsoft Purview (Tier 2) for a complete data protection view — Purview tracks labelled data, MDCA tracks where data flows
- App governance signals help detect supply chain attacks through malicious OAuth applications

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify MDCA table volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Microsoft Defender for Cloud Apps overview | [Learn](https://learn.microsoft.com/en-us/defender-cloud-apps/what-is-defender-for-cloud-apps) |
| Cloud Discovery overview | [Learn](https://learn.microsoft.com/en-us/defender-cloud-apps/set-up-cloud-discovery) |
| Connect MDCA to Sentinel | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-defender-for-cloud-apps) |
| Microsoft Sentinel integration (Preview) | [Learn](https://learn.microsoft.com/defender-cloud-apps/siem-sentinel) |
| App governance in MDCA | [Learn](https://learn.microsoft.com/en-us/defender-cloud-apps/app-governance-manage-app-governance) |
| Microsoft Sentinel tables and associated connectors | [Learn](https://learn.microsoft.com/azure/sentinel/sentinel-tables-connectors-reference) |
| McasShadowItReporting table schema | [Learn](https://learn.microsoft.com/azure/azure-monitor/reference/tables/mcasshadowitreporting) |

---

### Admin portal

- [Microsoft Defender portal](https://security.microsoft.com/) — manage Defender for Cloud Apps policies, app governance, and review activity that flows to Sentinel.
  - Quick links via [cmd.ms](https://cmd.ms/) (see [References §14.6](../references.md#14-admin-portals)): [`deca.cmd.ms`](https://deca.cmd.ms/) (Defender for Cloud Apps), [`decacat.cmd.ms`](https://decacat.cmd.ms/) (Cloud app catalog), [`decaoauth.cmd.ms`](https://decaoauth.cmd.ms/) (OAuth apps).

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
