# Layered Detection Approach

## Contents

- [Overview](#overview)
- [Why Layering Matters](#why-layering-matters)
- [EDR Telemetry Is Not Complete Telemetry](#edr-telemetry-is-not-complete-telemetry)
- [Real-World EDR Bypass Examples](#real-world-edr-bypass-examples)
- [When Correlation Is Not Enough](#when-correlation-is-not-enough)
  - [Canary Objects in Active Directory](#canary-objects-in-active-directory)
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

## When Correlation Is Not Enough

EDR and SIEM are both **observation** layers: they record what happened and infer intent afterwards. That inference has a limit, and Active Directory is where it is reached most often.

The joint guidance [*Detecting and mitigating Active Directory compromises*](https://www.cisa.gov/resources-tools/resources/detecting-and-mitigating-active-directory-compromises) — published by ASD, CISA, NSA, the FBI and international partners — states the problem directly:

> *"Many Active Directory compromises exploit legitimate functionality and generate the same events that are generated by normal activity. Distinguishing malicious activity from normal activity often requires correlating different events, sometimes from different sources, and analysing these events for discrepancies. For some Active Directory compromises, the detection relies on the presence of one event and the absence of another."*

That last sentence is the uncomfortable one. A Golden Ticket is detected not by an anomalous event but by a service-ticket request (4769) arriving with **no matching ticket-granting request (4768)**. A Silver Ticket produces no domain controller traffic at all. Neither has a signature; both have an absence. Absence-based rules are expensive to write, fragile against log gaps, and almost impossible to tune — which is precisely why the guidance names detection complexity as *"one of the leading causes of their success and their prevalence against organisations"*.

This is not an argument against correlation. It is an argument that a third layer is needed where correlation is weakest.

### Canary Objects in Active Directory

A canary object is a decoy: an Active Directory object that looks attractive to an attacker enumerating the directory, and that **no legitimate process ever reads**. Any read is therefore malicious by construction — there is no baseline to learn and no false-positive population to tune away.

The mechanism is simple and costs nothing to run:

1. Create a decoy object that appears valuable — typically a user object with a service principal name, which is exactly what Kerberoasting and AS-REP Roasting tooling looks for.
2. Deny read access to `Everyone` on that object.
3. Enable the *Directory Service Access* audit subcategory for **both Success and Failure**.
4. Alert in Sentinel on `SecurityEvent` 4662 audit-failure records containing the canary object's GUID.

Because the object is unreadable, any attempt to enumerate it produces a failure event carrying the attacker's account and source. The guidance notes that this detects Kerberoasting, AS-REP Roasting and DCSync, and — more importantly — catches the **enumeration phase** that precedes almost every AD compromise, when tooling such as SharpHound sweeps the directory for misconfigurations.

What makes this a genuinely different layer:

| Property | Correlation-based detection | Canary objects |
|:---------|:----------------------------|:---------------|
| Detects | Attacker **tooling** and its side effects | The **compromise itself** |
| Depends on | Multiple correlated events, sometimes across sources | A single event |
| Tuning burden | High — legitimate activity generates the same events | None — no legitimate activity exists |
| Ingestion cost | Proportional to the events being correlated | Negligible |
| Evades by | Changing tooling, timing, or encryption type | Not touching the object |

> [!IMPORTANT]
> **Failure auditing is the whole mechanism.** With *Directory Service Access* set to Success only, the denied read produces no event and the canary is silently inert — it will look deployed and detect nothing. Configure Success **and** Failure.

> [!WARNING]
> Canaries are not a replacement for logging. The guidance is explicit about the limitation: an attacker who targets only one or two specific objects will never touch the decoy, and the technique produces nothing at all. It is a high-confidence **addition** to the correlation layer, not a substitute for it.

For the audit policy and the Sentinel-side detection, see [Windows Security Events](../connectors/windows-security-events.md#audit-policy-for-active-directory-compromise-detection-domain-controllers).

## Practical Implications

For the connectors covered in this maturity model, layered detection means:

| Scenario | EDR Coverage | SIEM Fallback |
|:---------|:-------------|:--------------|
| Process execution on Windows server | `DeviceProcessEvents` (MDE) | `SecurityEvent` 4688 (via AMA) |
| Authentication to Entra ID | `IdentityLogonEvents` (MDI) | `SigninLogs` (Entra ID connector) |
| Linux SSH brute-force | MDE for Linux (if deployed) | `Syslog` auth/authpriv facility |
| Email phishing detection | `EmailEvents` (MDO) | `OfficeActivity` Exchange workload |
| Azure resource modification | N/A | `AzureActivity` (only available via Sentinel) |
| Azure resource data-plane access (Key Vault secret read, Storage blob download, SQL query) | Defender for Cloud plan, if enabled (alerts only) | Diagnostic logs via Sentinel — **opt-in only, no native retention** |

> [!TIP]
> For Windows and Linux servers specifically, see the layered logging sections in the [Windows Security Events](../connectors/windows-security-events.md) and [Syslog for Linux](../connectors/syslog-linux.md) connector pages.

> [!NOTE]
> The resource data-plane layer is unique: it has **no EDR fallback and no native retention**. Unlike Windows or Linux hosts — where MDE and the local event log exist independently — an Azure resource log exists **only** if you enabled its diagnostic settings beforehand. See [Forensic Readiness](forensic-readiness.md#you-cannot-investigate-logs-you-never-collected).

---

## References

| Title | Authors | Description | Link |
|:------|:--------|:------------|:-----|
| Detecting and mitigating Active Directory compromises | ASD, CISA, NSA, FBI and international partners | Why Active Directory compromises are hard to detect, and the canary-object technique as a detection layer that does not depend on event correlation | [cisa.gov](https://www.cisa.gov/resources-tools/resources/detecting-and-mitigating-active-directory-compromises) · [PDF](https://www.cyber.gov.au/sites/default/files/2026-09/Detecting%20and%20mitigating%20Active%20Directory%20compromises%20%28September%202026%29.pdf) |

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
