# Retention

## Contents

- [Retention](#retention)
  - [Contents](#contents)
  - [Overview](#overview)
  - [Why 365 Days Should Be the Default](#why-365-days-should-be-the-default)
  - [Framework Retention Requirements](#framework-retention-requirements)
    - [Microsoft Cloud Security Benchmark (MCSB)](#microsoft-cloud-security-benchmark-mcsb)
    - [NIST SP 800-92](#nist-sp-800-92)
    - [CIS Controls v8](#cis-controls-v8)
    - [NIS2 Directive](#nis2-directive)
    - [GDPR](#gdpr)
  - [Combined Requirements Summary](#combined-requirements-summary)
  - [Applying Retention in Microsoft Sentinel](#applying-retention-in-microsoft-sentinel)
    - [Sentinel Storage Tiers](#sentinel-storage-tiers)
    - [Mapping Frameworks to Sentinel Retention](#mapping-frameworks-to-sentinel-retention)
  - [When to Go Beyond 365 Days](#when-to-go-beyond-365-days)
  - [Operationalising Retention](#operationalising-retention)
  - [References](#references)

---

## Overview

Retention — how long security log data is stored and available for analysis — is one of the most important design decisions in a SIEM deployment. Too short, and incident investigators lose critical evidence. Too long without the right tier strategy, and costs spiral.

This page establishes retention guidance grounded in industry frameworks and best practices. The core recommendation is:

> **Set a default retention of 365 days for all security-relevant tables, then adjust upward per table based on the regulatory framework(s) that apply to your organisation.**

This aligns with the consensus across MCSB, NIST, CIS, NIS2, and GDPR — all of which point toward at least one year of security log availability.

---

## Why 365 Days Should Be the Default

Several converging factors make 365-day retention the practical baseline:

1. **Dwell time** — while median dwell time for ransomware has dropped (roughly 10 days in recent reports), advanced persistent threats (APTs) routinely maintain access for months before detection. A 90-day window is often insufficient to reconstruct the full attack timeline.

2. **Framework convergence** — as detailed [below](#framework-retention-requirements), MCSB, NIST, CIS, NIS2, and GDPR all require or strongly recommend that security logs be available for at least one year.

3. **Investigation reality** — many investigations start with a recent alert but trace activity back months. Identity compromise, supply chain attacks, and insider threats all have extended timelines.

4. **Cost efficiency** — Microsoft Sentinel's Data Lake tier provides long-term retention at a fraction of the Analytics tier cost ($0.026/GB/month vs. full ingestion pricing), making 365-day retention financially viable even at scale.

5. **Insurance and legal requirements** — cyber insurance providers increasingly require evidence of sufficient log retention. Organisations that cannot provide historical logs during a claim may face coverage disputes.

---

## Framework Retention Requirements

### Microsoft Cloud Security Benchmark (MCSB)

The [MCSB](https://learn.microsoft.com/en-us/security/benchmark/azure/overview) is Microsoft's primary cloud security framework and the basis for the default Defender for Cloud recommendations.

**Key control:**

| Control | Title | Retention Guidance |
|:--------|:------|:-------------------|
| **LT-6** | Configure log storage retention | *"Balance forensic preservation needs with storage costs by implementing tiered retention strategies aligned to regulatory mandates and investigation timelines."* |

LT-6.1 is specific about retention durations:

| Tier | MCSB Guidance |
|:-----|:--------------|
| **Short-to-medium term** (Log Analytics workspace) | *"log retention up to 1–2 years for active investigation, threat hunting, and operational analytics with KQL query capabilities"* |
| **Long-term archival** (Azure Storage / Data Explorer / Data Lake) | *"long-term and archival storage beyond 1–2 years to meet compliance requirements (PCI-DSS, SEC 17a-4, HIPAA)"* |

MCSB therefore recommends **1–2 years of queryable retention** as the operational baseline and longer archival for regulated workloads. The implementation example included with LT-6 reinforces this with a 1-year default and table-level overrides up to 2 years for identity logs.

> [!NOTE]
> For the full MCSB control mapping per connector, see the individual [connector pages](../connectors/README.md).

### NIST SP 800-92

[NIST SP 800-92 — Guide to Computer Security Log Management](https://csrc.nist.gov/pubs/sp/800/92/final) is the primary US government standard for security log management.

**Key recommendations:**

| Area | Guidance |
|:-----|:---------|
| **Retention period** | Organisations should retain logs for a period determined by their incident response, compliance, and operational requirements. NIST recommends that organisations keep logs for **at least one year**, with 90 days of readily accessible (online) data. |
| **Rotation and archival** | Old logs should be archived to cheaper storage, not deleted. This aligns directly with the Sentinel Analytics → Data Lake tier model. |
| **Legal hold** | Organisations must be able to preserve specific logs indefinitely when required for legal or investigative purposes. |

NIST 800-92 also references [NIST SP 800-61 (Incident Handling)](https://csrc.nist.gov/pubs/sp/800/61/r2/final), which reinforces that investigation can require months of historical data.

### CIS Controls v8

The [CIS Controls v8](https://www.cisecurity.org/controls) provide a prioritised set of security actions. Controls relevant to retention:

| Control | Title | Retention Guidance |
|:--------|:------|:-------------------|
| **8.1** | Establish and Maintain an Audit Log Management Process | *Ensure that the retention policy includes minimum retention duration, storage requirements, and handling procedures.* |
| **8.3** | Ensure Adequate Audit Log Storage | *Ensure that logging destinations maintain adequate storage for all audit logs, for at minimum the last 90 days of logs retained online and one year archived.* |
| **8.10** | Retain Audit Logs | *Retain audit logs across enterprise assets for a minimum of 90 days* (Implementation Group 1). Implementation Groups 2 and 3 recommend longer retention aligned with compliance requirements. |

CIS explicitly states **90 days online, 1 year total** as the minimum standard for moderately mature organisations — aligning precisely with the Sentinel Analytics (90d) + Data Lake (365d) model.

### NIS2 Directive

The [NIS2 Directive](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats) is the EU's updated cybersecurity regulation, applicable across a wide range of sectors.

**Key implications for retention:**

| Requirement | Retention Implication |
|:------------|:----------------------|
| **Incident notification within 24–72 hours** | Logs must be immediately accessible for rapid triage — drives the need for interactive retention (Analytics tier) |
| **Risk management measures** | Article 21 requires appropriate technical measures to manage risk, which includes maintaining sufficient log data to detect and investigate incidents |
| **Accountability** | Management is directly accountable for security measures — inability to investigate an incident due to insufficient retention is a governance failure |
| **Post-incident analysis** | NIS2 requires organisations to learn from incidents and improve — this is only possible with sufficient historical data |

NIS2 does not prescribe a specific log retention period, but **most national implementations and industry interpretations recommend at least one year** for security-relevant logs, with longer periods for critical infrastructure operators.

> [!IMPORTANT]
> Organisations classified as "essential entities" under NIS2 should consider retention periods beyond 365 days, particularly for identity and authentication logs.

### GDPR

The [General Data Protection Regulation (GDPR)](https://gdpr-info.eu/) applies to all organisations processing personal data of EU/EEA residents.

**Key retention considerations:**

| Principle | Implication |
|:----------|:------------|
| **Data minimisation (Art. 5(1)(c))** | Only collect and retain data that is necessary for the stated purpose. Security logging is a legitimate purpose under Article 6(1)(f) (legitimate interests). |
| **Storage limitation (Art. 5(1)(e))** | Personal data should not be retained longer than necessary. For security logs, the "necessary" period is determined by the investigation and compliance requirements — not by arbitrary time limits. |
| **Breach notification (Art. 33/34)** | Organisations must notify the supervisory authority within 72 hours and affected individuals "without undue delay." This requires immediate access to log data to determine breach scope. |
| **Accountability (Art. 5(2))** | Organisations must demonstrate compliance. Audit logs are the primary evidence that access controls, consent mechanisms, and security measures are functioning correctly. |

GDPR requires a **balancing act**: retain security logs long enough to investigate incidents and demonstrate compliance, but document the justification for the retention period. In practice, a well-documented 365-day retention policy for security logs is widely accepted as proportionate.

> [!NOTE]
> GDPR does not mandate a specific retention period for security logs. The retention period should be documented in your data processing records (Art. 30) with a clear justification. "Required for security incident investigation and regulatory compliance" is a defensible rationale for 365-day retention.

---

## Combined Requirements Summary

| Framework | Minimum Online (Interactive) | Minimum Total (Archived) | Notes |
|:----------|:----------------------------|:------------------------|:------|
| **MCSB (LT-6)** | Up to 1–2 years in Log Analytics | **1–2 years** queryable; archival beyond 1–2 years for regulated workloads | LT-6.1 explicitly recommends 1–2 years in Log Analytics workspace |
| **NIST 800-92** | 90 days | **1 year** | Explicitly recommends 90 days online + archival; legal hold may extend further |
| **CIS Controls v8** | 90 days (Control 8.10) | **1 year** (Control 8.3) | 90 days online, 1 year total — matches Sentinel's tier model exactly |
| **NIS2** | Sufficient for 24–72h incident notification | **1 year+** (industry consensus) | No explicit number; national implementations trend toward 1 year minimum |
| **GDPR** | Sufficient for breach notification (72h) | **Proportionate** to purpose | Document the justification; 365 days widely accepted for security logs |

**The consensus across all five frameworks: 90 days interactive, 365 days total is the defensible baseline.**

---

## Applying Retention in Microsoft Sentinel

### Sentinel Storage Tiers

Microsoft Sentinel provides a tiered storage model that maps directly to the framework requirements:

| Tier | Duration | Purpose | Cost Profile |
|:-----|:---------|:--------|:-------------|
| **Analytics** | 90 days (free with Sentinel) | Real-time detection, hunting, and active incident response | Included in ingestion pricing |
| **Data Lake** | Up to 12 years | Long-term retention, historical investigation, compliance | $0.026/GB/month (significantly cheaper than Analytics ingestion) |

The 90-day Analytics tier satisfies the "online / interactive" requirements from NIST, CIS, and the real-time access needs of NIS2 and GDPR breach notification. The Data Lake tier provides cost-effective long-term storage for the 365-day (or longer) archival requirement.

### Mapping Frameworks to Sentinel Retention

| Framework Requirement | Sentinel Implementation |
|:----------------------|:------------------------|
| 90 days interactive access | Analytics tier (included free with Sentinel) |
| 365 days total retention | Analytics 90d + Data Lake 275d = 365d total |
| Legal hold / extended compliance | Extend Data Lake retention per table (up to 12 years) |
| Documented retention policy | Configure per-table via **Settings > Tables** in Log Analytics workspace |

> [!TIP]
> Use the [Retention Insights workbook](../procedures/retention-insights.md) to review your current per-table retention settings and identify tables that still have default retention with no archiving configured.

---

## When to Go Beyond 365 Days

While 365 days is the recommended default, certain scenarios require longer retention:

| Scenario | Recommended Retention | Justification |
|:---------|:---------------------|:--------------|
| **Critical infrastructure (NIS2 essential entities)** | 2–3 years | Higher threat profile; APT investigations may span multiple years |
| **Financial services (DORA, SOX)** | 5–7 years | DORA requires ICT-related incident data retention; SOX audit trails typically require 7 years |
| **Healthcare (HIPAA)** | 6 years | HIPAA requires audit controls for ePHI access to be retained for 6 years |
| **Government / Defence** | 3–7 years | Classified or sensitive environment requirements; national security mandates |
| **Active legal proceedings** | Indefinite (legal hold) | Preserve all relevant logs until the matter is resolved |
| **Cyber insurance claims** | 2+ years | Insurers may request historical evidence for up to 2 years prior to a claim |

> [!IMPORTANT]
> When extending retention beyond 365 days, focus on the **highest-value tables** rather than applying blanket extensions. Identity logs (`SigninLogs`, `AuditLogs`, `IdentityLogonEvents`) and privileged activity logs are typically the best candidates for extended retention.

---

## Operationalising Retention

Setting retention is not a one-time activity. To maintain compliance and cost control:

1. **Document the retention policy** — record which retention period applies to each table and the regulatory justification. Include this in your data processing records (GDPR Art. 30) and security operations documentation.

2. **Review retention quarterly** — use the [Retention Insights workbook](../procedures/retention-insights.md) to verify that all tables have the correct retention configured and that no tables have reverted to defaults.

3. **Align with connector onboarding** — when enabling a new connector, immediately configure retention on the new tables. Retention is set at the table level, not the connector level — new tables default to the workspace default, which may not be sufficient.

4. **Cost-model before extending** — before increasing retention beyond 365 days, use the [Retention Insights Cost Estimation tab](../procedures/retention-insights.md#cost-estimation-tab) to model the financial impact with your actual ingestion volumes.

5. **Communicate to stakeholders** — retention decisions have budget implications. Ensure that security leadership, compliance, and finance teams are aligned on the retention strategy and its costs.

---

## References

- [Microsoft Cloud Security Benchmark (MCSB) — LT-6: Configure log storage retention](https://learn.microsoft.com/en-us/security/benchmark/azure/mcsb-v2-logging-threat-detection#lt-6)
- [NIST SP 800-92 — Guide to Computer Security Log Management](https://csrc.nist.gov/pubs/sp/800/92/final)
- [NIST SP 800-61 Rev. 2 — Computer Security Incident Handling Guide](https://csrc.nist.gov/pubs/sp/800/61/r2/final)
- [CIS Controls v8](https://www.cisecurity.org/controls)
- [NIS2 Directive — European Parliament](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats)
- [GDPR — General Data Protection Regulation](https://gdpr-info.eu/)
- [Microsoft Sentinel Data Lake overview](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-lake-overview)
- [Configure data retention and archive policies in Azure Monitor Logs](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-archive)

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
