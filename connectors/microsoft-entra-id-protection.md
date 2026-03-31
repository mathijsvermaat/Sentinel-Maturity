# Microsoft Entra ID Protection (Extended Risk Events)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes — free data source (via Entra ID connector diagnostic settings)

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

Microsoft Entra ID Protection extends the Tier 1 Entra ID connector with **detailed risk event data** for both user and workload identities. While the base Entra ID connector captures sign-in logs and audit events, the Protection tables provide granular risk detection signals — the *why* behind identity risk scores.

This data answers questions that sign-in logs alone cannot: *Why was this account flagged as risky? What specific risk detection triggered? Are service principals (workload identities) being abused?* These tables are critical for organisations using Conditional Access risk-based policies and need to audit or investigate the underlying detections.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Entra ID P2 (included in E5)** | Risk detections for user accounts — leaked credentials, atypical travel, unfamiliar sign-in properties |
| **Workload Identities Premium** | Risk detections for service principals — anomalous credential usage, suspicious application activity |

> [!NOTE]
> These tables are enabled via the same Entra ID diagnostic settings connector used in Tier 1. The additional log categories (`RiskyUsers`, `UserRiskEvents`, `RiskyServicePrincipals`, `ServicePrincipalRiskEvents`) must be explicitly selected in the diagnostic settings configuration.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AADRiskyUsers** | Users flagged as risky with risk level and state | Analytics: 90d / Lake: 365d | Tracks which users are considered compromised by Entra ID Protection — feeds Conditional Access risk policies | During investigation, confirms whether the compromised account was already flagged as risky before the incident | Risky user not remediated within SLA (T1078) |
| **AADUserRiskEvents** | Individual risk detections per user — leaked creds, atypical travel, anonymous IP | Analytics: 90d / Lake: 365d | Granular risk signal data — explains *why* an account was flagged | Proves the specific detection that triggered the risk — essential for incident timeline reconstruction | Leaked credentials detection from dark web monitoring (T1589.001) |
| **AADRiskyServicePrincipals** | Service principals flagged as risky | Analytics: 90d / Lake: 365d | Workload identity risk — detects compromised app registrations and managed identities | Identifies which service principals were behaving anomalously — critical for supply chain and app compromise investigations | Risky service principal with anomalous credential activity (T1078.004) |
| **ServicePrincipalRiskEvents** | Individual risk detections per service principal | Analytics: 90d / Lake: 365d | Provides the specific risk signal for workload identities — anomalous sign-in patterns, suspicious API calls | Maps the exact detection that flagged the service principal — proves timeline of compromise | Service principal accessing resources from unusual geography (T1078.004) |

---

## Example Detections

### User Risk Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Leaked credentials not remediated | AADRiskyUsers, AADUserRiskEvents | T1589.001 | User flagged with leaked credentials risk but risk state remains "atRisk" beyond remediation SLA |
| Multiple risk detections for single user | AADUserRiskEvents | T1078 | Multiple distinct risk detection types triggered for the same user within a short window — indicates active compromise |
| Atypical travel followed by data access | AADUserRiskEvents, SigninLogs | T1078, T1537 | Atypical travel risk detection followed by successful sign-in and resource access |

### Workload Identity Risk Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Risky service principal accessing Key Vault | AADRiskyServicePrincipals, AKVAuditLogs | T1078.004, T1552.004 | Service principal flagged as risky that subsequently accessed Key Vault secrets |
| Anomalous service principal credential usage | ServicePrincipalRiskEvents | T1098.001 | Service principal using credentials from an unusual location or at unusual times |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **IM-1** Use centralized identity and authentication system | Risk events validate the health of the centralized identity system — flags when it's being abused |
| **IM-3** Manage application identities securely and automatically | Workload identity risk detections (AADRiskyServicePrincipals) directly monitor application identity security |
| **IR-4** Detection and analysis — incident response | Risk event data provides the triggering signal for identity-based incidents |
| **IR-5** Prioritize incidents | Risk levels (low/medium/high) from Entra ID Protection feed incident prioritisation |

---

## Important Considerations

- **Enable all risk log categories:** The Entra ID diagnostic settings connector must have `RiskyUsers`, `UserRiskEvents`, `RiskyServicePrincipals`, and `ServicePrincipalRiskEvents` categories enabled — they are **not** enabled by default
- **Workload Identities Premium license:** Risk detections for service principals require the Workload Identities Premium add-on (not included in standard E5)
- **Risk remediation workflow:** These tables are most valuable when paired with Conditional Access risk-based policies — the risk data explains policy enforcement decisions
- **Volume:** Risk event volume is typically low (tens to hundreds of events per day for most organisations) — cost impact is minimal

---

## Notes

- These tables enrich the Tier 1 Entra ID connector data — they do not replace it
- Organisations using Conditional Access with risk-based policies should consider these tables essential for auditing enforcement decisions
- The `AADUserRiskEvents` table often surfaces leaked credentials from dark web monitoring before any active attack occurs — early warning signal

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify Entra ID Protection table volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Microsoft Entra ID Protection overview | [Learn](https://learn.microsoft.com/en-us/entra/id-protection/overview-identity-protection) |
| Risky users and risk detections | [Learn](https://learn.microsoft.com/en-us/entra/id-protection/howto-identity-protection-investigate-risk) |
| Workload identity risk | [Learn](https://learn.microsoft.com/en-us/entra/id-protection/concept-workload-identity-risk) |
| Entra ID diagnostic settings | [Learn](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/howto-integrate-activity-logs-with-azure-monitor-logs) |
| Sentinel Ninja — Microsoft Entra ID | [GitHub](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/Microsoft%20Entra%20ID.md) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
