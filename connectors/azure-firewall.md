# Azure Firewall

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

Azure Firewall is a cloud-native network security service that provides stateful packet inspection, application-level filtering, threat intelligence-based filtering, and DNS proxying. The diagnostic logs from Azure Firewall are one of the most forensically valuable network data sources in Azure — they answer the questions *"what did this resource connect to?"* and *"what was blocked?"*.

For organisations using Azure Firewall as their central egress point (hub-spoke topology), these logs provide the equivalent of a traditional perimeter firewall log — essential for detecting C2 communications, data exfiltration, lateral movement, and DNS-based attacks.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Azure Firewall Standard** | Network rules, application rules, threat intelligence, NAT rules |
| **Azure Firewall Premium** | All Standard features + TLS inspection, IDPS, URL filtering, web categories |

> [!NOTE]
> Azure Firewall diagnostic logs are **not** a free data source. Log volume can be significant depending on network traffic. Use **resource-specific** diagnostic settings (not Azure Diagnostics mode) for structured tables.

---

## Tables and Rationale

> [!TIP]
> Azure Firewall supports two diagnostic modes: **Azure Diagnostics** (all logs in `AzureDiagnostics`) and **Resource-specific** (dedicated tables like `AZFWNetworkRule`). Always use **resource-specific** mode — it provides structured tables with better query performance and lower ingestion cost.

### Network and Application Rule Logs

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AZFWNetworkRule** | Network rule evaluation — source/dest IP, port, protocol, action (allow/deny) | Analytics: 90d / Lake: 365d | **Core network forensics table.** Detects lateral movement, port scanning, C2 over non-HTTP protocols. MCSB LT-4. | Complete network connection audit trail — proves which source connected to which destination, on which port, and whether it was allowed or denied. Essential for lateral movement and C2 investigation. | Outbound connection to known C2 IP on unusual port (T1571), internal port scan (T1046) |
| **AZFWApplicationRule** | Application (L7) rule evaluation — FQDN, URL, HTTP method, action | Analytics: 90d / Lake: 365d | Detects data exfiltration to cloud storage, C2 over HTTPS, access to suspicious domains. MCSB LT-4. | Proves exactly which FQDNs and URLs were accessed through the firewall — essential for scoping data exfiltration and identifying C2 domains | Data exfiltration to personal cloud storage (T1567), C2 callback to newly registered domain (T1071.001) |
| **AZFWNatRule** | DNAT rule matches — inbound connections mapped to backend resources | Analytics: 90d / Lake: 365d | Tracks inbound access to published services — detects scanning and exploitation attempts against internet-facing services. | Proves which external IPs accessed published services and when — essential for investigating initial access to internet-facing workloads | Inbound exploitation attempt against published service (T1190) |

### Threat Intelligence and DNS

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AZFWThreatIntel** | Connections matching Microsoft Threat Intelligence feeds | Analytics: 90d / Lake: 365d | Direct IOC matching at the network level — detects known malicious IPs, domains, and URLs. MCSB LT-1. | Authoritative evidence that a resource communicated with known malicious infrastructure — strong indicator of compromise | Connection to known botnet C2 infrastructure (T1071) |
| **AZFWDnsQuery** | DNS queries proxied through Azure Firewall DNS proxy | Analytics: 90d / Lake: 365d | Detects DNS tunnelling, DGA domains, C2 over DNS, and data exfiltration via DNS. MCSB LT-4. Cross-reference with the [DNS Security Logs](dns-security-logs.md) page for endpoint-level DNS. | Complete DNS query audit trail — proves which resource queried which domain and when. Essential for detecting C2 communication patterns and DNS-based exfiltration. | DNS tunnelling with high query volume to single domain (T1071.004), DGA domain resolution (T1568.002) |

### IDPS Logs (Premium)

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AZFWIdpsSignature** | Intrusion detection and prevention signature matches (Premium only) | Analytics: 90d / Lake: 365d | Network-level intrusion detection — identifies known exploit signatures, malware communications, and protocol anomalies. | Evidence of network-level attack signatures — proves that specific exploit attempts or malware communications were detected at the perimeter | Known exploit signature detected in network traffic (T1190) |

### Diagnostic Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:-------------------|
| **AZFWFatFlow** | Top flows by bandwidth consumption | Analytics: 90d / Lake: 365d | Identifies high-bandwidth flows that may indicate data exfiltration or resource abuse. | Proves which flows consumed the most bandwidth — useful for scoping exfiltration volume | Abnormally large outbound flow to unexpected destination |
| **AZFWFlowTrace** | Flow-level tracing across firewall rule processing pipeline | Analytics: 90d / Lake: 365d | Detailed flow path information for troubleshooting and forensic analysis of how a connection was processed. | Traces exactly how the firewall evaluated a connection — which rules matched, in which order | Flow allowed by unexpected rule — firewall rule audit |
| **AZFWInternalFqdnResolutionFailure** | FQDN resolution failures for internal DNS lookups | Analytics: 90d / Lake: 365d | Detects DNS resolution issues that may indicate DNS infrastructure problems or DNS-based attacks. | Evidence of failed internal DNS resolution — can indicate DNS poisoning or infrastructure compromise | Spike in internal FQDN resolution failures — potential DNS tampering |

