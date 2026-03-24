# Microsoft Defender XDR

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes (E5 Security data grant)

---

## Overview

The Microsoft Defender XDR connector ingests advanced hunting data from Microsoft Defender for Endpoint (MDE), Microsoft Defender for Office 365 (MDO), Microsoft Defender for Identity (MDI), and Microsoft Defender for Cloud Apps (MDA) into Microsoft Sentinel. This is the **single most valuable connector** for organisations with Microsoft 365 E5 or equivalent licensing, as it provides deep endpoint, email, identity, and cloud application telemetry — all at **zero additional ingestion cost** via the security data grant.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft 365 E5 / E5 Security** | Full MDE, MDO, MDI, MDA data — ingested free into Sentinel |
| **Defender for Servers P2** | MDE data for servers (Windows and Linux) — 500 MB/day free per server |
| **Defender for Endpoint P2 (standalone)** | MDE data for endpoints |

> [!NOTE]
> The E5 security data grant covers ingestion of Defender XDR advanced hunting tables into Sentinel at no additional cost. This is one of the strongest arguments for enabling this connector.

---

## Tables and Rationale

### Endpoint Tables (Microsoft Defender for Endpoint)

| Table | Description | Retention Recommendation | Rationale |
|:------|:------------|:------------------------|:----------|
| **DeviceInfo** | Device inventory, OS, health state, onboarding status | Hot: 90d / Archive: 2y | Asset inventory is foundational for incident scoping. MCSB AM-1 (Asset inventory). Knowing which devices were in scope at any point in time is critical for forensic reconstruction. |
| **DeviceNetworkInfo** | Network adapter configuration, IPs, MAC addresses, DNS, DHCP | Hot: 90d / Archive: 1y | Network context for lateral movement investigation. MCSB LT-4 (Network logging). Helps correlate network-based detections with device identities. |
| **DeviceProcessEvents** | Process creation events with command lines | Hot: 90d / Archive: 2y | **Core forensic table.** Process execution chains are the backbone of threat hunting and incident response. MCSB LT-3 (Security investigation logging). Covers MITRE ATT&CK Execution, Defence Evasion, Persistence. |
| **DeviceNetworkEvents** | Outbound/inbound network connections per process | Hot: 90d / Archive: 2y | C2 detection, data exfiltration hunting, lateral movement. MCSB LT-4. Essential for correlating process execution with network activity. |
| **DeviceFileEvents** | File creation, modification, deletion | Hot: 90d / Archive: 2y | Malware delivery, staging, and exfiltration forensics. MCSB LT-3. Tracks ransomware file encryption patterns and data staging. |
| **DeviceRegistryEvents** | Registry key/value changes | Hot: 90d / Archive: 1y | Persistence mechanism detection (Run keys, services, scheduled tasks registered via registry). MCSB LT-3. Covers MITRE ATT&CK Persistence and Defence Evasion. |
| **DeviceLogonEvents** | Local and network logon events on endpoints | Hot: 90d / Archive: 2y | Lateral movement detection, credential abuse. MCSB IR-4. Complements IdentityLogonEvents with endpoint-side visibility. |
| **DeviceImageLoadEvents** | DLL and driver loading events | Hot: 90d / Archive: 1y | DLL side-loading, living-off-the-land detection. Covers MITRE ATT&CK Defence Evasion (T1574). |
| **DeviceEvents** | Miscellaneous events (exploit guard, tamper protection, USB, etc.) | Hot: 90d / Archive: 1y | Catch-all for attack surface reduction, exploit protection, and peripheral device events. |
| **DeviceFileCertificateInfo** | Certificate information for signed files | Hot: 90d / Archive: 1y | Validates file authenticity, detects unsigned or suspiciously signed binaries. Supports software integrity verification. |

### Alert Tables

| Table | Description | Retention Recommendation | Rationale |
|:------|:------------|:------------------------|:----------|
| **AlertInfo** | Alerts from all Defender workloads | Hot: 90d / Archive: 2y | Core incident response data. Every alert is a potential incident starting point. MCSB IR-4 (Detection and analysis). |
| **AlertEvidence** | Entities (files, processes, IPs, users) associated with alerts | Hot: 90d / Archive: 2y | Investigation context — links alerts to actionable evidence. Essential for automated enrichment and SOAR playbooks. |

### Email Tables (Microsoft Defender for Office 365)

| Table | Description | Retention Recommendation | Rationale |
|:------|:------------|:------------------------|:----------|
| **EmailEvents** | Email delivery events, sender, recipient, subject, verdict | Hot: 90d / Archive: 2y | Phishing and BEC detection. MCSB LT-3. Email is the #1 initial access vector (MITRE T1566). Retention beyond 90 days supports investigation of slow-burn phishing campaigns. |
| **EmailUrlInfo** | URLs contained in emails | Hot: 90d / Archive: 1y | Phishing URL analysis and retroactive hunting when new IOCs emerge. |
| **EmailAttachmentInfo** | Attachment metadata, file hashes | Hot: 90d / Archive: 1y | Malware delivery tracking. Enables retroactive hash lookups when new malware campaigns are identified. |
| **EmailPostDeliveryEvents** | Post-delivery actions (ZAP, user-reported, admin actions) | Hot: 90d / Archive: 1y | Tracks remediation effectiveness and identifies emails that bypassed initial filters. |

