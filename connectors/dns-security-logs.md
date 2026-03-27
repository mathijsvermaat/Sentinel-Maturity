# DNS Security Logs

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No

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

DNS is one of the most forensically valuable and tactically underutilised data sources in security operations. Every network connection starts with a DNS query — logging DNS gives you visibility into what every device is trying to communicate with, **before the connection is established**.

This page covers two complementary DNS data sources:

1. **Endpoint DNS logging** — DNS queries from Windows endpoints collected via Azure Monitor Agent (AMA) and the DNS extension
2. **Azure DNS diagnostic logs** — queries to Azure Private DNS zones and Azure DNS Resolver

For Azure Firewall DNS proxy logs, see the [Azure Firewall](azure-firewall.md) page (`AZFWDnsQuery`). All three sources are complementary and provide different vantage points.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft Sentinel + AMA** | DNS event collection from Windows endpoints via NXlog DNS extension |
| **Defender for DNS** | Adds threat detection alerts for DNS anomalies (alerts flow through `SecurityAlert` → Tier 2 Defender for Cloud page) |

> [!NOTE]
> DNS logs can be **high-volume**. Budget for ingestion cost based on the number of endpoints and DNS query rates.

---

## Tables and Rationale

### Endpoint DNS

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **DnsEvents** | DNS query events from Windows endpoints — queried domain, query type, result, client IP | Analytics: 90d / Lake: 365d | **Core DNS forensics table.** Detects C2 over DNS, DNS tunnelling, DGA, and domain reputation matches. MCSB LT-4. | Proves exactly which endpoint queried which domain — the definitive source for tracking C2 beaconing, phishing domain resolution, and data exfiltration attempts via DNS. | DNS tunnelling — high query volume to single domain (T1071.004), DGA detection — algorithmically generated subdomains (T1568.002) |
| **DnsInventory** | DNS server inventory — zones, records, configuration | Analytics: 90d / Lake: 365d | Infrastructure context for DNS investigations. | Understanding of DNS infrastructure state — which zones existed and which records were configured at the time of an incident | Rogue DNS zone created on internal DNS server |

### Azure DNS

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AzureDiagnostics** (Azure DNS) | Queries to Azure Private DNS zones and DNS Resolver | Analytics: 90d / Lake: 365d | Cloud-side DNS visibility — detects query patterns from Azure resources (VMs, containers, PaaS). | Proves which Azure resources queried which domains — essential for investigating compromised Azure workloads | Azure VM querying known C2 domain via Private DNS |

---

## Example Detections

### C2 and Tunnelling

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| DNS tunnelling | DnsEvents | T1071.004 | High-entropy or excessively long subdomain queries to a single domain — data exfiltration via DNS |
| DGA domain resolution | DnsEvents | T1568.002 | Algorithmically generated domain names — characteristic of malware families using DGA for C2 |
| DNS beaconing | DnsEvents | T1071.004 | Regular, periodic DNS queries to a single domain — C2 beacon pattern |
| Rare domain query | DnsEvents | T1071.004 | DNS query for a domain seen by only one endpoint — potential unique C2 infrastructure |

### Reputation and Threat Intel

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Known malicious domain query | DnsEvents + ThreatIntelligenceIndicator | T1071.004 | DNS query matching a known bad domain from threat intelligence feeds |
| Newly registered domain | DnsEvents | T1583.001 | DNS query for a domain registered within the last 14 days — common for phishing and C2 |
| Dynamic DNS domain | DnsEvents | T1568.001 | DNS query for a domain on dynamic DNS providers (duckdns.org, no-ip.com, etc.) |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-4** Enable network logging for security investigation | DNS logging provides network-layer visibility into domain resolution |
| **LT-1** Enable threat detection | DNS anomaly detection identifies C2, tunnelling, and DGA patterns |
| **NS-2** Secure cloud native services with network controls | DNS logging supports enforcement visibility for DNS-based security policies |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-12 (audit generation) and SC-20 (secure name resolution), CIS Controls v8 9.2 (DNS filtering) and 8.2 (collect audit logs), and ASD ACSC enterprise network logging priority #13 (DNS services).

---

## Important Considerations

### Three DNS Vantage Points

| Source | What It Captures | Complements |
|:-------|:-----------------|:------------|
| **DnsEvents** (endpoint) | DNS queries from Windows endpoints | Process-to-DNS correlation with DeviceNetworkEvents (Defender XDR) |
| **AZFWDnsQuery** (firewall) | DNS queries passing through Azure Firewall DNS proxy | Network-level DNS for Azure resources |
| **AzureDiagnostics** (Azure DNS) | Queries to Azure Private DNS zones | Cloud DNS infrastructure events |

For maximum DNS visibility, enable all three where applicable.

### Volume Management

DNS logs are **high-volume**. Strategies to manage cost:
- Use the **Data Lake** tier for `DnsEvents` if full KQL capability is not needed for all queries
- Filter DNS queries in the DCR to exclude known-safe domains (e.g., Windows Update, CDN domains) — but exercise caution to avoid filtering out C2 hiding behind legitimate services
- Start with a small pilot group before deploying DNS collection to all endpoints

---

## Notes

- DNS logging provides the **earliest signal** for C2 detection — the DNS query happens before the connection is established
- Combine DNS data with [Threat Intelligence](threat-intelligence.md) for maximum detection value — TI domain matching against DNS queries is one of the highest-confidence detections
- For Azure Firewall DNS proxy logs, see the [Azure Firewall](azure-firewall.md) page
- Consider the JSCU (Dutch AIVD/MIVD) [logging-essentials](https://github.com/JSCU-NL/logging-essentials) repository for Windows event logging baselines including DNS

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor DNS table ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **DNS Essentials** | Solution | ASIM-based DNS analytics — detections for tunnelling, DGA domains, and excessive NXDOMAIN queries | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect your DNS servers to Microsoft Sentinel | Connector setup guide — Windows DNS Events via AMA | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/dns) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — DNS connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/dns.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — DNS services are Enterprise Networks priority #13 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |
| JSCU Logging Essentials | AIVD / MIVD (Netherlands) | Dutch intelligence services' baseline for Windows event logging including DNS — developed by the Joint SIGINT Cyber Unit | [GitHub](https://github.com/JSCU-NL/logging-essentials) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
