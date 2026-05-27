# Sentinel Maturity Model — Copilot Instructions

## Project Overview

This is a **Microsoft Sentinel data connector maturity model** for the Dutch Security TS team. It provides tiered guidance (Tier 1/2/3) for connector onboarding, retention, and detection rationale.

**Repository structure:**

```
README.md                  # Main entry point — tier tables, TOC, tools, references
connectors/                # One .md per data connector + README.md + _TEMPLATE.md
guidance/                  # Strategic guidance articles + README.md
procedures/                # Step-by-step tool walkthroughs + README.md + _TEMPLATE.md
```

A separate repo (`mathijsvermaat.github.io`) hosts the assessment HTML checklist. Do NOT mix changes across repos.

---

## Critical Rules

1. **Never commit or push** unless explicitly asked.
2. **Never create markdown files to document changes** unless explicitly requested.
3. **Tier model is strict**: Tier 1 = foundational (every org), Tier 2 = extended visibility, Tier 3 = advanced/specialised.
4. **Retention default**: `Analytics: 90d / Lake: 365d` unless a specific compliance requirement justifies longer.
5. **Spelling**: Use British English (organisation, defence, behaviour, specialised, etc.).
6. **File naming**: Lowercase with hyphens (`azure-firewall.md`, not `AzureFirewall.md`).
7. **Link style**: Use relative paths within the repo. Never use absolute filesystem paths in markdown content.

---

## README Synchronisation Rules

When adding, removing, or renaming a connector, guidance, or procedure file:

- **Main `README.md`**: Update both the tier connector table AND the Procedures/Tools tables if affected.
- **Category `README.md`** (`connectors/README.md`, `guidance/README.md`, `procedures/README.md`): Update the index table.
- **TOC in main README**: Must list every tier subcategory heading.
- **Date**: Update `*Last updated: [Month Year]*` at the bottom of main README.

All four locations must stay in sync. Verify after every structural change.

---

## References Index Synchronisation Rules (`references.md`)

`references.md` at the repo root is a **consolidated index of every external URL** used anywhere in the model, grouped by category. It MUST be kept in sync whenever external links are added, changed, or removed in any `.md` file under `connectors/`, `guidance/`, `procedures/`, or the root `README.md`.

**When adding a new external URL to any page:**

1. Add (or update) a row in the appropriate category table in `references.md`. Use the next sequential number within that category (e.g. `5.20`).
2. Populate columns: **Title** (authoritative short title of the target page), **URL** (formatted as `[short-host-or-label](https://full-url)`), **Referenced in** (comma-separated markdown links to every repo page that cites the URL, using paths relative to the repo root — e.g. `[connectors/foo.md](connectors/foo.md)`).
3. If the same URL is cited in multiple pages, keep a **single** row and list all citing pages in the "Referenced in" cell — do not create duplicate rows across categories.
4. If the URL already exists in `references.md` and you add a new citation in another page, append that page to the existing row's "Referenced in" cell.

**When removing or renaming a citation:** update the "Referenced in" cell. If the last citation is removed, delete the row (renumber is not required — gaps are acceptable).

**Categories** (do not invent new ones unless clearly justified):

1. Microsoft Learn — Sentinel core
2. Microsoft Learn — Defender XDR & Advanced Hunting
3. Microsoft Learn — Azure Monitor, AMA & DCR
4. Microsoft Learn — Identity (Entra ID, ID Protection, GSA)
5. Microsoft Learn — Defender for Cloud / Servers / Containers / IoT / DNS / Storage / SQL / Cloud Apps
6. Microsoft Learn — Microsoft 365, Purview, Intune & Copilot
7. Microsoft Learn — Windows security event ID reference
8. Microsoft Learn — Azure workload logging
9. Azure pricing & commercial offers
10. Tools & workbooks (GitHub) — **executable / deployable** workbooks, scripts, KQL queries, hosted apps only
11. Blogs & community resources — articles, configuration baselines (e.g. Sysmon configs), mindmaps, vendor product documentation (GitHub Docs, etc.) and any non-executable third-party reading material
12. Standards & frameworks
13. Sentinel Ninja (reference documentation)
14. **Admin portals** — Microsoft cloud admin portals (Defender / Entra / Azure / Purview / Intune) and the **cmd.ms** quick-link service (entry 14.6). Each row's "Referenced in" cell must list every connector page that has an `### Admin portal` subsection citing it. When a connector page adds or removes its `### Admin portal` block, update the corresponding 14.x row(s) — and 14.6 if cmd.ms aliases are included.

