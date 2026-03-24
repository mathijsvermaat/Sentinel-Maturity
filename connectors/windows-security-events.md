# Windows Security Events / Windows Events

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party (AMA) · **Free ingestion:** 500 MB/day per server (Defender for Servers P2)

---

## Overview

Windows Security Events are the **foundational telemetry for server-side forensics and detection**. They capture authentication events, process execution, privilege use, account management, and security policy changes directly from the Windows event log. For servers that are onboarded to Microsoft Defender for Endpoint (via Defender for Servers P2), these events complement the richer MDE telemetry with the authoritative Windows audit trail.

There are two approaches to collecting these events:

| Method | Agent | Table | Status |
|:-------|:------|:------|:-------|
| **Windows Security Events via AMA** | Azure Monitor Agent (AMA) | `SecurityEvent` | **Recommended** |
| **Windows Events via AMA** (custom DCR) | Azure Monitor Agent (AMA) | `WindowsEvent` | Alternative — normalized schema |
| Legacy (MMA) | Log Analytics Agent (MMA) | `SecurityEvent` | **Deprecated — migrate to AMA** |

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **[Defender for Servers P2](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit)** | [500 MB/day free ingestion per server](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) (covers Security Events, Syslog, and other security data types) |
| **Defender for Servers P1** | MDE on servers, but no free data ingestion for Sentinel |
| **No Defender for Servers** | Full ingestion cost — still recommended for critical servers |

> [!NOTE]
> The **500 MB/day free allowance** from Defender for Servers P2 typically covers Windows Security Events for most servers. This is one of the key cost arguments for deploying Defender for Servers P2.

---

## Tables and Rationale

### SecurityEvent Table (Recommended)

The events to collect depend on your chosen Data Collection Rule (DCR) preset:

| Preset | Events | Volume | Use case |
|:-------|:-------|:-------|:---------|
| **Minimal** | Very limited (account logon, logoff) | Very Low | Not recommended — insufficient for detection |
| **Common** | Most security-relevant events | Medium | **Recommended starting point** for Tier 1 |
| **All Events** | Every Security event | High | Full forensic coverage — use with Defender for Servers P2 to manage cost |
| **Custom** | Your specific event IDs | Variable | Optimise for your detection needs |

### Key Event IDs and Rationale

#### Authentication Events

| Event ID | Description | Retention Recommendation | Rationale | Example Detection |
|:---------|:------------|:------------------------|:----------|:------------------|
| **4624** | Successful logon | Analytics: 90d / Lake: 365d | Core authentication forensics. Identifies who logged on, from where, and using which logon type. MCSB IM-1. Essential for lateral movement tracking (Type 3 = network, Type 10 = RDP). | Lateral movement via network logon (Type 3) from unexpected source (T1021) |
| **4625** | Failed logon | Analytics: 90d / Lake: 365d | Brute-force and password spray detection. MCSB IM-1. High volume of failures from a single source indicates an attack. | RDP brute-force — high volume failed Type 10 logons (T1110) |
| **4648** | Logon with explicit credentials | Analytics: 90d / Lake: 365d | Detects credential-based lateral movement (runas, PsExec). An attacker using stolen credentials on a compromised host generates this event. | Explicit credential use for lateral movement via PsExec (T1021.002) |
| **4672** | Special privileges assigned to logon | Analytics: 90d / Lake: 365d | Tracks every logon that receives administrative privileges. Critical for monitoring admin activity and detecting privilege abuse. | Admin logon from unexpected source or at unusual time |
| **4634 / 4647** | Logoff / User-initiated logoff | Analytics: 90d / Lake: 365d | Session duration tracking — helps scope attacker activity windows. | Session duration analysis during incident response |

#### Account Management Events

