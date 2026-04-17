# Third-Party Network & Proxy Appliances (CEF / Syslog)

**Tier:** 2 (Extended Visibility) · **Connector type:** Third-party · **Free ingestion:** No · **Conditional:** Only applicable with non-Microsoft network appliances

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Common Vendors with Sentinel Support](#common-vendors-with-sentinel-support)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Important Considerations](#important-considerations)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)

---

## Overview

Many organisations use non-Microsoft firewalls, web proxies, and network appliances — either on-premises, in cloud NVAs, or as cloud-delivered services. These devices generate security logs in **Common Event Format (CEF)** or raw **Syslog** format, which can be forwarded to Microsoft Sentinel via the Azure Monitor Agent (AMA).

This is the catch-all connector page for all third-party network security devices. The transport mechanism is standardised (CEF over Syslog via AMA), and many vendors also have dedicated Sentinel data connectors in the Content Hub that provide richer parsing and normalisation.

### Transport Mechanisms

| Method | Table | Best For |
|:-------|:------|:---------|
| **CEF via AMA** | `CommonSecurityLog` | Firewalls, IDS/IPS, network proxies — structured format with standardised fields |
| **Syslog via AMA** | `Syslog` | Devices that only support raw Syslog (no CEF) — less structured |
| **Dedicated Content Hub connector** | Vendor-specific custom table (e.g., `PaloAltoNetworks_CL`) | Vendors with Sentinel Content Hub solutions — richer parsing |

> [!NOTE]
> `CommonSecurityLog` is **not** covered by the Defender for Servers P2 500 MB/day data ingestion benefit — see the list of [eligible tables](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit). CEF/Syslog traffic from network appliances is billed at standard ingestion rates; use DCR transformations to drop non-security traffic and manage volume.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **CommonSecurityLog** | CEF-formatted events from firewalls, proxies, IDS/IPS — source/dest IP, port, protocol, action, device vendor, severity | Analytics: 90d / Lake: 365d | **Core third-party network forensics.** Detects perimeter attacks, C2, exfiltration, and lateral movement through non-Microsoft network appliances. MCSB LT-4. | Proves all traffic decisions made by third-party network security devices — essential when on-premises or hybrid infrastructure uses non-Microsoft firewalls | C2 callback blocked by firewall (T1071), data exfiltration detected by proxy (T1567), IDS signature match (T1190) |
| **Syslog** | Raw syslog events from devices without CEF support — facility, severity, message | Analytics: 90d / Lake: 365d | Fallback for legacy devices. Less structured than CEF but still valuable for forensic timeline. | Raw event data from legacy appliances — may require custom parsing but provides timeline evidence | Legacy firewall deny event correlating with attack timeline |

---

## Common Vendors with Sentinel Support

| Vendor | Product | Transport | Content Hub Solution | Notes |
|:-------|:--------|:----------|:--------------------|:------|
| **Palo Alto Networks** | PAN-OS | CEF + dedicated connector | [Yes](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/palo-alto-networks) | Also supports Cortex Data Lake integration |
| **Fortinet** | FortiGate | CEF | [Yes](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/fortinet) | FortiAnalyzer can aggregate before forwarding |
| **Check Point** | NGFW, SmartEvent | CEF | [Yes](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/check-point) | Use Log Exporter for CEF formatting |
| **Cisco** | ASA, FTD, Umbrella | CEF + Syslog | [Yes](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/cisco-asa) | ASA uses CEF; Umbrella has dedicated connector |
| **Zscaler** | ZIA, ZPA | CEF + dedicated connector | [Yes](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/zscaler) | Cloud-delivered — NSS feed to AMA forwarder |
| **Squid** | Web proxy | Syslog | No | Custom parsing required — use Syslog table |
| **Sophos** | XG Firewall | CEF | [Yes](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/sophos-xg-firewall) | |

> [!TIP]
> Check the [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-solutions-catalog) for your vendor — dedicated solutions often include pre-built analytics rules, workbooks, and hunting queries alongside the data connector.

---

## Example Detections

### Perimeter Security

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Outbound C2 blocked | CommonSecurityLog | T1071 | Firewall denying outbound traffic to known C2 infrastructure |
| IDS/IPS signature match | CommonSecurityLog | T1190 | Network intrusion detection signature triggered |
| Proxy bypass attempt | CommonSecurityLog | T1090 | Direct internet access bypassing the configured web proxy |
| Mass denied connections | CommonSecurityLog | T1046 | Single source generating many denied connections — scanning or misconfigured lateral movement |

### Data Exfiltration

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Large upload via proxy | CommonSecurityLog | T1567 | Unusually large outbound transfer through the web proxy |
| Access to file-sharing service from server | CommonSecurityLog | T1567 | Server accessing consumer file-sharing services (indicates compromised server exfiltrating) |
| Encrypted traffic to unusual destination | CommonSecurityLog | T1573 | TLS connection to an IP/domain not in baseline communication pattern |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-4** Enable network logging for security investigation | Third-party network appliance logs provide perimeter and segmentation visibility |
| **LT-3** Enable logging for security investigation | Legacy device audit trails support forensic investigation |
| **NS-1** Establish network segmentation boundaries | Firewall logs prove segmentation enforcement at non-Microsoft boundaries |
| **NS-7** Simplify network security configuration | Centralising third-party logs in Sentinel provides unified network visibility |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-12 (audit generation) and SC-7 (boundary protection), CIS Controls v8 13.6 (network traffic monitoring), and ASD ACSC enterprise network logging priority #5 (edge devices and firewalls) and #16 (legacy IT assets).

---

## Important Considerations

### Log Forwarder Architecture

CEF/Syslog collection requires a **log forwarder** — a Linux VM running AMA that receives Syslog from your devices and forwards to Sentinel:

```
[Firewall/Proxy] --Syslog/CEF--> [Linux VM + AMA] ---> [Sentinel Workspace]
```

- Deploy the forwarder in the same network as the log sources to avoid cross-network Syslog traffic
- Size the forwarder VM based on events per second (EPS) — Microsoft recommends one forwarder per 8,000 EPS
- For high availability, deploy multiple forwarders behind a load balancer

### CEF vs. Raw Syslog

Always prefer **CEF** over raw Syslog when the device supports it. CEF provides:
- Standardised field names (SourceIP, DestinationIP, DeviceAction, etc.)
- Consistent severity mapping
- Better query performance in Sentinel

### Data Collection Rules (DCR)

Configure DCRs to filter out noise — many network devices send informational and operational messages alongside security events. Filter at the DCR level to reduce ingestion cost.

---

## Notes

- If your organisation uses Azure Firewall for all network security, this connector page may not apply — see the [Azure Firewall](azure-firewall.md) page instead
- `CommonSecurityLog` receives the Defender for Servers P2 ingestion benefit (500 MB/day) when the AMA forwarder has Defender for Servers P2
- For Zscaler users who are also migrating to Microsoft Global Secure Access, evaluate whether both proxy log sources are needed or whether GSA will replace Zscaler — see the [Global Secure Access](global-secure-access.md) page
- ASIM (Advanced Security Information Model) normalisation parsers can unify `CommonSecurityLog`, `AZFWNetworkRule`, and `NetworkAccessTraffic` into a single normalised schema for cross-source detections

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor CommonSecurityLog and Syslog ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Network Session Essentials** | Solution | 2 workbooks, 10 analytic rules, 6 hunting queries — ASIM-based network session analytics; CEF/Syslog network appliance logs can feed ASIM-normalised detections | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| CEF via AMA — configure specific appliance or device | Setup guide for CEF-based third-party appliance connectors via AMA | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/unified-connector-cef-device) |
| Syslog via AMA — configure specific appliance or device | Setup guide for Syslog-based third-party appliance connectors via AMA | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/unified-connector-syslog-device) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — CEF via AMA connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/cefama.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — edge devices/firewalls are Enterprise Networks priority #5, web proxies are priority #12 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
