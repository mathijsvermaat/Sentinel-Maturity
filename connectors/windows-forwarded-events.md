# Windows Forwarded Events (Advanced)

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party (AMA) · **Free ingestion:** No

---

## Contents

- [Windows Forwarded Events (Advanced)](#windows-forwarded-events-advanced)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
  - [Example Detections](#example-detections)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Important Considerations](#important-considerations)
  - [Notes](#notes)
    - [Tools](#tools)
  - [References](#references)

---

## Overview

While the Tier 1 Windows Security Events connector focuses on the **Security event log** (authentication, process creation, group management), advanced Windows monitoring extends collection to other critical event channels: **PowerShell ScriptBlock logging**, **WMI events**, **AppLocker/WDAC enforcement**, **Sysmon**, and **Windows Firewall** events.

These additional event sources are essential for detecting sophisticated attacks that operate beyond the Security log: fileless malware using PowerShell, living-off-the-land (LOTL) techniques through WMI, application control bypass attempts, and advanced persistence mechanisms. Security researchers and red teams consistently identify these channels as the most valuable for threat detection.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Windows server** | Advanced event log collection via Azure Monitor Agent and Data Collection Rules |

> [!NOTE]
> These advanced `WindowsEvent` channels (PowerShell, WMI, AppLocker/WDAC, Sysmon, Windows Firewall) are **not** covered by the Defender for Servers P2 500 MB/day data ingestion benefit. Only the `Microsoft-SecurityEvent` stream that populates the `SecurityEvent` table is eligible — see the list of [eligible tables](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit). Advanced Windows event collection requires **Group Policy configuration** to enable the relevant event channels (PowerShell ScriptBlock, AppLocker, etc.). The data is collected via AMA using the `WindowsEvent` table — not the legacy `SecurityEvent` table.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **WindowsEvent** (PowerShell) | PowerShell ScriptBlock logging (Event ID 4104) — full script content for all executed scripts | Analytics: 90d / Lake: 365d | PowerShell is the most commonly abused tool in modern attacks — ScriptBlock logging captures the actual code executed | Provides the exact malicious script content — the most valuable single event source for investigating fileless attacks | Encoded PowerShell command execution (T1059.001) |
| **WindowsEvent** (WMI) | WMI activity events — WMI subscriptions, queries, and method executions | Analytics: 90d / Lake: 365d | WMI is a primary LOTL technique for persistence, lateral movement, and reconnaissance | Identifies WMI-based persistence mechanisms and remote execution — common in APT tradecraft | WMI event subscription created for persistence (T1546.003) |
| **WindowsEvent** (AppLocker/WDAC) | Application control enforcement events — allowed, blocked, and audit mode events | Analytics: 90d / Lake: 365d | Application control is the strongest preventive control — monitoring enforcement events detects bypass attempts | Proves which applications were blocked or audited — identifies attack attempts against application control | Application blocked by AppLocker but bypassed via alternate binary (T1218) |
| **WindowsEvent** (Sysmon) | Sysmon events — process creation with hashes, network connections, file creation, registry modification | Analytics: 90d / Lake: 365d | Sysmon provides the richest endpoint telemetry for threat detection — process lineage, file hashes, network connections | Complete process tree reconstruction with file hashes — definitive endpoint forensic data | Parent-child process chain indicating Cobalt Strike beacon (T1059.001) |
| **WindowsEvent** (Firewall) | Windows Filtering Platform events — firewall rule changes and blocked connections | Analytics: 30d / Lake: 180d | Detects firewall tampering and blocked connection attempts from malware | Identifies firewall changes made by attackers to enable communication — proves connectivity attempts | Windows Firewall rule disabled or modified (T1562.004) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Base64-encoded PowerShell execution | WindowsEvent (4104) | T1059.001 | PowerShell ScriptBlock containing encoded commands — common obfuscation technique |
| PowerShell download cradle | WindowsEvent (4104) | T1059.001, T1105 | ScriptBlock containing `Invoke-WebRequest`, `Net.WebClient`, or `DownloadString` — payload staging |
| WMI persistence subscription | WindowsEvent (WMI) | T1546.003 | `__EventFilter` and `__EventConsumer` WMI objects created — classic persistence mechanism |
| LOLBAS execution via AppLocker bypass | WindowsEvent (AppLocker) | T1218 | Living-off-the-land binary execution blocked or audited — indicates bypass attempt |
| Sysmon — process injection detected | WindowsEvent (Sysmon 8/10) | T1055 | Sysmon CreateRemoteThread or ProcessAccess events indicating process injection |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection capabilities | Advanced event channels enable detection of sophisticated attacks that bypass Security log-only monitoring |
| **LT-3** Enable logging for security investigation | PowerShell ScriptBlock and Sysmon provide the richest forensic data for endpoint investigations |
| **ES-2** Use modern anti-malware software | AppLocker/WDAC enforcement monitoring validates application control effectiveness |
| **AM-2** Use only approved services | Application control monitoring tracks execution of unapproved software |

---

## Important Considerations

- **Group Policy prerequisites:** PowerShell ScriptBlock logging must be enabled via GPO (`Module Logging` and `Script Block Logging`). AppLocker requires enforcement or audit mode configuration. Sysmon requires separate deployment
- **Sysmon deployment:** Sysmon is highly recommended but requires a custom configuration file. Use community configurations like [SwiftOnSecurity/sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config) or [olafhartong/sysmon-modular](https://github.com/olafhartong/sysmon-modular) as a baseline
- **DCR configuration:** Use separate DCR rules or XPath queries to collect specific event channels. Example XPath: `Microsoft-Windows-PowerShell/Operational!*[System[(EventID=4104)]]`
- **Volume management:** PowerShell ScriptBlock logging can generate significant volume on servers running PowerShell-heavy automation. Filter by event level or use DCR transformations
- **MDE integration:** If Defender for Endpoint (via XDR, Tier 1) is deployed, some of this telemetry overlaps with MDE's `DeviceProcessEvents` and `DeviceFileEvents`. The raw Windows events provide additional detail and longer retention control

---

## Notes

- PowerShell ScriptBlock logging (Event ID 4104) is considered the single most valuable event channel for detecting modern attacks after standard Security events
- Sysmon provides the most comprehensive endpoint telemetry available — but requires deployment and maintenance of the Sysmon agent and configuration
- These advanced channels build directly on the Tier 1 Windows Security Events foundation — deploy Tier 1 first, then extend to Tier 3

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify advanced Windows event log volumes | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |
| [Defender AMA Coverage](../procedures/defender-ama-coverage.md) | Workbook | Validate AMA deployment and DCR coverage for advanced channels | Sentinel Maturity Model | [Procedure guide](../procedures/defender-ama-coverage.md) |

---

## References

| Source | Link |
|:-------|:-----|
| PowerShell ScriptBlock logging | [Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_logging_windows) |
| Sysmon overview | [Learn](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) |
| AppLocker overview | [Learn](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/applocker/applocker-overview) |
| WDAC overview | [Learn](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/wdac) |
| AMA Windows Event collection | [Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-windows-events) |
| Sentinel — Windows agent-based connectors (WEF prerequisite) | [Learn](https://learn.microsoft.com/azure/sentinel/connect-services-windows-based) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
