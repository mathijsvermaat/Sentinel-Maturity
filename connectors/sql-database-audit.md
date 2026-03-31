# SQL / Database Audit Logs

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party (Diagnostic Settings) · **Free ingestion:** No

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

SQL and database audit logs capture **data-plane operations** on Azure SQL Database, SQL Managed Instance, Azure Cosmos DB, and other Azure database services. While Azure Activity Logs (Tier 1) capture management-plane operations (creating/deleting databases), database audit logs capture *who queried what data, when, and from where*.

For organisations with databases containing sensitive data (PII, financial records, healthcare data), these logs are critical for detecting data exfiltration, unauthorized queries, and SQL injection that successfully bypasses application-layer defences. Database audit logs answer the question: *"Did the attacker access our data?"*

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Azure SQL Database (any tier)** | SQL Auditing — captures all database operations and events |
| **Defender for SQL** | Advanced Threat Protection — adds active threat detection alerts for SQL injection, anomalous access patterns, and brute-force attacks |

> [!NOTE]
> SQL Auditing is a built-in feature of Azure SQL — no additional license required to enable. **Defender for SQL** adds threat detection alerts that flow through `SecurityAlert` (covered by the Tier 2 Defender for Cloud connector). The audit logs themselves require Sentinel ingestion.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SQLSecurityAuditEvents** | Azure SQL and Managed Instance audit records — queries, logins, permission changes, schema modifications | Analytics: 90d / Lake: 365d | Primary data-plane audit trail for SQL databases — captures all DML/DDL operations and authentication events | During breach investigation, proves exactly which queries were executed, by whom, and when — essential for determining data exposure scope | Bulk SELECT on sensitive table from unusual IP (T1213) |
| **AzureDiagnostics** (SQL) | Legacy diagnostic format for SQL — includes errors, timeouts, and deadlocks alongside audit data | Analytics: 90d / Lake: 365d | Supplementary operational diagnostics — useful when resource-specific mode is not configured | Provides additional context about database health and errors during an attack | Excessive login failures from single source (T1110) |
| **CDBDataPlaneRequests** (Cosmos DB) | Cosmos DB data-plane operations — reads, writes, queries, stored procedure executions | Analytics: 90d / Lake: 365d | NoSQL data access audit trail — captures operations against Cosmos DB containers and items | Proves which Cosmos DB items were accessed and what operations were performed | Anomalous bulk read operations on Cosmos DB (T1530) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Bulk data retrieval from sensitive tables | SQLSecurityAuditEvents | T1213 | Large SELECT queries against tables containing PII, financial data, or credentials |
| SQL login from unusual IP | SQLSecurityAuditEvents | T1078 | Database authentication from an IP address not in the normal application/admin range |
| Schema modification — new user or permission grant | SQLSecurityAuditEvents | T1098 | `CREATE USER`, `ALTER ROLE`, or `GRANT` statements indicating persistence or privilege escalation |
| SQL injection that reached the database | SQLSecurityAuditEvents | T1190 | Query patterns containing SQL injection strings (`UNION SELECT`, `xp_cmdshell`, `EXEC`) that successfully executed |
| Database export or backup to unusual location | SQLSecurityAuditEvents | T1567 | `COPY`, `BACKUP`, or `BCP` operations targeting locations outside normal backup paths |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-3** Enable logging for security investigation | Database audit logs provide the data-plane investigation trail for database compromise scenarios |
| **DP-2** Monitor anomalies and threats targeting sensitive data | Directly monitors access to the data that needs protection — the database contents themselves |
| **DP-3** Encrypt sensitive data in transit | Audit logs record connection encryption status — detects unencrypted connections |
| **DS-6** Enforce security of workloads through development lifecycle | Detects SQL injection attacks that bypass application security — last line of defence |

---

## Important Considerations

- **Resource-specific vs AzureDiagnostics mode:** Prefer resource-specific mode (`SQLSecurityAuditEvents`) for structured, queryable data. Legacy `AzureDiagnostics` mode mixes SQL logs with other resource types
- **Volume management:** Busy OLTP databases can generate millions of audit events per day. Use server-level audit policies with selective action group filtering to control volume
- **Audit action groups:** Start with `SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP`, `FAILED_DATABASE_AUTHENTICATION_GROUP`, `BATCH_COMPLETED_GROUP`, and `DATABASE_PERMISSION_CHANGE_GROUP` — add more as needed
- **Defender for SQL:** If you have Defender for Cloud (Tier 2), SQL threat detection alerts already flow through `SecurityAlert`. The audit logs in this Tier 3 connector add the detailed query-level trail

---

## Notes

- Database audit logs are most valuable when paired with application-level logging — correlate web requests (IIS logs, Tier 3) with the resulting SQL queries
- For Cosmos DB, enable diagnostic settings with `DataPlaneRequests` category — this captures all read/write operations
- Consider sensitivity-based filtering: audit all operations on tables classified as "highly confidential" while sampling lower-sensitivity tables

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify SQL audit log volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Azure SQL auditing overview | [Learn](https://learn.microsoft.com/en-us/azure/azure-sql/database/auditing-overview) |
| Audit to Log Analytics | [Learn](https://learn.microsoft.com/en-us/azure/azure-sql/database/auditing-log-analytics) |
| Defender for SQL overview | [Learn](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-introduction) |
| Cosmos DB diagnostic logging | [Learn](https://learn.microsoft.com/en-us/azure/cosmos-db/monitor-resource-logs) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
