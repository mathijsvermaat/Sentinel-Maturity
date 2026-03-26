# Microsoft Global Secure Access

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No · **Conditional:** Requires Global Secure Access licensing

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Important Considerations](#important-considerations)
- [Notes](#notes)
  - [Tools](#tools)
- [References](#references)

---

## Overview

Microsoft Global Secure Access (GSA) is Microsoft's Security Service Edge (SSE) solution, comprising **Entra Internet Access** (SWG/cloud proxy) and **Entra Private Access** (ZTNA replacement for VPN). It routes user internet and private application traffic through Microsoft's global edge network, applying identity-aware security policies.

The `NetworkAccessTraffic` table captures every web request, private app connection, and Microsoft 365 traffic flow processed by GSA — enriched with the user's Entra identity. This makes it the modern equivalent of a traditional web proxy log, but with built-in identity context.

### Relationship to Entra ID (Tier 1)

The [Microsoft Entra ID](microsoft-entra-id.md) connector covers **authentication events** (who signed in?). Global Secure Access covers **network traffic events** (what did they access after signing in?). Together, they provide full identity-to-network visibility.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft Entra Suite** | Full GSA — Internet Access + Private Access |
| **Microsoft Entra Private Access (standalone)** | Private Access only — ZTNA for internal applications |
| **Microsoft Entra Internet Access (standalone)** | Internet Access only — SWG for web traffic |

> [!NOTE]
> GSA is a distinct product from Entra ID. Logs only flow to the `NetworkAccessTraffic` table when GSA is deployed and the GSA client is installed on user endpoints. If your organisation does not use GSA, this connector page does not apply.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **NetworkAccessTraffic** | All web traffic, private app connections, and M365 traffic processed by GSA — includes user identity, destination FQDN/URL, action (allow/block), bytes transferred, traffic type (Internet/Private/M365) | Analytics: 90d / Lake: 365d | **Core proxy and ZTNA visibility.** Detects shadow IT, data exfiltration via web, access to phishing/C2 domains, and anomalous private application access. MCSB LT-4, NS-2. | Complete user-to-internet and user-to-private-app audit trail — proves exactly what every user accessed, when, and how much data was transferred. The identity enrichment means no separate proxy-to-identity correlation is needed. | User accessing known phishing domain (T1566.002), large upload to cloud storage service (T1567), unusual private app access outside business hours (T1078) |

---

## Example Detections

### Internet Access (Web Proxy)

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Access to phishing domain | NetworkAccessTraffic | T1566.002 | User traffic to newly registered or threat intel-flagged domains |
| Shadow IT discovery | NetworkAccessTraffic | — | Users accessing unapproved SaaS applications — build shadow IT baseline from traffic data |
| Data exfiltration to personal cloud storage | NetworkAccessTraffic | T1567 | Large uploads to consumer cloud storage services (Dropbox, Google Drive, WeTransfer) |
| C2 callback over HTTPS | NetworkAccessTraffic | T1071.001 | Repeated connections to low-reputation domain with consistent beacon pattern |
| Web category policy violation | NetworkAccessTraffic | — | Access to blocked web categories (adult, gambling, malware) — indicates policy bypass attempt or compromised endpoint |

### Private Access (ZTNA)

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Unusual private app access | NetworkAccessTraffic | T1078 | User accessing private applications they have never accessed before — possible lateral movement via ZTNA |
| After-hours private app access | NetworkAccessTraffic | T1078 | Private application access outside normal business hours — investigate with identity context |
| Failed private app connections | NetworkAccessTraffic | T1021 | Repeated connection failures to private applications — may indicate reconnaissance or misconfigured stolen credentials |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-4** Enable network logging for security investigation | GSA provides identity-enriched network traffic logging |
| **NS-2** Secure cloud native services with network controls | GSA enforces network security policies for internet and private access |
| **NS-7** Simplify network security configuration | Centralised proxy and ZTNA logging replaces fragmented VPN and proxy appliance logs |
| **IM-1** Centralise identity management | Traffic logs are identity-enriched — user context is built in |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AC-17 (remote access) and SC-7 (boundary protection), CIS Controls v8 13.6 (network traffic monitoring), and ASD ACSC enterprise network logging priority #12 (web proxies) and enterprise mobility priority #6 (VPN solutions).

---

## Important Considerations

### GSA Client Deployment

`NetworkAccessTraffic` only captures traffic from devices with the **GSA client** installed and active. Verify deployment coverage before relying on this as your primary proxy log source.

### Traffic Profiles

GSA uses traffic profiles to determine which traffic is routed through the service:

| Profile | What It Captures |
|:--------|:-----------------|
| **Microsoft 365** | All M365 traffic (Exchange Online, SharePoint, Teams) |
| **Internet Access** | All web traffic (configurable — can be all traffic or specific categories) |
| **Private Access** | Connections to configured private application segments |

Enable all relevant profiles to avoid log blind spots.

### Coexistence with Azure Firewall

If you use both Azure Firewall and GSA:
- GSA captures **user-level** traffic from managed endpoints
- Azure Firewall captures **resource-level** traffic from Azure VMs and services

They are complementary, not redundant. GSA logs have identity context; Azure Firewall logs have infrastructure context.

---

## Notes

- If your organisation does not use Global Secure Access, skip this connector page entirely
- `NetworkAccessTraffic` replaces the need for traditional proxy log ingestion (Zscaler, Cisco Umbrella, etc.) for users routed through GSA
- Consider the [Entra ID page](microsoft-entra-id.md) for the authentication side of the same user journey
- GSA logs are high-value for **insider threat** detection — the identity-enriched proxy log enables user-level behaviour analytics without SIEM-side join operations

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor NetworkAccessTraffic ingestion volumes | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

Community and third-party resources that support the guidance on this page.

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — web proxies are Enterprise Networks priority #12 and Enterprise Mobility priority #1 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
