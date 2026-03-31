# GitHub Enterprise

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

GitHub Enterprise audit logs capture **organisation-level operations**: repository access, Actions workflow runs, secret scanning alerts, code scanning results, team and permission management, and enterprise administration. For organisations using GitHub as their primary code platform, these logs are essential for detecting supply chain attacks and code compromise.

GitHub is often the central nervous system of software development — it holds source code, CI/CD workflows, secrets, and deployment configurations. Monitoring GitHub audit logs detects unauthorized access to code, malicious workflow modifications, leaked secrets, and insider threat activity.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **GitHub Enterprise Cloud** | Enterprise audit log streaming to Sentinel via the GitHub connector |
| **GitHub Advanced Security** | Secret scanning, code scanning, and Dependabot alerts — additional security event data |

> [!NOTE]
> Audit log streaming requires **GitHub Enterprise Cloud**. GitHub Enterprise Server (self-hosted) requires a different data forwarding approach. The Sentinel Content Hub includes a GitHub solution with pre-built analytics rules.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **GitHubAuditLogPolling** | Enterprise audit events — repo access, Actions runs, admin operations, team changes, SSO events | Analytics: 90d / Lake: 365d | Primary audit trail for GitHub platform security — the only source for detecting code repository and CI/CD compromise | Reconstructs attacker actions in GitHub — which repos were cloned, what Actions workflows were modified, what secrets were exposed | Workflow file modified to exfiltrate secrets (T1195.002) |
| **GitHubAuditEntry** (via API) | Detailed audit records including actor, action, and context for all enterprise operations | Analytics: 90d / Lake: 365d | Enriched audit data with full context — actor details, geo-location, and affected resources | Provides complete event context for investigation — matches actor to action with precise timestamps | Repository visibility changed from private to public (T1567) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Workflow file modified in protected branch | GitHubAuditLogPolling | T1195.002 | GitHub Actions workflow YAML changed — potential supply chain backdoor |
| Repository cloned by unusual actor | GitHubAuditLogPolling | T1213 | Repository clone event from a user or machine not in the normal contributor set |
| Secret scanning alert dismissed | GitHubAuditLogPolling | T1552 | Leaked secret detected by scanning but dismissed by a user — potential cover-up or negligence |
| Outside collaborator added to private repo | GitHubAuditLogPolling | T1199 | External user granted access to a private repository — trust boundary expansion |
| Personal Access Token created with broad scope | GitHubAuditLogPolling | T1528 | PAT with repo, admin, or write-all scope created — high-risk credential |
| Repository visibility changed to public | GitHubAuditLogPolling | T1567 | Private repository made public — potential data leak of source code or secrets |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **DS-6** Enforce security of workloads through development lifecycle | Monitors the code repository and CI/CD pipeline for supply chain threats |
| **LT-3** Enable logging for security investigation | GitHub audit logs provide the investigation trail for code and pipeline compromise |
| **IM-2** Protect identity and authentication systems | Monitors GitHub authentication, PAT creation, and SSO events |

---

## Important Considerations

- **Enterprise Cloud required:** Audit log streaming is only available for GitHub Enterprise Cloud organisations — not GitHub Free or Team plans
- **GitHub Advanced Security:** If licensed, secret scanning, code scanning, and Dependabot alerts provide additional security signals
- **Actions workflow security:** GitHub Actions workflows are a primary supply chain attack vector — monitor `.github/workflows/` file changes
- **Connector setup:** The Sentinel GitHub connector uses a GitHub App or PAT for authentication — ensure the credential has enterprise admin read access

---

## Notes

- GitHub and Azure DevOps monitoring can be deployed together for organisations using both platforms
- Pair with Entra ID sign-in logs (Tier 1) for SSO correlation — map GitHub audit events to identity-level authentication context
- The GitHub Advanced Security alerts (code scanning, secret scanning, Dependabot) can be forwarded to Sentinel for alerting and response

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify GitHub audit log volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| GitHub audit log streaming | [GitHub Docs](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/streaming-the-audit-log-for-your-enterprise) |
| Connect GitHub to Sentinel | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/github-enterprise-audit-log) |
| GitHub Enterprise Sentinel solution | [Content Hub](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/microsoftcorporation1702511680606.sentinel4github) |
| GitHub Advanced Security | [GitHub Docs](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