If a new URL fits none of the above, add a new category at the end with the next number and also add it to the Contents block at the top of `references.md`.

**Scope:** `references.md` indexes **external URLs only** (http/https). Internal cross-links between repo files are out of scope.

---

## Connector Pages (`connectors/*.md`)

Template: `connectors/_TEMPLATE.md`

### Required Sections (in order)

1. **H1 title** — Product name
2. **Metadata line** — `**Tier:** [1/2/3] · **Connector type:** [Microsoft first-party / Third-party] · **Free ingestion:** [Yes/No — details]`
3. **Contents** — Full markdown TOC
4. **Overview** — What the connector provides and why it matters
5. **Licensing Benefits** — Table: `| License | What it unlocks |`
6. **Tables and Rationale** — Core table(s) with columns: `| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |`
   - Group into H3 subsections when >5 tables (e.g., "### Authentication Tables")
7. **Example Detections** — H3 subsections by category. Table: `| Detection | Table(s) / Event ID(s) | MITRE ATT&CK | Detection Strategy | Description |`
8. **MITRE Detection Strategies** — Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on the page. Table: `| Technique | Detection Strategy | Relevant Event IDs / Tables |`. See "MITRE Detection Strategies mapping" below for the build rules.
9. **MCSB Control Mapping** — Table: `| MCSB Control | Relevance |`
10. **Notes** — Operational guidance bullets
11. **Tools** — Table: `| Tool | Type | Purpose | Source | Guide |`
12. **References** — Two subsections: `### Official Documentation` and `### Community & Third-Party Resources`
13. **Admin portal** *(when the connector has a configurable portal)* — H3 subsection placed after References and before the Footer. Bullet list of admin-portal links (Defender / Entra / Azure / Purview / Intune) with a short note on what to configure. Each portal bullet may carry a sub-bullet `Quick links via [cmd.ms](https://cmd.ms/) (see [References §14.6](../references.md#14-admin-portals))` listing relevant cmd.ms aliases for blade-level deep links. When you add this subsection, also append the connector page to the corresponding §14.x row in `references.md` (and §14.6 if cmd.ms aliases are included).
14. **Footer** — `[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)`

### Optional Sections (insert before Notes if applicable)

- `## Important Considerations` — Volume warnings, mode caveats
- `## Recommended Configuration` — GPO settings, DCR presets
- `## Key Events to Monitor` — Specific event IDs or log patterns
- `## [Connector-specific comparison]` — e.g., "OfficeActivity vs CloudAppEvents"
- `### Why Layered Logging Matters for [Topic]` — EDR complement rationale (only for endpoint/OS log connectors). Include resource table with blog links.

### Table Column Rules

- **Retention Recommendation**: Always formatted as `Analytics: 90d / Lake: 365d` (default). Note exceptions explicitly.
- **Forensic Value**: Phrased as investigative actions — "Reconstruct…", "Prove…", "Identify…", "Detect…"
- **MITRE ATT&CK**: Full technique notation `T1110.003`, linked to `https://attack.mitre.org/techniques/T1110/003/`.
- **Detection Strategy** (in `Example Detections`): `[DET####](https://attack.mitre.org/detectionstrategies/DET####/) — [Strategy name]`, or `— *(no published strategy)*` when neither the cited technique nor its current `revoked-by` target has one.
- **Table names**: Always in backticks: `SecurityEvent`, `AuditLogs`.

### Per-event-ID tier tables

When a connector page enumerates individual Event IDs and their collection tier (e.g. the "Key Events by Tier" tables on `windows-security-events.md`), use the columns: `| Event ID | Description | Minimal | Common | Full | Rationale | Forensic Value | MITRE | Example Detection |`

