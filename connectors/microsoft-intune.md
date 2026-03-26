# Microsoft Intune (Endpoint Management)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** Partial — IntuneAuditLogs and IntuneOperationalLogs are free; IntuneDevices incurs cost

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

Microsoft Intune is the cloud endpoint management platform for Windows, macOS, iOS, and Android devices. The Sentinel connector provides **device compliance state**, **configuration change auditing**, and **operational events** — answering the question *"was the device that was used in this incident managed and compliant?"*.

This connector bridges endpoint **management** (Intune) with endpoint **detection** (Defender XDR) — Defender tells you what happened; Intune tells you whether the device was in a healthy, compliant state when it happened.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft Intune Plan 1** (included in M365 E3/E5) | Device management, compliance policies, configuration profiles, audit logs |
| **Microsoft Intune Plan 2 / Suite** | Advanced features — Tunnel, Endpoint Privilege Management, remote actions |

> [!NOTE]
> `IntuneAuditLogs` and `IntuneOperationalLogs` are **free data sources** in Sentinel. `IntuneDevices` incurs standard ingestion cost.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **IntuneAuditLogs** | Administrative actions — policy changes, app deployments, role assignments, remote actions (wipe, lock, retire) | Analytics: 90d / Lake: 365d | Detects unauthorized configuration changes, rogue admin activity, and policy tampering. MCSB AM-1, PA-7. | Audit trail of all Intune administrative actions — proves who changed which policy, deployed which app, or triggered which remote action. Essential for investigating supply chain and admin compromise. | Compliance policy disabled by compromised admin account (T1562.001) |
| **IntuneOperationalLogs** | Device check-in, enrollment, compliance evaluation, policy application results | Analytics: 90d / Lake: 365d | Tracks device lifecycle events and compliance drift — detects devices falling out of compliance. | Proves device compliance state at the time of an incident — was the device encrypted? Was the OS up to date? Were security policies applied? | Device compliance failure correlating with security incident |
| **IntuneDevices** | Device inventory — device name, OS, ownership (corporate/personal), compliance state, last check-in | Analytics: 90d / Lake: 365d | Asset inventory enrichment — correlate incidents with device properties and compliance state. MCSB AM-1. | Historical device inventory — proves which devices were managed, their compliance state, and ownership type at any point during an investigation | Unmanaged device accessing corporate resources |

---

## Example Detections

### Endpoint Management

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Compliance policy disabled | IntuneAuditLogs | T1562.001 | Admin disabling a compliance policy — may indicate compromised admin credentials |
| Bulk remote wipe triggered | IntuneAuditLogs | T1485 | Mass remote wipe actions across multiple devices — destructive action |
| Privileged Intune role assigned | IntuneAuditLogs | T1098 | New user added to Intune Administrator or similar privileged role |
| Device compliance drift | IntuneOperationalLogs | — | Devices moving from compliant to non-compliant — encryption disabled, OS outdated |
| Stale device accessing resources | IntuneDevices + SigninLogs | T1078 | Device not checked in for 90+ days but still authenticating to resources |

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

- `IntuneAuditLogs` and `IntuneOperationalLogs` are free — enable them by default
- The primary detection value is in **correlating** Intune compliance state with security incidents — an incident on a non-compliant, unencrypted device has different risk implications than one on a fully compliant device
- For mobile device (iOS/Android) visibility, Intune logs are the primary source — Defender XDR endpoint tables primarily cover Windows/macOS
- Consider creating **compliance-based watchlists** from `IntuneDevices` to flag non-compliant devices in other detection rules

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor Intune table ingestion volumes | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

Community and third-party resources that support the guidance on this page.

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — MDM/MAM events are Enterprise Mobility priority #7 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
