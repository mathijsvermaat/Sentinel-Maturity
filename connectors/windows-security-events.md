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
- [References](#references)

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
> Start with **Common** for all servers. Upgrade domain controllers and high-value assets to **All Events**. Use the **Workspace Usage Report** workbook ([walkthrough](../procedures/workspace-usage-report.md)) to monitor actual daily ingestion per server and adjust if needed.

#### Key Events by Tier

The tables below highlight **key events per category** and indicate which collection tier includes them.

##### Authentication Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------------------|
| **4624** | Successful logon | ✅ | ✅ | ✅ | Core authentication forensics — who, from where, which logon type (3=network, 10=RDP). MCSB IM-1. | Reconstruct full authentication timeline — proves when and how access was gained, the logon type, source IP, and account used | Lateral movement via network logon from unexpected source (T1021) |
| **4625** | Failed logon | ✅ | ✅ | ✅ | Brute-force and password spray detection. MCSB IM-1. | Quantify attack intensity and duration — proves volume, timing, and source of brute-force or spray attempts across accounts | RDP brute-force — high volume failed Type 10 logons (T1110) |
| **4634** | Logoff | ❌ | ✅ | ✅ | Session duration tracking — scopes attacker activity windows during IR | Determine exact session duration — pairing with 4624 proves how long an attacker was active on each system | Session duration analysis during incident response |
| **4648** | Logon with explicit credentials | ❌ | ✅ | ✅ | Detects runas, PsExec, and credential-based lateral movement | Proves credential reuse and lateral movement — shows when an attacker used stolen credentials on a compromised host | Explicit credential use for lateral movement (T1078) |
| **4672** | Special privileges assigned at logon | ❌ | ✅ | ✅ | Every logon receiving admin privileges — critical for monitoring admin activity | Identify every administrative access event — proves which sessions had elevated privileges, essential for scoping admin-level compromise | Admin logon from unexpected source or at unusual time |
| **4740** | Account locked out | ✅ | ✅ | ✅ | Brute-force indicator — lockout storm across accounts | Correlate lockout events with attack timing — proves the impact of a brute-force campaign on account availability | Account lockout storm indicating password spray (T1110) |
| **4768** | Kerberos TGT requested | ❌ | ✅ | ✅ | Kerberoasting and pass-the-ticket detection. DC-only event. | Detect Kerberos-based attacks at source — proves TGT request patterns, encryption types, and anomalous ticket requests on DCs | High TGT volume with weak encryption type (T1558.003) |
| **4769** | Kerberos service ticket requested | ❌ | ✅ | ✅ | Service ticket abuse detection — abnormal SPN access patterns | Trace service ticket requests to identify Kerberoasting — proves which SPNs were targeted and from which account | Kerberoasting — unusual service ticket requests (T1558) |
| **4771** | Kerberos pre-authentication failed | ❌ | ✅ | ✅ | Password spray against Kerberos (pre-auth failure) | Evidence of pre-authentication brute-force — proves spray activity at the Kerberos level that may not appear in standard logon events | Spray across user accounts via Kerberos (T1110) |
| **4776** | NTLM authentication attempt | ❌ | ✅ | ✅ | Legacy authentication abuse — NTLM from unexpected hosts | Track NTLM relay and pass-the-hash — proves legacy auth usage patterns and identifies hosts still using NTLM | NTLM auth from non-legacy host indicating relay attack (T1110) |

##### Account and Group Management Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------------------|
| **4720** | User account created | ✅ | ✅ | ✅ | Persistence via new local accounts. MCSB PA-1. MITRE T1136.001. | Prove account creation as persistence — shows exactly when and by whom a backdoor account was created | New local account created and added to Administrators |
| **4722** | User account enabled | ✅ | ✅ | ✅ | Reactivation of dormant/backdoor accounts | Detect reactivated accounts — proves when a disabled account was re-enabled and by which identity | Dormant account re-enabled outside business hours (T1098) |
| **4724** | Password reset attempt | ✅ | ✅ | ✅ | Unauthorized password resets — account takeover | Trace credential manipulation — proves who reset which password and when, critical for account takeover investigations | Password reset on admin account by non-helpdesk user (T1098.004) |
| **4726** | User account deleted | ✅ | ✅ | ✅ | Covering tracks by deleting created accounts | Evidence of anti-forensic activity — proves attacker cleaned up backdoor accounts post-exploitation | Account deletion shortly after suspicious activity (T1070) |
| **4728** | Member added to global security group | ✅ | ✅ | ✅ | Privilege escalation: additions to Domain Admins. MCSB PA-1. | Prove privilege escalation path — authoritative record of group membership changes on DCs | User added to Domain Admins (T1098) |
| **4732** | Member added to local security group | ✅ | ✅ | ✅ | Local admin escalation via group membership | Trace local privilege escalation — proves when and by whom a user was added to local Administrators | User added to local Administrators group (T1098) |
| **4756** | Member added to universal security group | ✅ | ✅ | ✅ | High-impact: Enterprise Admin and other forest-wide groups | Prove forest-wide privilege escalation — authoritative evidence of Enterprise Admin group modifications | User added to Enterprise Admins (T1098) |
| **4731** | Local security group created | ❌ | ✅ | ✅ | Privilege staging — new admin-like groups | Detect privilege staging — proves creation of new local groups that may have been used to grant access | New local administrative group created (T1136) |
| **4741** | Computer account created | ❌ | ✅ | ✅ | Rogue machine join or resource-based constrained delegation abuse | Detect rogue domain joins — proves unauthorized machine accounts that may enable delegation attacks | Computer account created outside provisioning (T1136.002) |
| **4742** | Computer account changed | ❌ | ✅ | ✅ | SPN or delegation property modification — delegation abuse | Trace delegation abuse setup — proves SPN or delegation attribute changes on computer objects | SPN modified on computer object (T1098) |

##### Process, Persistence, and Policy Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------------------|
| **4688** | Process created (with command line) | ✅ | ✅ | ✅ | **High-value forensic event.** Requires GPO "Include command line in process creation events." MCSB LT-3. | Independent execution audit trail — authoritative process creation record that persists even if the EDR is bypassed or tampered with | Encoded PowerShell (T1059.001), LOLBin execution |
| **4698** | Scheduled task created | ✅ | ✅ | ✅ | Persistence detection. MITRE T1053.005. | Prove persistence installation — exact time, task name, command, and creating account | Task created to run from AppData or temp (T1053.005) |
| **4699** | Scheduled task deleted | ❌ | ✅ | ✅ | Defence evasion — task deleted after execution | Evidence of anti-forensic cleanup — proves attacker removed persistence artifacts | Task deleted immediately after single execution (T1070) |
| **4697** | Service installed | ✅ | ✅ | ✅ | Service-based persistence. MITRE T1543.003. | Identify service-based persistence — proves which binary was registered as a service and when | Service installed from user-writable path (T1543.003) |
| **4702** | Scheduled task updated | ✅ | ✅ | ✅ | Modified tasks may indicate hijacked persistence | Detect persistence hijacking — proves when a legitimate task was modified to execute malicious code | Task path changed to suspicious location (T1053.005) |
| **4719** | Audit policy changed | ✅ | ✅ | ✅ | Anti-forensic: attacker disabling audit logging. MCSB LT-3. | Prove logging was tampered with — authoritative evidence that audit policy was weakened by the attacker | Audit policy disabled after admin logon (T1562.002) |
| **1102** | Audit log cleared | ✅ | ✅ | ✅ | **Critical anti-forensic indicator.** MITRE T1070.001. | The last event before log destruction — proves the log was cleared and by whom. If this event exists in Sentinel, the centralised copy is the only surviving evidence. | Security log cleared by non-admin account (T1070.001) |
| **4739** | Domain policy changed | ✅ | ✅ | ✅ | Domain-wide GPO changes weakening security | Prove domain-level security weakening — authoritative evidence of GPO modifications that relaxed security controls | GPO modified to relax password policy (T1484.001) |

##### Network and Firewall Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------------------|
| **5140** | Network share accessed | ❌ | ✅ | ✅ | Lateral movement via admin shares (C$, ADMIN$). MITRE T1021.002. | Map lateral movement paths — proves which shares were accessed, from where, and by whom during an attack | Access to C$/ADMIN$ from unexpected source |
| **5145** | Network share object checked | ❌ | ✅ | ✅ | Data staging and write attempts to admin shares | Trace data exfiltration and staging — proves file-level write operations to network shares | Write attempt to admin share indicating staging (T1021.002) |
| **5156** | WFP connection allowed | ❌ | ✅ | ✅ | OS-level network connection tracking | Independent network telemetry — proves outbound connections even if the EDR was disabled or tampered with | Outbound connection to rare destination (T1071) |
| **4946** | Firewall rule added | ✅ | ✅ | ✅ | Network exposure — new inbound allow rules | Prove defence evasion — shows exactly when firewall rules were created to allow C2 or lateral movement | New allow rule for suspicious port (T1562.004) |
| **4948** | Firewall rule modified | ✅ | ✅ | ✅ | C2 enablement via rule modification | Track security control changes — proves which rules were weakened and when | Rule changed + outbound traffic spike (T1562.004) |
| **4956** | Firewall profile changed | ✅ | ✅ | ✅ | Defence evasion — profile change | Evidence of network profile manipulation — proves profile changes that weaken firewall protection | Public → Private profile change (T1562.004) |

##### AppLocker / WDAC Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------------------|
| **8001** | AppLocker policy applied | ✅ | ✅ | ✅ | Control enforcement validation | Prove application control state — confirms whether AppLocker policy was active at the time of an incident | Unexpected policy application (T1484.002) |
| **8003** | AppLocker blocked execution | ✅ | ✅ | ✅ | Blocked malware/LOLBin attempts | Evidence of blocked attack attempts — proves malware or LOLBin execution was attempted even though it was blocked | Repeated block attempts from same source (T1059) |
| **8222** | WDAC enforcement event | ✅ | ✅ | ✅ | Application control policy violation | Prove policy violation attempts — evidence of application control bypass efforts on critical systems | WDAC policy violation on critical server (T1484.002) |

##### Credential Access Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------------------|
| **5379** | Credential Manager credentials read | ❌ | ✅ | ✅ | Credential dumping precursor — reading stored credentials | Detect credential harvesting — proves which process accessed Credential Manager and when, identifying pre-exfiltration activity | Cred read by non-browser process (T1555) |

##### Full (All Events) Only — Additional Forensic and Audit Events

The following events are **only available in the All Events preset** (or via a Custom DCR). These provide deeper forensic granularity — particularly valuable for domain controllers, file servers, and compliance-driven environments.

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------------------|
| **4663** | Object access attempt | ❌ | ❌ | ✅ | Sensitive file/registry object access auditing. Detects access to credential files, SAM database, and sensitive data. Requires SACL configuration on target objects. | Prove exactly which files/objects were accessed — authoritative evidence of data access patterns during exfiltration or credential theft | Access to credential files or SAM database (T1005) |
| **4656** | Handle to object requested | ❌ | ❌ | ✅ | Detailed object access — tracks which process requested access to a specific object and with what permissions | Trace process-to-object access chains — proves exactly which process opened handles to LSASS or sensitive objects | Handle request to LSASS process memory (T1003.001) |
| **4670** | Permissions on object changed | ❌ | ❌ | ✅ | Detects permission changes on files, registry, or AD objects — key for detecting attackers weakening ACLs | Evidence of ACL manipulation — proves when and how access controls were weakened on sensitive resources | DACL modified on sensitive file or registry key (T1222) |
| **4907** | Auditing settings on object changed | ❌ | ❌ | ✅ | Anti-forensic: attacker removing SACLs to stop generating audit events for sensitive objects | Prove audit evasion — evidence that SACLs were removed to suppress future audit events, indicating sophisticated attacker activity | SACL removed from sensitive directory (T1562) |
| **4703** | Token right adjusted | ❌ | ❌ | ✅ | Privilege token manipulation — SeDebugPrivilege enables LSASS access; SeImpersonatePrivilege enables potato-style attacks | Prove privilege escalation technique — shows exactly when dangerous privileges were enabled on a process | SeDebugPrivilege enabled on non-admin process (T1134) |
| **4706** | New trust created to domain | ❌ | ❌ | ✅ | Domain trust creation — highly sensitive change that could enable cross-domain lateral movement | Authoritative evidence of trust manipulation — proves new trust relationships that may enable cross-forest attacks | New domain trust created (T1484.002) |
| **4713** | Kerberos policy changed | ❌ | ❌ | ✅ | Changes to Kerberos ticket lifetime or renewal settings — can indicate Golden Ticket preparation | Prove Kerberos configuration tampering — evidence of ticket lifetime changes that may indicate Golden Ticket setup | Kerberos ticket lifetime extended (T1558.001) |
| **4770** | Kerberos TGT renewed | ❌ | ❌ | ✅ | TGT renewal tracking — abnormal renewal patterns may indicate pass-the-ticket or Golden Ticket use | Detect ticket abuse patterns — proves abnormal TGT renewal activity that indicates pass-the-ticket or Golden Ticket usage | TGT renewed from unexpected host (T1550.003) |
| **4985** | State of a transaction changed | ❌ | ❌ | ✅ | Transactional NTFS operations — can indicate advanced file system manipulation | Evidence of TxF abuse — proves transactional file system operations used for covert file manipulation | Transactional file operation on sensitive path |
| **5136** | Directory service object modified | ❌ | ❌ | ✅ | AD object attribute changes — tracks modifications to user, group, and computer objects at the attribute level | The most granular AD forensic event — proves exactly which AD attribute was changed, from what value, to what value, and by whom | AdminSDHolder modification, SPN added to user (T1134) |
| **5137** | Directory service object created | ❌ | ❌ | ✅ | New AD objects — detects creation of GPOs, OUs, or other AD objects outside change management | Prove unauthorized AD changes — authoritative record of new AD objects created during an attack | New GPO created outside change window (T1484.001) |
| **5141** | Directory service object deleted | ❌ | ❌ | ✅ | AD object deletion — covering tracks or disrupting services | Evidence of AD-level destruction — proves when and by whom AD objects were deleted for anti-forensic or disruptive purposes | OU or GPO deleted unexpectedly (T1070) |

> [!TIP]
> The Full tier is especially valuable on **domain controllers** where events like 5136 (AD object modification), 4770 (Kerberos TGT renewal), and 4706 (trust creation) provide critical visibility that is unavailable from any other source.

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

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-2 (audit events) and AU-12 (audit generation), CIS Controls v8 8.5 (collect detailed audit logs) and 8.8 (command-line audit logs), and ASD ACSC enterprise network logging priority #10 (user computers) and #11 (servers and domain controllers).

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
> Volume estimates vary significantly by server role. Domain controllers, file servers, and web servers typically produce **much higher volumes** than application servers or utility VMs. Always validate with the **Workspace Usage Report** workbook ([walkthrough](../procedures/workspace-usage-report.md)) after initial deployment.

> [!NOTE]
> The P2 benefit of 500 MB/day is per server and covers **all qualifying security data types** combined (SecurityEvent, Syslog, and others) — not 500 MB per data type. If a server also sends Syslog or other security data, that counts against the same allowance. See the [data ingestion benefit documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) for the full list of qualifying tables.

### Why Layered Logging Matters for Windows Servers

EDR solutions like Microsoft Defender for Endpoint are powerful but **should not be your only detection source**. Windows Security Events provide an independent, authoritative audit trail that persists even if EDR is tampered with or bypassed.

#### Why EDR Telemetry Is Not the Full Picture

While EDR agents offer detailed and extensive telemetry, they are **not designed to serve as a complete visibility layer**. There are practical constraints that limit what an EDR can realistically collect:

- **Volume constraints.** Endpoints generate enormous amounts of data daily. EDR agents must be selective about what they log, focusing on events most relevant to detection and investigation rather than comprehensive auditing.
- **Signal-to-noise trade-offs.** Effective detection depends on keeping the signal-to-noise ratio high. To avoid alert fatigue and maintain detection quality, EDR vendors filter and reduce the volume of raw telemetry they ingest.
- **Endpoint performance.** Logging every event from every process would degrade system performance. EDR agents are therefore optimised to minimise their footprint, which inherently means collecting less.
- **Evolving collection logic.** The rules governing which events are captured change between agent versions as vendors refine their detection models. These changes are not always documented, and there is no guarantee of telemetry consistency over time.

Beyond these constraints, the telemetry that is collected is **curated by the vendor**, not the customer:

- Monitored registry keys are a fixed set that cannot be extended by the organisation
- Collection is biased toward events that modify the system — reads and queries are often excluded
- High-frequency event categories such as network connections and file writes are **heavily throttled** to control volume
- Events from trusted (e.g., Microsoft-signed) processes are logged at reduced fidelity
- Certain sensitive operations, like cross-process memory access, are only tracked for specific targets such as LSASS

MDE's primary data source is **Event Tracing for Windows (ETW)**, drawing from over 70 providers including private channels like the Threat Intelligence ETW provider. This is broad, but it remains a curated view — not a complete record of operating system activity.

**Windows Security Events fill these gaps.** They are generated by the operating system kernel, cannot be filtered or suppressed by a third-party agent, and persist in Sentinel even if the EDR is tampered with, uninstalled, or simply did not capture a particular event due to its throttling or filtering logic. Collecting them alongside EDR is a **layered defence** strategy, not a redundancy.

See the following resources for deeper analysis:

| Title | Description | Link |
|:------|:------------|:-----|
| MDE Telemetry Unreliability and Log Augmentation | In-depth analysis of MDE telemetry gaps, capping behaviour, and why native Windows logs are essential for complete forensic coverage | [FalconForce](https://falconforce.nl/microsoft-defender-for-endpoint-internals-0x03-mde-telemetry-unreliability-and-log-augmentation/) |
| The Evolution of EDR Bypasses | Historical timeline demonstrating how attackers continuously develop EDR bypass techniques — native logs are your fallback | [CovertSwarm](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) |
| Cloud Forensics: Forensic Readiness and IR in Azure Virtual Desktop | Demonstrates a layered approach combining EDR and native logging for incident response | [Microsoft Community Hub](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/cloud-forensics-forensic-readiness-and-incident-response-in-azure-virtual-desktop/3835484) |
| Windows Event Log Analysis: Techniques for Every SOC Analyst | Practical guide on using Windows Security Events for detection alongside EDR | [CyberDefenders Blog](https://blog.cyberdefenders.org/2024/02/windows-event-log-analysis-techniques.html) |

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor SecurityEvent/WindowsEvent ingestion volumes per server | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Defender AMA Coverage** | Workbook | Validate AMA agent deployment and Windows Security Event collection coverage | [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) | [Walkthrough](../procedures/defender-ama-coverage.md) |
| **Windows Security Events** | Solution | Event Analyzer workbook — explore, audit, and speed up Windows Event Log analysis with all event details and attributes | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect Windows Security Events via AMA to Microsoft Sentinel | Connector setup guide — AMA-based Windows Security Events with DCR filtering | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/windows-security-events-via-ama) |
| Windows Security Event ID reference | List of event IDs collected per preset (Minimal, Common, All) | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/windows-security-event-id-reference) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Windows Security Events connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/windowssecurityevents.md) |
| MDE Telemetry Unreliability and Log Augmentation | FalconForce | In-depth analysis of MDE telemetry gaps, capping behaviour, and why native Windows logs are essential for complete forensic coverage | [falconforce.nl](https://falconforce.nl/microsoft-defender-for-endpoint-internals-0x03-mde-telemetry-unreliability-and-log-augmentation/) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