- **`Rationale` and `Example Detection` cells must not contain MCSB control IDs or MITRE technique IDs.** Strip phrases like `MCSB IM-1.`, `MCSB PA-1.`, `MCSB LT-3.`, `MITRE T1136.001.`, and trailing parentheticals like `(T1110)` / `(T1059.001)`. MCSB belongs in the `MCSB Control Mapping` section; MITRE technique/strategy references belong in the new `MITRE` column and the dedicated `MITRE Detection Strategies` section.
- **`MITRE` column format**: `[N mappings](#mitre-detection-strategies)` (or `[1 mapping](#mitre-detection-strategies)`) where `N` is the count of distinct `(CurrentTechId, DetId)` pairs in your local MITRE mapping detail export for `Platform = <connector's platform>` and whose `EventCode` field matches the row's Event ID (regex `\bID\b`, so comma-separated lists like `EventCode=4624, 4648` match both). When no MITRE analytic references the Event ID, render `—`.
- The MITRE cell links to the page's own `## MITRE Detection Strategies` section (anchor `#mitre-detection-strategies`); do **not** inline individual technique or strategy links per row — the strategies section is the canonical list. Counts give a navigation cue ("this event has many published analytics; here are all of them in one place").

### MITRE Detection Strategies mapping

The `## MITRE Detection Strategies` section maps every technique cited on the page to MITRE's [Detection Strategies catalogue](https://attack.mitre.org/detectionstrategies/) — pseudo-code analytics that describe what to correlate across data sources.

**Source of truth**: the MITRE STIX 2.1 `enterprise-attack` bundle (source `github.com/mitre-attack/attack-stix-data`). Maintainers may keep a local cached copy plus derived mapping exports, but the repo does **not** require any specific filesystem path or filename. The local mapping exports used for faster editing should follow `revoked-by` chains and resolve each strategy's per-analytic log sources:

- Summary export — one row per `(CitedTech, Strategy)` with fields such as `CitedTechId`, `CurrentTechId`, `DetId`, `DetName`, and high-level log-source metadata.
- Detail export — one row per `(CitedTech, Strategy, Analytic, LogSource)` with fields such as `Platform`, `Channel`, and `EventCode`.

Refresh these derived files with your local MITRE-mapping build process after pulling a new STIX bundle. Older legacy mapping exports are superseded — do **not** use them for the log-sources column. If the derived exports are unavailable, work directly from the STIX bundle and MITRE ATT&CK technique / detection-strategy pages instead of assuming a local cache exists.

**Build rules**:

1. Extract every unique technique ID referenced anywhere on the page (regex `T\d{4}(\.\d{3})?`).
2. For each technique, look it up in your local MITRE mapping summary export. If `Revoked = True`, MITRE has reorganised it — the `CurrentTechId` column gives the current ID and `DetId` / `DetName` are the strategy attached to that current technique. Render the technique cell as `[Txxxx.xxx](…) — [Name] *(revoked → [Tyyyy.yyy](…))*`.
3. For the third column on raw-channel pages:
   - Use **MITRE Log Sources (<Platform>)** when the connector's native channels and tables substantially align with MITRE's published `x_mitre_log_source_references` for that platform.
   - Use **Connector Evidence (<Platform>)** when MITRE's published platform-family analytic is expressed through another vendor's concrete source names and repeating them verbatim would mislead readers on this page (for example `AWS:CloudTrail` on an Azure connector page, or mixed AWS/GCP exemplars on a single-cloud page). In that mode, translate MITRE's published analytic inputs into the analogous tables, operations, and telemetry on the current connector page.
   - The goal is clarity for the connector reader: preserve MITRE's analytic intent, but do not imply that a connector emits another vendor's literal table names.
4. For **MITRE Log Sources (<Platform>)** mode (e.g. `(Windows)` for `windows-security-events.md`, `(Linux)` for `syslog-linux.md`):
   - Open your local MITRE mapping detail export and filter rows by `CitedTechId = <T>`, `DetId = <DET>`, and `Platform = <connector's platform>`.
   - Group the resulting rows by `Channel` (`Security`, `System`, `PowerShell`, `Sysmon`, `auditd:SYSCALL`, etc.) and concatenate the `EventCode` values within each group.
   - Render as `` `Channel`: <codes> `` joined with ` · `. Example: `` `Security`: 4624, 4648 · `Sysmon`: 1, 3, 22 ``.
   - Use the literal `Channel` and `EventCode` strings from the CSV — they come straight from MITRE's `x_mitre_log_source_references` (`name` and `channel` fields). **Do not substitute** "similar-looking" events from the connector's own Event-ID tables.
   - When no row matches the connector's platform, render the cell as `*MITRE has not published a <Platform> analytic for this strategy*`.
   - When the platform rows contain only non-`Security` channels (e.g. only `Sysmon`, `PowerShell`, `System`), still list them verbatim and add the suffix `*(no \`Security\`-channel analytic published)*` so the reader knows MITRE expects out-of-`Security`-channel data.