### Identity Tables (Microsoft Defender for Identity)

| Table | Description | Retention Recommendation | Rationale |
|:------|:------------|:------------------------|:----------|
| **IdentityLogonEvents** | Authentication events from on-premises AD and cloud | Hot: 90d / Archive: 2y | **Core identity security table.** Detects brute-force, password spray, pass-the-hash, pass-the-ticket attacks. MCSB IM-1 (Centralise identity management). Bridges the gap between on-premises AD and Entra ID. |
| **IdentityQueryEvents** | LDAP, DNS, and SAMR queries against Active Directory | Hot: 90d / Archive: 1y | Reconnaissance detection (MITRE T1087, T1069). Attackers enumerate users, groups, and computers before lateral movement. |
| **IdentityDirectoryEvents** | Changes to AD objects (group membership, password resets, etc.) | Hot: 90d / Archive: 2y | Privilege escalation and persistence detection. MCSB PA-1 (Protect privileged users). Tracks changes to sensitive groups like Domain Admins. |

### Cloud App Tables (Microsoft Defender for Cloud Apps)

| Table | Description | Retention Recommendation | Rationale |
|:------|:------------|:------------------------|:----------|
| **CloudAppEvents** | Activities in cloud applications (Office 365, third-party SaaS) | Hot: 90d / Archive: 2y | Shadow IT detection, impossible travel, mass download/sharing detection. MCSB LT-3. Provides visibility into SaaS application usage beyond Office 365. |

### Other Tables

| Table | Description | Retention Recommendation | Rationale |
|:------|:------------|:------------------------|:----------|
| **UrlClickEvents** | Safe Links click events (user clicks on URLs in emails) | Hot: 90d / Archive: 1y | Identifies users who clicked on malicious links despite warnings. Critical for BEC and phishing response workflows. |

---

## Example Detections

### Endpoint

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Suspicious PowerShell execution | DeviceProcessEvents | T1059.001 | Encoded commands, download cradles, AMSI bypass attempts |
| Lateral movement via PsExec / SMB | DeviceProcessEvents, DeviceNetworkEvents | T1021.002 | Remote service execution combined with SMB connections |
| Ransomware file encryption pattern | DeviceFileEvents | T1486 | Mass file rename/extension changes in short timeframes |
| Credential dumping (LSASS access) | DeviceProcessEvents, DeviceEvents | T1003.001 | Process access to LSASS memory |
| Persistence via registry Run key | DeviceRegistryEvents | T1547.001 | New entries in common autostart registry locations |
| Suspicious DLL side-loading | DeviceImageLoadEvents | T1574.002 | Unsigned DLLs loaded from unusual paths by legitimate processes |

### Email

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Phishing email with suspicious URL | EmailEvents, EmailUrlInfo | T1566.002 | Emails containing newly registered domains or known phishing infrastructure |
| Malware delivery via attachment | EmailEvents, EmailAttachmentInfo | T1566.001 | High-risk file types (.iso, .vhd, .lnk) delivered to users |
| Business Email Compromise (BEC) | EmailEvents, IdentityLogonEvents | T1534 | Emails from compromised accounts combined with unusual sign-in patterns |

### Identity

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Password spray attack | IdentityLogonEvents | T1110.003 | Multiple failed logons across many accounts from limited sources |
| AD reconnaissance (LDAP enumeration) | IdentityQueryEvents | T1087 | Unusual LDAP queries enumerating users, groups, or computers |
| Privilege escalation (group add) | IdentityDirectoryEvents | T1098 | User added to Domain Admins or other sensitive groups |

### Cloud Apps

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Impossible travel | CloudAppEvents | T1078 | Same user accessing cloud apps from geographically impossible locations |
| Mass file download from SharePoint | CloudAppEvents | T1530 | Unusual volume of file downloads indicating potential data exfiltration |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection | Defender XDR provides native threat detection across endpoint, email, identity, and cloud apps |
| **LT-3** Enable logging for security investigation | Advanced hunting tables provide deep forensic telemetry |
| **LT-4** Enable network logging | DeviceNetworkEvents provides process-level network visibility |
| **LT-6** Configure log storage retention | Retention recommendations ensure forensic readiness while managing cost |
| **IR-4** Detection and analysis | Alert tables feed directly into incident response workflows |
| **IM-1** Centralise identity management | IdentityLogonEvents bridges on-premises AD and cloud identity |
| **PA-1** Protect privileged users | IdentityDirectoryEvents tracks changes to privileged groups |

---

## Notes

- Consider using **Basic Logs** for high-volume tables like `DeviceNetworkEvents` and `DeviceFileEvents` if cost becomes a concern beyond the free grant
- The free data grant applies to **advanced hunting tables only** — custom logs or additional enrichment pipelines may incur cost
- Enable **Incident creation rules** to automatically create Sentinel incidents from Defender XDR alerts

*[Back to overview](../README.md)*
