# Forensic Readiness

## Contents

- [Overview](#overview)
- [Forensic Readiness as a Design Requirement](#forensic-readiness-as-a-design-requirement)
- [Why Centralised Logging Is Critical](#why-centralised-logging-is-critical)
- [Forensic Value Across Log Sources](#forensic-value-across-log-sources)
- [Real-World Examples](#real-world-examples)

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

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
