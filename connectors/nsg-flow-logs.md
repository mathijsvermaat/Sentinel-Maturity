# NSG Flow Logs & Traffic Analytics

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

Network Security Group (NSG) Flow Logs capture information about IP traffic flowing through NSGs — source/destination IPs, ports, protocols, and allow/deny decisions. When combined with **Traffic Analytics**, the raw flow data is enriched with geographic, ASN, and traffic pattern insights and made queryable in Log Analytics.

While Azure Firewall logs cover traffic at the centralised egress/ingress point, NSG Flow Logs capture **east-west (lateral) traffic** between resources within the same VNet or across peered VNets — the traffic that never touches the firewall. This is critical for detecting lateral movement post-compromise.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **NSG Flow Logs v2** | Basic flow records — 5-tuple + byte/packet counts + flow state |
| **Traffic Analytics** | Enriched flow analysis with geo, ASN, traffic patterns, anomaly detection |

> [!NOTE]
> NSG Flow Logs + Traffic Analytics incur both **storage cost** (flow logs are stored in a Storage Account) and **processing cost** (Traffic Analytics has per-GB processing pricing). The enriched data in Log Analytics incurs standard Sentinel ingestion cost.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AzureNetworkAnalytics_CL** | Traffic Analytics enriched flow records — source/dest, geo, port, protocol, flow status, anomaly flags | Analytics: 90d / Lake: 365d | **Core east-west visibility.** Detects lateral movement, internal reconnaissance, and data exfiltration over internal paths. MCSB LT-4. | Proves exactly which internal resources communicated with each other, on which ports, and how much data was transferred — the definitive evidence for lateral movement investigation | Lateral movement — VM-to-VM RDP from unexpected source (T1021.001) |
| **NTANetAnalytics** | Next-generation Traffic Analytics (resource-specific) — same data in structured format | Analytics: 90d / Lake: 365d | Structured alternative to AzureNetworkAnalytics_CL with better query performance. | Same forensic value as above, in more efficient table format | Same detection coverage as AzureNetworkAnalytics_CL |

---

## Example Detections

### Lateral Movement

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Internal RDP from unexpected source | AzureNetworkAnalytics_CL | T1021.001 | RDP (3389) traffic between VMs that don't normally communicate |
| Internal SMB lateral movement | AzureNetworkAnalytics_CL | T1021.002 | SMB (445) traffic patterns indicating file share access or PsExec-style movement |
| Internal port scanning | AzureNetworkAnalytics_CL | T1046 | Single source connecting to many destinations on sequential ports |
| Unusual spoke-to-spoke traffic | AzureNetworkAnalytics_CL | T1021 | Flow between spoke VNets that have no business justification for direct communication |

### Exfiltration and Anomalies

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Large data transfer to external IP | AzureNetworkAnalytics_CL | T1048 | Abnormally high byte count outbound to an IP not seen in baseline traffic |
| Denied traffic spike | AzureNetworkAnalytics_CL | T1046 | Sudden increase in denied flows — may indicate scanning or misconfigured pivot attempt |
| Traffic to geo-anomalous destination | AzureNetworkAnalytics_CL | T1071 | Outbound connections to countries not in baseline communication pattern |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-4** Enable network logging for security investigation | NSG Flow Logs are the primary Azure network traffic logging mechanism |
| **NS-1** Establish network segmentation boundaries | Flow logs prove whether segmentation policy is being enforced |
| **NS-7** Simplify network security configuration | Traffic Analytics surfaces security-relevant traffic patterns |
| **IR-4** Detection and analysis | Network flow data is essential for scoping breach lateral movement |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-12 (audit generation) and SC-7 (boundary protection), CIS Controls v8 13.6 (network traffic monitoring), and ASD ACSC enterprise network logging priorities for network metadata and cloud priority #7 (network-related events).

---

## Important Considerations

### NSG Flow Logs v2

Always use **Flow Logs version 2** — it includes flow state tracking (established, continued, denied), byte counts, and packet counts that version 1 does not provide.

### Traffic Analytics Processing Interval

Traffic Analytics processes flow logs at a configurable interval (10 min or 60 min). For security use cases, use **10-minute** processing to reduce detection latency.

### Coverage

NSG Flow Logs only capture traffic that **passes through an NSG**. Ensure NSGs are applied to all subnets and NICs. Resources without NSGs will have no flow data.

### VNet Flow Logs (Preview)

Azure is introducing **VNet Flow Logs** as a successor to NSG Flow Logs, capturing traffic at the VNet level rather than the NSG level. When generally available, this simplifies coverage — one flow log per VNet instead of per-NSG.

---

## Notes

- NSG Flow Logs are **not** free — costs include storage (flow log files), Traffic Analytics processing, and Sentinel ingestion
- Flow logs complement Azure Firewall logs: the firewall covers north-south traffic; NSG flows cover east-west
- For organisations with Azure Firewall in forced-tunnel mode, most internet-bound traffic will appear in firewall logs, not NSG flows — NSG flows capture the internal segment
- High-volume environments should consider the **Data Lake** tier for flow data or aggressive filtering via Traffic Analytics

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor flow log ingestion volumes | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

Community and third-party resources that support the guidance on this page.

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — network metadata is listed as a logging priority | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
