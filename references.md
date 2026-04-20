# References

A consolidated index of every external resource cited across the Sentinel Maturity Model, grouped by category. Each entry links to the source and to the page(s) within this repo where it is used.

This page is kept in sync via the repository's Copilot instructions: whenever a new external URL is added to a connector, guidance, or procedure page through GitHub Copilot, a matching entry is added (or the existing entry's "Referenced in" cell extended) here automatically. See [.github/copilot-instructions.md](.github/copilot-instructions.md) — section *"References Index Synchronisation Rules"* — for the rule definition. Contributors editing files without Copilot are expected to follow the same rule by hand.

---

## Contents

- [1. Microsoft Learn — Sentinel core](#1-microsoft-learn--sentinel-core)
- [2. Microsoft Learn — Defender XDR & Advanced Hunting](#2-microsoft-learn--defender-xdr--advanced-hunting)
- [3. Microsoft Learn — Azure Monitor, AMA & DCR](#3-microsoft-learn--azure-monitor-ama--dcr)
- [4. Microsoft Learn — Identity (Entra ID, ID Protection, GSA)](#4-microsoft-learn--identity-entra-id-id-protection-gsa)
- [5. Microsoft Learn — Defender for Cloud / Servers / Containers / IoT / DNS / Storage / SQL / Cloud Apps](#5-microsoft-learn--defender-for-cloud--servers--containers--iot--dns--storage--sql--cloud-apps)
- [6. Microsoft Learn — Microsoft 365, Purview, Intune & Copilot](#6-microsoft-learn--microsoft-365-purview-intune--copilot)
- [7. Microsoft Learn — Windows security event ID reference](#7-microsoft-learn--windows-security-event-id-reference)
- [8. Microsoft Learn — Azure workload logging (Firewall, WAF, Key Vault, Storage, Network, AKS, DevOps)](#8-microsoft-learn--azure-workload-logging-firewall-waf-key-vault-storage-network-aks-devops)
- [9. Azure pricing & commercial offers](#9-azure-pricing--commercial-offers)
- [10. Tools & workbooks (GitHub)](#10-tools--workbooks-github)
- [11. Blogs & community resources](#11-blogs--community-resources)
- [12. Standards & frameworks](#12-standards--frameworks)
- [13. Sentinel Ninja (reference documentation)](#13-sentinel-ninja-reference-documentation)

---

## 1. Microsoft Learn — Sentinel core

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 1.1 | Microsoft Sentinel pricing and billing | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers) | [README.md](README.md), [guidance/budget-and-cost-planning.md](guidance/budget-and-cost-planning.md), [guidance/input-output-strategy.md](guidance/input-output-strategy.md), [procedures/xdr-data-volume-insights.md](procedures/xdr-data-volume-insights.md), [procedures/xdr-ingestion-calculator.md](procedures/xdr-ingestion-calculator.md), [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 1.2 | Free data sources in Microsoft Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources) | [README.md](README.md), [guidance/budget-and-cost-planning.md](guidance/budget-and-cost-planning.md) |
| 1.3 | Reduce costs for Microsoft Sentinel — pricing tier | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/billing-reduce-costs#set-or-change-pricing-tier) | [procedures/retention-insights.md](procedures/retention-insights.md) |
| 1.4 | Sentinel Content Hub | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [README.md](README.md), [guidance/budget-and-cost-planning.md](guidance/budget-and-cost-planning.md), [procedures/workspace-usage-report.md](procedures/workspace-usage-report.md), [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 1.5 | Sentinel solutions catalog | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-solutions-catalog) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.6 | Sentinel data connectors reference | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/data-connectors-reference) | Anchor-linked from multiple connector pages (Windows DNS via AMA, Microsoft Copilot, Defender XDR) |
| 1.7 | Sentinel tables and associated connectors | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/sentinel-tables-connectors-reference) | [connectors/microsoft-defender-cloud-apps.md](connectors/microsoft-defender-cloud-apps.md) |
| 1.8 | Sentinel Data Lake overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-lake-overview) | [guidance/retention.md](guidance/retention.md) |
| 1.9 | Sentinel data lake overview (short path) | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/datalake/sentinel-lake-overview) | [procedures/retention-insights.md](procedures/retention-insights.md) |
| 1.10 | Search jobs in Microsoft Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/search-jobs) | [procedures/retention-insights.md](procedures/retention-insights.md) |
| 1.11 | Restore archived data in Microsoft Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/restore) | [procedures/retention-insights.md](procedures/retention-insights.md) |
| 1.12 | Sentinel Health — audit logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/health-audit) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |
| 1.13 | Enable health monitoring in Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/enable-monitoring) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |
| 1.14 | Monitor data connector health | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/monitor-data-connector-health) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |
| 1.15 | SentinelHealth table reference | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/health-table-reference) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |
| 1.16 | Monitor analytics rule integrity | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/monitor-analytics-rule-integrity) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |
| 1.17 | Monitor automation health | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/monitor-automation-health) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |
| 1.18 | Summary rules in Microsoft Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/summary-rules) | [guidance/budget-and-cost-planning.md](guidance/budget-and-cost-planning.md) |
| 1.19 | SAP for Sentinel — solution overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/sap/solution-overview) | [connectors/sap.md](connectors/sap.md) |
| 1.20 | SAP for Sentinel — solution pricing | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/sap/solution-overview#solution-pricing) | [connectors/sap.md](connectors/sap.md) |
| 1.21 | SAP — deploy security content | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/sap/deploy-sap-security-content) | [connectors/sap.md](connectors/sap.md) |
| 1.22 | SAP — deploy data connector agent container | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/sap/deploy-data-connector-agent-container) | [connectors/sap.md](connectors/sap.md) |
| 1.23 | Connect Sentinel to Windows-based services (WEF) | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/connect-services-windows-based) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |
| 1.24 | Threat intelligence integration in Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/threat-intelligence-integration) | [connectors/threat-intelligence.md](connectors/threat-intelligence.md) |
| 1.25 | Connect a TIP to Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-threat-intelligence-tip) | [connectors/threat-intelligence.md](connectors/threat-intelligence.md) |
| 1.26 | Unified connector — CEF device | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/unified-connector-cef-device) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.27 | Unified connector — Syslog device | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/unified-connector-syslog-device) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.28 | CEF/Syslog via AMA | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-cef-syslog-ama) | [connectors/syslog-linux.md](connectors/syslog-linux.md) |
| 1.29 | Logstash output plugin for Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-logstash-data-connection-rules) | [connectors/custom-applications.md](connectors/custom-applications.md) |
| 1.30 | Windows Security Event ID reference (Sentinel) | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/windows-security-event-id-reference) | [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 1.31 | Connect Azure Active Directory to Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-azure-active-directory) | [connectors/microsoft-entra-id.md](connectors/microsoft-entra-id.md) |
| 1.32 | Connect AWS to Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-aws) | [connectors/amazon-web-services.md](connectors/amazon-web-services.md) |
| 1.33 | Connect GCP to Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-google-cloud-platform) | [connectors/google-cloud-platform.md](connectors/google-cloud-platform.md) |
| 1.34 | Data connectors reference — AWS (SQS-based CloudTrail) | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/amazon-web-services) | [connectors/amazon-web-services.md](connectors/amazon-web-services.md) |
| 1.35 | Data connectors reference — AWS S3 | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/amazon-web-services-s3) | [connectors/amazon-web-services.md](connectors/amazon-web-services.md) |
| 1.36 | Data connectors reference — Azure Activity | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/azure-activity) | [connectors/azure-activity-logs.md](connectors/azure-activity-logs.md) |
| 1.37 | Data connectors reference — Azure DevOps | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/azure-devops) | [connectors/azure-devops.md](connectors/azure-devops.md) |
| 1.38 | Data connectors reference — Azure Firewall | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/azure-firewall) | [connectors/azure-firewall.md](connectors/azure-firewall.md) |
| 1.39 | Data connectors reference — Azure Key Vault | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/azure-key-vault) | [connectors/azure-key-vault.md](connectors/azure-key-vault.md) |
| 1.40 | Data connectors reference — Azure Web Application Firewall | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/azure-web-application-firewall) | [connectors/azure-waf.md](connectors/azure-waf.md) |
| 1.41 | Data connectors reference — DNS | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/dns) | [connectors/dns-security-logs.md](connectors/dns-security-logs.md) |
| 1.42 | Data connectors reference — GCP Pub/Sub Audit Logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/gcp-pub-sub-audit-logs) | [connectors/google-cloud-platform.md](connectors/google-cloud-platform.md) |
| 1.43 | Data connectors reference — GitHub Enterprise audit log | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/github-enterprise-audit-log) | [connectors/github-enterprise.md](connectors/github-enterprise.md) |
| 1.44 | Data connectors reference — MDCA | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-defender-for-cloud-apps) | [connectors/microsoft-defender-cloud-apps.md](connectors/microsoft-defender-cloud-apps.md) |
| 1.45 | Data connectors reference — Defender for IoT (OT) | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/iot-ot-threat-monitoring-with-defender-for-iot) | [connectors/microsoft-defender-for-iot.md](connectors/microsoft-defender-for-iot.md) |
| 1.46 | Data connectors reference — Microsoft 365 (Office activity) | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-365) | [connectors/office-365.md](connectors/office-365.md) |
| 1.47 | Data connectors reference — Microsoft Purview Information Protection | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-purview-information-protection) | [connectors/microsoft-purview.md](connectors/microsoft-purview.md) |
| 1.48 | Data connectors reference — Windows Security Events via AMA | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/windows-security-events-via-ama) | [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 1.49 | Data connectors reference — Palo Alto Networks | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/palo-alto-networks) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.50 | Data connectors reference — Fortinet | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/fortinet) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.51 | Data connectors reference — Check Point | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/check-point) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.52 | Data connectors reference — Cisco ASA | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/cisco-asa) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.53 | Data connectors reference — Zscaler | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/zscaler) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 1.54 | Data connectors reference — Sophos XG Firewall | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/sophos-xg-firewall) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |

---

## 2. Microsoft Learn — Defender XDR & Advanced Hunting

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 2.1 | Connect Microsoft Defender XDR to Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-microsoft-365-defender) | [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 2.2 | Microsoft Defender XDR integration with Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/microsoft-365-defender-sentinel-integration) | [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 2.3 | Advanced hunting schema reference | [learn.microsoft.com](https://learn.microsoft.com/defender-xdr/advanced-hunting-schema-tables) | [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md), [procedures/xdr-data-volume-insights.md](procedures/xdr-data-volume-insights.md), [procedures/xdr-ingestion-calculator.md](procedures/xdr-ingestion-calculator.md) |
| 2.4 | Microsoft Defender XDR Advanced Hunting API | [learn.microsoft.com](https://learn.microsoft.com/defender-xdr/api/api-advanced-hunting) | [procedures/xdr-ingestion-calculator.md](procedures/xdr-ingestion-calculator.md) |
| 2.5 | Defender XDR data connector (Sentinel reference) | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/data-connectors-reference#microsoft-defender-xdr) | [procedures/xdr-data-volume-insights.md](procedures/xdr-data-volume-insights.md) |

---

## 3. Microsoft Learn — Azure Monitor, AMA & DCR

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 3.1 | Data Collection Rules in Azure Monitor — overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview) | [connectors/custom-applications.md](connectors/custom-applications.md), [guidance/budget-and-cost-planning.md](guidance/budget-and-cost-planning.md), [guidance/input-output-strategy.md](guidance/input-output-strategy.md) |
| 3.2 | Data collection transformations in DCR | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-transformations) | [connectors/custom-applications.md](connectors/custom-applications.md) |
| 3.3 | Create a transformation in an Azure Monitor DCR | [learn.microsoft.com](https://learn.microsoft.com/azure/azure-monitor/data-collection/data-collection-transformations-create) | [connectors/iis-web-server-logs.md](connectors/iis-web-server-logs.md) |
| 3.4 | Diagnostic settings policy (built-in) | [learn.microsoft.com](https://learn.microsoft.com/azure/azure-monitor/platform/diagnostic-settings-policy-built-in) | [connectors/azure-activity-logs.md](connectors/azure-activity-logs.md) |
| 3.5 | Azure Activity log event schema | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/activity-log-schema) | [connectors/azure-activity-logs.md](connectors/azure-activity-logs.md) |
| 3.6 | Logs Ingestion API overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-ingestion-api-overview) | [connectors/custom-applications.md](connectors/custom-applications.md) |
| 3.7 | Create custom tables in Log Analytics | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/create-custom-table) | [connectors/custom-applications.md](connectors/custom-applications.md) |
| 3.8 | Manage data retention in a Log Analytics workspace | [learn.microsoft.com](https://learn.microsoft.com/azure/azure-monitor/logs/data-retention-configure) | [procedures/retention-insights.md](procedures/retention-insights.md) |
| 3.9 | Configure data retention and archive policies | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-archive) | [guidance/retention.md](guidance/retention.md) |
| 3.10 | Collect IIS logs with Azure Monitor Agent | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-iis) | [connectors/iis-web-server-logs.md](connectors/iis-web-server-logs.md) |
| 3.11 | W3CIISLog table reference | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/w3ciislog) | [connectors/iis-web-server-logs.md](connectors/iis-web-server-logs.md) |
| 3.12 | StorageBlobLogs table reference | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/storagebloblogs) | [connectors/azure-storage-analytics.md](connectors/azure-storage-analytics.md) |
| 3.13 | McasShadowItReporting table schema | [learn.microsoft.com](https://learn.microsoft.com/azure/azure-monitor/reference/tables/mcasshadowitreporting) | [connectors/microsoft-defender-cloud-apps.md](connectors/microsoft-defender-cloud-apps.md) |
| 3.14 | AMA — Collect Windows Events | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-windows-events) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |

---

## 4. Microsoft Learn — Identity (Entra ID, ID Protection, GSA)

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 4.1 | Entra ID — audit activities reference | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-audit-activities) | [connectors/microsoft-entra-id.md](connectors/microsoft-entra-id.md) |
| 4.2 | Entra ID Protection — overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/id-protection/overview-identity-protection) | [connectors/microsoft-entra-id.md](connectors/microsoft-entra-id.md) |
| 4.3 | Entra ID Protection — investigate risk | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/id-protection/howto-identity-protection-investigate-risk) | [connectors/microsoft-entra-id.md](connectors/microsoft-entra-id.md) |
| 4.4 | Entra ID Protection — workload identity risk | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/id-protection/concept-workload-identity-risk) | [connectors/microsoft-entra-id.md](connectors/microsoft-entra-id.md) |
| 4.5 | Global Secure Access — enriched Microsoft 365 logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-view-enriched-logs) | [connectors/global-secure-access.md](connectors/global-secure-access.md) |
| 4.6 | Integrate Global Secure Access with Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-sentinel-integration) | [connectors/global-secure-access.md](connectors/global-secure-access.md) |

---

## 5. Microsoft Learn — Defender for Cloud / Servers / Containers / IoT / DNS / Storage / SQL / Cloud Apps

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 5.1 | Defender for Cloud data ingestion benefit | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) | [README.md](README.md), [guidance/budget-and-cost-planning.md](guidance/budget-and-cost-planning.md), [procedures/workspace-usage-report.md](procedures/workspace-usage-report.md), [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md), [connectors/windows-security-events.md](connectors/windows-security-events.md), [connectors/syslog-linux.md](connectors/syslog-linux.md), [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md), [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md), [connectors/iis-web-server-logs.md](connectors/iis-web-server-logs.md) |
| 5.2 | Connect Microsoft Defender for Cloud to Sentinel | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-defender-for-cloud) | [connectors/microsoft-defender-for-cloud.md](connectors/microsoft-defender-for-cloud.md) |
| 5.3 | Defender for Cloud — export to SIEM / stream alerts | [learn.microsoft.com](https://learn.microsoft.com/azure/defender-for-cloud/export-to-siem#stream-alerts-to-microsoft-sentinel) | [connectors/microsoft-defender-for-cloud.md](connectors/microsoft-defender-for-cloud.md) |
| 5.4 | Defender for Cloud — attack path analysis | [learn.microsoft.com](https://learn.microsoft.com/azure/defender-for-cloud/concept-attack-path) | [connectors/microsoft-defender-for-cloud.md](connectors/microsoft-defender-for-cloud.md) |
| 5.5 | Defender for Cloud — attack path API | [learn.microsoft.com](https://learn.microsoft.com/azure/defender-for-cloud/attack-path-api) | [connectors/microsoft-defender-for-cloud.md](connectors/microsoft-defender-for-cloud.md) |
| 5.6 | Defender for Containers — introduction | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-introduction) | [connectors/azure-kubernetes-service.md](connectors/azure-kubernetes-service.md) |
| 5.7 | Defender for Storage — introduction | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-storage-introduction) | [connectors/azure-storage-analytics.md](connectors/azure-storage-analytics.md) |
| 5.8 | Defender for SQL — introduction | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-introduction) | [connectors/sql-database-audit.md](connectors/sql-database-audit.md) |
| 5.9 | Defender for DNS — introduction | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-dns-introduction) | [connectors/microsoft-defender-for-dns.md](connectors/microsoft-defender-for-dns.md) |
| 5.10 | Secure your Azure DNS deployment | [learn.microsoft.com](https://learn.microsoft.com/azure/dns/secure-dns) | [connectors/microsoft-defender-for-dns.md](connectors/microsoft-defender-for-dns.md) |
| 5.11 | Azure DNS — metrics and alerts | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/dns/dns-metrics-alerts) | [connectors/microsoft-defender-for-dns.md](connectors/microsoft-defender-for-dns.md) |
| 5.12 | Azure DNS Private Resolver overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview) | [connectors/microsoft-defender-for-dns.md](connectors/microsoft-defender-for-dns.md) |
| 5.13 | Defender for IoT — overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/defender-for-iot/overview) | [connectors/microsoft-defender-for-iot.md](connectors/microsoft-defender-for-iot.md) |
| 5.14 | Defender for IoT — OT sensor deployment path | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/defender-for-iot/ot-deploy/ot-deploy-path) | [connectors/microsoft-defender-for-iot.md](connectors/microsoft-defender-for-iot.md) |
| 5.15 | Defender for IoT — Tutorial: connect with Sentinel | [learn.microsoft.com](https://learn.microsoft.com/azure/defender-for-iot/organizations/iot-solution) | [connectors/microsoft-defender-for-iot.md](connectors/microsoft-defender-for-iot.md) |
| 5.16 | Defender for Cloud Apps — overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/defender-cloud-apps/what-is-defender-for-cloud-apps) | [connectors/microsoft-defender-cloud-apps.md](connectors/microsoft-defender-cloud-apps.md) |
| 5.17 | Defender for Cloud Apps — Cloud Discovery | [learn.microsoft.com](https://learn.microsoft.com/en-us/defender-cloud-apps/set-up-cloud-discovery) | [connectors/microsoft-defender-cloud-apps.md](connectors/microsoft-defender-cloud-apps.md) |
| 5.18 | Defender for Cloud Apps — app governance | [learn.microsoft.com](https://learn.microsoft.com/en-us/defender-cloud-apps/app-governance-manage-app-governance) | [connectors/microsoft-defender-cloud-apps.md](connectors/microsoft-defender-cloud-apps.md) |
| 5.19 | MDCA — Microsoft Sentinel integration (Preview) | [learn.microsoft.com](https://learn.microsoft.com/defender-cloud-apps/siem-sentinel) | [connectors/microsoft-defender-cloud-apps.md](connectors/microsoft-defender-cloud-apps.md) |

---

## 6. Microsoft Learn — Microsoft 365, Purview, Intune & Copilot

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 6.1 | Purview — connect to Sentinel | [learn.microsoft.com](https://learn.microsoft.com/purview/purview-sentinel) | [connectors/microsoft-purview.md](connectors/microsoft-purview.md) |
| 6.2 | Purview — audit solutions overview | [learn.microsoft.com](https://learn.microsoft.com/purview/audit-solutions-overview) | [connectors/office-365.md](connectors/office-365.md) |
| 6.3 | Microsoft Copilot connector (Sentinel reference) | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/data-connectors-reference#microsoft-copilot) | [connectors/copilot-ai-governance.md](connectors/copilot-ai-governance.md) |
| 6.4 | Intune — review logs using Azure Monitor | [learn.microsoft.com](https://learn.microsoft.com/en-us/mem/intune/fundamentals/review-logs-using-azure-monitor) | [connectors/microsoft-intune.md](connectors/microsoft-intune.md) |

---

## 7. Microsoft Learn — Windows security event ID reference

Per-event pages on [learn.microsoft.com/windows/security/threat-protection/auditing/](https://learn.microsoft.com/windows/security/threat-protection/auditing/). All referenced from [connectors/windows-security-events.md](connectors/windows-security-events.md).

**Logon / Kerberos / NTLM:** [4624](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4624), [4625](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4625), [4634](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4634), [4648](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4648), [4672](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4672), [4740](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4740), [4768](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4768), [4769](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4769), [4770](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4770), [4771](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4771), [4776](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4776).

**Account / group management:** [4720](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4720), [4722](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4722), [4724](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4724), [4726](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4726), [4728](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4728), [4731](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4731), [4732](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4732), [4741](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4741), [4742](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4742), [4756](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4756).

**Process / scheduled tasks / services:** [4688](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4688), [4697](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4697), [4698](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4698), [4699](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4699), [4702](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4702).

**Audit / log tampering / policy:** [1102](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-1102), [4719](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4719), [4739](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4739), [4907](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4907).

**Share / filtering platform:** [5140](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5140), [5145](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5145), [5156](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5156).

**Windows Firewall rule changes:** [4946](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4946), [4948](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4948), [4956](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4956).

**Object / handle access:** [4656](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4656), [4663](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4663), [4670](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4670), [4703](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4703), [4706](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4706), [4713](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4713), [4985](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4985), [5136](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5136), [5137](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5137), [5141](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-5141).

**AppLocker (8001/8003/8222):** [Using Event Viewer with AppLocker](https://learn.microsoft.com/windows/security/application-security/application-control/app-control-for-business/applocker/using-event-viewer-with-applocker).

---

## 8. Microsoft Learn — Azure workload logging (Firewall, WAF, Key Vault, Storage, Network, AKS, DevOps)

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 8.1 | Azure Firewall structured logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/firewall/firewall-structured-logs) | [connectors/azure-firewall.md](connectors/azure-firewall.md) |
| 8.2 | Azure Firewall Workbook | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/firewall/firewall-workbook) | [connectors/azure-firewall.md](connectors/azure-firewall.md) |
| 8.3 | Azure WAF — monitoring and logging (Application Gateway) | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-waf-metrics) | [connectors/azure-waf.md](connectors/azure-waf.md) |
| 8.4 | Azure Key Vault — logging overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/key-vault/general/logging) | [connectors/azure-key-vault.md](connectors/azure-key-vault.md) |
| 8.5 | Azure Storage analytics logging | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/storage/common/storage-analytics-logging) | [connectors/azure-storage-analytics.md](connectors/azure-storage-analytics.md) |
| 8.6 | Monitor Azure Blob Storage | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/storage/blobs/monitor-blob-storage) | [connectors/azure-storage-analytics.md](connectors/azure-storage-analytics.md) |
| 8.7 | Azure SQL — auditing overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-sql/database/auditing-overview) | [connectors/sql-database-audit.md](connectors/sql-database-audit.md) |
| 8.8 | Azure SQL — send auditing to Log Analytics | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/azure-sql/database/auditing-log-analytics) | [connectors/sql-database-audit.md](connectors/sql-database-audit.md) |
| 8.9 | Cosmos DB — monitor resource logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/cosmos-db/monitor-resource-logs) | [connectors/sql-database-audit.md](connectors/sql-database-audit.md) |
| 8.10 | VNet Flow Logs — overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/network-watcher/vnet-flow-logs-overview) | [connectors/vnet-flow-logs.md](connectors/vnet-flow-logs.md) |
| 8.11 | NSG Flow Logs — overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/network-watcher/nsg-flow-logs-overview) | [connectors/vnet-flow-logs.md](connectors/vnet-flow-logs.md) |
| 8.12 | Traffic Analytics | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/network-watcher/traffic-analytics) | [connectors/vnet-flow-logs.md](connectors/vnet-flow-logs.md) |
| 8.13 | AKS — monitor cluster with diagnostics | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/aks/monitor-aks) | [connectors/azure-kubernetes-service.md](connectors/azure-kubernetes-service.md) |
| 8.14 | AKS — diagnostic settings categories | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/aks/monitor-aks-reference) | [connectors/azure-kubernetes-service.md](connectors/azure-kubernetes-service.md) |
| 8.15 | AKS — enable control plane logs | [learn.microsoft.com](https://learn.microsoft.com/azure/azure-monitor/containers/kubernetes-monitoring-enable#enable-control-plane-logs-on-an-aks-cluster) | [connectors/azure-kubernetes-service.md](connectors/azure-kubernetes-service.md) |
| 8.16 | Azure DevOps — auditing overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/devops/organizations/audit/azure-devops-auditing) | [connectors/azure-devops.md](connectors/azure-devops.md) |
| 8.17 | Azure DevOps — audit log streaming | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/devops/organizations/audit/auditing-streaming) | [connectors/azure-devops.md](connectors/azure-devops.md) |
| 8.18 | IIS log file formats (legacy) | [learn.microsoft.com](https://learn.microsoft.com/en-us/previous-versions/iis/6.0-sdk/ms525807(v=vs.90)) | [connectors/iis-web-server-logs.md](connectors/iis-web-server-logs.md) |
| 8.19 | PowerShell logging — about_Logging_Windows | [learn.microsoft.com](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_logging_windows) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |
| 8.20 | Sysinternals Sysmon download | [learn.microsoft.com](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |
| 8.21 | AppLocker overview | [learn.microsoft.com](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/applocker/applocker-overview) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |
| 8.22 | Windows Defender Application Control (WDAC) | [learn.microsoft.com](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/wdac) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |

---

## 9. Azure pricing & commercial offers

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 9.1 | Microsoft Sentinel benefit for Microsoft 365 E5 customers | [azure.microsoft.com](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer) | [README.md](README.md), [connectors/README.md](connectors/README.md), [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md), [guidance/budget-and-cost-planning.md](guidance/budget-and-cost-planning.md) |
| 9.2 | Azure Pricing Calculator | [azure.microsoft.com](https://azure.microsoft.com/pricing/calculator/) | [procedures/retention-insights.md](procedures/retention-insights.md) |
| 9.3 | Microsoft Defender portal (security.microsoft.com) | [security.microsoft.com](https://security.microsoft.com/) | [procedures/defender-ama-coverage.md](procedures/defender-ama-coverage.md), [procedures/xdr-data-volume-insights.md](procedures/xdr-data-volume-insights.md) |
| 9.4 | Azure Marketplace — Microsoft Sentinel for GitHub solution | [azuremarketplace.microsoft.com](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/microsoftcorporation1702511680606.sentinel4github) | [connectors/github-enterprise.md](connectors/github-enterprise.md) |

---

## 10. Tools & workbooks (GitHub)

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 10.1 | Defender AMA Coverage workbook | [github.com/mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) | [README.md](README.md), [procedures/defender-ama-coverage.md](procedures/defender-ama-coverage.md), [connectors/microsoft-defender-for-cloud.md](connectors/microsoft-defender-for-cloud.md), [connectors/syslog-linux.md](connectors/syslog-linux.md), [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md), [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 10.2 | XDR tables to Sentinel ingestion calculator (PowerShell) | [github.com/mathijsvermaat/DefenderIngestToSentinel](https://github.com/mathijsvermaat/DefenderIngestToSentinel) | [README.md](README.md), [procedures/xdr-ingestion-calculator.md](procedures/xdr-ingestion-calculator.md), [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 10.3 | XDR Data Volume Insights KQL | [github.com/mathijsvermaat/DefenderIngestToSentinelKQL](https://github.com/mathijsvermaat/DefenderIngestToSentinelKQL) | [procedures/xdr-data-volume-insights.md](procedures/xdr-data-volume-insights.md) |
| 10.4 | Archiving / Basic / Retention workbook (Azure-Sentinel) | [github.com/Azure/Azure-Sentinel](https://github.com/Azure/Azure-Sentinel/blob/master/Workbooks/ArchivingBasicLogsRetention.json) | [README.md](README.md), [procedures/retention-insights.md](procedures/retention-insights.md) |
| 10.5 | Sentinel Health workbook (Azure-Sentinel) | [github.com/Azure/Azure-Sentinel](https://github.com/Azure/Azure-Sentinel/blob/master/Workbooks/SentinelHealth.json) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |
| 10.6 | Sentinel Maturity Assessment Checklist (HTML) | [mathijsvermaat.github.io](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html) | [README.md](README.md) |

> Section 10 is reserved for **executable / deployable** tools — workbooks, scripts, KQL queries, hosted apps. Configuration baselines, vendor documentation, mindmaps, and reading material belong in section 11 below.

---

## 11. Blogs & community resources

| # | Title | Author | URL | Referenced in |
| - | ----- | ------ | --- | ------------- |
| 11.1 | Closing the telemetry gap — how we built the KQL query & workbook | Mathijs Vermaat (LinkedIn) | [linkedin.com](https://www.linkedin.com/pulse/closing-telemetry-gap-how-we-built-kql-query-workbook-mathijs-vermaat-rzfbe/) | [README.md](README.md), [procedures/defender-ama-coverage.md](procedures/defender-ama-coverage.md), [connectors/microsoft-defender-for-cloud.md](connectors/microsoft-defender-for-cloud.md), [connectors/syslog-linux.md](connectors/syslog-linux.md), [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md), [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 11.2 | Cloud Forensics: Forensic Readiness and IR in Azure Virtual Desktop | Microsoft Sentinel blog | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/cloud-forensics-forensic-readiness-and-incident-response-in-azure-virtual-desktop/3835484) | [README.md](README.md), [guidance/forensic-readiness.md](guidance/forensic-readiness.md), [guidance/layered-detection.md](guidance/layered-detection.md), [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 11.3 | Detect, correlate, contain — new Azure Firewall IDPS detections in Sentinel & XDR | Azure Network Security blog | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/azurenetworksecurityblog/detect-correlate-contain-new-azure-firewall-idps-detections-in-microsoft-sentine/4502128) | [connectors/azure-firewall.md](connectors/azure-firewall.md) |
| 11.4 | Microsoft Copilot data connector for Sentinel is now in public preview | Microsoft Sentinel blog | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/the-microsoft-copilot-data-connector-for-microsoft-sentinel-is-now-in-public-pre/4491986) | [connectors/copilot-ai-governance.md](connectors/copilot-ai-governance.md) |
| 11.5 | Data Lake tier ingestion for Defender advanced hunting tables is GA | Microsoft Sentinel blog | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/data-lake-tier-ingestion-for-microsoft-defender-advanced-hunting-tables-is-now-g/4494206) | [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 11.6 | MDE Internals 0x02 — Audit Settings and Telemetry | FalconForce | [falconforce.nl](https://falconforce.nl/blogs/microsoft-defender-for-endpoint-internals-0x02-audit-settings-and-telemetry/) | [guidance/layered-detection.md](guidance/layered-detection.md) |
| 11.7 | MDE Internals 0x03 — Telemetry unreliability and log augmentation | FalconForce | [falconforce.nl](https://falconforce.nl/microsoft-defender-for-endpoint-internals-0x03-mde-telemetry-unreliability-and-log-augmentation/) | [README.md](README.md), [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 11.8 | How to archive Defender logs natively in Defender XDR up to 12 years | Jeffrey Appel | [jeffreyappel.nl](https://jeffreyappel.nl/how-to-archive-defender-logs-natively-in-defender-xdr-up-to-12-years/) | [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 11.9 | Windows Event Log analysis techniques | CyberDefenders | [blog.cyberdefenders.org](https://blog.cyberdefenders.org/2024/02/windows-event-log-analysis-techniques.html) | [README.md](README.md), [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 11.10 | Sentinel data connectors — what actually matters | IT Professor | [itprofessor.cloud](https://www.itprofessor.cloud/sentinel-data-connectors-what-actually-matters/) | [README.md](README.md), [connectors/syslog-linux.md](connectors/syslog-linux.md) |
| 11.11 | The evolution of EDR bypasses — a historical timeline | CovertSwarm | [covertswarm.com](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) | [README.md](README.md), [guidance/layered-detection.md](guidance/layered-detection.md), [connectors/windows-security-events.md](connectors/windows-security-events.md), [connectors/syslog-linux.md](connectors/syslog-linux.md) |
| 11.12 | Shanya — Packer-as-a-Service powering the ransomware ecosystem | Decoded Layer | [decodedlayer.substack.com](https://decodedlayer.substack.com/p/shanya-the-packer-as-a-service-powering) | [guidance/layered-detection.md](guidance/layered-detection.md) |
| 11.13 | EDR Killer tool uses signed kernel driver from forensic software | BleepingComputer | [bleepingcomputer.com](https://www.bleepingcomputer.com/news/security/edr-killer-tool-uses-signed-kernel-driver-from-forensic-software/) | [guidance/layered-detection.md](guidance/layered-detection.md) |
| 11.14 | EDR Telemetry Project | edrtelemetry.com | [edrtelemetry.com](https://www.edrtelemetry.com/) | [guidance/layered-detection.md](guidance/layered-detection.md) |
| 11.15 | Microsoft Security blog — attack matrix for Kubernetes | Microsoft | [microsoft.com](https://www.microsoft.com/en-us/security/blog/2020/04/02/attack-matrix-kubernetes/) | [connectors/azure-kubernetes-service.md](connectors/azure-kubernetes-service.md) |
| 11.16 | SwiftOnSecurity/sysmon-config (Sysmon configuration baseline) | community | [github.com/SwiftOnSecurity/sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |
| 11.17 | olafhartong/sysmon-modular (Sysmon configuration baseline) | Olaf Hartong | [github.com/olafhartong/sysmon-modular](https://github.com/olafhartong/sysmon-modular) | [connectors/windows-forwarded-events.md](connectors/windows-forwarded-events.md) |
| 11.18 | JSCU-NL/logging-essentials (Windows event logging baseline) | AIVD / MIVD (Netherlands) | [github.com/JSCU-NL/logging-essentials](https://github.com/JSCU-NL/logging-essentials) | [connectors/dns-security-logs.md](connectors/dns-security-logs.md) |
| 11.19 | matro7sh/BypassAV mindmap (AV/EDR bypass techniques) | matro7sh | [github.com/matro7sh/BypassAV](https://github.com/matro7sh/BypassAV) | [guidance/layered-detection.md](guidance/layered-detection.md) |
| 11.20 | GitHub Docs — audit log streaming (Enterprise Cloud) | GitHub | [docs.github.com](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/streaming-the-audit-log-for-your-enterprise) | [connectors/github-enterprise.md](connectors/github-enterprise.md) |
| 11.21 | GitHub Docs — GitHub Advanced Security | GitHub | [docs.github.com](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security) | [connectors/github-enterprise.md](connectors/github-enterprise.md) |

---

## 12. Standards & frameworks

| # | Title | URL | Referenced in |
| - | ----- | --- | ------------- |
| 12.1 | Microsoft Cloud Security Benchmark (MCSB) | [learn.microsoft.com](https://learn.microsoft.com/en-us/security/benchmark/azure/overview) | [README.md](README.md), [guidance/frameworks-and-compliance.md](guidance/frameworks-and-compliance.md), [guidance/retention.md](guidance/retention.md) |
| 12.2 | MCSB LT-6 — Configure log storage retention | [learn.microsoft.com](https://learn.microsoft.com/en-us/security/benchmark/azure/mcsb-v2-logging-threat-detection#lt-6) | [guidance/retention.md](guidance/retention.md) |
| 12.3 | Microsoft Secure Future Initiative | [learn.microsoft.com](https://learn.microsoft.com/en-us/security/engineering/secure-future-initiative) | [guidance/frameworks-and-compliance.md](guidance/frameworks-and-compliance.md) |
| 12.4 | SFI — Centralise access to security logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/security/engineering/secure-future-initiative#security-monitoring) | [guidance/frameworks-and-compliance.md](guidance/frameworks-and-compliance.md) |
| 12.5 | Microsoft compliance offerings (SOC 2, ISO 27001, HIPAA, FedRAMP …) | [learn.microsoft.com](https://learn.microsoft.com/en-us/compliance/regulatory/offering-home) | [guidance/frameworks-and-compliance.md](guidance/frameworks-and-compliance.md) |
| 12.6 | ASD ACSC — Best practices for event logging and threat detection | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) | [README.md](README.md), [connectors/README.md](connectors/README.md) and 11 connector pages |
| 12.7 | NSA — Manage Cloud Logs for Effective Threat Hunting (PDF) | [defense.gov](https://media.defense.gov/2024/Mar/07/2003407864/-1/-1/0/CSI_CloudTop10-Logs-for-Effective-Threat-Hunting.PDF) | [connectors/amazon-web-services.md](connectors/amazon-web-services.md), [connectors/google-cloud-platform.md](connectors/google-cloud-platform.md) |
| 12.8 | NIST SP 800-92 — Guide to Computer Security Log Management | [csrc.nist.gov](https://csrc.nist.gov/pubs/sp/800/92/final) | [README.md](README.md), [guidance/retention.md](guidance/retention.md) |
| 12.9 | NIST SP 800-61 Rev. 2 — Computer Security Incident Handling Guide | [csrc.nist.gov](https://csrc.nist.gov/pubs/sp/800/61/r2/final) | [guidance/retention.md](guidance/retention.md) |
| 12.10 | CIS Controls v8 | [cisecurity.org](https://www.cisecurity.org/controls) | [guidance/retention.md](guidance/retention.md) |
| 12.11 | NIS2 Directive — European Parliament | [europarl.europa.eu](https://www.europarl.europa.eu/topics/en/article/20221206STO60677/cybersecurity-how-the-eu-tackles-cyber-threats) | [README.md](README.md), [guidance/frameworks-and-compliance.md](guidance/frameworks-and-compliance.md), [guidance/retention.md](guidance/retention.md) |
| 12.12 | GDPR — General Data Protection Regulation | [gdpr-info.eu](https://gdpr-info.eu/) | [guidance/retention.md](guidance/retention.md) |
| 12.13 | MITRE ATT&CK for ICS | [attack.mitre.org](https://attack.mitre.org/matrices/ics/) | [connectors/microsoft-defender-for-iot.md](connectors/microsoft-defender-for-iot.md) |

---

## 13. Sentinel Ninja (reference documentation)

Auto-generated Sentinel solutions / connectors / tables reference by **Ofer Shezaf (Microsoft)** — [github.com/oshezaf/sentinelninja](https://github.com/oshezaf/sentinelninja).

| # | Connector / topic | URL | Referenced in |
| - | ----------------- | --- | ------------- |
| 13.1 | Sentinel Ninja training (root) | [github.com/oshezaf/sentinelninja](https://github.com/oshezaf/sentinelninja) | [README.md](README.md) |
| 13.2 | Solutions Docs index | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/README.md) | [connectors/README.md](connectors/README.md), [connectors/global-secure-access.md](connectors/global-secure-access.md), [connectors/microsoft-intune.md](connectors/microsoft-intune.md) |
| 13.3 | AWS connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/aws.md) | [connectors/amazon-web-services.md](connectors/amazon-web-services.md) |
| 13.4 | Azure Activity connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azureactivity.md) | [connectors/azure-activity-logs.md](connectors/azure-activity-logs.md) |
| 13.5 | Azure Firewall connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azurefirewall.md) | [connectors/azure-firewall.md](connectors/azure-firewall.md) |
| 13.6 | Azure Key Vault connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azurekeyvault.md) | [connectors/azure-key-vault.md](connectors/azure-key-vault.md) |
| 13.7 | Azure WAF connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/waf.md) | [connectors/azure-waf.md](connectors/azure-waf.md) |
| 13.8 | DNS connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/dns.md) | [connectors/dns-security-logs.md](connectors/dns-security-logs.md) |
| 13.9 | GCP Pub/Sub Audit Logs connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/gcppub-subauditlogs.md) | [connectors/google-cloud-platform.md](connectors/google-cloud-platform.md) |
| 13.10 | Microsoft Copilot connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftcopilot.md) | [connectors/copilot-ai-governance.md](connectors/copilot-ai-governance.md) |
| 13.11 | Defender for Cloud (tenant-based) connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftdefenderforcloudtenantbased.md) | [connectors/microsoft-defender-for-cloud.md](connectors/microsoft-defender-for-cloud.md) |
| 13.12 | Microsoft Threat Protection (Defender XDR) connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftthreatprotection.md) | [connectors/microsoft-defender-xdr.md](connectors/microsoft-defender-xdr.md) |
| 13.13 | Azure Active Directory connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azureactivedirectory.md) | [connectors/microsoft-entra-id.md](connectors/microsoft-entra-id.md) |
| 13.14 | Microsoft Purview Information Protection connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftpurviewinformationprotection.md) | [connectors/microsoft-purview.md](connectors/microsoft-purview.md) |
| 13.15 | Office 365 connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/office365.md) | [connectors/office-365.md](connectors/office-365.md) |
| 13.16 | Syslog (via AMA) connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/syslogama.md) | [connectors/syslog-linux.md](connectors/syslog-linux.md) |
| 13.17 | CEF (via AMA) connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/cefama.md) | [connectors/third-party-network-appliances.md](connectors/third-party-network-appliances.md) |
| 13.18 | Threat Intelligence connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/threatintelligence.md) | [connectors/threat-intelligence.md](connectors/threat-intelligence.md) |
| 13.19 | Azure NSG connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azurensg.md) | [connectors/vnet-flow-logs.md](connectors/vnet-flow-logs.md) |
| 13.20 | Windows Security Events connector | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/windowssecurityevents.md) | [connectors/windows-security-events.md](connectors/windows-security-events.md) |
| 13.21 | SentinelHealth table | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/tables/sentinelhealth.md) | [connectors/sentinel-health.md](connectors/sentinel-health.md) |

---

[← Back to Sentinel Maturity Model](README.md)