| Event ID | Description | Retention Recommendation | Rationale | Example Detection |
|:---------|:------------|:------------------------|:----------|:------------------|
| **4720** | User account created | Analytics: 90d / Lake: 365d | Detects persistence via new local accounts. MCSB PA-1. Also relevant for MITRE T1136.001 (Create Account: Local). | New local account created and added to Administrators (T1136.001) |
| **4726** | User account deleted | Analytics: 90d / Lake: 365d | May indicate an attacker covering tracks by deleting created accounts. | Account deletion shortly after suspicious activity |
| **4728 / 4732 / 4756** | Member added to security-enabled group | Analytics: 90d / Lake: 365d | Privilege escalation via group membership. Tracks additions to local Administrators and other privileged groups. MCSB PA-1. | User added to local Administrators or Domain Admins (T1098) |
| **4724 / 4723** | Password reset / Password change | Analytics: 90d / Lake: 365d | Unauthorized password resets may indicate account takeover. | Password reset on privileged account from unexpected source |

#### Process and Policy Events

| Event ID | Description | Retention Recommendation | Rationale | Example Detection |
|:---------|:------------|:------------------------|:----------|:------------------|
| **4688** | Process creation (with command line) | Analytics: 90d / Lake: 365d | **High-value forensic event.** Captures command-line arguments for every process. MCSB LT-3. Covers MITRE Execution, Defence Evasion, Discovery. Requires "Include command line in process creation events" GPO to be enabled. | Encoded PowerShell command (T1059.001), Download cradle execution |
| **4689** | Process exit | Analytics: 90d / Lake: 365d | Process lifecycle tracking — useful for long-running malicious processes. | Long-running process correlated with C2 activity |
| **4698 / 4699 / 4702** | Scheduled task created / deleted / updated | Analytics: 90d / Lake: 365d | Persistence detection (MITRE T1053.005). Attackers frequently use scheduled tasks for persistence and execution. | Scheduled task with suspicious command line (T1053.005) |
| **4697** | Service installed | Analytics: 90d / Lake: 365d | Persistence via new services (MITRE T1543.003). Detects malware installing as a Windows service. | New service pointing to unusual binary path (T1543.003) |
| **4719** | System audit policy changed | Analytics: 90d / Lake: 365d | Anti-forensic detection — attackers disabling audit logging. MCSB LT-3. | Audit policy weakened or disabled (T1562.002) |
| **1102** | Audit log cleared | Analytics: 90d / Lake: 365d | **Critical anti-forensic indicator.** Event log clearing is a strong signal of attacker activity (MITRE T1070.001). | Security event log cleared (T1070.001) |

#### Firewall and Network Events

| Event ID | Description | Retention Recommendation | Rationale | Example Detection |
|:---------|:------------|:------------------------|:----------|:------------------|
| **5156** | Windows Filtering Platform connection allowed | Analytics: 90d / Lake: 365d | Network connection tracking at the OS level. Useful when MDE DeviceNetworkEvents isn't available. | Outbound connection to suspicious IP/port |
| **5157** | Windows Filtering Platform connection blocked | Analytics: 90d / Lake: 365d | Blocked connection attempts may indicate lateral movement or C2 attempts. | Blocked lateral movement attempt to internal server |

---

## Example Detections

| Detection | Event ID(s) | MITRE ATT&CK | Description |
|:----------|:------------|:-------------|:------------|
| RDP brute-force | 4625 (Type 10) | T1110 | High volume of failed RDP logons from a single source IP |
| Lateral movement via network logon | 4624 (Type 3), 4648 | T1021 | Network logon from an unexpected source, especially to servers |
| New local admin account | 4720, 4732 | T1136.001 | New user account created and added to local Administrators group |
| Suspicious process execution | 4688 | T1059 | PowerShell/cmd launching with encoded commands, download cradles |
| Scheduled task persistence | 4698 | T1053.005 | New scheduled task created with suspicious command line |
| Service installation | 4697 | T1543.003 | New service installed pointing to unusual binary path |
| Audit log cleared | 1102 | T1070.001 | Security event log cleared — high-confidence attacker indicator |
| Privilege escalation (group modification) | 4728, 4732, 4756 | T1098 | User added to a privileged local or domain group |
| Pass-the-hash detection | 4624 (Type 9), 4648 | T1550.002 | New logon with explicit credentials combined with NTLM authentication |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **IM-1** Centralise identity management | Logon events (4624, 4625) provide local authentication visibility |
| **PA-1** Protect privileged users | Account management events (4720, 4728, 4732) track privilege changes |
| **LT-1** Enable threat detection | Windows Security Events enable endpoint-level threat detection |
| **LT-3** Enable logging for security investigation | Process creation (4688) and logon events are core forensic telemetry |
| **LT-6** Configure log storage retention | Extended retention ensures forensic coverage beyond native Windows limits |
| **IR-4** Detection and analysis | Security events are the primary evidence source for server-side investigations |

