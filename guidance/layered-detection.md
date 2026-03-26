# Layered Detection Approach

## Contents

- [Overview](#overview)
- [Why Layering Matters](#why-layering-matters)
- [EDR Telemetry Is Not Complete Telemetry](#edr-telemetry-is-not-complete-telemetry)
- [Real-World EDR Bypass Examples](#real-world-edr-bypass-examples)
- [Practical Implications](#practical-implications)
- [References](#references)

---

## Overview

A defensible security strategy assumes that **no single tool is sufficient**. Microsoft Defender for Endpoint brings visibility into endpoints and servers with its EDR capabilities — but EDRs can be circumvented, disabled, or may simply not be deployed on all systems. Sending logs from high-priority devices to a SIEM provides the necessary redundancy.

> *"We must accept the fact that no barrier is impenetrable, and detection/response represents an extremely critical line of defence. Let's stop treating it like a backup plan if things go wrong."*

## Why Layering Matters

### EDR Solutions

EDR solutions such as Microsoft Defender for Endpoint:

- Provide **deep behavioural telemetry** with rich context
- Are optimised for **real-time detection and response**
- Often **abstract raw data into alerts** — the underlying telemetry may not be preserved
- May **retain data for limited periods** (typically 30–180 days depending on licence and configuration)

### SIEM-Based Logging

SIEM-based logging through Microsoft Sentinel:

- Preserves **raw, authoritative event records** as they occurred
- Enables **long-term retention** (Analytics: 90 days + Lake: 365 days)
- Supports **cross-source correlation** across identity, endpoint, email, and cloud layers
- Provides **independent evidence** if EDR telemetry is unavailable or has been tampered with

### What Layered Detection Ensures

| Benefit | Description |
|:--------|:------------|
| **Redundancy in detection** | If one detection layer misses an attack, another layer may catch it |
| **Survivability of evidence** | Centralised logs persist even if the source system is compromised |
| **Defence against blind spots** | No single platform covers 100% of attacker techniques — see the [EDR Telemetry Project](https://www.edrtelemetry.com/) for coverage gaps |

## EDR Telemetry Is Not Complete Telemetry

EDRs are configured to collect certain telemetry, but that does **not** mean all telemetry. Understanding what your EDR does and does not collect is critical to identifying gaps that SIEM-based logging must fill.

| Resource | Description | Link |
|:---------|:------------|:-----|
| EDR Telemetry Project | Comprehensive endpoint detection and response analysis with real-time telemetry comparison, behavioural analytics insights, and detailed platform coverage | [edrtelemetry.com](https://www.edrtelemetry.com/) |
| Defender for Endpoint Internals — Audit Settings and Telemetry | Technical deep-dive on how MDE collects telemetry through kernel callbacks and ETW, why proper audit policy configuration is critical for full detection coverage, and what blind spots can occur if settings are misconfigured | [FalconForce](https://falconforce.nl/blogs/microsoft-defender-for-endpoint-internals-0x02-audit-settings-and-telemetry/) |

## Real-World EDR Bypass Examples

The following examples demonstrate why relying solely on EDR is insufficient. To maintain visibility when EDR is bypassed, disabled, or not installed, you need SIEM-based logging and analytics as a fallback detection layer.

| Title | Description | Link |
|:------|:------------|:-----|
| Shanya — Packer-as-a-Service | A service that obfuscates malware and actively disables antivirus and EDR solutions, fuelling the ransomware ecosystem | [Decoded Layer](https://decodedlayer.substack.com/p/shanya-the-packer-as-a-service-powering) |
| EDR Killer | EDR killer tool that uses a signed kernel driver from forensic software to terminate EDR processes | [BleepingComputer](https://www.bleepingcomputer.com/news/security/edr-killer-tool-uses-signed-kernel-driver-from-forensic-software/) |
| The Evolution of EDR Bypasses | Historical timeline showing how EDR bypass techniques have evolved over time, reinforcing why native logs are essential as a fallback | [CovertSwarm](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) |
| Cloud Forensics: Forensic Readiness and IR in AVD | Layered approach combining EDR and native logging for incident response in cloud environments | [Microsoft Community Hub](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/cloud-forensics-forensic-readiness-and-incident-response-in-azure-virtual-desktop/3835484) |
| BypassAV Mindmap | Comprehensive list of all essential techniques to bypass antivirus and EDR | [GitHub — matro7sh/BypassAV](https://github.com/matro7sh/BypassAV) |

## Practical Implications

For the connectors covered in this maturity model, layered detection means:

| Scenario | EDR Coverage | SIEM Fallback |
|:---------|:-------------|:--------------|
| Process execution on Windows server | `DeviceProcessEvents` (MDE) | `SecurityEvent` 4688 (via AMA) |
| Authentication to Entra ID | `IdentityLogonEvents` (MDI) | `SigninLogs` (Entra ID connector) |
| Linux SSH brute-force | MDE for Linux (if deployed) | `Syslog` auth/authpriv facility |
| Email phishing detection | `EmailEvents` (MDO) | `OfficeActivity` Exchange workload |
| Azure resource modification | N/A | `AzureActivity` (only available via Sentinel) |

> [!TIP]
> For Windows and Linux servers specifically, see the layered logging sections in the [Windows Security Events](../connectors/windows-security-events.md) and [Syslog for Linux](../connectors/syslog-linux.md) connector pages.

---

## References

*No community references yet — contributions welcome.*

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