---

## Example Detections

### C2 and Exfiltration

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Outbound C2 to suspicious domain | AZFWApplicationRule, AZFWThreatIntel | T1071.001 | HTTPS connections to newly registered or threat intel-flagged domains |
| DNS tunnelling | AZFWDnsQuery | T1071.004 | High-entropy subdomain queries to a single domain — data exfiltration via DNS |
| Data exfiltration to cloud storage | AZFWApplicationRule | T1567 | Large outbound transfers to personal cloud storage services (Dropbox, Google Drive, etc.) |
| DGA domain resolution | AZFWDnsQuery | T1568.002 | Algorithmically generated domain names resolved through the DNS proxy |

### Lateral Movement and Reconnaissance

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Internal port scan | AZFWNetworkRule | T1046 | Single source connecting to many destinations on the same port in short timeframe |
| Unexpected spoke-to-spoke traffic | AZFWNetworkRule | T1021 | Traffic between spoke VNets that should not communicate directly |
| Inbound exploitation attempt | AZFWNatRule | T1190 | External IP scanning or exploiting DNAT-published services |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-4** Enable network logging for security investigation | Azure Firewall is the primary network logging source for cloud perimeter traffic |
| **LT-1** Enable threat detection | Threat intelligence integration provides IOC-based network detection |
| **LT-3** Enable logging for security investigation | Application and network rule logs provide the audit trail for all egress traffic |
| **NS-1** Establish network segmentation boundaries | Firewall rules enforce segmentation — logs prove enforcement |
| **NS-2** Secure cloud native services with network controls | Application rules control and log outbound access from Azure services |
| **NS-7** Simplify network security configuration | Centralised firewall logging provides unified network visibility |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-12 (audit generation) and SC-7 (boundary protection), CIS Controls v8 13.6 (network traffic monitoring), and ASD ACSC enterprise network logging priority #5 (edge devices and firewalls) and #13 (DNS services).

---

## Important Considerations

### Resource-Specific vs. Azure Diagnostics Mode

Always configure diagnostic settings with **resource-specific** destination tables:

| Mode | Tables | Recommendation |
|:-----|:-------|:---------------|
| **Resource-specific** (recommended) | `AZFWNetworkRule`, `AZFWApplicationRule`, `AZFWDnsQuery`, `AZFWThreatIntel`, `AZFWNatRule`, `AZFWIdpsSignature` | Structured tables with proper columns — better query performance and lower cost |
| Azure Diagnostics (legacy) | `AzureDiagnostics` (all logs in one table) | Unstructured, higher cost, harder to query — avoid |

### Volume Considerations

Azure Firewall logs can be **high-volume**, particularly:
- `AZFWDnsQuery` — every DNS query through the proxy
- `AZFWNetworkRule` — every connection attempt (including denied)

Consider using the **Data Lake** tier for the highest-volume tables if cost is a concern, or configure **log filtering** in the diagnostic settings to exclude routine traffic patterns.

### Multiple Firewalls

If you have Azure Firewalls in multiple regions or hub VNets, ensure **all instances** have diagnostic settings configured. Use Azure Policy to enforce this:

```
Microsoft.Insights/diagnosticSettings — deployIfNotExists
```

---

## Notes

- Azure Firewall logs are **not** free — plan for ingestion cost based on network traffic volume
- `AZFWDnsQuery` is particularly valuable when combined with endpoint DNS logs — see [DNS Security Logs](dns-security-logs.md) for the complementary endpoint view
- For Azure Firewall Premium customers, `AZFWIdpsSignature` adds network IDS capability similar to on-premises Snort/Suricata
- Consider the [Azure Firewall Workbook](https://learn.microsoft.com/en-us/azure/firewall/firewall-workbook) for operational monitoring alongside Sentinel detections

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor Azure Firewall table ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Azure Firewall** | Solution | 2 workbooks (Classic and Structured Logs), 6 analytic rules, 5 hunting queries, 5 playbooks — covers firewall rule monitoring, threat intelligence hits, and automated blocking | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect Azure Firewall to Microsoft Sentinel | Connector setup guide — resource-specific diagnostic settings for structured logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/azure-firewall) |
| Azure Firewall structured logs | Schema reference for all resource-specific log tables | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/firewall/firewall-structured-logs) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Azure Firewall connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azurefirewall.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance on logging priorities — firewalls are listed as Enterprise Networks priority #5 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
