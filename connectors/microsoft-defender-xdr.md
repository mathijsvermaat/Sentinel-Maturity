# Microsoft Defender XDR

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes — Analytics tier only ([E5 Security data grant](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer))

---

## Overview

The Microsoft Defender XDR connector ingests advanced hunting data from Microsoft Defender for Endpoint (MDE), Microsoft Defender for Office 365 (MDO), Microsoft Defender for Identity (MDI), and Microsoft Defender for Cloud Apps (MDA) into Microsoft Sentinel. This is the **single most valuable connector** for organisations with Microsoft 365 E5 or equivalent licensing, as it provides deep endpoint, email, identity, and cloud application telemetry — all at **zero additional ingestion cost** when ingested to the **Analytics tier** via the security data grant.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft 365 E5 / E5 Security** | Full MDE, MDO, MDI, MDA data — ingested free into Sentinel **Analytics tier** (not Lake direct ingest) |
| **Defender for Endpoint P2 (standalone)** | MDE data for endpoints |

> [!NOTE]
> The E5 security data grant covers ingestion of Defender XDR advanced hunting tables into the Sentinel **Analytics tier** at no additional cost. Ingesting directly to the Sentinel Data Lake (Lake) does **not** qualify for the free grant. See [Microsoft Sentinel benefit for M365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer) for details.

> [!IMPORTANT]
> Defender for Servers P2 provides a [500 MB/day ingestion benefit](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) for specific security data types (SecurityEvent, Syslog, etc.) but this does **not** apply to Defender XDR advanced hunting tables.

---

## Tables and Rationale

### Endpoint Tables (Microsoft Defender for Endpoint)

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **DeviceInfo** | Device inventory, OS, health state, onboarding status | Analytics: 90d / Lake: 365d | Asset inventory is foundational for incident scoping. MCSB AM-1 (Asset inventory). Knowing which devices were in scope at any point in time is critical for forensic reconstruction. | Asset inventory drift — device OS not updated or health state degraded |
| **DeviceNetworkInfo** | Network adapter configuration, IPs, MAC addresses, DNS, DHCP | Analytics: 90d / Lake: 365d | Network context for lateral movement investigation. MCSB LT-4 (Network logging). Helps correlate network-based detections with device identities. | Device network configuration change correlating with lateral movement |
| **DeviceProcessEvents** | Process creation events with command lines | Analytics: 90d / Lake: 365d | **Core forensic table.** Process execution chains are the backbone of threat hunting and incident response. MCSB LT-3 (Security investigation logging). Covers MITRE ATT&CK Execution, Defence Evasion, Persistence. | Suspicious PowerShell with encoded commands (T1059.001), LSASS credential dumping (T1003.001) |
| **DeviceNetworkEvents** | Outbound/inbound network connections per process | Analytics: 90d / Lake: 365d | C2 detection, data exfiltration hunting, lateral movement. MCSB LT-4. Essential for correlating process execution with network activity. | Outbound connection to known C2 infrastructure, SMB lateral movement (T1021.002) |
| **DeviceFileEvents** | File creation, modification, deletion | Analytics: 90d / Lake: 365d | Malware delivery, staging, and exfiltration forensics. MCSB LT-3. Tracks ransomware file encryption patterns and data staging. | Ransomware mass file rename/extension change pattern (T1486) |
| **DeviceRegistryEvents** | Registry key/value changes | Analytics: 90d / Lake: 365d | Persistence mechanism detection (Run keys, services, scheduled tasks registered via registry). MCSB LT-3. Covers MITRE ATT&CK Persistence and Defence Evasion. | New Run key persistence entry (T1547.001) |
| **DeviceLogonEvents** | Local and network logon events on endpoints | Analytics: 90d / Lake: 365d | Lateral movement detection, credential abuse. MCSB IR-4. Complements IdentityLogonEvents with endpoint-side visibility. | Unusual network logon (Type 3/10) from unexpected source — lateral movement |
| **DeviceImageLoadEvents** | DLL and driver loading events | Analytics: 90d / Lake: 365d | DLL side-loading, living-off-the-land detection. Covers MITRE ATT&CK Defence Evasion (T1574). | Unsigned DLL loaded from unusual path by legitimate process (T1574.002) |
| **DeviceEvents** | Miscellaneous events (exploit guard, tamper protection, USB, etc.) | Analytics: 90d / Lake: 365d | Catch-all for attack surface reduction, exploit protection, and peripheral device events. | ASR rule triggered, tamper protection event, USB device connected |
| **DeviceFileCertificateInfo** | Certificate information for signed files | Analytics: 90d / Lake: 365d | Validates file authenticity, detects unsigned or suspiciously signed binaries. Supports software integrity verification. | Executable signed with revoked or untrusted certificate |

