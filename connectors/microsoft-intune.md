# Microsoft Intune (Endpoint Management)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No — Intune tables are billed at standard Log Analytics ingestion rates

> [!IMPORTANT]
> **Microsoft Intune is not a Sentinel data connector.** It does not appear in **Content Hub** or under **Data connectors** in the Sentinel/Defender portal. Intune log ingestion is configured directly from the **Intune admin center → Reports → Diagnostics settings**, sending logs to your Log Analytics workspace. Detections that use Intune tables come from generic or cross-solution analytic-rule templates rather than a dedicated Intune solution.

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

Microsoft Intune is the cloud endpoint management platform for Windows, macOS, iOS, and Android devices. The Sentinel connector provides **device compliance state**, **configuration change auditing**, and **operational events** — answering the question *"was the device that was used in this incident managed and compliant?"*.

This connector bridges endpoint **management** (Intune) with endpoint **detection** (Defender XDR) — Defender tells you what happened; Intune tells you whether the device was in a healthy, compliant state when it happened.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft Intune Plan 1** (included in M365 E3/E5) | Device management, compliance policies, configuration profiles, audit logs |
| **Microsoft Intune Plan 2 / Suite** | Advanced features — Tunnel, Endpoint Privilege Management, remote actions |

> [!NOTE]
> Intune tables are **not** on Sentinel's [free data sources](https://learn.microsoft.com/azure/sentinel/billing#free-data-sources) list — all four (`IntuneAuditLogs`, `IntuneOperationalLogs`, `IntuneDevices`, `IntuneDeviceComplianceOrg`) are billed at standard Log Analytics ingestion rates. Use DCR transformations and Microsoft Sentinel data lake (Auxiliary / Total retention) tiers to manage volume on `IntuneOperationalLogs` and `IntuneDevices`, which are typically the highest-volume tables.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **IntuneAuditLogs** | Administrative actions — policy changes, app deployments, role assignments, remote actions (wipe, lock, retire) | Analytics: 90d / Lake: 365d | Detects unauthorized configuration changes, rogue admin activity, and policy tampering. MCSB AM-1, PA-7. | Audit trail of all Intune administrative actions — proves who changed which policy, deployed which app, or triggered which remote action. Essential for investigating supply chain and admin compromise. | Compliance policy disabled by compromised admin account (T1562.001) |
| **IntuneOperationalLogs** | Device check-in, enrollment, compliance evaluation, policy application results | Analytics: 90d / Lake: 365d | Tracks device lifecycle events and compliance drift — detects devices falling out of compliance. | Proves device compliance state at the time of an incident — was the device encrypted? Was the OS up to date? Were security policies applied? | Device compliance failure correlating with security incident |
| **IntuneDevices** | Device inventory — device name, OS, ownership (corporate/personal), compliance state, last check-in | Analytics: 90d / Lake: 365d | Asset inventory enrichment — correlate incidents with device properties and compliance state. MCSB AM-1. | Historical device inventory — proves which devices were managed, their compliance state, and ownership type at any point during an investigation | Unmanaged device accessing corporate resources |
| **IntuneDeviceComplianceOrg** | Organisational device-compliance reporting — per-policy and per-setting compliance state across the tenant | Analytics: 90d / Lake: 365d | Tenant-wide compliance posture reporting — surfaces non-compliant devices and the specific policy/setting causing failure. MCSB ES-1. | Identifies which compliance policy or setting was failing on a device at the time of an incident; supports systemic posture trending | Sustained drop in tenant compliance rate after a policy change |

---

## Example Detections

