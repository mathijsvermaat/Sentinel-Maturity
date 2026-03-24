# [Connector Name]

**Tier:** [1/2/3] · **Connector type:** [Microsoft first-party / Third-party] · **Free ingestion:** [Yes/No — details]

---

## Overview

[Brief description of the connector, what data it provides, and why it matters for security monitoring.]

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **[License name]** | [What tables/features become available] |
| **[License name]** | [What tables/features become available] |

> [!NOTE]
> [Key licensing or cost note — e.g., free data source, E5 data grant, P2 ingestion benefit.]

---

## Tables and Rationale

<!-- 
  Use H3 subsections to group tables by category if the connector has many tables.
  Example: ### Authentication Tables, ### Alert Tables, etc.
  For connectors with few tables (e.g., Office 365, Azure Activity), a single table is fine.
  
  Every table row MUST include an Example Detection column.
-->

### [Table Category Name] (optional grouping)

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **[TableName]** | [What data this table contains] | Analytics: 90d / Lake: 365d | [Why this data matters — reference MCSB controls, forensic readiness, MITRE ATT&CK coverage] | [Specific detection example with MITRE technique ID] |
| **[TableName]** | [What data this table contains] | Analytics: 90d / Lake: 365d | [Rationale] | [Detection example] |

---

## Example Detections

<!--
  Detailed detection rules beyond the one-liner in the table.
  Use H3 subsections to group by category if needed.
  Example: ### Authentication-Based, ### Endpoint, ### Email, etc.
-->

### [Detection Category]

| Detection | Table(s) / Event ID(s) | MITRE ATT&CK | Description |
|:----------|:-----------------------|:-------------|:------------|
| [Detection name] | [Table or Event ID] | [Txxxx.xxx] | [What this detection catches and how] |
| [Detection name] | [Table or Event ID] | [Txxxx.xxx] | [Description] |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **[XX-N]** [Control name] | [How this connector's data supports this control] |
| **[XX-N]** [Control name] | [Relevance] |

---

<!--
  OPTIONAL SECTIONS — Add any of the below between MCSB Control Mapping and Notes 
  if relevant for this connector:
  
  ## [Connector-specific comparison]
     Example: "## OfficeActivity vs CloudAppEvents" (Office 365 page)
  
  ## Important Considerations
     Example: Log categories to enable, deployment guidance (Azure Activity page)
  
  ## Recommended Configuration
     Example: Audit policy GPO, DCR facility settings (Windows Security Events, Syslog pages)
  
  ## Key Events to Monitor
     Example: Specific log patterns to watch for (Syslog page)
-->

## Notes

- [Key operational note — e.g., migration guidance, configuration tips]
- [Additional note]
- [Additional note]

<!--
  OPTIONAL: Add "### Why Layered Logging Matters" subsection for connectors 
  where native OS logging complements EDR (Windows Security Events, Syslog).
  Include 2-3 blog/article references in a table.
-->

### Useful Workbooks

| Workbook | Purpose | Source |
|:---------|:--------|:-------|
| **Workspace Usage Report** | Monitor ingestion volumes for this connector's tables | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) |
| **[Additional workbook]** | [Purpose] | [Source link] |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
