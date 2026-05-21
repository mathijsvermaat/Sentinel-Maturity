# Windows Security Events / Windows Events

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party (AMA) · **Free ingestion:** Pooled 500 MB/day × Defender for Servers P2-licensed servers for `SecurityEvent`

---

## Contents

- [Windows Security Events / Windows Events](#windows-security-events--windows-events)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
    - [SecurityEvent Table (Recommended)](#securityevent-table-recommended)
      - [Event Collection Tiers — Minimal, Common, and Full](#event-collection-tiers--minimal-common-and-full)
      - [Key Events by Tier](#key-events-by-tier)
        - [Authentication Events](#authentication-events)
        - [Account and Group Management Events](#account-and-group-management-events)
        - [Process, Persistence, and Policy Events](#process-persistence-and-policy-events)
        - [Network and Firewall Events](#network-and-firewall-events)
        - [AppLocker / WDAC Events](#applocker--wdac-events)
        - [Credential Access Events](#credential-access-events)
        - [Full (All Events) Only — Additional Forensic and Audit Events](#full-all-events-only--additional-forensic-and-audit-events)
  - [Example Detections](#example-detections)
  - [MITRE Detection Strategies](#mitre-detection-strategies)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Recommended Configuration](#recommended-configuration)
    - [Minimum Audit Policy (GPO)](#minimum-audit-policy-gpo)
    - [Essential GPO Setting](#essential-gpo-setting)
  - [Notes](#notes)
    - [Staying Within the Defender for Servers P2 Ingestion Benefit](#staying-within-the-defender-for-servers-p2-ingestion-benefit)
      - [Example: 5,000 servers with Defender for Servers P2](#example-5000-servers-with-defender-for-servers-p2)
    - [Why Layered Logging Matters for Windows Servers](#why-layered-logging-matters-for-windows-servers)
      - [Why EDR Telemetry Is Not the Full Picture](#why-edr-telemetry-is-not-the-full-picture)
  - [Tools](#tools)
  - [References](#references)
    - [Official Documentation](#official-documentation)
    - [Community \& Third-Party Resources](#community--third-party-resources)

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
| **[Defender for Servers P2](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit)** | [Pooled 500 MB/day × Defender for Servers P2-licensed servers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) for eligible security tables — applies to `SecurityEvent` (and the `Microsoft-SecurityEvent` stream in `WindowsEvent`) |
| **Defender for Servers P1** | MDE on servers, but no free data ingestion for Sentinel |
| **No Defender for Servers** | Full ingestion cost — still recommended for critical servers |

> [!NOTE]
> The P2 benefit is a **pooled allowance across the subscription** (500 MB × number of **Defender for Servers P2 licences**, i.e. the count of servers metered/billed under the P2 plan), not a per-machine cap and not per AMA-covered machine. Individual servers can ingest more as long as the pool isn’t exceeded. Use the [Defender for Servers P2 Count](https://github.com/mathijsvermaat/DefenderForServersP2Count) KQL to enumerate the licensed/billed server count across your subscriptions. The allowance applies only to [eligible tables](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) — `SecurityAlert`, `SecurityBaseline`, `SecurityBaselineSummary`, `SecurityDetection`, `SecurityEvent`, `WindowsFirewall`, `ProtectionStatus`, `MDCFileIntegrityMonitoringEvents`, the `Microsoft-SecurityEvent` stream that lands in `SecurityEvent` (via `WindowsEvent`), and `Update` / `UpdateSummary` (only when the Update Management solution isn't running in the workspace, or solution targeting is enabled). `LinuxAuditLog`, the general `Syslog` table, `CommonSecurityLog`, `W3CIISLog`, and non-SecurityEvent `WindowsEvent` channels (PowerShell, Sysmon, AppLocker) are **not** eligible. This is one of the key cost arguments for deploying Defender for Servers P2.

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

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------|:------------------|
| **[4624](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4624)** | Successful logon | ✅ | ✅ | ✅ | Core authentication forensics — who, from where, which logon type (3=network, 10=RDP). | Reconstruct full authentication timeline — proves when and how access was gained, the logon type, source IP, and account used | [34 mappings](#mitre-detection-strategies) | Lateral movement via network logon from unexpected source |
| **[4625](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4625)** | Failed logon | ✅ | ✅ | ✅ | Brute-force and password spray detection. | Quantify attack intensity and duration — proves volume, timing, and source of brute-force or spray attempts across accounts | [10 mappings](#mitre-detection-strategies) | RDP brute-force — high volume failed Type 10 logons |
| **[4634](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4634)** | Logoff | ❌ | ✅ | ✅ | Session duration tracking — scopes attacker activity windows during IR | Determine exact session duration — pairing with 4624 proves how long an attacker was active on each system | [5 mappings](#mitre-detection-strategies) | Session duration analysis during incident response |
| **[4648](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4648)** | Logon with explicit credentials | ❌ | ✅ | ✅ | Detects runas, PsExec, and credential-based lateral movement | Proves credential reuse and lateral movement — shows when an attacker used stolen credentials on a compromised host | [33 mappings](#mitre-detection-strategies) | Explicit credential use for lateral movement |
| **[4672](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4672)** | Special privileges assigned at logon | ❌ | ✅ | ✅ | Every logon receiving admin privileges — critical for monitoring admin activity | Identify every administrative access event — proves which sessions had elevated privileges, essential for scoping admin-level compromise | [16 mappings](#mitre-detection-strategies) | Admin logon from unexpected source or at unusual time |
| **[4740](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4740)** | Account locked out | ✅ | ✅ | ✅ | Brute-force indicator — lockout storm across accounts | Correlate lockout events with attack timing — proves the impact of a brute-force campaign on account availability | [1 mapping](#mitre-detection-strategies) | Account lockout storm indicating password spray |
| **[4768](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4768)** | Kerberos TGT requested | ❌ | ✅ | ✅ | Kerberoasting and pass-the-ticket detection. DC-only event. | Detect Kerberos-based attacks at source — proves TGT request patterns, encryption types, and anomalous ticket requests on DCs | [6 mappings](#mitre-detection-strategies) | High TGT volume with weak encryption type |
| **[4769](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4769)** | Kerberos service ticket requested | ❌ | ✅ | ✅ | Service ticket abuse detection — abnormal SPN access patterns | Trace service ticket requests to identify Kerberoasting — proves which SPNs were targeted and from which account | [5 mappings](#mitre-detection-strategies) | Kerberoasting — unusual service ticket requests |
| **[4771](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4771)** | Kerberos pre-authentication failed | ❌ | ✅ | ✅ | Password spray against Kerberos (pre-auth failure) | Evidence of pre-authentication brute-force — proves spray activity at the Kerberos level that may not appear in standard logon events | [2 mappings](#mitre-detection-strategies) | Spray across user accounts via Kerberos |
| **[4776](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4776)** | NTLM authentication attempt | ❌ | ✅ | ✅ | Legacy authentication abuse — NTLM from unexpected hosts | Track NTLM relay and pass-the-hash — proves legacy auth usage patterns and identifies hosts still using NTLM | [5 mappings](#mitre-detection-strategies) | NTLM auth from non-legacy host indicating relay attack |

##### Account and Group Management Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------|:------------------|
| **[4720](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4720)** | User account created | ✅ | ✅ | ✅ | Persistence via new local accounts. | Prove account creation as persistence — shows exactly when and by whom a backdoor account was created | [6 mappings](#mitre-detection-strategies) | New local account created and added to Administrators |
| **[4722](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4722)** | User account enabled | ✅ | ✅ | ✅ | Reactivation of dormant/backdoor accounts | Detect reactivated accounts — proves when a disabled account was re-enabled and by which identity | — | Dormant account re-enabled outside business hours |
| **[4724](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4724)** | Password reset attempt | ✅ | ✅ | ✅ | Unauthorized password resets — account takeover | Trace credential manipulation — proves who reset which password and when, critical for account takeover investigations | [1 mapping](#mitre-detection-strategies) | Password reset on admin account by non-helpdesk user |
| **[4726](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4726)** | User account deleted | ✅ | ✅ | ✅ | Covering tracks by deleting created accounts | Evidence of anti-forensic activity — proves attacker cleaned up backdoor accounts post-exploitation | [1 mapping](#mitre-detection-strategies) | Account deletion shortly after suspicious activity |
| **[4728](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4728)** | Member added to global security group | ✅ | ✅ | ✅ | Privilege escalation: additions to Domain Admins. | Prove privilege escalation path — authoritative record of group membership changes on DCs | [2 mappings](#mitre-detection-strategies) | User added to Domain Admins |
| **[4732](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4732)** | Member added to local security group | ✅ | ✅ | ✅ | Local admin escalation via group membership | Trace local privilege escalation — proves when and by whom a user was added to local Administrators | [1 mapping](#mitre-detection-strategies) | User added to local Administrators group |
| **[4756](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4756)** | Member added to universal security group | ✅ | ✅ | ✅ | High-impact: Enterprise Admin and other forest-wide groups | Prove forest-wide privilege escalation — authoritative evidence of Enterprise Admin group modifications | [1 mapping](#mitre-detection-strategies) | User added to Enterprise Admins |
| **[4731](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4731)** | Local security group created | ❌ | ✅ | ✅ | Privilege staging — new admin-like groups | Detect privilege staging — proves creation of new local groups that may have been used to grant access | — | New local administrative group created |
| **[4741](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4741)** | Computer account created | ❌ | ✅ | ✅ | Rogue machine join or resource-based constrained delegation abuse | Detect rogue domain joins — proves unauthorized machine accounts that may enable delegation attacks | — | Computer account created outside provisioning |
| **[4742](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4742)** | Computer account changed | ❌ | ✅ | ✅ | SPN or delegation property modification — delegation abuse | Trace delegation abuse setup — proves SPN or delegation attribute changes on computer objects | — | SPN modified on computer object |

##### Process, Persistence, and Policy Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------|:------------------|
| **[4688](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4688)** | Process created (with command line) | ✅ | ✅ | ✅ | **High-value forensic event.** Requires GPO "Include command line in process creation events." | Independent execution audit trail — authoritative process creation record that persists even if the EDR is bypassed or tampered with | [106 mappings](#mitre-detection-strategies) | Encoded PowerShell, LOLBin execution |
| **[4698](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4698)** | Scheduled task created | ✅ | ✅ | ✅ | Persistence detection. | Prove persistence installation — exact time, task name, command, and creating account | [7 mappings](#mitre-detection-strategies) | Task created to run from AppData or temp |
| **[4699](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4699)** | Scheduled task deleted | ❌ | ✅ | ✅ | Defence evasion — task deleted after execution | Evidence of anti-forensic cleanup — proves attacker removed persistence artifacts | — | Task deleted immediately after single execution |
| **[4697](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4697)** | Service installed | ✅ | ✅ | ✅ | Service-based persistence. | Identify service-based persistence — proves which binary was registered as a service and when | [5 mappings](#mitre-detection-strategies) | Service installed from user-writable path |
| **[4702](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4702)** | Scheduled task updated | ✅ | ✅ | ✅ | Modified tasks may indicate hijacked persistence | Detect persistence hijacking — proves when a legitimate task was modified to execute malicious code | [1 mapping](#mitre-detection-strategies) | Task path changed to suspicious location |
| **[4719](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4719)** | Audit policy changed | ✅ | ✅ | ✅ | Anti-forensic: attacker disabling audit logging. | Prove logging was tampered with — authoritative evidence that audit policy was weakened by the attacker | — | Audit policy disabled after admin logon |
| **[1102](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-1102)** | Audit log cleared | ✅ | ✅ | ✅ | **Critical anti-forensic indicator.** | The last event before log destruction — proves the log was cleared and by whom. If this event exists in Sentinel, the centralised copy is the only surviving evidence. | [3 mappings](#mitre-detection-strategies) | Security log cleared by non-admin account |
| **[4739](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4739)** | Domain policy changed | ✅ | ✅ | ✅ | Domain-wide GPO changes weakening security | Prove domain-level security weakening — authoritative evidence of GPO modifications that relaxed security controls | [2 mappings](#mitre-detection-strategies) | GPO modified to relax password policy |

##### Network and Firewall Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------|:------------------|
| **[5140](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5140)** | Network share accessed | ❌ | ✅ | ✅ | Lateral movement via admin shares (C$, ADMIN$). | Map lateral movement paths — proves which shares were accessed, from where, and by whom during an attack | [1 mapping](#mitre-detection-strategies) | Access to C$/ADMIN$ from unexpected source |
| **[5145](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5145)** | Network share object checked | ❌ | ✅ | ✅ | Data staging and write attempts to admin shares | Trace data exfiltration and staging — proves file-level write operations to network shares | [7 mappings](#mitre-detection-strategies) | Write attempt to admin share indicating staging |
| **[5156](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5156)** | WFP connection allowed | ❌ | ✅ | ✅ | OS-level network connection tracking | Independent network telemetry — proves outbound connections even if the EDR was disabled or tampered with | [4 mappings](#mitre-detection-strategies) | Outbound connection to rare destination |
| **[4946](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4946)** | Firewall rule added | ✅ | ✅ | ✅ | Network exposure — new inbound allow rules | Prove defence evasion — shows exactly when firewall rules were created to allow C2 or lateral movement | — | New allow rule for suspicious port |
| **[4948](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4948)** | Firewall rule modified | ✅ | ✅ | ✅ | C2 enablement via rule modification | Track security control changes — proves which rules were weakened and when | — | Rule changed + outbound traffic spike |
| **[4956](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4956)** | Firewall profile changed | ✅ | ✅ | ✅ | Defence evasion — profile change | Evidence of network profile manipulation — proves profile changes that weaken firewall protection | — | Public → Private profile change |

##### AppLocker / WDAC Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------|:------------------|
| **[8001](https://learn.microsoft.com/windows/security/application-security/application-control/app-control-for-business/applocker/using-event-viewer-with-applocker)** | AppLocker policy applied | ✅ | ✅ | ✅ | Control enforcement validation | Prove application control state — confirms whether AppLocker policy was active at the time of an incident | [2 mappings](#mitre-detection-strategies) | Unexpected policy application |
| **[8003](https://learn.microsoft.com/windows/security/application-security/application-control/app-control-for-business/applocker/using-event-viewer-with-applocker)** | AppLocker blocked execution | ✅ | ✅ | ✅ | Blocked malware/LOLBin attempts | Evidence of blocked attack attempts — proves malware or LOLBin execution was attempted even though it was blocked | [1 mapping](#mitre-detection-strategies) | Repeated block attempts from same source |
| **[8222](https://learn.microsoft.com/windows/security/application-security/application-control/app-control-for-business/applocker/using-event-viewer-with-applocker)** | WDAC enforcement event | ✅ | ✅ | ✅ | Application control policy violation | Prove policy violation attempts — evidence of application control bypass efforts on critical systems | — | WDAC policy violation on critical server |

##### Credential Access Events

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------|:------------------|
| **5379** | Credential Manager credentials read | ❌ | ✅ | ✅ | Credential dumping precursor — reading stored credentials | Detect credential harvesting — proves which process accessed Credential Manager and when, identifying pre-exfiltration activity | — | Cred read by non-browser process |

##### Full (All Events) Only — Additional Forensic and Audit Events

The following events are **only available in the All Events preset** (or via a Custom DCR). These provide deeper forensic granularity — particularly valuable for domain controllers, file servers, and compliance-driven environments.

| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |
|:---------|:------------|:-------:|:------:|:----:|:----------|:---------------|:------|:------------------|
| **[4663](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4663)** | Object access attempt | ❌ | ❌ | ✅ | Sensitive file/registry object access auditing. Detects access to credential files, SAM database, and sensitive data. Requires SACL configuration on target objects. | Prove exactly which files/objects were accessed — authoritative evidence of data access patterns during exfiltration or credential theft | [51 mappings](#mitre-detection-strategies) | Access to credential files or SAM database |
| **[4656](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4656)** | Handle to object requested | ❌ | ❌ | ✅ | Detailed object access — tracks which process requested access to a specific object and with what permissions | Trace process-to-object access chains — proves exactly which process opened handles to LSASS or sensitive objects | [51 mappings](#mitre-detection-strategies) | Handle request to LSASS process memory |
| **[4670](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4670)** | Permissions on object changed | ❌ | ❌ | ✅ | Detects permission changes on files, registry, or AD objects — key for detecting attackers weakening ACLs | Evidence of ACL manipulation — proves when and how access controls were weakened on sensitive resources | [52 mappings](#mitre-detection-strategies) | DACL modified on sensitive file or registry key |
| **[4907](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4907)** | Auditing settings on object changed | ❌ | ❌ | ✅ | Anti-forensic: attacker removing SACLs to stop generating audit events for sensitive objects | Prove audit evasion — evidence that SACLs were removed to suppress future audit events, indicating sophisticated attacker activity | — | SACL removed from sensitive directory |
| **[4703](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4703)** | Token right adjusted | ❌ | ❌ | ✅ | Privilege token manipulation — SeDebugPrivilege enables LSASS access; SeImpersonatePrivilege enables potato-style attacks | Prove privilege escalation technique — shows exactly when dangerous privileges were enabled on a process | — | SeDebugPrivilege enabled on non-admin process |
| **[4706](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4706)** | New trust created to domain | ❌ | ❌ | ✅ | Domain trust creation — highly sensitive change that could enable cross-domain lateral movement | Authoritative evidence of trust manipulation — proves new trust relationships that may enable cross-forest attacks | — | New domain trust created |
| **[4713](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4713)** | Kerberos policy changed | ❌ | ❌ | ✅ | Changes to Kerberos ticket lifetime or renewal settings — can indicate Golden Ticket preparation | Prove Kerberos configuration tampering — evidence of ticket lifetime changes that may indicate Golden Ticket setup | — | Kerberos ticket lifetime extended |
| **[4770](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4770)** | Kerberos TGT renewed | ❌ | ❌ | ✅ | TGT renewal tracking — abnormal renewal patterns may indicate pass-the-ticket or Golden Ticket use | Detect ticket abuse patterns — proves abnormal TGT renewal activity that indicates pass-the-ticket or Golden Ticket usage | [2 mappings](#mitre-detection-strategies) | TGT renewed from unexpected host |
| **[4985](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4985)** | State of a transaction changed | ❌ | ❌ | ✅ | Transactional NTFS operations — can indicate advanced file system manipulation | Evidence of TxF abuse — proves transactional file system operations used for covert file manipulation | — | Transactional file operation on sensitive path |
| **[5136](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5136)** | Directory service object modified | ❌ | ❌ | ✅ | AD object attribute changes — tracks modifications to user, group, and computer objects at the attribute level | The most granular AD forensic event — proves exactly which AD attribute was changed, from what value, to what value, and by whom | [7 mappings](#mitre-detection-strategies) | AdminSDHolder modification, SPN added to user |
| **[5137](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5137)** | Directory service object created | ❌ | ❌ | ✅ | New AD objects — detects creation of GPOs, OUs, or other AD objects outside change management | Prove unauthorized AD changes — authoritative record of new AD objects created during an attack | — | New GPO created outside change window |
| **[5141](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5141)** | Directory service object deleted | ❌ | ❌ | ✅ | AD object deletion — covering tracks or disrupting services | Evidence of AD-level destruction — proves when and by whom AD objects were deleted for anti-forensic or disruptive purposes | — | OU or GPO deleted unexpectedly |

> [!TIP]
> The Full tier is especially valuable on **domain controllers** where events like 5136 (AD object modification), 4770 (Kerberos TGT renewal), and 4706 (trust creation) provide critical visibility that is unavailable from any other source.

> [!NOTE]
> The tables above show **key events per category**, not every Event ID in each tier. For the complete list, refer to the [Windows Security Event ID reference](https://learn.microsoft.com/en-us/azure/sentinel/windows-security-event-id-reference).

All events above follow the same retention recommendation: **Analytics: 90d / Lake: 365d**.

---

## Example Detections

The **MITRE ATT&CK** column links to the technique on attack.mitre.org. The **Detection Strategy** column links to MITRE's [Detection Strategies catalogue](https://attack.mitre.org/detectionstrategies/) — pseudo-code analytic patterns published by MITRE that describe how to detect a technique across multiple data sources.

| Detection | Event ID(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:------------|:-------------|:-------------------|:------------|
| RDP brute-force | 4625 (Type 10) | [T1110](https://attack.mitre.org/techniques/T1110/) | [DET0463](https://attack.mitre.org/detectionstrategies/DET0463/) — Brute Force Authentication Failures with Multi-Platform Log Correlation | High volume of failed RDP logons from a single source IP |
| Lateral movement via network logon | 4624 (Type 3), 4648 | [T1021](https://attack.mitre.org/techniques/T1021/) | [DET0269](https://attack.mitre.org/detectionstrategies/DET0269/) — Behavioral Detection Strategy for Remote Service Logins and Post-Access Activity | Network logon from an unexpected source, especially to servers |
| New local admin account | 4720, 4732 | [T1136.001](https://attack.mitre.org/techniques/T1136/001/) | [DET0447](https://attack.mitre.org/detectionstrategies/DET0447/) — T1136.001 Detection Strategy - Local Account Creation Across Platforms | New user account created and added to local Administrators group |
| Suspicious process execution | 4688 | [T1059](https://attack.mitre.org/techniques/T1059/) | [DET0516](https://attack.mitre.org/detectionstrategies/DET0516/) — Behavioral Detection of Command and Scripting Interpreter Abuse | PowerShell/cmd launching with encoded commands, download cradles |
| Scheduled task persistence | 4698 | [T1053.005](https://attack.mitre.org/techniques/T1053/005/) | [DET0441](https://attack.mitre.org/detectionstrategies/DET0441/) — Detection of Suspicious Scheduled Task Creation and Execution on Windows | New scheduled task created with suspicious command line |
| Service installation | 4697 | [T1543.003](https://attack.mitre.org/techniques/T1543/003/) | [DET0552](https://attack.mitre.org/detectionstrategies/DET0552/) — Detection of Windows Service Creation or Modification | New service installed pointing to unusual binary path |
| Audit log cleared | 1102 | [T1070.001](https://attack.mitre.org/techniques/T1070/001/) (revoked → [T1685.005](https://attack.mitre.org/techniques/T1685/005/)) | [DET0532](https://attack.mitre.org/detectionstrategies/DET0532/) — Detection of Event Log Clearing on Windows via Behavioral Chain | Security event log cleared — high-confidence attacker indicator |
| Privilege escalation (group modification) | 4728, 4732, 4756 | [T1098](https://attack.mitre.org/techniques/T1098/) | [DET0096](https://attack.mitre.org/detectionstrategies/DET0096/) — Account Manipulation Behavior Chain Detection | User added to a privileged local or domain group |
| Pass-the-hash detection | 4624 (Type 9), 4648 | [T1550.002](https://attack.mitre.org/techniques/T1550/002/) | [DET0409](https://attack.mitre.org/detectionstrategies/DET0409/) — Detection Strategy for T1550.002 - Pass the Hash (Windows) | New logon with explicit credentials combined with NTLM authentication |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page. The **MITRE Log Sources (Windows)** column lists the exact log channels and event codes referenced by the *Windows* analytic of each strategy — taken verbatim from the strategy's published `log_sources` field in the [ATT&CK STIX bundle](https://github.com/mitre-attack/attack-stix-data). Channels other than `Security` (e.g. `Sysmon`, `System`, `PowerShell`) require additional collection (custom DCR for `WindowsEvent`, or the Sysmon / PowerShell connectors); they're shown here so you can see the full correlation MITRE expects.

| Technique | Detection Strategy | MITRE Log Sources (Windows) |
|:----------|:-------------------|:----------------------------|
| [T1003.001](https://attack.mitre.org/techniques/T1003/001/) — OS Credential Dumping: LSASS Memory | [DET0363](https://attack.mitre.org/detectionstrategies/DET0363/) — Detection of Credential Dumping from LSASS Memory via Access and Dump Sequence | `Security`: 4673 · `Sysmon`: 1, 10, 11, 13, 14 |
| [T1005](https://attack.mitre.org/techniques/T1005/) — Data from Local System | [DET0380](https://attack.mitre.org/detectionstrategies/DET0380/) — Detection of Local Data Collection Prior to Exfiltration | `Security`: 4688 · `Sysmon`: 11 |
| [T1021](https://attack.mitre.org/techniques/T1021/) — Remote Services | [DET0269](https://attack.mitre.org/detectionstrategies/DET0269/) — Behavioral Detection Strategy for Remote Service Logins and Post-Access Activity | `Security`: 4624, 4648 · `Sysmon`: 1, 3, 22 |
| [T1021.002](https://attack.mitre.org/techniques/T1021/002/) — SMB/Windows Admin Shares | [DET0530](https://attack.mitre.org/detectionstrategies/DET0530/) — Multi-Event Detection for SMB Admin Share Lateral Movement | `Security`: 4624, 4648 · `Sysmon`: 1, 3, 22 |
| [T1053.005](https://attack.mitre.org/techniques/T1053/005/) — Scheduled Task | [DET0441](https://attack.mitre.org/detectionstrategies/DET0441/) — Detection of Suspicious Scheduled Task Creation and Execution on Windows | `Security`: 4698, 4702 · `Sysmon`: 1, 11, 13, 14 |
| [T1059](https://attack.mitre.org/techniques/T1059/) — Command and Scripting Interpreter | [DET0516](https://attack.mitre.org/detectionstrategies/DET0516/) — Behavioral Detection of Command and Scripting Interpreter Abuse | `Sysmon`: 1 *(no `Security`-channel analytic published)* |
| [T1059.001](https://attack.mitre.org/techniques/T1059/001/) — PowerShell | [DET0455](https://attack.mitre.org/detectionstrategies/DET0455/) — Abuse of PowerShell for Arbitrary Execution | `PowerShell`: 400, 403, 4103, 4104, 4105, 4106 · `Sysmon`: 1, 7 *(no `Security`-channel analytic published)* |
| [T1070](https://attack.mitre.org/techniques/T1070/) — Indicator Removal | [DET0184](https://attack.mitre.org/detectionstrategies/DET0184/) — Behavioral Detection of Indicator Removal Across Platforms | `Security`: 1102 · `Sysmon`: 13, 14, 23 |
| [T1071](https://attack.mitre.org/techniques/T1071/) — Application Layer Protocol | [DET0444](https://attack.mitre.org/detectionstrategies/DET0444/) — Detection of Command and Control Over Application Layer Protocols | `Sysmon`: 3, 22 · `NSM:Flow`: http, dns, smb, ssl *(no `Security`-channel analytic published)* |
| [T1078](https://attack.mitre.org/techniques/T1078/) — Valid Accounts | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Detection of Valid Account Abuse Across Platforms | `Security`: 4624, 4625, 4776 · `Sysmon`: 1 |
| [T1098](https://attack.mitre.org/techniques/T1098/) — Account Manipulation | [DET0096](https://attack.mitre.org/detectionstrategies/DET0096/) — Account Manipulation Behavior Chain Detection | `Security`: 4670, 4728, 4738 · `Sysmon`: 1 |
| [T1098.004](https://attack.mitre.org/techniques/T1098/004/) — SSH Authorized Keys | [DET0126](https://attack.mitre.org/detectionstrategies/DET0126/) — Detection Strategy for SSH Key Injection in Authorized Keys | *MITRE has not published a Windows analytic for this strategy* |
| [T1110](https://attack.mitre.org/techniques/T1110/) — Brute Force | [DET0463](https://attack.mitre.org/detectionstrategies/DET0463/) — Brute Force Authentication Failures with Multi-Platform Log Correlation | `Security`: 4625, 4776 |
| [T1134](https://attack.mitre.org/techniques/T1134/) — Access Token Manipulation | [DET0283](https://attack.mitre.org/detectionstrategies/DET0283/) — Behavior-chain detection for T1134 Access Token Manipulation on Windows | `Security`: 4634, 4672, 5136 · `Sysmon`: 1, 10 · `ETW:Token` API trace |
| [T1136](https://attack.mitre.org/techniques/T1136/) — Create Account | [DET0583](https://attack.mitre.org/detectionstrategies/DET0583/) — Detection Strategy for T1136 - Create Account across platforms | `Security`: 4720 · `Sysmon`: 1 |
| [T1136.001](https://attack.mitre.org/techniques/T1136/001/) — Local Account | [DET0447](https://attack.mitre.org/detectionstrategies/DET0447/) — T1136.001 Detection Strategy - Local Account Creation Across Platforms | `Security`: 4720 · `Sysmon`: 1 |
| [T1136.002](https://attack.mitre.org/techniques/T1136/002/) — Domain Account | [DET0003](https://attack.mitre.org/detectionstrategies/DET0003/) — T1136.002 Detection Strategy - Domain Account Creation Across Platforms | `Security`: 4720 · `Sysmon`: 1 |
| [T1222](https://attack.mitre.org/techniques/T1222/) — File and Directory Permissions Modification | [DET0299](https://attack.mitre.org/detectionstrategies/DET0299/) — Multi-Platform File and Directory Permissions Modification Detection Strategy | `Security`: 4656, 4663, 4670, 4688 · `Sysmon`: 11 · `PowerShell`: 4103, 4104, 4105, 4106 |
| [T1484.001](https://attack.mitre.org/techniques/T1484/001/) — Group Policy Modification | [DET0305](https://attack.mitre.org/detectionstrategies/DET0305/) — Detection of Group Policy Modifications via AD Object Changes and File Activity | `Security`: 4656, 4663, 4670, 4704, 5136 · `Sysmon`: 1, 11 |
| [T1484.002](https://attack.mitre.org/techniques/T1484/002/) — Domain Trust Modification | [DET0458](https://attack.mitre.org/detectionstrategies/DET0458/) — Detection of Trust Relationship Modifications in Domain or Tenant Policies | `Security`: 4704, 5136 · `Sysmon`: 1 |
| [T1543.003](https://attack.mitre.org/techniques/T1543/003/) — Windows Service | [DET0552](https://attack.mitre.org/detectionstrategies/DET0552/) — Detection of Windows Service Creation or Modification | `Security`: 4697 · `Sysmon`: 1, 6, 13, 14 |
| [T1550.002](https://attack.mitre.org/techniques/T1550/002/) — Pass the Hash | [DET0409](https://attack.mitre.org/detectionstrategies/DET0409/) — Detection Strategy for T1550.002 - Pass the Hash (Windows) | `Security`: 4624, 4648, 4768 · `Sysmon`: 1, 3, 22 |
| [T1550.003](https://attack.mitre.org/techniques/T1550/003/) — Pass the Ticket | [DET0352](https://attack.mitre.org/detectionstrategies/DET0352/) — Detection Strategy for T1550.003 - Pass the Ticket (Windows) | `Security`: 4624, 4648, 4768, 4769 · `Sysmon`: 7, 10 |
| [T1555](https://attack.mitre.org/techniques/T1555/) — Credentials from Password Stores | [DET0430](https://attack.mitre.org/detectionstrategies/DET0430/) — Detect Credentials Access from Password Stores | `Security`: 4656, 4663, 4670 · `Sysmon`: 1, 10 |
| [T1558](https://attack.mitre.org/techniques/T1558/) — Steal or Forge Kerberos Tickets | [DET0522](https://attack.mitre.org/detectionstrategies/DET0522/) — Detect Kerberos Ticket Theft or Forgery | `Security`: 4634, 4672 · `Sysmon`: 10 |
| [T1558.001](https://attack.mitre.org/techniques/T1558/001/) — Golden Ticket | [DET0144](https://attack.mitre.org/detectionstrategies/DET0144/) — Detect Forged Kerberos Golden Tickets | `Security`: 4634, 4672, 4769 · `Sysmon`: 10 |
| [T1558.003](https://attack.mitre.org/techniques/T1558/003/) — Kerberoasting | [DET0157](https://attack.mitre.org/detectionstrategies/DET0157/) — Detect Kerberoasting Attempts | `Security`: 4624, 4648, 4672, 4769 · `Sysmon`: 10 |
| [T1070.001](https://attack.mitre.org/techniques/T1070/001/) — Clear Windows Event Logs *(revoked → [T1685.005](https://attack.mitre.org/techniques/T1685/005/))* | [DET0532](https://attack.mitre.org/detectionstrategies/DET0532/) — Detection of Event Log Clearing on Windows via Behavioral Chain | `Security`: 1102 · `Sysmon`: 1, 23 |
| [T1562](https://attack.mitre.org/techniques/T1562/) — Impair Defenses *(revoked → [T1685](https://attack.mitre.org/techniques/T1685/))* | [DET0497](https://attack.mitre.org/detectionstrategies/DET0497/) — Detection of Defense Impairment through Disabled or Modified Tools across OS Platforms | `System`: 7045 · `Sysmon`: 5, 13, 14 *(no `Security`-channel analytic published)* |
| [T1562.002](https://attack.mitre.org/techniques/T1562/002/) — Disable Windows Event Logging *(revoked → [T1685.001](https://attack.mitre.org/techniques/T1685/001/))* | [DET0187](https://attack.mitre.org/detectionstrategies/DET0187/) — Detect Disabled Windows Event Log | `Security`: 1102 · `System`: 7035 · `Sysmon`: 1, 13, 14 |
| [T1562.004](https://attack.mitre.org/techniques/T1562/004/) — Disable or Modify System Firewall *(revoked → [T1686](https://attack.mitre.org/techniques/T1686/))* | [DET0145](https://attack.mitre.org/detectionstrategies/DET0145/) — Detection of Disabled or Modified System Firewalls across OS Platforms | `Security`: 4688 · `Sysmon`: 13, 14 |

> [!NOTE]
> **Log sources are verbatim from MITRE.** The third column is generated directly from each strategy's published `x_mitre_log_source_references` field in the [ATT&CK STIX 2.1 bundle](https://github.com/mitre-attack/attack-stix-data) — it is **not** a hand-picked list of "events that look related on this connector page". If the cell shows only `Sysmon` or `PowerShell` events, that is exactly what MITRE's Windows analytic queries; the page-author has not substituted similar-looking `Security`-channel events. Where MITRE has not published a Windows analytic at all (e.g. DET0126), the cell says so explicitly.

> [!NOTE]
> **MITRE legacy technique IDs.** Several technique IDs cited elsewhere on this page (and in Microsoft Sentinel content) are *legacy* IDs — in the April 2026 ATT&CK release MITRE **revoked** the `T1070.001`, `T1562`, `T1562.002` and `T1562.004` techniques and moved them into a new `T1685` / `T1686` family ("Disable or Modify Tools" / "Disable or Modify System Firewalls"). Published Detection Strategies are attached to the *current* technique IDs only. The table above follows the `revoked-by` chain in the MITRE STIX bundle, so the strategy in each row applies to the legacy ID cited on the page — the parenthetical *(revoked → T1685.x)* shows the current technique. Pages may continue to cite legacy IDs because that is what Microsoft Sentinel docs and built-in analytic rules still reference.

> [!TIP]
> Detection Strategies are MITRE-published *pseudo-code analytics*, not vendor rules — they tell you **what** to correlate (e.g. process-creation + token-adjustment + network-connection within N seconds) across data sources. Use them to validate that your Sentinel analytics rules and KQL hunting queries cover the published correlation logic.

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
> The P2 benefit of 500 MB/day per licensed server is a pooled allowance covering **all qualifying security data types** combined (`SecurityEvent`, the `Microsoft-SecurityEvent` `WindowsEvent` stream, `SecurityAlert`, `SecurityBaseline*`, `SecurityDetection`, `WindowsFirewall`, `ProtectionStatus`, `MDCFileIntegrityMonitoringEvents`, and conditionally `Update` / `UpdateSummary`) — not 500 MB per data type. Note that `LinuxAuditLog` and the general `Syslog` table are **not** eligible and are billed at standard ingestion rates. See the [data ingestion benefit documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) for the full list.

> [!TIP]
> To validate the size of your pooled allowance, use the [Defender for Servers P2 Count](https://github.com/mathijsvermaat/DefenderForServersP2Count) KQL query (Azure Resource Graph). It enumerates the servers currently covered by the P2 plan across your subscriptions so you can multiply the count by 500 MB to reconcile actual ingestion against the benefit.

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
| **Defender AMA Coverage** | Workbook | Validate AMA agent deployment and Windows Security Event collection coverage | [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) | [Walkthrough](../procedures/defender-ama-coverage.md) · [Blog](https://www.linkedin.com/pulse/closing-telemetry-gap-how-we-built-kql-query-workbook-mathijs-vermaat-rzfbe/) |
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