5. For **Connector Evidence (<Platform>)** mode, express the third column in this connector's own evidence terms: actual table names, operation names, event families, or telemetry categories available on the page. Preserve MITRE's analytic intent, but avoid foreign vendor table names. When no analogous evidence exists on the page, render the cell as `*No direct connector-native evidence mapped for this strategy*`.
6. Only mark a technique as `— *(no published strategy)*` in the `Example Detections` table when **neither** the cited nor the current `revoked-by` target appears in your local MITRE mapping summary export.
7. Include a `> [!NOTE]` callout in the `## MITRE Detection Strategies` section explaining which mode is in use:
   - For **MITRE Log Sources** mode: keep the existing "log sources are verbatim from MITRE" wording.
   - For **Connector Evidence** mode, use wording like:
     > **Connector-native evidence mapping.** MITRE's published Detection Strategies for this platform family sometimes cite another vendor's concrete source names. To avoid implying a false 1:1 table match on this connector page, the third column translates MITRE's analytic intent into the analogous evidence available in this connector's own tables.
8. Include a `> [!NOTE]` legacy-ID callout whenever at least one row uses a revoked technique. Suggested wording:
   > **MITRE legacy technique IDs.** Some technique IDs cited on this page are *legacy* IDs that MITRE later revoked and moved to a new family (e.g. in April 2026 `T1070.001`, `T1562.*` were revoked and moved into `T1685` / `T1686`). Detection Strategies are attached to the *current* technique IDs — the parenthetical *(revoked → Txxxx.xxx)* shows the current ID. Pages may continue to cite legacy IDs because that is what Microsoft Sentinel docs and built-in analytic rules still reference.
9. Include a `> [!TIP]` reminding readers that Detection Strategies are pseudo-code analytics, not vendor rules — they describe *what* to correlate and should be used to validate Sentinel analytic-rule / KQL coverage.
10. The same DET#### link must also appear in the corresponding row of the `## Example Detections` summary table.

**Do NOT** add DET#### inline to the per-Event-ID detail tables under `Tables and Rationale` — keep the mapping in the dedicated `## MITRE Detection Strategies` section and the `Example Detections` summary table only.

### Raw-channel vs portal-abstracted connectors

The `MITRE Log Sources (<Platform>)` column **only** belongs on connectors that ingest raw channels at the same abstraction level MITRE references in `x_mitre_log_source_references`. For connectors that surface telemetry through a vendor-normalised schema, the column is misleading and must be omitted.

- **Raw-channel** (column included): `windows-security-events`, `windows-forwarded-events`, `syslog-linux`, `office-365` (m365 unified audit), `microsoft-entra-id` (signinlogs / audit), `amazon-web-services` (CloudTrail), `google-cloud-platform`, `iis-web-server-logs`, `dns-security-logs`, `azure-activity-logs`, `azure-firewall`, `azure-waf`, `azure-storage-account`, `azure-key-vault`, `vnet-flow-logs`, `third-party-network-appliances`, `azure-kubernetes-service`.
- **Portal-abstracted** (omit log-sources column; render 2-column `| Technique | Detection Strategy |` table and add a `[!NOTE]` explaining why): `microsoft-defender-xdr`, `microsoft-defender-cloud-apps`, `microsoft-defender-for-cloud`, `microsoft-defender-for-iot`, `microsoft-intune`, `microsoft-purview-data-map`, `microsoft-purview-information-protection`, `copilot-ai-governance`, `sentinel-health`, `threat-intelligence`, `global-secure-access`, `sap`, `sql-database-audit`, `azure-devops`, `github-enterprise`, `custom-applications`.

