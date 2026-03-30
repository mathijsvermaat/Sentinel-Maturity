# Sentinel Health & Audit Diagnostics

**Tier:** 1 (Bare Minimum) · **Connector type:** Built-in diagnostic setting · **Free ingestion:** Yes (SentinelHealth is not billable)

---

## Contents

- [Sentinel Health \& Audit Diagnostics](#sentinel-health--audit-diagnostics)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
    - [Health and Audit Tables](#health-and-audit-tables)
  - [Example Detections](#example-detections)
    - [Health Monitoring](#health-monitoring)
    - [Audit Trail](#audit-trail)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Enabling Health Monitoring](#enabling-health-monitoring)
  - [Notes](#notes)
  - [Tools](#tools)
  - [References](#references)
    - [Official Documentation](#official-documentation)
    - [Community \& Third-Party Resources](#community--third-party-resources)

---

## Overview

Sentinel Health & Audit Diagnostics is a **built-in monitoring feature** — not a traditional data connector — that provides visibility into the operational health and change audit trail of your Microsoft Sentinel workspace. When enabled, Sentinel writes health and audit events into dedicated tables (`SentinelHealth` and `SentinelAudit`) that let you detect broken data connectors, failed analytics rules, automation failures, and unauthorized configuration changes.

This is a **Tier 1 essential** because a SIEM that silently stops ingesting data is worse than having no SIEM at all. Without health monitoring, a misconfigured data connector or a broken analytics rule can go unnoticed for days or weeks — exactly the window an attacker needs.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Microsoft Sentinel workspace** | SentinelHealth table (data connectors, analytics rules, automation rules, playbooks) |
| **Any Microsoft Sentinel workspace** | SentinelAudit table (analytics rule change tracking) |

> [!NOTE]
> The **SentinelHealth** table is **not billable** — there are no charges for ingesting health data. The **SentinelAudit** table is billable, but audit volume is typically very low (proportional to the number of rule changes made by analysts and automation).

> [!TIP]
> Health monitoring is not enabled by default. You must explicitly turn it on in Sentinel Settings → Auditing and health monitoring, or configure diagnostic settings for your workspace.

---

## Tables and Rationale

### Health and Audit Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SentinelHealth** | Operational health events for data connectors, analytics rules, automation rules, and playbooks — records success/failure status, data fetch results, and execution outcomes | Analytics: 90d / Lake: 365d | **Core operational visibility table.** Detects silent failures in data ingestion, broken analytics rules, and automation issues before they create blind spots. MCSB LT-1 (Enable threat detection), LT-3 (Enable logging for security investigation). A SIEM that silently stops working is a critical security risk. | Proves when a data connector started failing, how long the gap lasted, and when it recovered. Answers "were we actually collecting data during the incident?" — critical for forensic completeness assessments. | Data connector failure persisting > 1 hour (ingestion gap) |
| **SentinelAudit** | Audit trail of changes to analytics rules — who changed what, when, and from where | Analytics: 90d / Lake: 365d | **Configuration integrity table.** Detects unauthorized or accidental changes to detection rules that could create coverage gaps. MCSB PA-1 (Protect privileged users), LT-4 (Enable network logging). Change tracking for SIEM rules is a requirement in mature SOC environments and compliance frameworks. | Complete change audit trail — proves exactly who modified an analytics rule, what was changed, and when. Answers "did someone disable our detection rule before the attack?" | Analytics rule disabled by unexpected user (T1562.001) |

---

## Example Detections

### Health Monitoring

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Data connector ingestion failure | SentinelHealth | T1562.002 | Data connector reports persistent failure status — indicates data is no longer being ingested into the workspace |
| Analytics rule execution failure | SentinelHealth | — | Scheduled or NRT analytics rule fails to execute, potentially leaving detection gaps |
| Automation rule failure | SentinelHealth | — | Automation rule or playbook fails to execute, indicating broken incident response workflows |
| Data connector status changed to failure | SentinelHealth | T1562.002 | Connector transitions from success to failure state — immediate detection of new ingestion problems |
| Connector recovered from failure | SentinelHealth | — | Connector transitions from failure back to success — useful for tracking resolution times and SLA compliance |

### Audit Trail

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Analytics rule disabled | SentinelAudit | T1562.001 | Detection rule was disabled — could indicate an attacker or insider disabling detections before malicious activity |
| Analytics rule modified by unexpected user | SentinelAudit | T1562.001 | Rule configuration changed by a user who is not part of the expected SOC engineering team |
| Analytics rule query modified | SentinelAudit | T1562.001 | The KQL query in an analytics rule was changed — could weaken detection logic |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection | Health monitoring ensures detection rules and data connectors remain operational |
| **LT-3** Enable logging for security investigation | SentinelHealth provides the audit trail proving data was actually collected during an incident window |
| **LT-4** Enable network logging | SentinelAudit tracks changes to the SIEM configuration itself |
| **PA-1** Protect privileged users | SentinelAudit detects unauthorized changes to analytics rules by tracking who made modifications |
| **IR-4** Detection and analysis | Health data proves whether detections were active during an incident — essential for root cause analysis |
| **IR-5** Incident response | Automation health monitoring confirms playbooks and automation rules executed correctly during incident response |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-137 (continuous monitoring), ISO 27001 A.12.4 (logging and monitoring), and NIS2 Article 21 (security monitoring and incident detection capabilities).

---

## Enabling Health Monitoring

Health monitoring is not a traditional data connector — it is enabled through Sentinel's diagnostic settings:

1. Navigate to **Microsoft Sentinel** → **Settings** → **Settings** tab
2. Select **Auditing and health monitoring**
3. Click **Enable** to turn on monitoring for all resource types (data connectors, analytics rules, automation rules, playbooks)
4. Alternatively, select **Configure diagnostic settings** for granular control over which resource types to monitor and where to send the data

The `SentinelHealth` and `SentinelAudit` tables are automatically created after the first health or audit event is generated.

> [!TIP]
> After enabling, verify data is flowing by running: `_SentinelHealth() | take 20` and `_SentinelAudit() | take 20` in the Logs blade. Use the pre-built functions (`_SentinelHealth()` and `_SentinelAudit()`) rather than querying the tables directly — they ensure backward compatibility if the schema changes.

---

## Notes

- **Always enable health monitoring on every workspace** — this is a zero-cost, high-value feature for SentinelHealth data
- SentinelHealth currently supports health events for: **data connectors**, **analytics rules**, **automation rules**, and **playbooks**
- SentinelAudit currently supports audit events for **analytics rules** only
- The `SentinelHealth` table is **not billable** — enable it without cost concerns
- The `SentinelAudit` table **is billable**, but volume is typically minimal (only creates records when rule changes occur)
- Consider creating **Azure Monitor alert rules** on the SentinelHealth table for push notifications on connector failures — this provides alerting even if Sentinel analytics rules themselves are failing
- For a complete automation health picture, also enable Azure Logic Apps diagnostics to capture playbook execution details in `AzureDiagnostics`

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Sentinel Health** | Workbook | Visualise data connector health status, analytics rule execution health, and automation health — provides a single-pane dashboard for operational monitoring of your Sentinel workspace | [GitHub — Azure-Sentinel/Workbooks](https://github.com/Azure/Azure-Sentinel/blob/master/Workbooks/SentinelHealth.json) | — |
| **Data collection health monitoring** | Workbook | Monitor data ingestion volumes, detect anomalies, and track agent health — complements SentinelHealth with ingestion-level visibility | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/monitor-data-connector-health#use-the-health-monitoring-workbook) (search "Data collection health monitoring") | — |
| **Workspace Usage Report** | Workbook | Monitor ingestion volumes per table and validate data connector coverage | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Auditing and health monitoring in Microsoft Sentinel | Overview of the health monitoring and auditing capabilities | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/health-audit) |
| Turn on auditing and health monitoring for Microsoft Sentinel | Step-by-step guide to enable health monitoring via Settings or diagnostic settings | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/enable-monitoring) |
| Monitor the health of your data connectors | Detailed guide on using the SentinelHealth table and workbooks for connector monitoring | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/monitor-data-connector-health) |
| SentinelHealth and SentinelAudit table reference | Schema reference for all columns in the health and audit tables | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/health-table-reference) |
| Monitor the health and integrity of your analytics rules | Using health data to track analytics rule execution and detect failures | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/monitor-analytics-rule-integrity) |
| Monitor the health of your automation rules and playbooks | Health monitoring for automation rules and Logic Apps playbook execution | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/monitor-automation-health) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — SentinelHealth table | Ofer Shezaf (Microsoft) | Auto-generated reference: schema, solutions, and content items using the SentinelHealth table | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/tables/sentinelhealth.md) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
