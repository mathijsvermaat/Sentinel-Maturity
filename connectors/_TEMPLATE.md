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

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **[TableName]** | [What data this table contains] | Analytics: 90d / Lake: 365d | [Why this data matters — reference MCSB controls, forensic readiness, MITRE ATT&CK coverage] | [What this data proves during an investigation — describe how it supports incident response and forensic analysis] | [Specific detection example with MITRE technique ID] |
| **[TableName]** | [What data this table contains] | Analytics: 90d / Lake: 365d | [Rationale] | [Forensic value] | [Detection example] |

---

## Example Detections

<!--
  Detailed detection rules beyond the one-liner in the table.
  Use H3 subsections to group by category if needed.
  Example: ### Authentication-Based, ### Endpoint, ### Email, etc.

  Each row should include the **MITRE ATT&CK technique** and, where available,
  the matching **MITRE Detection Strategy** (DET####). See the section below.
-->

### [Detection Category]

| Detection | Table(s) / Event ID(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:-----------------------|:-------------|:-------------------|:------------|
| [Detection name] | [Table or Event ID] | [Txxxx.xxx](https://attack.mitre.org/techniques/Txxxx/xxx/) | [DET####](https://attack.mitre.org/detectionstrategies/DET####/) — [Strategy name] | [What this detection catches and how] |
| [Detection name] | [Table or Event ID] | [Txxxx.xxx](https://attack.mitre.org/techniques/Txxxx/xxx/) | — *(no published strategy)* | [Description] |

---

## MITRE Detection Strategies

<!--
  Curated list of MITRE Detection Strategies (https://attack.mitre.org/detectionstrategies/)
  relevant to the techniques referenced on this page. The third column lists the
  EXACT log channels and event codes referenced by each strategy's analytic for
  this connector's platform — taken verbatim from MITRE's published
  `x_mitre_log_source_references` field. Never hand-pick "similar-looking"
  events from this connector's own tables.

  SOURCE OF TRUTH (in C:\Temp):
    - build_mitre_map_v3.ps1            (regenerate after pulling a new STIX bundle)
    - enterprise-attack.json            (MITRE STIX 2.1 bundle)
    - tech_to_det_v3.csv                (summary: one row per CitedTech+Strategy)
    - tech_to_det_v3_detail.csv         (one row per CitedTech+Strategy+Analytic+LogSource)
                                        columns include Platform, Channel, EventCode

  HOW TO FILL THE THIRD COLUMN:
    1. Rename the column header "MITRE Log Sources (<Platform>)" — substitute
       this connector's primary platform: (Windows), (Linux), (macOS), (Azure),
       (IaaS), (Containers), (Identity Provider), (SaaS), (Network Devices),
       (ESXi), or (Office Suite).
    2. Filter tech_to_det_v3_detail.csv by CitedTechId, DetId, Platform.
    3. Group the remaining rows by Channel and concatenate EventCode values.
       Render `` `Channel`: <codes> `` joined with ` · `.
       Example: `` `Security`: 4624, 4648 · `Sysmon`: 1, 3, 22 ``
    4. If no rows match the platform, write:
       `*MITRE has not published a <Platform> analytic for this strategy*`
    5. If matching rows are only non-`Security`-channel (Sysmon / System /
       PowerShell only), still list them and append
       `*(no \`Security\`-channel analytic published)*`.

  LEGACY / REVOKED TECHNIQUE IDs:
    MITRE periodically revokes technique IDs and reorganises them under new IDs
    (e.g. in April 2026 T1070.001, T1562, T1562.002, T1562.004 were revoked and
    moved into the T1685 / T1686 family). Detection Strategies are only attached
    to current technique IDs. Both v3 CSVs already follow the `revoked-by`
    chain; show legacy IDs as `*(revoked → Txxxx.xxx)*`.

    Only mark a technique as "no published strategy" (in the Example Detections
    table) when NEITHER the legacy nor the current (post-revoked-by) technique
    appears in tech_to_det_v3.csv.
-->

| Technique | Detection Strategy | MITRE Log Sources (<Platform>) |
|:----------|:-------------------|:-------------------------------|
| [Txxxx.xxx](https://attack.mitre.org/techniques/Txxxx/xxx/) — [Name] | [DET####](https://attack.mitre.org/detectionstrategies/DET####/) — [Strategy name] | `Channel`: <codes> · `Channel`: <codes> |
| [Txxxx.xxx](https://attack.mitre.org/techniques/Txxxx/xxx/) — [Name] *(revoked → [Tyyyy.yyy](https://attack.mitre.org/techniques/Tyyyy/yyy/))* | [DET####](https://attack.mitre.org/detectionstrategies/DET####/) — [Strategy name] | `Channel`: <codes> |
| [Txxxx.xxx](https://attack.mitre.org/techniques/Txxxx/xxx/) — [Name] | [DET####](https://attack.mitre.org/detectionstrategies/DET####/) — [Strategy name] | *MITRE has not published a [Platform] analytic for this strategy* |

> [!NOTE]
> **Log sources are verbatim from MITRE.** The third column is generated directly from each strategy's published `x_mitre_log_source_references` field in the [ATT&CK STIX 2.1 bundle](https://github.com/mitre-attack/attack-stix-data). If the cell shows only `Sysmon` or `PowerShell` events, that is exactly what MITRE's analytic queries; the page-author has **not** substituted similar-looking events from this connector's tables.

> [!NOTE]
> *(Include only if the page cites any revoked techniques)* **MITRE legacy technique IDs.** Some technique IDs cited on this page are *legacy* IDs that MITRE later revoked and moved to a new family. Detection Strategies are attached to the current technique IDs — the parenthetical *(revoked → Txxxx.xxx)* in each row shows the current ID. Pages may continue to cite legacy IDs because that is what Microsoft Sentinel docs and built-in analytic rules still reference.

> [!TIP]
> Detection Strategies are MITRE-published *pseudo-code analytics*, not vendor rules — they describe **what** to correlate across data sources. Use them to validate that your Sentinel analytics rules and KQL hunting queries cover the published correlation logic.

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

  ## Key Events by Tier (per-event-ID tier table)
     Used when a connector defines collection tiers (Minimal / Common / Full) and
     enumerates individual Event IDs per tier (see windows-security-events.md).
     Columns:
       | Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |

     RULES:
     - Rationale and Example Detection cells MUST NOT contain MCSB control IDs
       (MCSB IM-1., MCSB PA-1., MCSB LT-3., …) or MITRE technique IDs
       (MITRE T1136.001., trailing (T1110), (T1059.001), …). MCSB belongs in
       the MCSB Control Mapping section; MITRE technique/strategy references
       belong in the new MITRE column and the MITRE Detection Strategies section.
     - MITRE column format: `[N mappings](#mitre-detection-strategies)` (or
       `[1 mapping](#mitre-detection-strategies)`) where N = count of distinct
       (CurrentTechId, DetId) pairs in tech_to_det_v3_detail.csv for
       Platform = <connector's platform> and whose EventCode field matches the
       row's Event ID (regex \bID\b — so EventCode=4624, 4648 matches both).
       Use `—` when no MITRE analytic references the Event ID.
     - The MITRE cell links to the page's own ## MITRE Detection Strategies
       section (anchor #mitre-detection-strategies). Do NOT inline individual
       technique or strategy links per row — that section is the canonical list.
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

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor ingestion volumes for this connector's tables | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |
| **[Additional tool]** | [Workbook / Script / ...] | [Purpose] | [Source link] | [Walkthrough](../procedures/[guide].md) |

---

## References

Community and third-party resources that support the guidance on this page.

<!--
  Add community blog posts, third-party articles, and other external resources
  that underpin the advice on this page. Use the table format below.
-->

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| [Blog/article title] | [Author name] | [Brief description of relevance to this connector] | [Source](https://example.com) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
