# Sentinel Maturity Model — Data Connector Guidance

A structured approach to Microsoft Sentinel data connector onboarding, retention, and detection rationale for the Dutch Security TS team.

---

## Purpose

This guide provides a **tiered maturity model** for Microsoft Sentinel data connectors. It helps teams answer three questions:

1. **What data should we ingest?** — Which connectors and tables are essential?
2. **Why should we keep it?** — What is the security rationale (forensic readiness, detection, compliance)?
3. **How long should we retain it?** — What retention periods align with regulatory and operational needs?

## Guidance

Before diving into specific connectors and tables, review the strategic guidance that underpins the decisions in this maturity model:

| Topic | Description |
|:------|:------------|
| [Risk Considerations](guidance/risk-considerations.md) | Why there is no one-size-fits-all logging configuration and how to apply a risk-based approach |
| [Input/Output Strategy](guidance/input-output-strategy.md) | Gartner's SIEM input/output strategy — tiering telemetry for cost-effective security operations |
| [Forensic Readiness](guidance/forensic-readiness.md) | Designing logging and retention for incident investigation from day one |
| [Layered Detection Approach](guidance/layered-detection.md) | Why EDR alone is not sufficient and how SIEM-based logging provides defence in depth |
| [Frameworks and Compliance](guidance/frameworks-and-compliance.md) | MCSB, SFI, NIS2, and other regulatory standards that inform logging decisions |
| [Budget and Cost Planning](guidance/budget-and-cost-planning.md) | SOC budgeting and Microsoft Sentinel cost optimisation strategies |

## Tier Model

| Tier | Description | Target Audience |
|:-----|:------------|:----------------|
| **Tier 1** | **Bare minimum** — Essential connectors that every Sentinel deployment should have. Covers identity, endpoint, email, cloud activity, and server logs. | All customers |
| Tier 2 | Extended visibility — Additional connectors for customers with higher maturity requirements. | *Coming soon* |
| Tier 3 | Advanced — Full-spectrum monitoring including network, OT/IoT, and third-party integrations. | *Coming soon* |

## Tier 1 Connectors (Bare Minimum)

| Connector | Key Tables | Licensing Benefit | Free Ingestion |
|:-----------|:-----------|:------------------|:---------------|
| [Microsoft Defender XDR](connectors/microsoft-defender-xdr.md) | DeviceEvents, AlertInfo, EmailEvents, IdentityLogonEvents, CloudAppEvents, ... | M365 E5 / E5 Security | Yes — ingestion to **Analytics tier only** via [Microsoft Sentinel benefit for M365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer) |
| [Microsoft Entra ID](connectors/microsoft-entra-id.md) | SigninLogs, AuditLogs, AADNonInteractiveUserSignInLogs, ... | Entra ID P2 (in E5) | Yes — [free data connectors](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources) |
| [Office 365](connectors/office-365.md) | OfficeActivity | M365 E3/E5 | Yes — free data connector |
| [Azure Activity Logs](connectors/azure-activity-logs.md) | AzureActivity | Any Azure subscription | Yes — free data connector |
| [Windows Security Events](connectors/windows-security-events.md) | SecurityEvent / WindowsEvent | [Defender for Servers P2](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) | [500 MB/day per server](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) via Defender for Servers P2 |
| [Syslog for Linux](connectors/syslog-linux.md) | Syslog | [Defender for Servers P2](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) | [500 MB/day per server](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) via Defender for Servers P2 |

## Retention Philosophy

Our retention recommendations are informed by:

- **[Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)** — Specifically controls LT-1 through LT-6 and IR-4/IR-5
- **Forensic readiness** — The ability to investigate incidents that may have started weeks or months before detection (average dwell time in 2024: ~10 days for ransomware, but APTs can persist for months)
- **Layered security approach** — Defence in depth requires correlated data across identity, endpoint, network, and cloud layers
- **Regulatory and compliance requirements** — GDPR, NIS2, SOC 2, ISO 27001

### Recommended Retention Tiers

| Tier | Duration | Purpose | Sentinel Feature |
|:-----|:---------|:--------|:-----------------|
| **Analytics** | 90 days | Active detection, hunting, and incident response | Analytics logs (interactive) |
| **Long-term** | 365 days | Extended investigations, historical correlation, threat hunting | Sentinel Data Lake (Lake) |

> [!NOTE]
> The default long-term retention for all Tier 1 tables is **365 days** in the Sentinel Data Lake. Adjust per table based on compliance or forensic requirements.

---

## Why a Layered Approach?

EDR solutions like Microsoft Defender for Endpoint are essential but **not sufficient on their own**. A layered approach combining EDR with native OS logging (Windows Security Events, Syslog) provides defence in depth:

- **EDR can be bypassed** — attackers continuously develop techniques to evade endpoint detection. Native OS logs provide an independent audit trail that persists even if EDR is tampered with.
- **Forensic readiness** — native logs provide authoritative evidence admissible in investigations, complementing EDR telemetry.
- **Correlation across data sources** — combining identity, endpoint, email, and cloud activity logs enables detection of multi-stage attacks that no single source can catch alone.

### Recommended Reading

| Title | Description | Link |
|:------|:------------|:-----|
| The Evolution of EDR Bypasses | Historical timeline showing how EDR bypass techniques evolve, reinforcing why native logs are essential as a fallback | [CovertSwarm](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) |
| Cloud Forensics: Forensic Readiness and IR in Azure Virtual Desktop | Demonstrates a layered approach combining EDR and native logging for incident response in cloud environments | [Microsoft Community Hub](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/cloud-forensics-forensic-readiness-and-incident-response-in-azure-virtual-desktop/3835484) |
| Windows Event Log Analysis: Techniques for Every SOC Analyst | Practical guide on using Windows Security Events for detection, showing their value alongside EDR | [CyberDefenders Blog](https://blog.cyberdefenders.org/2024/02/windows-event-log-analysis-techniques.html) |
| Sentinel Data Connectors: What Actually Matters | Practical guidance on which Sentinel data connectors to prioritize | [IT Professor](https://www.itprofessor.cloud/sentinel-data-connectors-what-actually-matters/) |

---

## Useful Workbooks

To help identify retention settings, monitor ingestion volumes, and validate data connector coverage, use these workbooks:

| Workbook | Purpose | Source |
|:---------|:--------|:-------|
| **Workspace Usage Report** | Monitor ingestion volumes per table, identify cost optimization opportunities, and validate data connector health across all connectors | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) (search "Workspace Usage") |
| **Defender AMA Coverage** | Validate Defender for Endpoint and AMA agent deployment coverage, identify gaps in security event and syslog collection | [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) |

---

## References

- [Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)
- [Microsoft Sentinel pricing and free data sources](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources)
- [Microsoft Sentinel benefit for Microsoft 365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer)
- [Defender for Cloud data ingestion benefit](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit)
- [NIST SP 800-92 — Guide to Computer Security Log Management](https://csrc.nist.gov/pubs/sp/800/92/final)
- [NIS2 Directive](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats)
- [Sentinel Ninja training](https://github.com/oshezaf/sentinelninja)

*Last updated: March 2026*
