# Data Connectors

This section contains the detailed guidance for each data connector, organised by tier.

---

## Tier 1 — Bare Minimum

Every Microsoft Sentinel deployment should have these connectors enabled.

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Defender XDR](microsoft-defender-xdr.md) | Endpoint, email, identity, and cloud app telemetry from M365 E5 | Yes — Analytics tier via E5 grant |
| [Microsoft Entra ID](microsoft-entra-id.md) | Authentication, directory changes, identity risk events | Yes — free data source |
| [Office 365](office-365.md) | Exchange, SharePoint, and Teams audit activity | Yes — free data source |
| [Azure Activity Logs](azure-activity-logs.md) | Azure control plane operations across all subscriptions | Yes — free data source |
| [Windows Security Events](windows-security-events.md) | Windows server authentication, process, and account management events | 500 MB/day/server via Defender for Servers P2 |
| [Syslog for Linux](syslog-linux.md) | Linux server authentication and system logging | 500 MB/day/server via Defender for Servers P2 |
| [Sentinel Health & Audit Diagnostics](sentinel-health.md) | Data connector health, analytics rule execution, automation monitoring, rule change auditing | Yes — SentinelHealth is not billable |

---

## Tier 2 — Extended Visibility

Additional connectors for customers with higher maturity requirements. Connectors marked *conditional* only apply when the relevant product or cloud is in use. Tier 2 is aligned with the [ASD ACSC Best Practices for Event Logging and Threat Detection](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) logging priorities.

### Cloud Security Posture

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Defender for Cloud](microsoft-defender-for-cloud.md) | Cloud workload alerts, security recommendations, regulatory compliance | Yes — SecurityAlert is free |

### Data Protection & Governance

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Azure Key Vault](azure-key-vault.md) | Secrets, keys, and certificate access audit trail | No |
| [Microsoft Copilot / AI Governance](copilot-ai-governance.md) | AI interaction auditing and governance for Copilot and Azure OpenAI | No — *conditional* |
| [Microsoft Purview (Information Protection & DLP)](microsoft-purview.md) | Sensitivity labels, data loss prevention events | No — *conditional* |

### Detection Enrichment

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Threat Intelligence Platforms](threat-intelligence.md) | IOC matching — IPs, domains, URLs, file hashes from TI feeds | Yes — free data source |

### Endpoint Compliance

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Intune (Endpoint Management)](microsoft-intune.md) | Device compliance, MDM/MAM events, admin audit trail | Partial — audit/operational logs free |

### Identity & Access (Extended)

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Entra ID Protection (Extended Risk Events)](microsoft-entra-id-protection.md) | Detailed risk detections for user and workload identities | Yes — free data source |
| Third-Party Identity | Non-Microsoft identity providers and PAM solutions (Okta, CyberArk, Ping Identity, BeyondTrust) via API or CEF/Syslog | No — *conditional* |

### Multi-Cloud

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Amazon Web Services (AWS)](amazon-web-services.md) | CloudTrail, GuardDuty, VPC Flow Logs — AWS control plane and threat detection | No — *conditional* |
| [Google Cloud Platform (GCP)](google-cloud-platform.md) | GCP Audit Logs — GCP control plane and IAM activity | No — *conditional* |

### Network Visibility

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Azure Firewall](azure-firewall.md) | Perimeter firewall rules, threat intelligence, DNS proxy | No |
| [Azure WAF (Application Gateway / Front Door)](azure-waf.md) | Layer 7 web application attack detection (OWASP Top 10) | No |
| [DNS Security Logs](dns-security-logs.md) | Endpoint and infrastructure DNS query logging for C2 and tunnelling detection | No |
| [Microsoft Global Secure Access](global-secure-access.md) | Cloud-delivered web proxy and ZTNA (Entra Internet/Private Access) | No — *conditional* |
| [VNet Flow Logs & Traffic Analytics](nsg-flow-logs.md) | East-west network traffic metadata, lateral movement detection | No |
| [Third-Party Network & Proxy Appliances (CEF/Syslog)](third-party-network-appliances.md) | Non-Microsoft firewalls, proxies, IDS/IPS — Palo Alto, Fortinet, Zscaler, etc. | 500 MB/day via DfS P2 — *conditional* |

