# Forensic Readiness

## Contents

- [Overview](#overview)
- [Forensic Readiness as a Design Requirement](#forensic-readiness-as-a-design-requirement)
- [Why Centralised Logging Is Critical](#why-centralised-logging-is-critical)
- [You Cannot Investigate Logs You Never Collected](#you-cannot-investigate-logs-you-never-collected)
- [Forensic Value Across Log Sources](#forensic-value-across-log-sources)
- [Real-World Examples](#real-world-examples)
- [References](#references)

---

## Overview

Forensic readiness is a foundational security capability that enables an organisation to effectively investigate and respond to security incidents. It is **not something that can be added after an incident has occurred**; instead, it must be deliberately designed into logging, monitoring, and data retention strategies from the outset.

At its core, forensic readiness enables organisations to:

- **Reconstruct attacker activity** — understand exactly what happened, when, and how
- **Preserve the integrity of evidence** — ensure log data is tamper-resistant and trustworthy
- **Support informed decision-making** after an incident
- **Meet legal, regulatory, and insurance-related obligations** — the ability to demonstrate what happened can be just as important as remediation itself

## Forensic Readiness as a Design Requirement

Designing for forensic readiness requires making **conscious logging decisions**. These decisions should be guided by the types of questions investigators may need to answer during an incident:

| Investigation Question | Required Log Sources |
|:-----------------------|:---------------------|
| How was initial access gained? | Authentication logs (SigninLogs, SecurityEvent 4624/4625) |
| How was privilege escalated? | Audit logs (AuditLogs, SecurityEvent 4672/4728) |
| What systems were accessed laterally? | Identity logs + endpoint logs + network logs |
| How was data exfiltrated? | Network logs, OfficeActivity, CloudAppEvents |
| What persistence mechanisms were established? | Endpoint logs (DeviceRegistryEvents, SecurityEvent 4698) |
| Were security controls tampered with? | SecurityEvent 1102 (log cleared), DeviceEvents |

Equally important is ensuring that **evidence will still be available** weeks or even months after the initial compromise, and that the data collected is sufficiently granular, trustworthy, and tamper-resistant to support reliable conclusions.

## Why Centralised Logging Is Critical

Modern attacks rarely rely on noisy or overt techniques. Instead, attackers frequently:

- Use **valid credentials** rather than malware
- **Move laterally** across systems using legitimate tools
- Operate **below traditional alert thresholds**
- Remain **dormant or undetected for extended periods** while establishing persistence

Without centralised logging, early attacker activity is often **lost**:

- Local logs may **roll over** due to size limits
- Logs may be **deleted** by attackers with administrative access
- Logs may be **altered** to cover tracks

As a result, investigations are forced to rely on partial data or reconstructed timelines, making root cause analysis speculative and confidence in findings difficult to achieve.

### What a Centralised SIEM Provides

A centralised SIEM platform like Microsoft Sentinel addresses these challenges:

| Capability | Forensic Benefit |
|:-----------|:-----------------|
| **Longer retention** than most source systems | Evidence available for investigations spanning months |
| **Consistent access and normalisation** | Uniform query interface across diverse log sources |
| **Independent evidence store** | Data resides outside the potentially compromised environment |
| **Tamper resistance** | Centralised logs cannot be modified by attackers on source systems |
| **Cross-source correlation** | Combine identity + endpoint + network + cloud for full attack reconstruction |

> [!IMPORTANT]
> The independence of the SIEM from the source environment is particularly critical from a forensic standpoint. It increases confidence that the data used during an investigation has not been manipulated by the attacker.

Log clearing is not an edge case. The joint guidance [*Detecting and mitigating Active Directory compromises*](https://www.cisa.gov/resources-tools/resources/detecting-and-mitigating-active-directory-compromises) lists Windows event **1102** — *the Security audit log was cleared* — against four separate techniques: dumping `ntds.dit`, one-way domain trust bypass, SID History compromise and Skeleton Key. It appears again on the recommended event lists for AD CS certificate authority servers, AD FS servers and Microsoft Entra Connect servers. Clearing the log is simply what an attacker does once they hold the privileges these techniques grant.

That makes 1102 the sharpest illustration of why centralisation must happen **before** the incident. Once the log is cleared, the forwarded copy in Sentinel is not the best evidence — it is the **only** evidence. And the event itself inverts: locally it is the last record before the trail disappears, while centrally it becomes a high-confidence alert that an attacker has reached administrative privilege and started cleaning up.

## You Cannot Investigate Logs You Never Collected

In the cloud, a critical nuance compounds the case for centralised logging: **most Azure resource logs do not exist until you deliberately enable them.** There is no local buffer to fall back on. Where an on-premises server at least records to a local event log that rolls over, an Azure resource generates **nothing** at the data-plane level until diagnostic settings (or a Data Collection Rule) route its logs to a destination such as Azure Monitor / Log Analytics.

| Log source | Default state | If not configured before an incident |
|:-----------|:--------------|:-------------------------------------|
| Azure Activity Log (control plane) | On by default — 90 days, free | Available for 90 days; export for longer retention |
| Resource / diagnostic logs (Key Vault, Storage, SQL, AKS, Firewall, WAF, NSG/VNet, DNS) | **Off — no data generated** | **Permanently lost — the evidence never existed** |
| Entra ID sign-in / audit logs | 7 days (Free) / 30 days (P1/P2) | Lost beyond the retention window unless exported |

The implication for forensic readiness is severe: the moment you need a resource log during an investigation is far too late to enable it. The data for the period under investigation will simply not exist.

At enterprise scale this risk is amplified by **configuration drift** — per-resource diagnostic settings are inconsistently applied, disabled, or never added to newly created resources, leaving silent gaps. [Data Collection Rules for Azure resource platform logs](https://techcommunity.microsoft.com/blog/AzureObservabilityBlog/public-preview---azure-monitor---collect-azure-resource-platform-logs-at-scale-w/4525296) (public preview) address this by centralising collection under a single policy-enforced, drift-resistant rule. For a per-log-type breakdown of defaults and retention, see [Demystifying Log Retention in Azure](https://www.shankuehn.io/post/demystifying-log-retention-in-azure).

> [!IMPORTANT]
> Treat "enable diagnostic logging" as a forensic-readiness control, not a monitoring nicety. Evidence that is not collected at the time of the event cannot be recovered afterwards.

## Forensic Value Across Log Sources

Different log sources contribute distinct and complementary forensic insights. When combined and correlated centrally, they enable a much more complete reconstruction of an attack lifecycle.

### Identity and Authentication Logs

Identity-related logs form the **backbone of many investigations**, especially in environments where attackers rely on stolen or abused credentials.

| What They Capture | Forensic Value |
|:------------------|:---------------|
| Successful and failed authentication attempts | Reconstruct authentication timelines — when and how access was obtained |
| Credential validation failures | Identify brute-force attacks, password spraying, and credential theft |
| Changes to roles or privileges | Detect privilege escalation and role manipulation |
| Service principal and managed identity activity | Track non-human identity abuse |

**Key Sentinel tables:** `SigninLogs`, `AADNonInteractiveUserSignInLogs`, `AADServicePrincipalSignInLogs`, `IdentityLogonEvents`

### Endpoint and Operating System Logs

Endpoint logs provide visibility into **what actually happened on a system** after access was gained.

| What They Capture | Forensic Value |
|:------------------|:---------------|
| Process creation and execution events | Reconstruct execution chains and command-line activity |
| Privilege escalation attempts | Identify how attackers elevated from standard to admin |
| Configuration and security control changes | Detect defence evasion and anti-forensic behaviour |
| Service installations and scheduled tasks | Identify persistence mechanisms |

**Key Sentinel tables:** `DeviceProcessEvents`, `DeviceFileEvents`, `SecurityEvent`, `Syslog`

> [!NOTE]
> Without endpoint-level telemetry, it becomes extremely difficult to distinguish between benign administrative activity and malicious actions performed by an attacker using valid tools.

### Network and Infrastructure Logs

Network logs add critical context by showing **how systems communicate** with each other and with external destinations.

| What They Capture | Forensic Value |
|:------------------|:---------------|
| Firewall allow and deny decisions | Track lateral movement paths and external connections |
| VPN connection logs | Identify remote access patterns and anomalies |
| Network flow metadata | Correlate endpoint activity with observed network behaviour |
| DNS queries | Detect command-and-control or data exfiltration patterns |

**Key Sentinel tables:** `AzureNetworkAnalytics_CL`, `CommonSecurityLog`, `AzureDiagnostics`

Network telemetry is often the key to validating whether suspicious endpoint activity resulted in **actual data movement beyond the environment**.

## Real-World Examples

| Title | Description | Link |
|:------|:------------|:-----|
| Cloud Forensics: Forensic Readiness and IR in Azure Virtual Desktop | Demonstrates a layered approach combining EDR and native logging for incident response in cloud environments | [Microsoft Community Hub](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/cloud-forensics-forensic-readiness-and-incident-response-in-azure-virtual-desktop/3835484) |

---

## References

- [Demystifying Log Retention in Azure — shankuehn.io](https://www.shankuehn.io/post/demystifying-log-retention-in-azure) — per-log-type breakdown of Azure default retention and the opt-in nature of resource diagnostic logs
- [Collect Azure resource platform logs at scale with DCRs (public preview) — Azure Observability blog](https://techcommunity.microsoft.com/blog/AzureObservabilityBlog/public-preview---azure-monitor---collect-azure-resource-platform-logs-at-scale-w/4525296) — centralised, drift-resistant collection of Azure resource platform logs
- [Detecting and mitigating Active Directory compromises — CISA](https://www.cisa.gov/resources-tools/resources/detecting-and-mitigating-active-directory-compromises) ([PDF](https://www.cyber.gov.au/sites/default/files/2026-09/Detecting%20and%20mitigating%20Active%20Directory%20compromises%20%28September%202026%29.pdf)) — joint ASD/CISA/NSA/FBI guidance; lists event 1102 (Security log cleared) against four separate Active Directory compromise techniques

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