---

## Recommended Configuration

### Minimum Audit Policy (GPO)

Enable these audit subcategories for Tier 1 coverage:

| Category | Subcategory | Setting |
|:---------|:------------|:--------|
| Account Logon | Credential Validation | Success, Failure |
| Account Management | User Account Management | Success, Failure |
| Account Management | Security Group Management | Success, Failure |
| Detailed Tracking | Process Creation | Success |
| Logon/Logoff | Logon | Success, Failure |
| Logon/Logoff | Logoff | Success |
| Logon/Logoff | Special Logon | Success |
| Policy Change | Audit Policy Change | Success, Failure |
| System | Security State Change | Success |
| System | System Integrity | Success, Failure |
| Object Access | Filtering Platform Connection | Success (if no MDE) |

### Essential GPO Setting

> [!WARNING]
> **Enable** "Include command line in process creation events" (Computer Configuration > Administrative Templates > System > Audit Process Creation). Without this, Event ID 4688 captures the process name but not the command-line arguments — losing most of its forensic value.

---

## Notes

- **Migrate from MMA to AMA** — the Log Analytics Agent (MMA) is deprecated. Use Azure Monitor Agent with Data Collection Rules
- Process creation (4688) with command-line logging is **critical** — this overlaps with MDE's `DeviceProcessEvents` but provides the native Windows audit trail as a safety net
- Use the **Common** event set as your DCR baseline, then add specific event IDs as detection engineering matures
- For **domain controllers**, consider the "All Events" preset or a custom DCR — DCs generate authentication events for the entire domain
- The WindowsEvent table (normalized) is useful if you want to collect non-security event logs (System, Application, PowerShell Operational) — consider this for Tier 2

### Why Layered Logging Matters for Windows Servers

EDR solutions like Microsoft Defender for Endpoint are powerful but **should not be your only detection source**. Windows Security Events provide an independent, authoritative audit trail that persists even if EDR is tampered with or bypassed. See the following resources:

| Title | Description | Link |
|:------|:------------|:-----|
| The Evolution of EDR Bypasses | Historical timeline demonstrating how attackers continuously develop EDR bypass techniques — native logs are your fallback | [CovertSwarm](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) |
| Cloud Forensics: Forensic Readiness and IR in Azure Virtual Desktop | Demonstrates a layered approach combining EDR and native logging for incident response | [Microsoft Community Hub](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/cloud-forensics-forensic-readiness-and-incident-response-in-azure-virtual-desktop/3835484) |
| Windows Event Log Analysis: Techniques for Every SOC Analyst | Practical guide on using Windows Security Events for detection alongside EDR | [CyberDefenders Blog](https://blog.cyberdefenders.org/2024/02/windows-event-log-analysis-techniques.html) |

### Tools

| Tool | Type | Purpose | Source |
|:-----|:-----|:--------|:-------|
| **Workspace Usage Report** | Workbook | Monitor SecurityEvent/WindowsEvent ingestion volumes per server | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) |
| **Defender AMA Coverage** | Workbook | Validate AMA agent deployment and Windows Security Event collection coverage | [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
