# Microsoft Teams (Advanced)

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes — via Office 365 connector (free data source)

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Important Considerations](#important-considerations)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)

---

## Overview

While the Tier 1 Office 365 connector already captures Teams activity through `OfficeActivity`, advanced Teams monitoring focuses on **deeper governance and collaboration security events**: external access patterns, guest user activity, Teams application permissions, meeting policies, and channel configuration changes.

This Tier 3 entry is not a separate connector — it represents **advanced analytics and monitoring** built on top of the existing Office 365 and Defender XDR data. The value comes from purpose-built detection rules that surface Teams-specific risks: data sharing with external organisations, sensitive content in Teams channels, guest access abuse, and communication compliance violations.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **M365 E3/E5** | Teams activity in `OfficeActivity` via Office 365 connector (Tier 1) — free data source |
| **M365 E5** | Teams events in `CloudAppEvents` via Defender XDR connector (Tier 1) — ingestion benefit |
| **Communication Compliance (E5)** | Policy match events for detecting inappropriate or sensitive content in Teams messages |

> [!NOTE]
> No additional connector is needed. Tier 3 Teams monitoring builds on Tier 1 data with advanced analytics rules and workbooks focused on collaboration security.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **OfficeActivity** (Teams workload) | Teams events — channel creation, membership changes, file sharing, external participant activity | Analytics: 90d / Lake: 365d | Already ingested via Tier 1 Office 365 connector — advanced monitoring adds detection rules focused on Teams-specific risks | Reconstructs collaboration activity during a breach — which files were shared, with whom, and through which channels | Sensitive file shared with external guest via Teams (T1567) |
| **CloudAppEvents** (Teams) | Detailed Teams events from Defender XDR — meeting join/leave, chat activity, app interactions | Analytics: 90d / Lake: 365d | Higher-fidelity Teams telemetry from the XDR pipeline — richer event detail than OfficeActivity | Provides granular Teams interaction timeline — who joined which meetings, what app interactions occurred | External user added to private channel with sensitive data (T1199) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| External user added to sensitive team | OfficeActivity, CloudAppEvents | T1199 | Guest or external user added to a team or channel containing sensitive/confidential data |
| Mass file download from Teams | OfficeActivity | T1530 | Single user downloading abnormally large numbers of files from Teams channels |
| Teams app with excessive permissions | CloudAppEvents | T1550.001 | Third-party Teams app granted broad permissions — potential data access vector |
| External sharing of sensitive content | OfficeActivity | T1567 | Files labelled confidential or restricted shared externally through Teams channels |
| Meeting policy changed to allow anonymous join | OfficeActivity | T1562 | Admin action reducing meeting security — allows anonymous participants in corporate meetings |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **DP-2** Monitor anomalies and threats targeting sensitive data | Detects sensitive data sharing through Teams collaboration channels |
| **IM-7** Restrict resource access based on conditions | Monitors external access and guest policies — detects policy violations |

---

## Important Considerations

- **Not a separate connector:** This Tier 3 entry uses data already collected by the Tier 1 Office 365 and Defender XDR connectors
- **Analytics rules required:** The value is in purpose-built detection rules — deploy Teams-specific analytics from Content Hub or build custom rules
- **Teams governance policies:** Pair with Microsoft Teams admin center policies for prevention — Sentinel provides the detection and response layer
- **Guest access baseline:** Establish a baseline of normal external/guest activity to reduce false positives in detection rules

---

## Notes

- Teams has become a primary collaboration and data-sharing channel in most organisations — and a growing attack surface for social engineering and data exfiltration
- Advanced Teams monitoring is most valuable for organisations with significant external collaboration, guest access, or compliance requirements
- Consider pairing with Microsoft Purview (Tier 2) for complete data protection coverage — Purview labels + Teams monitoring

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify Teams event volumes in OfficeActivity/CloudAppEvents | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Office 365 connector for Teams data | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/office-365) |
| Teams security best practices | [Learn](https://learn.microsoft.com/en-us/microsoftteams/security-compliance-overview) |
| Communication compliance | [Learn](https://learn.microsoft.com/en-us/purview/communication-compliance) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
