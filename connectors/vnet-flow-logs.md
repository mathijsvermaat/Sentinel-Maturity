# VNet Flow Logs & Traffic Analytics

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No

---

## Contents

- [VNet Flow Logs \& Traffic Analytics](#vnet-flow-logs--traffic-analytics)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
  - [Example Detections](#example-detections)
    - [Lateral Movement](#lateral-movement)
    - [Exfiltration and Anomalies](#exfiltration-and-anomalies)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Important Considerations](#important-considerations)
    - [VNet Flow Logs vs. NSG Flow Logs](#vnet-flow-logs-vs-nsg-flow-logs)
    - [Traffic Analytics Processing Interval](#traffic-analytics-processing-interval)
    - [Coverage](#coverage)
    - [Volume](#volume)
  - [Notes](#notes)
  - [Tools](#tools)
  - [References](#references)

---

## Overview

Virtual Network (VNet) Flow Logs are the successor to NSG Flow Logs, capturing IP traffic at the **virtual network level** rather than the NSG level. This simplifies deployment — one flow log per VNet instead of per-NSG — and provides broader coverage including traffic evaluated by Azure Virtual Network Manager security admin rules and VNet encryption status.

When combined with **Traffic Analytics**, the raw flow data is enriched with geographic, ASN, and traffic pattern insights and made queryable in Log Analytics via the `NTANetAnalytics` table.

While Azure Firewall logs cover traffic at the centralised egress/ingress point, VNet Flow Logs capture **east-west (lateral) traffic** between resources within the same VNet or across peered VNets — the traffic that never touches the firewall. This is critical for detecting lateral movement post-compromise.

> [!IMPORTANT]
> VNet Flow Logs replace NSG Flow Logs. Microsoft recommends disabling NSG Flow Logs before enabling VNet Flow Logs on the same workloads to avoid duplicate traffic recording and additional costs. The `NTANetAnalytics` table replaces `AzureNetworkAnalytics_CL`.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **VNet Flow Logs** | Flow records at the VNet level — 5-tuple + byte/packet counts + flow state + encryption status |
| **Traffic Analytics** | Enriched flow analysis with geo, ASN, traffic patterns, anomaly detection |

> [!NOTE]
> VNet Flow Logs + Traffic Analytics incur both **storage cost** (flow logs are stored in a Storage Account) and **processing cost** (Traffic Analytics has per-GB processing pricing). The enriched data in Log Analytics incurs standard Sentinel ingestion cost.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **NTANetAnalytics** | Traffic Analytics enriched flow records — source/dest, geo, port, protocol, flow status, anomaly flags, encryption state | Analytics: 90d / Lake: 365d | **Core east-west visibility.** Detects lateral movement, internal reconnaissance, and data exfiltration over internal paths. MCSB LT-4. Replaces `AzureNetworkAnalytics_CL` from NSG Flow Logs. | Proves exactly which internal resources communicated with each other, on which ports, and how much data was transferred — the definitive evidence for lateral movement investigation | Lateral movement — VM-to-VM RDP from unexpected source (T1021.001) |
| **NTAIpDetails** | Public IP enrichment — WHOIS, geo-location, threat intelligence attribution for public IPs seen in flows | Analytics: 90d / Lake: 365d | Enrichment layer for public IP context. Replaces `AzureNetworkAnalyticsIPDetails_CL`. | Links external IPs in flow data to geographic location, ASN ownership, and threat intelligence — proves whether traffic was directed at known malicious infrastructure | Outbound flow to IP flagged as C2 by Microsoft threat intelligence |

---

## Example Detections

### Lateral Movement

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Internal RDP from unexpected source | NTANetAnalytics | T1021.001 | RDP (3389) traffic between VMs that don't normally communicate |
| Internal SMB lateral movement | NTANetAnalytics | T1021.002 | SMB (445) traffic patterns indicating file share access or PsExec-style movement |
| Internal port scanning | NTANetAnalytics | T1046 | Single source connecting to many destinations on sequential ports |
| Unusual spoke-to-spoke traffic | NTANetAnalytics | T1021 | Flow between spoke VNets that have no business justification for direct communication |

### Exfiltration and Anomalies

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Large data transfer to external IP | NTANetAnalytics | T1048 | Abnormally high byte count outbound to an IP not seen in baseline traffic |
| Denied traffic spike | NTANetAnalytics | T1046 | Sudden increase in denied flows — may indicate scanning or misconfigured pivot attempt |
| Traffic to geo-anomalous destination | NTANetAnalytics, NTAIpDetails | T1071 | Outbound connections to countries not in baseline communication pattern |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-4** Enable network logging for security investigation | VNet Flow Logs are the primary Azure network traffic logging mechanism |
| **NS-1** Establish network segmentation boundaries | Flow logs prove whether segmentation policy is being enforced |
| **NS-7** Simplify network security configuration | Traffic Analytics surfaces security-relevant traffic patterns |
| **IR-4** Detection and analysis | Network flow data is essential for scoping breach lateral movement |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-12 (audit generation) and SC-7 (boundary protection), CIS Controls v8 13.6 (network traffic monitoring), and ASD ACSC enterprise network logging priorities for network metadata and cloud priority #7 (network-related events).

---

## Important Considerations

### VNet Flow Logs vs. NSG Flow Logs

VNet Flow Logs are the successor to NSG Flow Logs. Key differences:

| Aspect | NSG Flow Logs | VNet Flow Logs |
|:-------|:--------------|:---------------|
| **Scope** | Per-NSG (subnet or NIC level) | Per-VNet (entire virtual network) |
| **Sentinel table** | `AzureNetworkAnalytics_CL` (legacy) | `NTANetAnalytics` |
| **Encryption visibility** | Not supported | Supported |
| **Virtual Network Manager rules** | Not supported | Supported |
| **Gateway traffic** | Not supported | Supported (VPN, ExpressRoute) |

> [!WARNING]
> If you enable both NSG Flow Logs and VNet Flow Logs on the same workloads, you will get **duplicate traffic recording** and additional costs. Disable NSG Flow Logs before enabling VNet Flow Logs.

### Traffic Analytics Processing Interval

Traffic Analytics processes flow logs at a configurable interval (10 min or 60 min). For security use cases, use **10-minute** processing to reduce detection latency.

### Coverage

VNet Flow Logs capture traffic for all supported workloads within a virtual network. Some Azure services are not yet supported — see the [VNet Flow Logs documentation](https://learn.microsoft.com/en-us/azure/network-watcher/vnet-flow-logs-overview) for the current list of incompatible services (e.g., Azure Functions, Container Instances, Logic Apps).

### Volume

VNet Flow Logs capture traffic at the VNet level including gateway traffic, which may result in **higher log volumes** compared to NSG Flow Logs. Plan ingestion budgets accordingly.

---

## Notes

- VNet Flow Logs are **not** free — costs include storage (flow log files), Traffic Analytics processing, and Sentinel ingestion
- Flow logs complement Azure Firewall logs: the firewall covers north-south traffic; VNet flows cover east-west
- For organisations with Azure Firewall in forced-tunnel mode, most internet-bound traffic will appear in firewall logs, not VNet flows — VNet flows capture the internal segment
- High-volume environments should consider the **Data Lake** tier for flow data or aggressive filtering via Traffic Analytics

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor flow log ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Network Session Essentials** | Solution | 2 workbooks, 10 analytic rules, 6 hunting queries, 1 playbook — ASIM-based network session analytics covering port scans, beaconing, brute force, and SMB anomalies | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| VNet flow logs overview | GA successor to NSG flow logs — setup, pricing, VNet vs NSG comparison | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/network-watcher/vnet-flow-logs-overview) |
| Traffic Analytics overview | How Traffic Analytics processes flow logs into NTANetAnalytics for Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/network-watcher/traffic-analytics) |
| NSG flow logs (legacy) | Reference for the legacy NSG flow logs product being retired on 30 September 2027 — included for brownfield deployments that have not yet migrated | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/network-watcher/nsg-flow-logs-overview) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Network Security Groups connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azurensg.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — network metadata is listed as a logging priority | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
