# Sentinel Maturity Model — Data Connector Guidance

A structured approach to Microsoft Sentinel data connector onboarding, retention, and detection rationale for the Dutch Security TS team.

---

## Contents

- [Sentinel Maturity Model — Data Connector Guidance](#sentinel-maturity-model--data-connector-guidance)
  - [Contents](#contents)
  - [Purpose](#purpose)
  - [Guidance](#guidance)
  - [Procedures](#procedures)
  - [Tier Model](#tier-model)
  - [Tier 1 Connectors (Bare Minimum)](#tier-1-connectors-bare-minimum)
  - [Tier 2 Connectors (Extended Visibility)](#tier-2-connectors-extended-visibility)
    - [Cloud Security Posture](#cloud-security-posture)
    - [Data Protection \& Governance](#data-protection--governance)
    - [Detection Enrichment](#detection-enrichment)
    - [Endpoint Compliance](#endpoint-compliance)
    - [Identity \& Access (Extended)](#identity--access-extended)
    - [Multi-Cloud](#multi-cloud)
    - [Network Visibility](#network-visibility)
  - [Tier 3 Connectors (Advanced / Specialised)](#tier-3-connectors-advanced--specialised)
    - [Application \& Workload Security](#application--workload-security)
    - [Collaboration \& Communication](#collaboration--communication)
    - [Custom Applications (Crown Jewels)](#custom-applications-crown-jewels)
    - [DevOps \& CI/CD Security](#devops--cicd-security)
    - [Infrastructure \& Platform](#infrastructure--platform)
    - [OT / IoT Security](#ot--iot-security)
  - [Retention Philosophy](#retention-philosophy)
    - [Recommended Retention Tiers](#recommended-retention-tiers)
  - [Why a Layered Approach?](#why-a-layered-approach)
    - [Recommended Reading](#recommended-reading)
  - [Tools](#tools)
  - [Assessment Checklist](#assessment-checklist)
  - [References](#references)

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
| [Retention](guidance/retention.md) | Industry best practices for log retention — MCSB, NIST, CIS, NIS2, and GDPR mapped to Sentinel storage tiers |

## Procedures

Step-by-step guides for the operational tools used alongside this maturity model:

| Procedure | Tool Type | Description |
|:----------|:----------|:------------|
| [Workspace Usage Report](procedures/workspace-usage-report.md) | Workbook | Check free data connectors, ingestion benefit coverage, connector volumes, and retention settings |
| [XDR Ingestion Calculator](procedures/xdr-ingestion-calculator.md) | Script | Estimate Defender XDR ingestion volumes before enabling the Sentinel connector |
| [XDR Data Volume Insights](procedures/xdr-data-volume-insights.md) | KQL Query | Measure Defender XDR and Entra ID table sizes, daily averages, and event counts to inform Analytics vs Data Lake tier decisions |
| [Defender AMA Coverage](procedures/defender-ama-coverage.md) | Workbook | Validate AMA deployment coverage and identify gaps in security event and syslog collection |
| [Retention Insights](procedures/retention-insights.md) | Workbook | Review table-level retention and archiving settings, evaluate Data Lake candidates, and estimate cost impact of plan changes |

## Tier Model

| Tier | Description | When to adopt |
|:-----|:------------|:--------------|
| **[Tier 1](#tier-1-connectors-bare-minimum)** | **Bare minimum** — Essential connectors that every Sentinel deployment should have. Covers identity, endpoint, email, cloud activity, and server logs. | Start here — the foundation for every organisation |
| **[Tier 2](#tier-2-connectors-extended-visibility)** | **Extended visibility** — Network security, cloud posture, data protection, multi-cloud, endpoint compliance, and threat intelligence. | Once Tier 1 is operational and the team is ready to broaden coverage |
| **[Tier 3](#tier-3-connectors-advanced--specialised)** | **Advanced / Specialised** — Full-spectrum monitoring including OT/IoT, CI/CD, SAP, databases, custom applications, and specialised integrations. | When Tier 1 & 2 are in place and specialised workloads require visibility |

## Tier 1 Connectors (Bare Minimum)

| Connector | Key Tables | Licensing Benefit | Free Ingestion |
|:-----------|:-----------|:------------------|:---------------|
| [Microsoft Defender XDR](connectors/microsoft-defender-xdr.md) | DeviceEvents, AlertInfo, EmailEvents, IdentityLogonEvents, CloudAppEvents, ... | M365 E5 / E5 Security | Yes — ingestion to **Analytics tier only** via [Microsoft Sentinel benefit for M365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer) |
| [Microsoft Entra ID](connectors/microsoft-entra-id.md) | SigninLogs, AuditLogs, AADNonInteractiveUserSignInLogs, AADRiskyUsers, AADRiskyServicePrincipals, ... | Entra ID P2 (in E5) | Yes — [free data connectors](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources) |
| [Office 365](connectors/office-365.md) | OfficeActivity | M365 E3/E5 | Yes — free data connector |
| [Azure Activity Logs](connectors/azure-activity-logs.md) | AzureActivity | Any Azure subscription | Yes — free data connector |
| [Windows Security Events](connectors/windows-security-events.md) | SecurityEvent / WindowsEvent | [Defender for Servers P2](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) | [Pooled 500 MB/day × AMA-covered servers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) via Defender for Servers P2 (SecurityEvent stream only) |
| [Syslog for Linux](connectors/syslog-linux.md) | Syslog | None | None |
| [Sentinel Health & Audit Diagnostics](connectors/sentinel-health.md) | SentinelHealth, SentinelAudit | Any Sentinel workspace | Yes — SentinelHealth is not billable |

## Tier 2 Connectors (Extended Visibility)

Tier 2 extends monitoring into network security, cloud posture, data protection, multi-cloud, endpoint compliance, and threat intelligence. These connectors are aligned with frameworks like MCSB, NIST, CIS and more. Connectors marked *conditional* only apply when the relevant product or cloud is in use. Tier 2 is aligned with the [ASD ACSC Best Practices for Event Logging and Threat Detection](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) logging priorities.

### Cloud Security Posture

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Microsoft Defender for Cloud](connectors/microsoft-defender-for-cloud.md) | SecurityAlert, SecurityRecommendation | Yes — SecurityAlert is free |

### Data Protection & Governance

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Azure Key Vault](connectors/azure-key-vault.md) | AKVAuditLogs | No |
| [Microsoft Copilot / AI Governance](connectors/copilot-ai-governance.md) | OfficeActivity (Copilot), AzureDiagnostics (OpenAI) | No |
| [Microsoft Purview (Information Protection & DLP)](connectors/microsoft-purview.md) | MicrosoftPurviewInformationProtection | No |

### Detection Enrichment

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Threat Intelligence Platforms](connectors/threat-intelligence.md) | ThreatIntelligenceIndicator | Yes — free data source |

### Endpoint Compliance

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Microsoft Intune (Endpoint Management)](connectors/microsoft-intune.md) | IntuneAuditLogs, IntuneOperationalLogs, IntuneDevices | Partial — audit/operational logs free |

### Identity & Access (Extended)

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| Third-Party Identity (Okta, CyberArk, Ping Identity, BeyondTrust) | Vendor-specific tables via API or CEF/Syslog | No — *conditional* |

### Multi-Cloud

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Amazon Web Services (AWS)](connectors/amazon-web-services.md) | AWSCloudTrail, AWSGuardDuty, AWSVPCFlow | No |
| [Google Cloud Platform (GCP)](connectors/google-cloud-platform.md) | GCPAuditLogs | No |

### Network Visibility

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Azure Firewall](connectors/azure-firewall.md) | AZFWNetworkRule, AZFWApplicationRule, AZFWDnsQuery, AZFWThreatIntel | No |
| [Azure WAF (Application Gateway / Front Door)](connectors/azure-waf.md) | ApplicationGatewayFirewallLog, FrontDoorWebApplicationFirewallLog | No |
| [DNS Security Logs](connectors/dns-security-logs.md) | DnsEvents, DnsInventory | No |
| [Microsoft Global Secure Access](connectors/global-secure-access.md) | NetworkAccessTraffic | No |
| [VNet Flow Logs & Traffic Analytics](connectors/vnet-flow-logs.md) | NTANetAnalytics, NTAIpDetails | No |
| [Third-Party Network & Proxy Appliances (CEF/Syslog)](connectors/third-party-network-appliances.md) | CommonSecurityLog | No — *conditional* |

## Tier 3 Connectors (Advanced / Specialised)

Tier 3 provides full-spectrum monitoring for mature organisations that have completed Tier 1 and Tier 2. These connectors cover OT/IoT, DevOps supply chain, databases, custom business applications, and advanced infrastructure telemetry.

### Application & Workload Security

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [IIS / Web Server Logs](connectors/iis-web-server-logs.md) | W3CIISLog | No |
| [Microsoft Defender for Cloud Apps (Standalone)](connectors/microsoft-defender-cloud-apps.md) | McasShadowItReporting | No |
| [SAP](connectors/sap.md) | SAPAuditLog, ABAPAuditLog, SAPChangeDocuments | No — separately licensed |
| [SQL / Database Audit Logs](connectors/sql-database-audit.md) | SQLSecurityAuditEvents, CDBDataPlaneRequests | No |
| Third-Party Applications (ServiceNow, Salesforce, Workday) | Vendor-specific tables via API or CEF/Syslog | No — *conditional* |

### Collaboration & Communication

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| Third-Party Collaboration (Slack, Zoom, Cisco Webex) | Vendor-specific tables via API or webhook | No — *conditional* |

### Custom Applications (Crown Jewels)

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Custom Applications](connectors/custom-applications.md) | {AppName}_CL (custom tables) | No |

### DevOps & CI/CD Security

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Azure DevOps](connectors/azure-devops.md) | AzureDevOpsAuditing | No |
| [GitHub Enterprise](connectors/github-enterprise.md) | GitHubAuditLogPolling | No |
| Third-Party DevOps (GitLab, Jenkins, Bitbucket) | Vendor-specific tables via API or webhook | No — *conditional* |

### Infrastructure & Platform

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Azure Kubernetes Service (AKS) Audit](connectors/azure-kubernetes-service.md) | AKSAudit, AKSAuditAdmin | No |
| [Azure Storage Analytics](connectors/azure-storage-analytics.md) | StorageBlobLogs, StorageFileLogs | No |
| [Microsoft Defender for DNS (Azure DNS)](connectors/microsoft-defender-for-dns.md) | AzureDiagnostics (DNS), DNSQueryLogs | No |
| [Windows Forwarded Events (Advanced)](connectors/windows-forwarded-events.md) | WindowsEvent (PowerShell, Sysmon, AppLocker) | No |

### OT / IoT Security

| Connector | Key Tables | Free Ingestion |
|:----------|:-----------|:---------------|
| [Microsoft Defender for IoT](connectors/microsoft-defender-for-iot.md) | SecurityAlert (IoT) | Yes — SecurityAlert is free |
| Third-Party OT / IoT (Claroty, Nozomi Networks, Armis) | Vendor-specific tables via CEF/Syslog | No — *conditional* |

## Retention Philosophy

For the full retention framework analysis including specific requirements from MCSB, NIST, CIS, NIS2, and GDPR, see [Retention](guidance/retention.md). For investigation readiness considerations, see [Forensic Readiness](guidance/forensic-readiness.md). Our retention recommendations are informed by:

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

For the full rationale, see [Layered Detection Approach](guidance/layered-detection.md). EDR solutions like Microsoft Defender for Endpoint are essential but **not sufficient on their own**. A layered approach combining EDR with native OS logging (Windows Security Events, Syslog) provides defence in depth:

- **EDR can be bypassed** — attackers continuously develop techniques to evade endpoint detection. Native OS logs provide an independent audit trail that persists even if EDR is tampered with.
- **Forensic readiness** — native logs provide authoritative evidence admissible in investigations, complementing EDR telemetry.
- **Correlation across data sources** — combining identity, endpoint, email, and cloud activity logs enables detection of multi-stage attacks that no single source can catch alone.

### Recommended Reading

| Title | Description | Link |
|:------|:------------|:-----|
| The Evolution of EDR Bypasses | Historical timeline showing how EDR bypass techniques evolve, reinforcing why native logs are essential as a fallback | [CovertSwarm](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) |
| MDE Telemetry Unreliability and Log Augmentation | In-depth analysis of MDE telemetry gaps, capping behaviour, and why native Windows logs are essential for complete forensic coverage | [FalconForce](https://falconforce.nl/microsoft-defender-for-endpoint-internals-0x03-mde-telemetry-unreliability-and-log-augmentation/) |
| Cloud Forensics: Forensic Readiness and IR in Azure Virtual Desktop | Demonstrates a layered approach combining EDR and native logging for incident response in cloud environments | [Microsoft Community Hub](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/cloud-forensics-forensic-readiness-and-incident-response-in-azure-virtual-desktop/3835484) |
| Windows Event Log Analysis: Techniques for Every SOC Analyst | Practical guide on using Windows Security Events for detection, showing their value alongside EDR | [CyberDefenders Blog](https://blog.cyberdefenders.org/2024/02/windows-event-log-analysis-techniques.html) |
| Sentinel Data Connectors: What Actually Matters | Practical guidance on which Sentinel data connectors to prioritize | [IT Professor](https://www.itprofessor.cloud/sentinel-data-connectors-what-actually-matters/) |

---

## Tools

To help identify retention settings, monitor ingestion volumes, estimate costs, and validate data connector coverage. Each tool has a step-by-step walkthrough in the [Procedures](procedures/README.md) section.

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor ingestion volumes per table, identify cost optimisation opportunities, and validate data connector health across all connectors | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) (search "Workspace Usage") | [Walkthrough](procedures/workspace-usage-report.md) |
| **Defender AMA Coverage** | Workbook | Validate Defender for Endpoint and AMA agent deployment coverage, identify gaps in security event and syslog collection | [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) | [Walkthrough](procedures/defender-ama-coverage.md) |
| **XDR tables to Sentinel ingestion calculator** | Script | Estimate Defender XDR ingestion volumes from the Advanced Hunting API before enabling the Sentinel connector | [GitHub — mathijsvermaat/DefenderIngestToSentinel](https://github.com/mathijsvermaat/DefenderIngestToSentinel) | [Walkthrough](procedures/xdr-ingestion-calculator.md) |
| **XDR Data Volume Insights** | KQL Query | Measure Defender XDR and Entra ID table sizes, daily averages, and event counts to inform Analytics vs Data Lake tier decisions | Run in Sentinel Logs | [Walkthrough](procedures/xdr-data-volume-insights.md) |
| **Retention Insights** | Workbook | Review table-level retention and archiving settings, evaluate Data Lake candidates, and estimate cost impact of plan changes | [Github — Azure-Sentinel/Workbooks](https://github.com/Azure/Azure-Sentinel/blob/master/Workbooks/ArchivingBasicLogsRetention.json) | [Walkthrough](procedures/retention-insights.md) |

---

## Assessment Checklist

Use the interactive [Sentinel Maturity Assessment Checklist](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html) to track progress during a connector onboarding engagement. The checklist covers every Tier 1 connector with per-table checks, retention validation, and configuration items. Each section has a comment field for rationale and notes.

Features: save/load progress (JSON), export to PDF, export to Excel.

---

## References

- [Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)
- [ASD ACSC Best Practices for Event Logging and Threat Detection](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection)
- [Microsoft Sentinel pricing and free data sources](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources)
- [Microsoft Sentinel benefit for Microsoft 365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer)
- [Defender for Cloud data ingestion benefit](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit)
- [NIST SP 800-92 — Guide to Computer Security Log Management](https://csrc.nist.gov/pubs/sp/800/92/final)
- [NIS2 Directive](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats)
- [Sentinel Ninja training](https://github.com/oshezaf/sentinelninja)

*Last updated: April 2026*
