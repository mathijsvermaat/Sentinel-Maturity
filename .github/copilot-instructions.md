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
3. **Tier model is strict**: Tier 1 = bare minimum (every org), Tier 2 = extended visibility, Tier 3 = advanced/specialised.
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
7. **Example Detections** — H3 subsections by category. Table: `| Detection | Table(s) / Event ID(s) | MITRE ATT&CK | Description |`
8. **MCSB Control Mapping** — Table: `| MCSB Control | Relevance |`
9. **Notes** — Operational guidance bullets
10. **Tools** — Table: `| Tool | Type | Purpose | Source | Guide |`
11. **References** — Two subsections: `### Official Documentation` and `### Community & Third-Party Resources`
12. **Footer** — `[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)`

### Optional Sections (insert before Notes if applicable)

- `## Important Considerations` — Volume warnings, mode caveats
- `## Recommended Configuration` — GPO settings, DCR presets
- `## Key Events to Monitor` — Specific event IDs or log patterns
- `## [Connector-specific comparison]` — e.g., "OfficeActivity vs CloudAppEvents"
- `### Why Layered Logging Matters for [Topic]` — EDR complement rationale (only for endpoint/OS log connectors). Include resource table with blog links.

### Table Column Rules

- **Retention Recommendation**: Always formatted as `Analytics: 90d / Lake: 365d` (default). Note exceptions explicitly.
- **Forensic Value**: Phrased as investigative actions — "Reconstruct…", "Prove…", "Identify…", "Detect…"
- **MITRE ATT&CK**: Full technique notation `T1110.003`, not just tactic names.
- **Table names**: Always in backticks: `SecurityEvent`, `AuditLogs`.

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

### Tier Conventions in Main README

- Tier 1 connector table columns: `| Connector | Key Tables | Licensing Benefit | Free Ingestion |`
- Tier 2/3 connector table columns: `| Connector | Key Tables | Free Ingestion |`
- Tier 2/3 are grouped under H3 category headings
- Conditional connectors: append `— *conditional*` to the Free Ingestion cell
- Connector names link to their page: `[Product Name](connectors/file-name.md)`
- Third-party placeholder rows (no link): `Third-Party [Category] (Vendor1, Vendor2, Vendor3)`
