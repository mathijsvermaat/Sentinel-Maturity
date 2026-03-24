# Tier 1 Connectors

This section contains the detailed guidance for each **Tier 1 (Bare Minimum)** data connector. Every Microsoft Sentinel deployment should have these connectors enabled.

---

## Connector Pages

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Defender XDR](microsoft-defender-xdr.md) | Endpoint, email, identity, and cloud app telemetry from M365 E5 | Yes — Analytics tier via E5 grant |
| [Microsoft Entra ID](microsoft-entra-id.md) | Authentication, directory changes, identity risk events | Yes — free data source |
| [Office 365](office-365.md) | Exchange, SharePoint, and Teams audit activity | Yes — free data source |
| [Azure Activity Logs](azure-activity-logs.md) | Azure control plane operations across all subscriptions | Yes — free data source |
| [Windows Security Events](windows-security-events.md) | Windows server authentication, process, and account management events | 500 MB/day/server via Defender for Servers P2 |
| [Syslog for Linux](syslog-linux.md) | Linux server authentication and system logging | 500 MB/day/server via Defender for Servers P2 |

## Template

Use the [connector template](_TEMPLATE.md) when creating pages for new connectors (Tier 1, Tier 2, Tier 3).

---

[← Back to Sentinel Maturity Model](../README.md)
