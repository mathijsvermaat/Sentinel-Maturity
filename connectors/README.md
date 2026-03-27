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

---

## Tier 2 — Extended Visibility

Additional connectors for customers with higher maturity requirements. Connectors marked *conditional* only apply when the relevant product or cloud is in use. Tier 2 is aligned with the [ASD ACSC Best Practices for Event Logging and Threat Detection](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) logging priorities.

### Cloud Security Posture

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Defender for Cloud](microsoft-defender-for-cloud.md) | Cloud workload alerts, security recommendations, regulatory compliance | Yes — SecurityAlert is free |

### Network Visibility

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Azure Firewall](azure-firewall.md) | Perimeter firewall rules, threat intelligence, DNS proxy | No |
| [Azure WAF (Application Gateway / Front Door)](azure-waf.md) | Layer 7 web application attack detection (OWASP Top 10) | No |
| [VNet Flow Logs & Traffic Analytics](nsg-flow-logs.md) | East-west network traffic metadata, lateral movement detection | No |
| [Microsoft Global Secure Access](global-secure-access.md) | Cloud-delivered web proxy and ZTNA (Entra Internet/Private Access) | No — *conditional* |
| [DNS Security Logs](dns-security-logs.md) | Endpoint and infrastructure DNS query logging for C2 and tunnelling detection | No |
| [Third-Party Network & Proxy Appliances (CEF/Syslog)](third-party-network-appliances.md) | Non-Microsoft firewalls, proxies, IDS/IPS — Palo Alto, Fortinet, Zscaler, etc. | 500 MB/day via DfS P2 — *conditional* |

### Data Protection & Governance

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Purview (Information Protection & DLP)](microsoft-purview.md) | Sensitivity labels, data loss prevention events | No — *conditional* |
| [Azure Key Vault](azure-key-vault.md) | Secrets, keys, and certificate access audit trail | No |
| [Microsoft Copilot / AI Governance](copilot-ai-governance.md) | AI interaction auditing and governance for Copilot and Azure OpenAI | No — *conditional* |

### Endpoint Compliance

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Microsoft Intune (Endpoint Management)](microsoft-intune.md) | Device compliance, MDM/MAM events, admin audit trail | Partial — audit/operational logs free |

### Detection Enrichment

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Threat Intelligence Platforms](threat-intelligence.md) | IOC matching — IPs, domains, URLs, file hashes from TI feeds | Yes — free data source |

### Multi-Cloud

| Connector | Key Focus | Free Ingestion |
|:----------|:----------|:---------------|
| [Amazon Web Services (AWS)](amazon-web-services.md) | CloudTrail, GuardDuty, VPC Flow Logs — AWS control plane and threat detection | No — *conditional* |
| [Google Cloud Platform (GCP)](google-cloud-platform.md) | GCP Audit Logs — GCP control plane and IAM activity | No — *conditional* |

---

## Template

Use the [connector template](_TEMPLATE.md) when creating pages for new connectors (Tier 1, Tier 2, Tier 3).

---

[← Back to Sentinel Maturity Model](../README.md)
