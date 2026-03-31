# Microsoft Defender for DNS (Azure DNS)

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party (Diagnostic Settings) · **Free ingestion:** No

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

Azure DNS diagnostic logs capture **DNS query and zone operations** at the Azure infrastructure level. This is distinct from the Tier 2 DNS Security Logs connector (endpoint DNS via AMA) — Azure DNS logs capture queries resolved by **Azure-hosted DNS zones** (public and private) and Azure DNS Private Resolver.

This connector provides visibility into DNS activity for Azure-native workloads that use Azure DNS for name resolution. It complements endpoint-level DNS logging by capturing DNS resolution at the infrastructure layer — useful for detecting C2 communication from PaaS services, serverless functions, and container workloads that may not have endpoint-level agents.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Azure subscription** | Azure DNS diagnostic logging — no additional license required |
| **Defender for DNS** | Adds threat detection alerts for DNS-based threats — anomalous queries, DGA detection, C2 communication (alerts flow through Defender for Cloud) |

> [!NOTE]
> Defender for DNS provides **threat detection** alerts (flowing through the Tier 2 Defender for Cloud connector). This Tier 3 connector adds the **raw DNS query logs** for investigation and custom detection building.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AzureDiagnostics** (DNS) | Azure DNS query logs — query name, type, response code, source IP for queries against Azure-hosted zones | Analytics: 90d / Lake: 365d | Infrastructure-level DNS audit trail — captures DNS resolution for Azure workloads without endpoint agents | Maps DNS resolution activity during compromise — identifies C2 domains, data exfiltration via DNS, and reconnaissance patterns | DGA domain resolution from Azure workload (T1568.002) |
| **DNSQueryLogs** (Private Resolver) | Queries resolved by Azure DNS Private Resolver — internal name resolution patterns | Analytics: 90d / Lake: 365d | Private DNS resolution audit trail — captures internal name resolution for hybrid environments | Identifies internal DNS queries that indicate lateral movement or reconnaissance within the Azure network | Unusual reverse DNS lookups indicating reconnaissance (T1018) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| DGA domain resolution | AzureDiagnostics (DNS) | T1568.002 | Azure workload resolving algorithmically generated domain names — C2 indicator |
| High-entropy DNS queries | AzureDiagnostics (DNS) | T1071.004 | DNS queries with high entropy in subdomain — potential DNS tunnelling for data exfiltration |
| Known malicious domain resolution | AzureDiagnostics (DNS) | T1071.004 | DNS query matching threat intelligence IOCs for known C2 or malware infrastructure |
| DNS query volume anomaly | AzureDiagnostics (DNS) | T1048.003 | Sudden spike in DNS queries from a workload — potential DNS-based data exfiltration |
| TXT record queries for data exfiltration | AzureDiagnostics (DNS) | T1048.003 | Excessive TXT record queries — commonly used for DNS data exfiltration channels |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **NS-6** Deploy network security monitoring | DNS logs provide network-layer threat detection for Azure-native workloads |
| **LT-1** Enable threat detection capabilities | DNS-based threat detection for C2, DGA, and data exfiltration at the infrastructure level |
| **LT-3** Enable logging for security investigation | DNS query logs support investigation of network-based compromise — maps domain resolution to workload activity |

---

## Important Considerations

- **Distinction from Tier 2 DNS:** Tier 2 DNS Security Logs captures endpoint-level DNS queries via AMA. This Tier 3 connector captures Azure-infrastructure DNS — queries resolved by Azure DNS zones and Private Resolver
- **Complementary coverage:** Use both for comprehensive DNS visibility — endpoint DNS for managed devices, Azure DNS for cloud-native workloads
- **Volume:** DNS query volume depends on the number of Azure workloads using Azure DNS — can be significant in large environments
- **Private Resolver:** If using Azure DNS Private Resolver for hybrid resolution, enable diagnostic settings on the resolver for internal DNS visibility

---

## Notes

- Particularly valuable for serverless, PaaS, and container workloads that cannot run endpoint agents — Azure DNS is their primary DNS audit source
- Complements Azure Firewall DNS proxy logs (Tier 2) — Azure Firewall captures DNS at the network perimeter; Azure DNS captures at the resolution layer
- Consider threat intelligence matching against DNS query logs — use Microsoft Defender TI (Tier 2) IOCs for automated correlation

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify Azure DNS log volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Azure DNS diagnostic logging | [Learn](https://learn.microsoft.com/en-us/azure/dns/dns-metrics-alerts) |
| Azure DNS Private Resolver | [Learn](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview) |
| Defender for DNS overview | [Learn](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-dns-introduction) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
