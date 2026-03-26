# Threat Intelligence Platforms

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes — ThreatIntelligenceIndicator is a free data source

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

Threat Intelligence (TI) connectors bring **indicators of compromise (IOCs)** — malicious IPs, domains, URLs, file hashes — into Microsoft Sentinel for automated matching against all ingested log data. Rather than being a source of event data, TI is an **enrichment and detection layer** that amplifies the value of every other connector.

Without TI, your detections rely entirely on behavioural analytics and custom rules. With TI, you get automated IOC matching across all tables — a force multiplier for detection coverage.

### Threat Intelligence Sources in Sentinel

| Source | What It Provides |
|:-------|:-----------------|
| **Microsoft Defender Threat Intelligence (MDTI)** | Microsoft's proprietary TI — IOCs from Microsoft incident response, honeypots, and telemetry across the Microsoft ecosystem |
| **Threat Intelligence — TAXII** | STIX/TAXII feeds from third-party providers (Anomali, Recorded Future, MISP, etc.) |
| **Threat Intelligence Upload** | REST API for uploading custom IOCs from internal threat hunting or incident response |
| **Defender XDR TI integration** | IOCs from Defender XDR Threat Intelligence blade |

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft Sentinel** | TI platform connector and TAXII connector at no additional TI cost — community feeds available |
| **Microsoft Defender Threat Intelligence (MDTI)** | Premium Microsoft TI feed with high-fidelity IOCs and context |

> [!NOTE]
> The `ThreatIntelligenceIndicator` table is a **free data source** in Sentinel. IOC storage costs nothing. The detection value is immediate.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **ThreatIntelligenceIndicator** | IOCs from all connected TI sources — IPs, domains, URLs, file hashes, email addresses, with confidence scores and expiry dates | Analytics: 90d / Lake: 365d | **Detection force multiplier.** Automated matching of known malicious indicators against all ingested logs. MCSB LT-1. | Proves that a specific IP, domain, URL, or file hash seen in your environment matches known threat intelligence — strong evidence of compromise when correlated with behavioural signals | Network connection to known C2 IP (T1071), DNS resolution of known malicious domain (T1071.004), file hash match on known malware (T1204) |

---

## Example Detections

### IOC Matching

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| IP match — inbound connection | ThreatIntelligenceIndicator + AZFWNetworkRule / CommonSecurityLog | T1190 | Inbound connection from a known malicious IP |
| IP match — outbound C2 | ThreatIntelligenceIndicator + DeviceNetworkEvents / AZFWApplicationRule | T1071 | Outbound connection to a known C2 IP |
| Domain match — DNS resolution | ThreatIntelligenceIndicator + AZFWDnsQuery / DnsEvents | T1071.004 | DNS query for a known malicious domain |
| File hash match | ThreatIntelligenceIndicator + DeviceFileEvents | T1204 | File on endpoint matching a known malware hash |
| Email sender match | ThreatIntelligenceIndicator + EmailEvents | T1566 | Email received from a known threat actor email address |
| URL match — user visited | ThreatIntelligenceIndicator + UrlClickEvents / NetworkAccessTraffic | T1566.002 | User visited a known phishing or malware delivery URL |

### TI Quality and Lifecycle

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| High-confidence IOC match | ThreatIntelligenceIndicator | — | Alert only on IOCs with confidence score ≥ 80 to reduce false positives |
| Expired IOC still matching | ThreatIntelligenceIndicator | — | IOC past its expiry date still generating matches — may need refresh or removal |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection | TI provides automated IOC-based threat detection across all data sources |
| **IR-4** Detection and analysis | IOC matches provide high-confidence indicators for incident triage |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-150 (cyber threat information sharing) and NIST SP 800-53 SI-5 (security alerts and advisories), CIS Controls v8 13.3 (network monitoring enrichment), and ASD ACSC recommendations for leveraging threat intelligence to enhance detection strategies.

---

## Important Considerations

### Sentinel Analytics Rules for TI

Sentinel includes **built-in analytics rules** that automatically match TI indicators against common tables. Enable these rules:

- TI map IP entity to AzureActivity
- TI map IP entity to CommonSecurityLog
- TI map Domain entity to DnsEvents
- TI map FileHash entity to DeviceFileEvents
- TI map URL entity to EmailUrlInfo

### Feed Quality

Not all TI feeds are equal. Prioritise:
1. **MDTI** — highest signal-to-noise ratio for Microsoft environments
2. **Industry ISACs** — sector-specific IOCs (FS-ISAC, H-ISAC, etc.)
3. **OSINT feeds via TAXII** — AlienVault OTX, Abuse.ch, etc. — free but noisier

### IOC Expiry

Ensure IOCs have appropriate expiry dates. Stale IOCs generate false positives and erode analyst confidence. Review and prune expired indicators regularly.

---

## Notes

- `ThreatIntelligenceIndicator` is **free** — there is no cost barrier to enabling TI
- TI is only as valuable as the data it matches against — the more connectors you enable, the more value TI provides
- Consider creating a **TI matching dashboard** workbook to track match rates by source and confidence level
- MDTI requires a separate license — evaluate whether the premium IOC quality justifies the cost for your threat landscape

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor TI indicator ingestion and match rates | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

Community and third-party resources that support the guidance on this page.

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — recommends leveraging threat intelligence and machine learning for detection | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
