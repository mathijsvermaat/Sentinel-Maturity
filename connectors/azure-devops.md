# Azure DevOps

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party · **Free ingestion:** No

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

Azure DevOps audit logs capture **control plane operations** across your DevOps environment: repository access, pipeline executions, permission changes, service connection modifications, and project-level administration. In the era of supply chain attacks (SolarWinds, Codecov), monitoring CI/CD platforms is critical.

An attacker with access to your DevOps environment can modify build pipelines to inject malicious code, steal service connection credentials to access production infrastructure, or create backdoor accounts. Azure DevOps audit logs are the sole detection source for these activities.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Azure DevOps (any plan)** | Audit log streaming via Azure DevOps diagnostic settings |
| **Microsoft Sentinel** | Analytics rules and hunting queries for DevOps security monitoring |

> [!NOTE]
> Azure DevOps audit logs are available for all Azure DevOps organisations. Streaming to Sentinel requires enabling audit log streaming in the Azure DevOps organisation settings. Content Hub includes a **DevOps** solution with pre-built analytics rules.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AzureDevOpsAuditing** | Azure DevOps audit events — repo access, pipeline runs, permission changes, service connections, PAT usage | Analytics: 90d / Lake: 365d | Primary audit trail for CI/CD platform security — captures all administrative and security-relevant operations | Reconstructs attacker actions in DevOps — which repos were accessed, what pipelines were modified, what credentials were exposed | Pipeline modified to exfiltrate secrets (T1195.002) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Pipeline definition modified | AzureDevOpsAuditing | T1195.002 | Build or release pipeline YAML/definition changed — potential supply chain attack vector |
| Service connection created or modified | AzureDevOpsAuditing | T1098.001 | New service connection added or existing one modified — could grant access to production infrastructure |
| Personal Access Token (PAT) created with broad scope | AzureDevOpsAuditing | T1528 | PAT created with full access scope — high-risk credential that bypasses MFA |
| External user added to organisation | AzureDevOpsAuditing | T1199 | User from outside the organisation invited to DevOps — potential trusted relationship abuse |
| Repository permissions changed | AzureDevOpsAuditing | T1098 | Repository-level permissions modified — could grant read access to sensitive code or secrets |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **DS-6** Enforce security of workloads through development lifecycle | Directly monitors the development lifecycle for supply chain compromises |
| **LT-3** Enable logging for security investigation | DevOps audit logs are essential for investigating CI/CD pipeline compromises |
| **IM-2** Protect identity and authentication systems | Monitors PAT creation, service connection credentials, and identity operations in DevOps |

---

## Important Considerations

- **Enable audit streaming:** In Azure DevOps → Organisation Settings → Auditing → Streams, configure a stream to your Log Analytics workspace
- **Pipeline agent security:** Consider monitoring pipeline agent activity alongside audit logs for a complete CI/CD security picture
- **Secret scanning:** Pair with GitHub Advanced Security for Azure DevOps (GHAzDO) for code-level secret detection
- **Supply chain framework:** Align DevOps monitoring with SLSA and NIST SSDF frameworks for comprehensive supply chain security

---

## Notes

- Azure DevOps monitoring is especially important for organisations that deploy to production directly from pipelines — a compromised pipeline means compromised production
- Consider paired monitoring: DevOps audit logs + Azure Activity Logs (Tier 1) for end-to-end deployment chain visibility
- The Azure DevOps Content Hub solution includes pre-built analytics rules for common DevOps security scenarios

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify DevOps audit log volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Azure DevOps auditing overview | [Learn](https://learn.microsoft.com/en-us/azure/devops/organizations/audit/azure-devops-auditing) |
| Stream audit logs to Sentinel | [Learn](https://learn.microsoft.com/en-us/azure/devops/organizations/audit/auditing-streaming) |
| Azure DevOps Sentinel solution | [Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/azure-devops) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
