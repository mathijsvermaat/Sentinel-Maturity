# Google Cloud Platform (GCP)

**Tier:** 2 (Extended Visibility) · **Connector type:** Multi-cloud · **Free ingestion:** No · **Conditional:** Only applicable with GCP workloads

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

For customers with workloads in Google Cloud Platform, **Cloud Audit Logs** are the equivalent of Azure Activity Logs and AWS CloudTrail — they capture the control plane audit trail for all GCP API calls, IAM changes, and resource modifications. Without these logs in Sentinel, GCP is a blind spot in your security operations.

The same ACSC cloud logging priorities that apply to Azure and AWS apply to GCP. If your organisation operates in GCP, these logs complete your multi-cloud visibility.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **GCP Cloud Audit Logs (Admin Activity)** | Always enabled, free, cannot be disabled — all admin API calls |
| **GCP Cloud Audit Logs (Data Access)** | Must be explicitly enabled — API calls that read data or metadata. May incur GCP logging cost at high volume |
| **Google Security Command Center** | GCP-native threat detection findings — equivalent of GuardDuty / Defender for Cloud |

> [!NOTE]
> GCP Audit Logs are **not** a free data source in Sentinel. Sentinel ingestion cost applies. GCP Admin Activity audit logs are free within GCP; Data Access audit logs may incur GCP logging charges.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **GCPAuditLogs** | All GCP Cloud Audit Logs — Admin Activity, Data Access, System Events, Policy Denied | Analytics: 90d / Lake: 365d | **Core GCP control plane audit trail.** Equivalent of AzureActivity and AWSCloudTrail. Detects IAM privilege escalation, firewall rule changes, resource deployment, and data access anomalies. MCSB LT-3. | Proves exactly which GCP API calls were made, by which principal, from which IP, and when. The authoritative evidence for GCP infrastructure investigations. | Service account key created for existing service account (T1098.001), VPC firewall rule opened to 0.0.0.0/0 (T1562.007), IAM policy binding granting Owner role (T1098) |

---

## Example Detections

### IAM and Access

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| IAM Owner binding added | GCPAuditLogs | T1098 | SetIamPolicy granting Owner or Editor role at project/org level |
| Service account key created | GCPAuditLogs | T1098.001 | CreateServiceAccountKey — new credentials for service account (lateral movement risk) |
| Service account impersonation | GCPAuditLogs | T1550 | GenerateAccessToken or SignBlob for service account impersonation |
| Console login from unusual location | GCPAuditLogs | T1078 | Admin Activity showing authentication from geo-anomalous IP |

### Resource Security

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| VPC firewall rule allowing all inbound | GCPAuditLogs | T1562.007 | CreateFirewall or UpdateFirewall with 0.0.0.0/0 source range on sensitive ports |
| Cloud Storage bucket made public | GCPAuditLogs | T1530 | SetIamPolicy on storage bucket granting allUsers or allAuthenticatedUsers access |
| Audit logging disabled | GCPAuditLogs | T1562.008 | SetIamPolicy or UpdateSink removing audit log exports — attacker covering tracks |
| Compute instance created in unusual region | GCPAuditLogs | T1496 | Instance creation in a region not used by the organisation — potential crypto mining |

### Data Access

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Bulk BigQuery export | GCPAuditLogs (Data Access) | T1530 | Large query or export from BigQuery tables containing sensitive data |
| Secret Manager access from new principal | GCPAuditLogs | T1552.004 | AccessSecretVersion from a service account or user not seen before |
| KMS key usage anomaly | GCPAuditLogs | T1552 | Decrypt operations from unexpected services or principals |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-3** Enable logging for security investigation | GCP Audit Logs provide the control plane audit trail for GCP |
| **LT-1** Enable threat detection | GCP Security Command Center findings complement Sentinel analytics |
| **IM-1** Centralise identity management | IAM activity logging supports cross-cloud identity visibility |
| **PA-7** Follow just enough administration | IAM policy binding changes tracked for least-privilege enforcement |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-2 (audit events) and AC-2 (account management), CIS Controls v8 8.2 (collect audit logs), and ASD ACSC cloud logging priorities #3–#7 (cloud user accounts, administrative changes, security principals, authentication, and cloud service logs).

---

## Important Considerations

### Connector Architecture

The GCP Sentinel connector uses Pub/Sub for log delivery:

```
[GCP Audit Logs] → [Log Router / Sink] → [Pub/Sub Topic] → [Sentinel Connector] → [GCPAuditLogs table]
```

- Create a **log sink** at the GCP organisation or project level to route audit logs to Pub/Sub
- The Sentinel connector authenticates to GCP via **Workload Identity Federation** (recommended) or a service account key
- For multi-project setups, create an **organisation-level sink** to aggregate all projects

### Admin Activity vs. Data Access Logs

| Log Type | What It Captures | GCP Cost | Recommendation |
|:---------|:-----------------|:---------|:---------------|
| **Admin Activity** | Resource CRUD, IAM changes, config modifications | **Free** (always enabled) | **Always forward to Sentinel** — low volume, high value |
| **Data Access** | Data read/write/metadata operations on GCP resources | May incur GCP logging charges at high volume | Enable selectively for critical resources (BigQuery, Secret Manager, Cloud Storage) |
| **System Event** | GCP-initiated system actions (live migration, etc.) | Free | Forward for operational context |
| **Policy Denied** | Access denied by organisation policies or IAM | Free | Forward for security investigation |

Start with Admin Activity + Policy Denied; add Data Access for crown-jewel resources.

### Federated Access (Entra ID → GCP)

If users authenticate to GCP via Entra ID federation (Cloud Identity / Workspace SSO), the authentication appears in Entra ID SigninLogs (Tier 1) and the subsequent GCP actions appear in GCPAuditLogs. Cross-reference both tables for complete federated user investigation.

---

## Notes

- If your organisation has no GCP workloads, skip this connector entirely
- GCP Admin Activity audit logs are always enabled and free within GCP — the only cost is Sentinel ingestion
- Admin Activity log volume is typically low — a few hundred MB to a few GB/day for most organisations
- For **Defender for Cloud multi-cloud CSPM**, GCP security findings already flow through `SecurityAlert` — see [Defender for Cloud](microsoft-defender-for-cloud.md)
- The [Microsoft Sentinel GCP connector](https://learn.microsoft.com/en-us/azure/sentinel/connect-google-cloud-platform) documentation provides step-by-step setup instructions

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor GCPAuditLogs ingestion volumes | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

Community and third-party resources that support the guidance on this page.

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — cloud logging priorities apply equally to all cloud providers including GCP | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |
| Manage Cloud Logs for Effective Threat Hunting | NSA | NSA guidance on cloud log management including GCP audit logging best practices | [defense.gov (PDF)](https://media.defense.gov/2024/Mar/07/2003407864/-1/-1/0/CSI_CloudTop10-Logs-for-Effective-Threat-Hunting.PDF) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
