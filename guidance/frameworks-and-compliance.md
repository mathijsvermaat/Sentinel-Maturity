# Frameworks and Compliance

## Overview

Logging and retention decisions are not made in isolation — they must align with industry security frameworks and regulatory requirements. This page outlines the key frameworks and compliance standards that inform the Sentinel Maturity Model recommendations.

## Microsoft Cloud Security Benchmark (MCSB)

The [Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/security/benchmark/azure/overview) is Microsoft's primary security framework for Azure and Microsoft 365 workloads. It provides specific controls relevant to logging and monitoring:

### Logging and Threat Detection (LT) Controls

| Control | Title | Relevance |
|:--------|:------|:----------|
| **LT-1** | Enable threat detection capabilities | Enable built-in threat detection across Sentinel-connected data sources |
| **LT-2** | Enable threat detection for identity and access management | Ensure identity logs (Entra ID, MDI) flow into Sentinel for detection |
| **LT-3** | Enable logging for security investigation | Collect sufficient log data to support incident investigations |
| **LT-4** | Enable network logging for security investigation | Capture network-level telemetry for lateral movement and exfiltration detection |
| **LT-5** | Centralise security log management and analysis | Aggregate logs in a centralised SIEM (Sentinel) for correlation |
| **LT-6** | Configure log storage retention | Define and enforce retention periods aligned with forensic and compliance needs |

### Incident Response (IR) Controls

| Control | Title | Relevance |
|:--------|:------|:----------|
| **IR-4** | Detection and analysis — investigate an incident | Requires accessible, searchable log data to reconstruct incident timelines |
| **IR-5** | Detection and analysis — prioritise incidents | Requires correlated, enriched alerts from multiple data sources |

> [!NOTE]
> The MCSB controls are mapped to specific Sentinel tables and connectors throughout the [connector pages](../connectors/) in this maturity model.

## Microsoft Secure Future Initiative (SFI)

The [Microsoft Secure Future Initiative](https://learn.microsoft.com/en-us/security/engineering/secure-future-initiative) includes a specific pillar on centralised security logging:

- [Centralise access to security logs](https://learn.microsoft.com/en-us/security/engineering/secure-future-initiative#security-monitoring) — Microsoft's own commitment to ensuring security-relevant logs are centrally accessible for analysis and investigation

This aligns directly with the SIEM centralisation approach recommended in this maturity model.

## Microsoft Compliance Offerings

Microsoft provides a comprehensive set of compliance certifications and attestations relevant to log management:

- [Compliance offerings for Microsoft 365, Azure, and other Microsoft services](https://learn.microsoft.com/en-us/compliance/regulatory/offering-home) — covers SOC 2, ISO 27001, HIPAA, FedRAMP, and many others

These compliance offerings determine what logging capabilities are available within the platform and what guarantees Microsoft provides around data handling and retention.

## Regulatory Compliance

### NIS2 Directive

The [NIS2 Directive](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats) is the EU's updated cybersecurity regulation that significantly expands the scope and requirements for organisations operating in the European Union.

Key NIS2 requirements relevant to logging and monitoring:

| Requirement | Logging Implication |
|:------------|:--------------------|
| **Incident reporting** within 24–72 hours | Requires real-time alerting and rapid access to correlated log data |
| **Risk management measures** | Mandates appropriate security controls including logging and monitoring |
| **Supply chain security** | Requires visibility into third-party access and activity |
| **Business continuity** | Requires the ability to reconstruct events during and after incidents |
| **Accountability and governance** | Management must ensure security measures are implemented — logging gaps represent governance risk |

> [!IMPORTANT]
> NIS2 applies to a much broader set of organisations than its predecessor (NIS1). Organisations classified as "essential" or "important" entities must comply, with significant penalties for non-compliance.

### Other Regulatory Frameworks

Depending on your industry and geography, additional regulations may apply:

| Framework | Jurisdiction | Key Logging Requirements |
|:----------|:-------------|:-------------------------|
| **GDPR** | EU/EEA | Audit trails for personal data access; breach notification within 72 hours |
| **SOC 2** | Global (US-origin) | Security monitoring and incident response logging under the Security Trust Services Criterion |
| **ISO 27001** | Global | Annex A controls A.8.15 (logging), A.8.16 (monitoring activities) |
| **HIPAA** | United States | Audit controls for electronic protected health information access |
| **DORA** | EU (financial sector) | ICT risk management including logging, detection, and incident reporting |

## How This Maps to the Maturity Model

| Framework Requirement | Maturity Model Alignment |
|:----------------------|:-------------------------|
| Centralised logging | All Tier 1 connectors feed into Microsoft Sentinel |
| Sufficient retention | Analytics: 90 days + Lake: 365 days default |
| Cross-source correlation | Identity + endpoint + email + cloud activity connectors |
| Incident investigation capability | Detection examples and forensic rationale per table |
| Compliance reporting | Workspace Usage Report workbook for audit and reporting |

---

### References

- [Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)
- [Microsoft Secure Future Initiative](https://learn.microsoft.com/en-us/security/engineering/secure-future-initiative)
- [Compliance offerings for Microsoft 365, Azure, and other Microsoft services](https://learn.microsoft.com/en-us/compliance/regulatory/offering-home)
- [NIS2 Directive — European Parliament](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats)

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