**When in doubt, omit the column.** The cost of an omitted column is small (readers still follow strategy links to MITRE's pages); the cost of a misleading column is high (readers assume their connector emits raw channels it does not).

The rationale: MDE/MDI/MDO/MDCA, Defender for Cloud, Intune, Purview, etc. do **not** surface raw Sysmon / auditd / m365 unified audit / Okta events — they surface their own parsed tables (`DeviceProcessEvents`, `CloudAppEvents`, etc.). Listing MITRE's raw `log_sources` against those connectors implies a 1:1 mapping that doesn't exist. Use the strategy pages on attack.mitre.org for **what** to correlate; implement against the connector's own tables listed in `Tables and Rationale`.

If you use a local helper such as `generate_strategies_section.ps1`, it should support both modes:
- Raw-channel: `-Platform <Name>` (or `-Platform "A,B,C" -MultiPlatform` for cross-platform raw connectors).
- Portal-abstracted: add `-NoLogSources`.

**Do NOT** fill the log-sources column from the connector page's own Event-ID tables. If a strategy's MITRE-published analytic uses 4688 + Sysmon 13/14, write exactly that — do not "improve" it with 4946/4948/4956 because they look semantically related. This was the v2 mistake; the v3 CSV exists precisely to remove that temptation.

---

## Guidance Pages (`guidance/*.md`)

### Required Sections (in order)

1. **H1 title** — Topic name
2. **Contents** — Full markdown TOC
3. **Overview** — Sets problem context, may include a blockquote with core thesis
4. **Core content** — 3–5 H2 sections with topic-specific names
5. **References** — External resources (if applicable)
6. **Footer** — `[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)`

### Writing Style

- Explanatory narrative, not procedural
- Strategic/design-focused
- Tie every major point to frameworks: MCSB, NIST, CIS, NIS2, GDPR
- Use callout blocks: `> [!NOTE]`, `> [!IMPORTANT]`, `> [!TIP]`, `> [!WARNING]`
- Use comparison tables for framework mappings

---

## Procedure Pages (`procedures/*.md`)

Template: `procedures/_TEMPLATE.md`

### Required Sections (in order)

1. **H1 title** — `[Tool Name] — Walkthrough`
2. **Metadata line** — `**Tool type:** [Workbook / Script / KQL Query] · **Source:** [Link]`
3. **Intro paragraph** — What this guide covers
4. **Contents** — Full markdown TOC
5. **When to Use This Tool** — Specific operational questions it answers
6. **Prerequisites** — Table or bullet list with clear requirements
7. **Step-by-step instructions** — H2 sections: `## Step 1 — [Action]`, `## Step 2 — [Action]`, etc. Subsections use H3.
8. **Footer** — `[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)`

### Optional End Sections

- `## Interpret the Results`
- `## Common Scenarios`
- `## Troubleshooting`
- `## Accuracy and Limitations`
- `## Customisation`
- `## Related Tools`

---

## Cross-Cutting Conventions

### Links

| Type | Format |
|:-----|:-------|
| Back navigation | `[← Back to [Category]](README.md) · [← Back to Sentinel Maturity Model](../README.md)` |
| Cross-reference to connector | `[Windows Security Events](../connectors/windows-security-events.md)` |
| Cross-reference to procedure | `[Workspace Usage Report walkthrough](../procedures/workspace-usage-report.md)` |
| External Microsoft docs | `[Title](https://learn.microsoft.com/...)` |
| External GitHub repos | `[GitHub — owner/repo](https://github.com/owner/repo)` |

### Callout Blocks

Use GitHub-flavoured callouts consistently:
- `> [!NOTE]` — Contextual information
- `> [!IMPORTANT]` — Critical decision impact
- `> [!TIP]` — Best practice
- `> [!WARNING]` — Caution or risk

### cmd.ms quick-links

Community short-link service by Merill Fernando ([cmd.ms](https://cmd.ms/)). When listing portal blade deep-links on a connector page's `### Admin portal` subsection, prefer cmd.ms aliases (e.g. `enca.cmd.ms`, `azkv.cmd.ms`, `defender.cmd.ms`) for human readability. Always keep the canonical Microsoft URL as the primary link; cmd.ms aliases live as a sub-bullet labelled `Quick links via [cmd.ms](https://cmd.ms/) (see [References §14.6](../references.md#14-admin-portals))`. Skip cmd.ms when no precise alias exists for the target blade (e.g. per-resource diagnostic-settings on Azure Firewall, IoT, or Copilot).

### Tier Conventions in Main README

- Tier 1 connector table columns: `| Connector | Key Tables | Licensing Benefit | Free Ingestion |`
- Tier 2/3 connector table columns: `| Connector | Key Tables | Free Ingestion |`
- Tier 2/3 are grouped under H3 category headings
- Conditional connectors: append `— *conditional*` to the Free Ingestion cell
- Connector names link to their page: `[Product Name](connectors/file-name.md)`
- Third-party placeholder rows (no link): `Third-Party [Category] (Vendor1, Vendor2, Vendor3)`
