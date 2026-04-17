# Office 365

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes (free data source)

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [OfficeActivity vs CloudAppEvents](#officeactivity-vs-cloudappevents)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)

---

## Overview

The Office 365 connector provides **audit log data for Exchange Online, SharePoint Online, and Microsoft Teams**. While there is overlap with Defender XDR's `CloudAppEvents` table, the Office 365 `OfficeActivity` table provides the native Office 365 audit format and is a **free data source** in Sentinel. It captures user and admin activities that are critical for insider threat detection, data exfiltration monitoring, and compliance.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Microsoft 365 license (E3/E5/Business)** | Exchange, SharePoint, and Teams audit logs |
| **Microsoft 365 E5** | Additional Audit (Premium) events — long-running search, more detailed MailItemsAccessed, Send events |

> [!NOTE]
> The Office 365 connector is a **free data source** in Sentinel. Enable it with all three workloads (Exchange, SharePoint, Teams).

---

## Tables and Rationale

| Table | Workload | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:---------|:------------|:------------------------|:----------|:---------------|:------------------|
| **OfficeActivity** (Exchange) | Exchange Online | Mailbox activity: login, mail access, send, delegate access, inbox rule creation, mailbox permissions changes | Analytics: 90d / Lake: 365d | BEC detection and investigation. Inbox rule creation is a top indicator of compromised mailboxes (MITRE T1564.008). MailItemsAccessed (E5 Audit Premium) enables precise forensic scoping of what data an attacker accessed. MCSB LT-3. | Reconstruct exactly which emails the attacker read, sent, or forwarded — MailItemsAccessed proves the blast radius of a BEC incident and which data was exposed. Essential for breach notification scoping. | Suspicious inbox rule forwarding to external domain (T1564.008), Delegate access granted (T1098.002) |
| **OfficeActivity** (SharePoint) | SharePoint Online | File access, sharing, download, upload, site collection changes | Analytics: 90d / Lake: 365d | Data exfiltration detection (mass downloads, external sharing). Insider threat monitoring. MCSB DP-2 (Protect sensitive data). Tracks who accessed which files and when — essential for data breach scoping. | Proves exactly which files were accessed or downloaded by a compromised account — critical for regulatory breach notification where you must demonstrate what data was exposed | Mass file download by single user (T1530), Anonymous sharing link created (T1567) |
| **OfficeActivity** (Teams) | Microsoft Teams | Teams messaging, meeting, app, and channel events | Analytics: 90d / Lake: 365d | Shadow IT detection (unauthorized apps in Teams), data loss via Teams messaging, guest access monitoring. Becoming increasingly important as Teams adoption grows. | Traces communication activity during an incident — shows whether an attacker communicated via Teams, installed malicious apps, or accessed sensitive team channels | Unauthorized third-party app installed (T1195.002), Guest added to sensitive team |

> [!IMPORTANT]
> Ensure **Unified Audit Log** is enabled in Microsoft 365. Without it, no Office 365 audit events will flow to Sentinel. Check via `Get-AdminAuditLogConfig` or the Microsoft Purview compliance portal.

---

## Example Detections

### Exchange Online

| Detection | Operation(s) | MITRE ATT&CK | Description |
|:----------|:-------------|:-------------|:------------|
| Suspicious inbox rule creation | New-InboxRule, Set-InboxRule | T1564.008 | Rules that forward/redirect/delete email — classic BEC persistence |
| Mailbox forwarding to external address | Set-Mailbox (ForwardingSmtpAddress) | T1114.003 | Email forwarding configured to external domain |
| MailItemsAccessed by compromised account | MailItemsAccessed | T1114.002 | After a confirmed compromise, scope exactly which emails were accessed (E5 Audit Premium) |
| Delegate access granted | Add-MailboxPermission | T1098.002 | Unexpected delegate access (FullAccess, SendAs, SendOnBehalf) to a mailbox |
| eDiscovery abuse | New-ComplianceSearch, SearchStarted | T1114 | Misuse of eDiscovery to search and export mailbox content |

### SharePoint Online

| Detection | Operation(s) | MITRE ATT&CK | Description |
|:----------|:-------------|:-------------|:------------|
| Mass file download | FileDownloaded (high frequency) | T1530 | Unusually high volume of file downloads by a single user |
| External sharing of sensitive documents | SharingSet, AnonymousLinkCreated | T1567 | Documents shared externally or via anonymous links |
| Site permission changes | SiteCollectionAdminAdded | T1098 | Granting admin rights to a site collection |
| Sensitive file access | FileAccessed | T1530 | Access to files in designated sensitive libraries |

### Microsoft Teams

| Detection | Operation(s) | MITRE ATT&CK | Description |
|:----------|:-------------|:-------------|:------------|
| Third-party app installation | AppInstalled | T1195.002 | Unauthorized or suspicious app installed in Teams |
| Guest user added to sensitive team | MemberAdded (guest) | T1136 | External guest accounts added to internal-only teams |
| Suspicious bot or connector activity | BotAddedToTeam, ConnectorAdded | T1059 | Bots or connectors that could exfiltrate data from Teams channels |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection | Exchange audit logs power BEC and email compromise detection |
| **LT-3** Enable logging for security investigation | Office activity logs are essential for investigating data breaches involving M365 data |
| **DP-2** Protect sensitive data | SharePoint logs track access and sharing of sensitive documents |
| **DP-3** Encrypt sensitive data in transit | Audit logs can detect sharing of unprotected sensitive data |
| **IR-4** Detection and analysis | OfficeActivity is a primary data source for M365-based incident investigation |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-2 (audit events) and AU-12 (audit generation), CIS Controls v8 8.2 (collect audit logs), and ASD ACSC enterprise network logging priority #8 (data repositories) and cloud priority #1 (critical data holdings).

---

## OfficeActivity vs CloudAppEvents

| Aspect | OfficeActivity | CloudAppEvents (Defender XDR) |
|:-------|:---------------|:------------------------------|
| **Source** | Office 365 Management API | Microsoft Defender for Cloud Apps |
| **Cost** | Free data source | Free (E5 data grant) |
| **Coverage** | Exchange, SharePoint, Teams | Office 365 + third-party SaaS (if connected) |
| **Schema** | Native Office 365 audit format | Normalized Defender XDR schema |
| **Recommendation** | **Enable both** — OfficeActivity for detailed native fields, CloudAppEvents for cross-app correlation | |

> [!TIP]
> Both tables are free — enable both. `OfficeActivity` provides richer detail for Exchange-specific investigations, while `CloudAppEvents` provides a normalized schema that works better for cross-workload hunting and analytics rules.

---

## Notes

- Enable all three workloads: **Exchange**, **SharePoint**, and **Teams**
- If you have **E5**, ensure Audit (Premium) is enabled for enhanced events like `MailItemsAccessed` and `Send`
- Default M365 audit log retention is **180 days** (E5 Audit with 10-year retention is available but separate from Sentinel)
- Consider creating **watchlists** for sensitive SharePoint sites to trigger alerts on access to high-value data
- Inbox rule detections are among the **highest-fidelity BEC indicators** — prioritize these analytics rules

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor OfficeActivity ingestion volumes and validate connector health | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Microsoft 365** | Solution | 3 workbooks (Office 365, Exchange Online, SharePoint & OneDrive), 16 analytic rules, 21 hunting queries — covers suspicious mail forwarding, mass downloads, and Teams/SharePoint anomalies | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect Office 365 Logs to Microsoft Sentinel | Connector setup guide — Exchange, SharePoint, and Teams activity logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-365) |
| Microsoft Purview auditing solutions overview | Overview of Audit (Standard) vs Audit (Premium) — activation, retention, and premium-only events such as `MailItemsAccessed`, `Send`, `SearchQueryInitiatedExchange`, requiring Microsoft 365 E5 or the Audit add-on | [learn.microsoft.com](https://learn.microsoft.com/purview/audit-solutions-overview) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Microsoft 365 connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/office365.md) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