### Alert Tables

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **AlertInfo** | Alerts from all Defender workloads | Analytics: 90d / Lake: 365d | Core incident response data. Every alert is a potential incident starting point. MCSB IR-4 (Detection and analysis). | Alert trend analysis, alert-to-incident correlation |
| **AlertEvidence** | Entities (files, processes, IPs, users) associated with alerts | Analytics: 90d / Lake: 365d | Investigation context — links alerts to actionable evidence. Essential for automated enrichment and SOAR playbooks. | Automated entity enrichment for incident triage |

### Email Tables (Microsoft Defender for Office 365)

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **EmailEvents** | Email delivery events, sender, recipient, subject, verdict | Analytics: 90d / Lake: 365d | Phishing and BEC detection. MCSB LT-3. Email is the #1 initial access vector (MITRE T1566). Retention beyond 90 days supports investigation of slow-burn phishing campaigns. | Phishing email from newly registered domain (T1566.002) |
| **EmailUrlInfo** | URLs contained in emails | Analytics: 90d / Lake: 365d | Phishing URL analysis and retroactive hunting when new IOCs emerge. | Retroactive IOC match on URL found in historical email |
| **EmailAttachmentInfo** | Attachment metadata, file hashes | Analytics: 90d / Lake: 365d | Malware delivery tracking. Enables retroactive hash lookups when new malware campaigns are identified. | Malware hash match on .iso/.vhd/.lnk attachment (T1566.001) |
| **EmailPostDeliveryEvents** | Post-delivery actions (ZAP, user-reported, admin actions) | Analytics: 90d / Lake: 365d | Tracks remediation effectiveness and identifies emails that bypassed initial filters. | Email delivered then ZAP'd — measure detection gap |

### Identity Tables (Microsoft Defender for Identity)

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **IdentityLogonEvents** | Authentication events from on-premises AD and cloud | Analytics: 90d / Lake: 365d | **Core identity security table.** Detects brute-force, password spray, pass-the-hash, pass-the-ticket attacks. MCSB IM-1 (Centralise identity management). Bridges the gap between on-premises AD and Entra ID. | Password spray — multiple failed logons across many accounts (T1110.003) |
| **IdentityQueryEvents** | LDAP, DNS, and SAMR queries against Active Directory | Analytics: 90d / Lake: 365d | Reconnaissance detection (MITRE T1087, T1069). Attackers enumerate users, groups, and computers before lateral movement. | Unusual LDAP query enumerating Domain Admins (T1087) |
| **IdentityDirectoryEvents** | Changes to AD objects (group membership, password resets, etc.) | Analytics: 90d / Lake: 365d | Privilege escalation and persistence detection. MCSB PA-1 (Protect privileged users). Tracks changes to sensitive groups like Domain Admins. | User added to Domain Admins group (T1098) |

### Cloud App Tables (Microsoft Defender for Cloud Apps)

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **CloudAppEvents** | Activities in cloud applications (Office 365, third-party SaaS) | Analytics: 90d / Lake: 365d | Shadow IT detection, impossible travel, mass download/sharing detection. MCSB LT-3. Provides visibility into SaaS application usage beyond Office 365. | Impossible travel to cloud app (T1078), mass file download from SharePoint (T1530) |

### Other Tables

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **UrlClickEvents** | Safe Links click events (user clicks on URLs in emails) | Analytics: 90d / Lake: 365d | Identifies users who clicked on malicious links despite warnings. Critical for BEC and phishing response workflows. | User clicked Safe Links warning override on phishing URL |

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

- The free data grant applies to ingestion into the **Analytics tier only** — ingesting directly to the Sentinel Data Lake (Lake) is not covered by the E5 grant
- Consider using **Basic Logs** for high-volume tables like `DeviceNetworkEvents` and `DeviceFileEvents` if cost becomes a concern beyond the free grant
- The free data grant applies to **advanced hunting tables only** — custom logs or additional enrichment pipelines may incur cost
- Enable **Incident creation rules** to automatically create Sentinel incidents from Defender XDR alerts

### Useful Workbooks

| Workbook | Purpose | Source |
|:---------|:--------|:-------|
| **Workspace Usage Report** | Monitor Defender XDR table ingestion volumes and validate the E5 data grant | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