---

## Tier 3 — Advanced / Specialised

Full-spectrum monitoring for OT/IoT, DevOps, databases, custom applications, and advanced infrastructure. These connectors are for mature organisations that have completed Tier 1 and Tier 2 and need specialised visibility.

### Application & Workload Security

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [IIS / Web Server Logs](iis-web-server-logs.md) | HTTP request logs from Windows web servers — application-layer attack detection | No (500 MB/day via DfS P2) |
| [Microsoft Defender for Cloud Apps (Standalone)](microsoft-defender-cloud-apps.md) | Shadow IT discovery, app governance — beyond XDR CloudAppEvents | No |
| [SAP](sap.md) | SAP audit logs, security events, change documents — ERP monitoring | No — separately licensed |
| [SQL / Database Audit Logs](sql-database-audit.md) | Azure SQL, Managed Instance, and Cosmos DB data-plane audit trail | No |
| Third-Party Applications | Non-Microsoft SaaS and business applications (ServiceNow, Salesforce, Workday) via API or CEF/Syslog | No — *conditional* |

### Collaboration & Communication

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Teams (Advanced)](microsoft-teams-advanced.md) | Advanced Teams governance — external access, guest activity, app permissions | Yes — via Office 365 connector |
| Third-Party Collaboration | Non-Microsoft collaboration platforms (Slack, Zoom, Cisco Webex) via API or webhook | No — *conditional* |

### Custom Applications (Crown Jewels)

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Custom Applications](custom-applications.md) | Business-critical application logs via DCR, Log Analytics API, or Logstash | No |

### DevOps & CI/CD Security

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Azure DevOps](azure-devops.md) | Pipeline, repo, and permission audit logs — supply chain security | No |
| [GitHub Enterprise](github-enterprise.md) | Enterprise audit logs — repo access, Actions workflow runs, secret scanning | No |
| Third-Party DevOps | Non-Microsoft DevOps platforms (GitLab, Jenkins, Bitbucket) via API or webhook | No — *conditional* |

### Infrastructure & Platform

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Azure Kubernetes Service (AKS) Audit](azure-kubernetes-service.md) | Kubernetes API server audit — pod, RBAC, secrets, and namespace operations | No |
| [Azure Storage Analytics](azure-storage-analytics.md) | Blob, File, Queue, and Table access logs — data exfiltration detection | No |
| [Microsoft Defender for DNS (Azure DNS)](microsoft-defender-for-dns.md) | Azure-level DNS query logs — C2 and tunnelling detection for cloud-native workloads | No |
| [Windows Forwarded Events (Advanced)](windows-forwarded-events.md) | PowerShell ScriptBlock, WMI, Sysmon, AppLocker/WDAC — advanced endpoint telemetry | No (500 MB/day via DfS P2) |

### OT / IoT Security

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Defender for IoT](microsoft-defender-for-iot.md) | OT/IoT network monitoring — ICS, SCADA, building management, medical devices | Yes — SecurityAlert is free |
| Third-Party OT / IoT | Non-Microsoft OT/IoT platforms (Claroty, Nozomi Networks, Armis) via CEF/Syslog or native connector | No — *conditional* |

---

## Community Reference

For a comprehensive auto-generated reference covering all 495+ Sentinel solutions, 536 data connectors, 2,000+ tables, and 6,000+ content items (workbooks, analytic rules, hunting queries, playbooks), see:

> **[Sentinel Ninja — Solutions Docs](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/README.md)** by [Ofer Shezaf](https://github.com/oshezaf) (Principal Product Manager, Microsoft Sentinel)

Each connector page in this maturity model includes a per-connector link to the relevant Sentinel Ninja reference in its **References** section.

---

## Template

Use the [connector template](_TEMPLATE.md) when creating pages for new connectors (Tier 1, Tier 2, Tier 3).

---

[← Back to Sentinel Maturity Model](../README.md)
