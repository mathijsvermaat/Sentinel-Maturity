# Procedures

Step-by-step guides for the tools referenced throughout the Sentinel Maturity Model. Each procedure walks you through a specific operational task — from validating ingestion volumes to estimating costs before enabling a connector.

---

## Guides

| Procedure | Tool Type | Description |
|:----------|:----------|:------------|
| [Workspace Usage Report](workspace-usage-report.md) | Workbook | Check free data connectors, ingestion benefit coverage, general ingestion volumes, and retention settings |
| [Retention Insights](retention-insights.md) | Workbook | Review table-level retention and archiving settings, evaluate Basic Logs candidates, and estimate cost impact of plan changes |
| [XDR Ingestion Calculator](xdr-ingestion-calculator.md) | Script | Estimate Defender XDR ingestion volumes from the Advanced Hunting API before enabling the Sentinel connector |
| [M365 E5 Benefit — Table Sizes by Product](xdr-e5-benefit-table-sizes.md) | KQL Query | Quantify the value of the E5 security data grant by showing all benefit-eligible tables with size, event count, and estimated cost |
| [Defender AMA Coverage](defender-ama-coverage.md) | Workbook | Validate AMA agent deployment coverage and identify gaps in security event and syslog collection |

## Template

Use the [procedure template](_TEMPLATE.md) when creating guides for new tools.

---

[← Back to Sentinel Maturity Model](../README.md)