### Endpoint Management

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Compliance policy disabled | IntuneAuditLogs | [T1562.001](https://attack.mitre.org/techniques/T1562/001/) | — *(no published strategy)* | Admin disabling a compliance policy — may indicate compromised admin credentials |
| Bulk remote wipe triggered | IntuneAuditLogs | [T1485](https://attack.mitre.org/techniques/T1485/) | [DET0146](https://attack.mitre.org/detectionstrategies/DET0146/) — Detection of Data Destruction Across Platforms via Mass Overwrite and Deletion Patterns | Mass remote wipe actions across multiple devices — destructive action |
| Privileged Intune role assigned | IntuneAuditLogs | [T1098](https://attack.mitre.org/techniques/T1098/) | [DET0096](https://attack.mitre.org/detectionstrategies/DET0096/) — Account Manipulation Behavior Chain Detection | New user added to Intune Administrator or similar privileged role |
| Device compliance drift | IntuneOperationalLogs | — | — | Devices moving from compliant to non-compliant — encryption disabled, OS outdated |
| Stale device accessing resources | IntuneDevices + SigninLogs | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Detection of Valid Account Abuse Across Platforms | Device not checked in for 90+ days but still authenticating to resources |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page.

| Technique | Detection Strategy |
|:----------|:-------------------|
| [T1562.001](https://attack.mitre.org/techniques/T1562/001/) | — *(no published strategy)* |
| [T1485](https://attack.mitre.org/techniques/T1485/) | [DET0146](https://attack.mitre.org/detectionstrategies/DET0146/) &mdash; Detection of Data Destruction Across Platforms via Mass Overwrite and Deletion Patterns |
| [T1098](https://attack.mitre.org/techniques/T1098/) | [DET0096](https://attack.mitre.org/detectionstrategies/DET0096/) &mdash; Account Manipulation Behavior Chain Detection |
| [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) &mdash; Detection of Valid Account Abuse Across Platforms |

> [!NOTE]
> This page intentionally omits the third MITRE-evidence column. Intune exposes administrative and device state changes through normalized audit and operational tables, not the raw endpoint or identity channels MITRE strategies may reference.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **AM-1** Track asset inventory | IntuneDevices provides cloud-managed device inventory |
| **ES-1** Use endpoint detection and response | Intune compliance policies enforce EDR deployment status |
| **PA-7** Follow just enough administration | Audit logs track Intune administrative role usage and delegation |
| **GS-3** Align roles and responsibilities | Administrative action audit trail supports governance |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 CM-8 (system component inventory) and CM-3 (configuration change control), CIS Controls v8 1.1 (enterprise asset inventory) and 4.1 (secure configuration), and ASD ACSC enterprise mobility logging priority #3 (device security posture) and #7 (MDM/MAM events).

---

## Notes

- All Intune tables incur standard Log Analytics ingestion cost — plan volume carefully and consider DCR transformations or lake-only ingestion for `IntuneOperationalLogs` and `IntuneDevices`
- The primary detection value is in **correlating** Intune compliance state with security incidents — an incident on a non-compliant, unencrypted device has different risk implications than one on a fully compliant device
- For mobile device (iOS/Android) visibility, Intune logs are the primary source — Defender XDR endpoint tables primarily cover Windows/macOS
- Consider creating **compliance-based watchlists** from `IntuneDevices` to flag non-compliant devices in other detection rules

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor Intune table ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Microsoft Defender XDR** | Solution | Endpoint detection signals — correlate Defender XDR endpoint alerts with Intune compliance/inventory state for richer device-context investigations | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Send Intune log data to Azure Storage, Event Hubs, or Log Analytics | Setup guide for routing Intune audit, operational, device, and compliance logs to Log Analytics via Intune Diagnostics settings | [learn.microsoft.com](https://learn.microsoft.com/intune/intune-service/fundamentals/review-logs-using-azure-monitor) |
| Microsoft Sentinel pricing — Free data sources | Authoritative list of Sentinel free data sources (Intune tables are not included) | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/billing#free-data-sources) |

### Admin portal

- [Microsoft Intune admin centre](https://intune.microsoft.com/) — configure Intune diagnostic settings (`Tenant administration → Diagnostic settings`) to send audit / operational / device / compliance logs to Log Analytics.
  - Quick links via [cmd.ms](https://cmd.ms/) (see [References §14.6](../references.md#14-admin-portals)): [`in.cmd.ms`](https://in.cmd.ms/) (Intune root), [`indevices.cmd.ms`](https://indevices.cmd.ms/) (Devices), [`intenant.cmd.ms`](https://intenant.cmd.ms/) (Tenant admin).

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Solutions Docs | Ofer Shezaf (Microsoft) | Comprehensive auto-generated reference for all Sentinel solutions, connectors, and tables | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/README.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — MDM/MAM events are Enterprise Mobility priority #7 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
