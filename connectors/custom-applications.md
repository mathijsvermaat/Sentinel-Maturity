# Custom Applications (Crown Jewels)

**Tier:** 3 (Advanced) · **Connector type:** Custom (DCR / Log Analytics API / Logstash) · **Free ingestion:** No

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Important Considerations](#important-considerations)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)

---

## Overview

Custom application logging brings your organisation's **business-critical applications** — crown jewels — into Microsoft Sentinel. These are the line-of-business (LOB) applications, internal portals, financial systems, and proprietary platforms that contain your most sensitive data and are unique to your organisation.

No two organisations have the same crown jewels. This connector category covers any custom or third-party application that isn't served by a standard Sentinel connector. The ingestion method varies: **Data Collection Rules (DCR)** for structured logs, the **Logs Ingestion API** for application-emitted events, **Logstash** for legacy systems, or **Azure Event Hub** for high-volume streaming.

The security value is unique: only your custom applications know what "normal" business activity looks like. Detecting anomalies in financial transaction patterns, unauthorized access to patient records, or unusual export activity from a procurement system requires the application's own logs.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Azure subscription** | Log Analytics workspace with custom table ingestion via DCR or API |
| **Microsoft Sentinel** | Analytics rules, hunting queries, and automation on custom log data |

> [!NOTE]
> Custom application logs are ingested into **custom tables** (ending in `_CL`) in Log Analytics. Cost depends entirely on the volume your applications generate. Use DCR transformations to filter, parse, and reduce volume at ingestion time.

---

## Tables and Rationale

Custom application tables are defined per-application. Below are common patterns:

| Table Pattern | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **{AppName}AuditLog_CL** | Application audit trail — user actions, CRUD operations, authorization decisions | Analytics: 90d / Lake: 365d | Business-specific audit trail that no standard connector captures — the only source for application-level threat detection | Proves exactly what actions were taken within the application — essential for business impact assessment | Unauthorized access to restricted records (T1078) |
| **{AppName}SecurityEvents_CL** | Application security events — failed logins, permission changes, suspicious activity flags | Analytics: 90d / Lake: 365d | Application-level security signals — complements identity logs with app-specific authentication context | Identifies application-specific attack patterns that identity logs alone cannot surface | Brute-force against application login endpoint (T1110) |
| **{AppName}Transactions_CL** | Business transactions — financial postings, order processing, data exports | Analytics: 90d / Lake: 180d | Business process monitoring — detects fraud, unauthorized transactions, and data exfiltration through business channels | Reconstructs the business impact of a breach — which transactions were manipulated or exfiltrated | Anomalous bulk data export from financial system (T1567) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Unusual login hours for business application | {AppName}AuditLog_CL | T1078 | User accessing crown jewel application outside normal business hours — correlated with role expectations |
| Mass record access or export | {AppName}AuditLog_CL | T1530, T1567 | Single user accessing or exporting abnormally large volumes of records within a short timeframe |
| Privilege escalation within application | {AppName}SecurityEvents_CL | T1098 | User role or permission changed within the application to gain elevated access |
| Failed authentication spike | {AppName}SecurityEvents_CL | T1110 | Significant increase in failed login attempts against the application |
| Business logic anomaly | {AppName}Transactions_CL | T1565 | Transaction patterns deviating from established baselines — potential fraud or data manipulation |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-3** Enable logging for security investigation | Crown jewel application logs provide the most business-relevant investigation data |
| **DP-2** Monitor anomalies and threats targeting sensitive data | Direct monitoring of the applications that process and store the organisation's most sensitive data |
| **IR-4** Detection and analysis — incident response | Application logs provide the business context needed to assess the true impact of an incident |

---

## Important Considerations

- **Data Classification Rules (DCR):** Define the schema for your custom tables carefully. Use DCR transformations to parse, filter, and enrich data at ingestion time — this is more cost-effective than transforming in analytics rules
- **Custom table schema:** Plan your table schema upfront — column names, data types, and mandatory fields. Changes to schema after deployment require careful migration
- **Volume estimation:** Work with application teams to estimate log volume before enabling ingestion — custom applications can generate significant data
- **Sensitive data handling:** Application logs may contain PII, financial data, or credentials. Use DCR transformations to mask or remove sensitive fields before ingestion
- **Application team coordination:** Requires coordination with development teams to implement logging endpoints or configure log forwarding

---

## Notes

- Start with your highest-value applications — identify your "crown jewels" during a business impact assessment and prioritise those for logging
- Common crown jewels include: ERP/financial systems, HR platforms, healthcare/patient systems, intellectual property repositories, customer data platforms
- Consider using the Logs Ingestion API for modern applications and Logstash for legacy systems that cannot be modified
- Custom applications are inherently unique — build custom analytics rules and workbooks tailored to each application's business logic

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify custom table volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Logs Ingestion API overview | [Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-ingestion-api-overview) |
| Data Collection Rules overview | [Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview) |
| Create custom tables in Log Analytics | [Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/create-custom-table) |
| DCR transformations | [Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-transformations) |
| Logstash output plugin for Sentinel | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/connect-logstash-data-connection-rules) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
