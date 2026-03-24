# Windows Security Events / Windows Events

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party (AMA) · **Free ingestion:** 500 MB/day per server (Defender for Servers P2)

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
  - [Event Collection Tiers — Minimal, Common, and Full](#event-collection-tiers--minimal-common-and-full)
  - [Key Events by Tier](#key-events-by-tier)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Recommended Configuration](#recommended-configuration)
- [Notes](#notes)
  - [Staying Within the Defender for Servers P2 Ingestion Benefit](#staying-within-the-defender-for-servers-p2-ingestion-benefit)
  - [Why Layered Logging Matters for Windows Servers](#why-layered-logging-matters-for-windows-servers)
  - [Tools](#tools)

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

#### Event Collection Tiers — Minimal, Common, and Full

The Windows Security Events connector uses **Data Collection Rules (DCRs)** with preset tiers that control which Event IDs are collected. Choosing the right tier is a trade-off between **detection coverage**, **forensic completeness**, and **ingestion cost**.

For the full list of Event IDs per tier, see the [Microsoft documentation on Windows Security Event ID reference](https://learn.microsoft.com/en-us/azure/sentinel/windows-security-event-id-reference).

| Preset | What it collects | Volume Estimate | When to use |
|:-------|:-----------------|:----------------|:------------|
| **Minimal** | Breach-focused events only — successful/failed logons (4624, 4625), process creation (4688), account management, firewall and AppLocker events. **No full audit trail** (e.g. logoff events 4634 are excluded). | **Low** (~50–150 MB/day typical server) | Budget-constrained environments where P2 ingestion benefit must not be exceeded. Acceptable for workstations; **not recommended as the sole tier for servers**. |
| **Common** | All Minimal events **plus** full audit trail — logoff (4634), explicit credentials (4648), special privileges (4672), Kerberos (4768/4769/4771), NTLM (4776), network shares (5140/5145), credential access (5379), and more. | **Medium** (~150–400 MB/day typical server) | **Recommended starting point for Tier 1.** Provides sufficient detection and forensic coverage for most servers while staying within the P2 ingestion benefit on most workloads. |
| **All Events** | Every Windows Security event — includes verbose events like detailed object access, filtering platform operations, and all registry auditing. | **High** (~400 MB–1+ GB/day depending on server role) | Full forensic coverage for **domain controllers**, **critical servers**, and environments with compliance requirements demanding complete audit trails. Best paired with Defender for Servers P2 to offset cost. |
| **Custom** | Your specific Event IDs | **Variable** | Fine-tuned collection for mature SOCs that have identified exactly which events their detection rules require. |

> [!TIP]
> Start with **Common** for all servers. Upgrade domain controllers and high-value assets to **All Events**. Use the **Workspace Usage Report** workbook to monitor actual daily ingestion per server and adjust if needed.

#### Key Events by Tier

The tables below highlight **key events per category** and indicate which collection tier includes them. The "MDE Gap" column shows where Windows Security Events fill visibility gaps that MDE does not cover — reinforcing the [layered detection approach](../guidance/layered-detection.md).

##### Authentication Events

| Event ID | Description | Minimal | Common | MDE Gap | Rationale | Example Detection |
|:---------|:------------|:-------:|:------:|:--------|:----------|:------------------|
| **4624** | Successful logon | ✅ | ✅ | ⚠️ Partial — MDE has logon telemetry but DCs require SecurityEvent | Core authentication forensics — who, from where, which logon type (3=network, 10=RDP). MCSB IM-1. | Lateral movement via network logon from unexpected source (T1021) |
| **4625** | Failed logon | ✅ | ✅ | ⚠️ Partial — better correlation in Sentinel | Brute-force and password spray detection. MCSB IM-1. | RDP brute-force — high volume failed Type 10 logons (T1110) |
| **4634** | Logoff | ❌ | ✅ | ⚠️ Gap | Session duration tracking — scopes attacker activity windows during IR | Session duration analysis during incident response |
| **4648** | Logon with explicit credentials | ❌ | ✅ | ⚠️ Gap — MDE often lacks explicit-cred context | Detects runas, PsExec, and credential-based lateral movement | Explicit credential use for lateral movement (T1078) |
| **4672** | Special privileges assigned at logon | ❌ | ✅ | ⚠️ Gap — DC-level signal | Every logon receiving admin privileges — critical for monitoring admin activity | Admin logon from unexpected source or at unusual time |
| **4740** | Account locked out | ✅ | ✅ | ⚠️ Partial | Brute-force indicator — lockout storm across accounts | Account lockout storm indicating password spray (T1110) |
| **4768** | Kerberos TGT requested | ❌ | ✅ | ⚠️ Major gap — MDE weak on Kerberos | Kerberoasting and pass-the-ticket detection. DC-only event. | High TGT volume with weak encryption type (T1558.003) |
| **4769** | Kerberos service ticket requested | ❌ | ✅ | ⚠️ Major gap | Service ticket abuse detection — abnormal SPN access patterns | Kerberoasting — unusual service ticket requests (T1558) |
| **4771** | Kerberos pre-authentication failed | ❌ | ✅ | ⚠️ Gap | Password spray against Kerberos (pre-auth failure) | Spray across user accounts via Kerberos (T1110) |
| **4776** | NTLM authentication attempt | ❌ | ✅ | ⚠️ Gap | Legacy authentication abuse — NTLM from unexpected hosts | NTLM auth from non-legacy host indicating relay attack (T1110) |

##### Account and Group Management Events

| Event ID | Description | Minimal | Common | MDE Gap | Rationale | Example Detection |
|:---------|:------------|:-------:|:------:|:--------|:----------|:------------------|
| **4720** | User account created | ✅ | ✅ | ⚠️ Gap — Sentinel required for account lifecycle | Persistence via new local accounts. MCSB PA-1. MITRE T1136.001. | New local account created and added to Administrators |
| **4722** | User account enabled | ✅ | ✅ | ⚠️ Gap | Reactivation of dormant/backdoor accounts | Dormant account re-enabled outside business hours (T1098) |
| **4724** | Password reset attempt | ✅ | ✅ | ⚠️ Gap | Unauthorized password resets — account takeover | Password reset on admin account by non-helpdesk user (T1098.004) |
| **4726** | User account deleted | ✅ | ✅ | ⚠️ Gap | Covering tracks by deleting created accounts | Account deletion shortly after suspicious activity (T1070) |
| **4728** | Member added to global security group | ✅ | ✅ | ⚠️ Gap — critical DC signal | Privilege escalation: additions to Domain Admins. MCSB PA-1. | User added to Domain Admins (T1098) |
| **4732** | Member added to local security group | ✅ | ✅ | ⚠️ Partial — MDE may miss DC context | Local admin escalation via group membership | User added to local Administrators group (T1098) |
| **4756** | Member added to universal security group | ✅ | ✅ | ⚠️ Gap | High-impact: Enterprise Admin and other forest-wide groups | User added to Enterprise Admins (T1098) |
| **4731** | Local security group created | ❌ | ✅ | ⚠️ Gap | Privilege staging — new admin-like groups | New local administrative group created (T1136) |
| **4741** | Computer account created | ❌ | ✅ | ⚠️ Gap — MDE blind spot | Rogue machine join or resource-based constrained delegation abuse | Computer account created outside provisioning (T1136.002) |
| **4742** | Computer account changed | ❌ | ✅ | ⚠️ Gap | SPN or delegation property modification — delegation abuse | SPN modified on computer object (T1098) |

##### Process, Persistence, and Policy Events

| Event ID | Description | Minimal | Common | MDE Gap | Rationale | Example Detection |
|:---------|:------------|:-------:|:------:|:--------|:----------|:------------------|
| **4688** | Process created (with command line) | ✅ | ✅ | ❌ Mostly covered by MDE (use for correlation/fallback) | **High-value forensic event.** Requires GPO "Include command line in process creation events." MCSB LT-3. | Encoded PowerShell (T1059.001), LOLBin execution |
| **4698** | Scheduled task created | ✅ | ✅ | ⚠️ Gap — critical persistence telemetry | Persistence detection. MITRE T1053.005. | Task created to run from AppData or temp (T1053.005) |
| **4699** | Scheduled task deleted | ❌ | ✅ | ⚠️ Gap | Defence evasion — task deleted after execution | Task deleted immediately after single execution (T1070) |
| **4697** | Service installed | ✅ | ✅ | ⚠️ Partial — MDE sees some installs | Service-based persistence. MITRE T1543.003. | Service installed from user-writable path (T1543.003) |
| **4702** | Scheduled task updated | ✅ | ✅ | ⚠️ Partial — MDE sometimes misses task edits | Modified tasks may indicate hijacked persistence | Task path changed to suspicious location (T1053.005) |
| **4719** | Audit policy changed | ✅ | ✅ | ⚠️ Gap — critical control-plane signal | Anti-forensic: attacker disabling audit logging. MCSB LT-3. | Audit policy disabled after admin logon (T1562.002) |
| **1102** | Audit log cleared | ✅ | ✅ | ⚠️ Gap — SecurityEvent is authoritative | **Critical anti-forensic indicator.** MITRE T1070.001. | Security log cleared by non-admin account (T1070.001) |
| **4739** | Domain policy changed | ✅ | ✅ | ⚠️ Major gap — Sentinel required | Domain-wide GPO changes weakening security | GPO modified to relax password policy (T1484.001) |

##### Network and Firewall Events

| Event ID | Description | Minimal | Common | MDE Gap | Rationale | Example Detection |
|:---------|:------------|:-------:|:------:|:--------|:----------|:------------------|
| **5140** | Network share accessed | ❌ | ✅ | ⚠️ Partial | Lateral movement via admin shares (C$, ADMIN$). MITRE T1021.002. | Access to C$/ADMIN$ from unexpected source |
| **5145** | Network share object checked | ❌ | ✅ | ⚠️ Gap | Data staging and write attempts to admin shares | Write attempt to admin share indicating staging (T1021.002) |
| **5156** | WFP connection allowed | ❌ | ✅ | ⚠️ Partial | OS-level network connection tracking when MDE DeviceNetworkEvents unavailable | Outbound connection to rare destination (T1071) |
| **4946** | Firewall rule added | ✅ | ✅ | ⚠️ Gap | Network exposure — new inbound allow rules | New allow rule for suspicious port (T1562.004) |
| **4948** | Firewall rule modified | ✅ | ✅ | ⚠️ Gap | C2 enablement via rule modification | Rule changed + outbound traffic spike (T1562.004) |
| **4956** | Firewall profile changed | ✅ | ✅ | ⚠️ Gap | Defence evasion — profile change | Public → Private profile change (T1562.004) |

##### AppLocker / WDAC Events (Minimal tier only)

| Event ID | Description | Minimal | Common | MDE Gap | Rationale | Example Detection |
|:---------|:------------|:-------:|:------:|:--------|:----------|:------------------|
| **8001** | AppLocker policy applied | ✅ | ✅ | ⚠️ Gap | Control enforcement validation | Unexpected policy application (T1484.002) |
| **8003** | AppLocker blocked execution | ✅ | ✅ | ⚠️ Partial | Blocked malware/LOLBin attempts | Repeated block attempts from same source (T1059) |
| **8222** | WDAC enforcement event | ✅ | ✅ | ⚠️ Gap | Application control policy violation | WDAC policy violation on critical server (T1484.002) |

##### Credential Access Events (Common tier only)

| Event ID | Description | Minimal | Common | MDE Gap | Rationale | Example Detection |
|:---------|:------------|:-------:|:------:|:--------|:----------|:------------------|
| **5379** | Credential Manager credentials read | ❌ | ✅ | ⚠️ Gap | Credential dumping precursor — reading stored credentials | Cred read by non-browser process (T1555) |

##### Full (All Events) Only — Additional Forensic and Audit Events

The following events are **only available in the All Events preset** (or via a Custom DCR). These provide deeper forensic granularity — particularly valuable for domain controllers, file servers, and compliance-driven environments.

| Event ID | Description | Minimal | Common | Full | MDE Gap | Rationale | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:--------|:----------|:------------------|
| **4663** | Object access attempt | ❌ | ❌ | ✅ | ⚠️ Gap — requires SACLs; MDE limited | Sensitive file/registry object access auditing. Detects access to credential files, SAM database, and sensitive data. Requires SACL configuration on target objects. | Access to credential files or SAM database (T1005) |
| **4656** | Handle to object requested | ❌ | ❌ | ✅ | ⚠️ Gap | Detailed object access — tracks which process requested access to a specific object and with what permissions | Handle request to LSASS process memory (T1003.001) |
| **4670** | Permissions on object changed | ❌ | ❌ | ✅ | ⚠️ Gap | Detects permission changes on files, registry, or AD objects — key for detecting attackers weakening ACLs | DACL modified on sensitive file or registry key (T1222) |
| **4907** | Auditing settings on object changed | ❌ | ❌ | ✅ | ⚠️ Gap | Anti-forensic: attacker removing SACLs to stop generating audit events for sensitive objects | SACL removed from sensitive directory (T1562) |
| **4703** | Token right adjusted | ❌ | ❌ | ✅ | ⚠️ Gap | Privilege token manipulation — SeDebugPrivilege enables LSASS access; SeImpersonatePrivilege enables potato-style attacks | SeDebugPrivilege enabled on non-admin process (T1134) |
| **4706** | New trust created to domain | ❌ | ❌ | ✅ | ⚠️ Major gap | Domain trust creation — highly sensitive change that could enable cross-domain lateral movement | New domain trust created (T1484.002) |
| **4713** | Kerberos policy changed | ❌ | ❌ | ✅ | ⚠️ Gap | Changes to Kerberos ticket lifetime or renewal settings — can indicate Golden Ticket preparation | Kerberos ticket lifetime extended (T1558.001) |
| **4770** | Kerberos TGT renewed | ❌ | ❌ | ✅ | ⚠️ Major gap | TGT renewal tracking — abnormal renewal patterns may indicate pass-the-ticket or Golden Ticket use | TGT renewed from unexpected host (T1550.003) |
| **4985** | State of a transaction changed | ❌ | ❌ | ✅ | ⚠️ Gap | Transactional NTFS operations — can indicate advanced file system manipulation | Transactional file operation on sensitive path |
| **5136** | Directory service object modified | ❌ | ❌ | ✅ | ⚠️ Gap — critical for DC forensics | AD object attribute changes — tracks modifications to user, group, and computer objects at the attribute level | AdminSDHolder modification, SPN added to user (T1134) |
| **5137** | Directory service object created | ❌ | ❌ | ✅ | ⚠️ Gap | New AD objects — detects creation of GPOs, OUs, or other AD objects outside change management | New GPO created outside change window (T1484.001) |
| **5141** | Directory service object deleted | ❌ | ❌ | ✅ | ⚠️ Gap | AD object deletion — covering tracks or disrupting services | OU or GPO deleted unexpectedly (T1070) |

> [!TIP]
> The Full tier is especially valuable on **domain controllers** where events like 5136 (AD object modification), 4770 (Kerberos TGT renewal), and 4706 (trust creation) provide critical visibility that is unavailable from any other source — including MDE.

> [!NOTE]
> The tables above show **key events per category**, not every Event ID in each tier. For the complete list, refer to the [Windows Security Event ID reference](https://learn.microsoft.com/en-us/azure/sentinel/windows-security-event-id-reference).

All events above follow the same retention recommendation: **Analytics: 90d / Lake: 365d**.

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
- For the full list of Event IDs per collection tier, see the [Windows Security Event ID reference](https://learn.microsoft.com/en-us/azure/sentinel/windows-security-event-id-reference)

### Staying Within the Defender for Servers P2 Ingestion Benefit

Many organisations rely on the [Defender for Servers P2 ingestion benefit](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) (500 MB/day per server) to offset the cost of Windows Security Events. If your budget does not allow for ingestion overage, you have two strategies:

**Strategy A — Broad coverage, lower tier (all servers)**

Apply the **Minimal** or **Common** DCR preset to all servers. This ensures every server has at least baseline detection coverage while keeping per-server volumes within the P2 benefit.

**Strategy B — Full coverage on critical servers only**

Apply **All Events** to a targeted set of high-value servers (domain controllers, PAW stations, internet-facing servers) and **Minimal** to the rest. This gives deep forensic coverage where it matters most while staying within budget on the broader fleet.

#### Example: 5,000 servers with Defender for Servers P2

| Scenario | Tier | Est. Daily per Server | Total Daily Ingestion | P2 Allowance (5,000 × 500 MB) | Within Benefit? |
|:---------|:-----|:----------------------|:----------------------|:-------------------------------|:----------------|
| A1 — Minimal on all 5,000 | Minimal | ~100 MB | ~500 GB | 2,500 GB | ✅ Yes — ~20% of allowance |
| A2 — Common on all 5,000 | Common | ~300 MB | ~1,500 GB | 2,500 GB | ✅ Yes — ~60% of allowance |
| B1 — All Events on 200 DCs + Common on 4,800 | All + Common | ~800 MB (DC) / ~300 MB | ~1,600 GB | 2,500 GB | ✅ Yes — ~64% of allowance |
| B2 — All Events on all 5,000 | All Events | ~600 MB | ~3,000 GB | 2,500 GB | ⚠️ ~500 GB overage |

> [!IMPORTANT]
> Volume estimates vary significantly by server role. Domain controllers, file servers, and web servers typically produce **much higher volumes** than application servers or utility VMs. Always validate with the **Workspace Usage Report** workbook after initial deployment.

> [!NOTE]
> The P2 benefit of 500 MB/day is per server and covers **all qualifying security data types** combined (SecurityEvent, Syslog, and others) — not 500 MB per data type. If a server also sends Syslog or other security data, that counts against the same allowance. See the [data ingestion benefit documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) for the full list of qualifying tables.

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
