# Microsoft Defender for IoT

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes — SecurityAlert from Defender for IoT is a free data source

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

Microsoft Defender for IoT provides **network-layer threat detection** for OT (Operational Technology) and IoT (Internet of Things) environments. The solution uses passive network monitoring (network sensors) to discover and monitor industrial control systems (ICS), SCADA, building management systems, medical devices, and IoT assets — without requiring agents on the devices.

OT/IoT environments are increasingly targeted: ransomware impacting manufacturing, attacks on critical infrastructure, and weaponised IoT botnets. Traditional IT security tools have no visibility into these environments. Defender for IoT closes this gap by detecting protocol anomalies, unauthorized PLC programming changes, known OT-specific threats, and network policy violations.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Defender for IoT (per-device)** | OT/IoT network sensor deployment, asset discovery, vulnerability assessment, and threat detection |
| **Defender for IoT (Enterprise IoT)** | Enterprise IoT device discovery and monitoring — integrated with Defender for Endpoint |

> [!NOTE]
> `SecurityAlert` from Defender for IoT is a **free data source** in Sentinel. Device inventory and recommendation data incur ingestion cost. OT sensor deployment requires network TAP or SPAN port access.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SecurityAlert** (IoT) | OT/IoT threat detection alerts — protocol anomalies, unauthorized operations, known OT threats, network policy violations | Analytics: 90d / Lake: 365d | Primary OT/IoT security signal — the only threat detection source for unmanaged OT/IoT devices | Identifies the specific OT/IoT attack detected — essential for responding to incidents in industrial environments | Unauthorized PLC programming change (T0839) |
| **SecurityRecommendation** (IoT) | Device security recommendations — firmware vulnerabilities, insecure protocols, missing patches | Analytics: 30d / Lake: 180d | Posture management for OT/IoT — tracks device vulnerabilities and misconfigurations | Provides the vulnerability context during investigation — which devices were vulnerable at the time of the incident | Unpatched OT device running known vulnerable firmware |
| **IoTHubDistributedTracing** | IoT Hub message tracing and routing events | Analytics: 30d / Lake: 180d | Operational visibility for IoT Hub — traces message flow from device to cloud | Supports investigation of IoT data manipulation or message injection attacks | Anomalous IoT Hub message patterns indicating compromised device |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK (ICS) | Description |
|:----------|:---------|:--------------------|:------------|
| Unauthorized PLC programming | SecurityAlert (IoT) | T0839 | PLC program download or upload from an unauthorized engineering workstation |
| OT network scan detected | SecurityAlert (IoT) | T0846 | Network reconnaissance activity within the OT network — ARP scanning, port scanning from IT segment |
| Insecure industrial protocol usage | SecurityAlert (IoT) | T0869 | Unencrypted Modbus, DNP3, or OPC-UA communication detected — man-in-the-middle risk |
| New device in OT network | SecurityAlert (IoT) | T0800 | Previously unseen device communicating on the OT network — unauthorized connection |
| IT-to-OT lateral movement | SecurityAlert (IoT) | T0886 | Communication from IT network segment to OT devices — potential IT compromise spreading to OT |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection capabilities | OT/IoT-specific threat detection for industrial and IoT environments |
| **AM-1** Track asset inventory | Automated discovery and inventory of OT/IoT devices |
| **NS-1** Establish network segmentation boundaries | Detects IT-to-OT boundary violations and unauthorized cross-segment communication |
| **VM-1** Conduct vulnerability scanning | Identifies vulnerabilities in OT/IoT device firmware and configurations |

---

## Important Considerations

- **Network sensor deployment:** OT sensors require network TAP or SPAN port access on the OT network. Plan deployment with OT operations teams to avoid disrupting industrial processes
- **OT protocol support:** Defender for IoT supports 100+ industrial protocols (Modbus, DNP3, IEC 61850, OPC-UA, BACnet, etc.) — verify your protocol landscape is covered
- **Enterprise IoT vs OT:** Enterprise IoT (cameras, printers, smart TVs) integrates with Defender for Endpoint; OT (ICS/SCADA) uses dedicated OT sensors — different deployment models
- **Air-gapped environments:** For air-gapped OT networks, on-premises management console is available without cloud connectivity

---

## Notes

- OT/IoT monitoring is essential for critical infrastructure, manufacturing, healthcare (medical devices), smart buildings, and utilities
- The MITRE ATT&CK for ICS framework provides OT-specific TTPs — Defender for IoT detections map to this framework
- Consider pairing with Azure Firewall (Tier 2) or VNet Flow Logs (Tier 2) for IT-OT boundary monitoring

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify Defender for IoT alert volumes | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Defender for IoT overview | [Learn](https://learn.microsoft.com/en-us/azure/defender-for-iot/overview) |
| OT sensor deployment | [Learn](https://learn.microsoft.com/en-us/azure/defender-for-iot/ot-deploy/ot-deploy-path) |
| Connect Defender for IoT to Sentinel | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/iot-ot-threat-monitoring-with-defender-for-iot) |
| Tutorial: Connect Defender for IoT with Microsoft Sentinel | [Learn](https://learn.microsoft.com/azure/defender-for-iot/organizations/iot-solution) |
| MITRE ATT&CK for ICS | [MITRE](https://attack.mitre.org/matrices/ics/) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
