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
| **Defender for Servers P2** | 500 MB/day free ingestion per server (covers Security Events, Syslog, and other security data types) |
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

| Event ID | Description | Retention Recommendation | Rationale |
|:---------|:------------|:------------------------|:----------|
| **4624** | Successful logon | Hot: 90d / Archive: 2y | Core authentication forensics. Identifies who logged on, from where, and using which logon type. MCSB IM-1. Essential for lateral movement tracking (Type 3 = network, Type 10 = RDP). |
| **4625** | Failed logon | Hot: 90d / Archive: 1y | Brute-force and password spray detection. MCSB IM-1. High volume of failures from a single source indicates an attack. |
| **4648** | Logon with explicit credentials | Hot: 90d / Archive: 2y | Detects credential-based lateral movement (runas, PsExec). An attacker using stolen credentials on a compromised host generates this event. |
| **4672** | Special privileges assigned to logon | Hot: 90d / Archive: 2y | Tracks every logon that receives administrative privileges. Critical for monitoring admin activity and detecting privilege abuse. |
| **4634 / 4647** | Logoff / User-initiated logoff | Hot: 90d / Archive: 6m | Session duration tracking — helps scope attacker activity windows. |

#### Account Management Events

| Event ID | Description | Retention Recommendation | Rationale |
|:---------|:------------|:------------------------|:----------|
| **4720** | User account created | Hot: 90d / Archive: 2y | Detects persistence via new local accounts. MCSB PA-1. Also relevant for MITRE T1136.001 (Create Account: Local). |
| **4726** | User account deleted | Hot: 90d / Archive: 1y | May indicate an attacker covering tracks by deleting created accounts. |
| **4728 / 4732 / 4756** | Member added to security-enabled group | Hot: 90d / Archive: 2y | Privilege escalation via group membership. Tracks additions to local Administrators and other privileged groups. MCSB PA-1. |
| **4724 / 4723** | Password reset / Password change | Hot: 90d / Archive: 1y | Unauthorized password resets may indicate account takeover. |

#### Process and Policy Events

| Event ID | Description | Retention Recommendation | Rationale |
|:---------|:------------|:------------------------|:----------|
| **4688** | Process creation (with command line) | Hot: 90d / Archive: 2y | **High-value forensic event.** Captures command-line arguments for every process. MCSB LT-3. Covers MITRE Execution, Defence Evasion, Discovery. Requires "Include command line in process creation events" GPO to be enabled. |
| **4689** | Process exit | Hot: 90d / Archive: 6m | Process lifecycle tracking — useful for long-running malicious processes. |
| **4698 / 4699 / 4702** | Scheduled task created / deleted / updated | Hot: 90d / Archive: 2y | Persistence detection (MITRE T1053.005). Attackers frequently use scheduled tasks for persistence and execution. |
| **4697** | Service installed | Hot: 90d / Archive: 2y | Persistence via new services (MITRE T1543.003). Detects malware installing as a Windows service. |
| **4719** | System audit policy changed | Hot: 90d / Archive: 2y | Anti-forensic detection — attackers disabling audit logging. MCSB LT-3. |
| **1102** | Audit log cleared | Hot: 90d / Archive: 2y | **Critical anti-forensic indicator.** Event log clearing is a strong signal of attacker activity (MITRE T1070.001). |

#### Firewall and Network Events

| Event ID | Description | Retention Recommendation | Rationale |
|:---------|:------------|:------------------------|:----------|
| **5156** | Windows Filtering Platform connection allowed | Hot: 90d / Archive: 1y | Network connection tracking at the OS level. Useful when MDE DeviceNetworkEvents isn't available. |
| **5157** | Windows Filtering Platform connection blocked | Hot: 90d / Archive: 1y | Blocked connection attempts may indicate lateral movement or C2 attempts. |

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

*[Back to overview](../README.md)*
