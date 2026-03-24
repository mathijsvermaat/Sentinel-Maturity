# Sentinel Maturity Model — Data Connector Guidance

A structured approach to Microsoft Sentinel data connector onboarding, retention, and detection rationale for the Dutch Security TS team.

---

## Purpose

This guide provides a **tiered maturity model** for Microsoft Sentinel data connectors. It helps teams answer three questions:

1. **What data should we ingest?** — Which connectors and tables are essential?
2. **Why should we keep it?** — What is the security rationale (forensic readiness, detection, compliance)?
3. **How long should we retain it?** — What retention periods align with regulatory and operational needs?

## Tier Model

| Tier | Description | Target Audience |
|:-----|:------------|:----------------|
| **Tier 1** | **Bare minimum** — Essential connectors that every Sentinel deployment should have. Covers identity, endpoint, email, cloud activity, and server logs. | All customers |
| Tier 2 | Extended visibility — Additional connectors for customers with higher maturity requirements. | *Coming soon* |
| Tier 3 | Advanced — Full-spectrum monitoring including network, OT/IoT, and third-party integrations. | *Coming soon* |

## Tier 1 Connectors (Bare Minimum)

| Connector | Key Tables | Licensing Benefit | Free Ingestion |
|:-----------|:-----------|:------------------|:---------------|
| [Microsoft Defender XDR](connectors/microsoft-defender-xdr.md) | DeviceEvents, AlertInfo, EmailEvents, IdentityLogonEvents, CloudAppEvents, ... | E5 / Defender for Servers P2 | Yes — via [Microsoft 365 E5 Security data grant](https://learn.microsoft.com/en-us/azure/sentinel/microsoft-365-defender-sentinel-integration) |
| [Microsoft Entra ID](connectors/microsoft-entra-id.md) | SigninLogs, AuditLogs, AADNonInteractiveUserSignInLogs, ... | Entra ID P2 (in E5) | Yes — [free data connectors](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources) |
| [Office 365](connectors/office-365.md) | OfficeActivity | M365 E3/E5 | Yes — free data connector |
| [Azure Activity Logs](connectors/azure-activity-logs.md) | AzureActivity | Any Azure subscription | Yes — free data connector |
| [Windows Security Events](connectors/windows-security-events.md) | SecurityEvent / WindowsEvent | Defender for Servers P2 | 500 MB/day per server via Defender for Servers P2 |
| [Syslog for Linux](connectors/syslog-linux.md) | Syslog | Defender for Servers P2 | 500 MB/day per server via Defender for Servers P2 |

## Retention Philosophy

Our retention recommendations are informed by:

- **[Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)** — Specifically controls LT-1 through LT-6 and IR-4/IR-5
- **Forensic readiness** — The ability to investigate incidents that may have started weeks or months before detection (average dwell time in 2024: ~10 days for ransomware, but APTs can persist for months)
- **Layered security approach** — Defence in depth requires correlated data across identity, endpoint, network, and cloud layers
- **Regulatory and compliance requirements** — GDPR, NIS2, SOC 2, ISO 27001

### Recommended Retention Tiers

| Tier | Duration | Purpose | Sentinel Feature |
|:-----|:---------|:--------|:-----------------|
| **Hot** | 90 days | Active detection, hunting, and incident response | Analytics logs (interactive) |
| **Warm** | 90 days – 2 years | Extended investigations, historical correlation, threat hunting | Basic / Auxiliary logs |
| **Cold** | 2 – 7 years | Compliance, legal hold, long-term forensic archive | Archive tier |

---

## References

- [Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)
- [Microsoft Sentinel pricing and free data sources](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources)
- [Microsoft 365 E5 data grant for Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/microsoft-365-defender-sentinel-integration)
- [NIST SP 800-92 — Guide to Computer Security Log Management](https://csrc.nist.gov/pubs/sp/800/92/final)
- [NIS2 Directive](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats)
- [Sentinel Ninja training](https://github.com/oshezaf/sentinelninja)

*Last updated: March 2026*
