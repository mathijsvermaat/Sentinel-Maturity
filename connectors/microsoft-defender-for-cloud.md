# Microsoft Defender for Cloud

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes — SecurityAlert table is a free data source

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

Microsoft Defender for Cloud is Microsoft's cloud-native application protection platform (CNAPP). It provides security posture management (CSPM) and workload protection (CWP) across Azure, AWS, and GCP. The Sentinel connector streams **security alerts** and optionally **recommendations** and **regulatory compliance** data into your workspace.

This connector adds the **"so what"** layer on top of the raw telemetry from Tier 1 connectors. While Azure Activity Logs tell you *what changed*, and Defender XDR tells you *what ran*, Defender for Cloud tells you *what's misconfigured and what's under active attack* — from VM brute-force to storage account exfiltration to container escape attempts.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Defender for Cloud (Free tier)** | Security recommendations, Secure Score — limited alerts |
| **Defender for Cloud (workload plans)** | Full threat detection alerts — Defender for Servers, Storage, SQL, Containers, Key Vault, Resource Manager, DNS, App Service |

> [!NOTE]
> The `SecurityAlert` table from Defender for Cloud is a **free data source** in Sentinel. Alerts cost nothing to ingest. Recommendations and compliance data (`SecurityRecommendation`, `SecurityRegulatoryCompliance`) do incur ingestion cost.

---

## Tables and Rationale

### Alert Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SecurityAlert** | Security alerts from all Defender for Cloud workload plans | Analytics: 90d / Lake: 365d | Core cloud threat detection — covers brute-force, malware, anomalous access, container escapes, storage exfiltration, and SQL injection attempts. MCSB LT-1. | Complete alert history — reconstruct which cloud resources were targeted, when attacks were detected, and whether remediation was performed. Essential for breach timeline analysis. | Brute-force on VM (T1110), suspicious storage access (T1530), container escape (T1611) |
| **SecurityIncident** | Incidents that aggregate related security alerts | Analytics: 90d / Lake: 365d | Incident grouping provides attack campaign context beyond individual alerts. | Correlate related alerts into attack campaigns — proves that seemingly unrelated alerts were part of the same kill chain | Multi-stage attack campaign across multiple Azure resources |

### Posture Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SecurityRecommendation** | Security posture recommendations and compliance state | Analytics: 90d / Lake: 365d | Tracks security drift over time — proves that a misconfiguration existed before a breach. MCSB GS-3. | Post-incident audit — proves whether a security recommendation was outstanding at the time of compromise, establishing root cause as unactioned posture findings | Unactioned critical recommendation preceding breach |
| **SecurityRegulatoryCompliance** | Regulatory compliance assessment results (MCSB, CIS, PCI-DSS, etc.) | Analytics: 90d / Lake: 365d | Compliance audit trail — proves regulatory posture at any point in time. | Audit evidence — provides point-in-time compliance state that can be produced for regulators, auditors, or insurance claims | Compliance drift — resource moved from compliant to non-compliant |

---

## Example Detections

### Cloud Workloads

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| VM brute-force attack | SecurityAlert | T1110 | Defender for Servers detects repeated failed login attempts from external IPs |
| Suspicious storage account access | SecurityAlert | T1530 | Defender for Storage detects anomalous blob access patterns or access from Tor exit nodes |
| SQL injection attempt | SecurityAlert | T1190 | Defender for SQL detects malicious SQL queries targeting Azure SQL databases |
| Container escape attempt | SecurityAlert | T1611 | Defender for Containers detects privilege escalation from container to host node |
| Fileless attack on VM | SecurityAlert | T1059 | Defender for Servers detects in-memory attack execution without file drops |
| Key Vault suspicious access | SecurityAlert | T1552.004 | Defender for Key Vault detects unusual access patterns to secrets and keys |

### Posture and Compliance

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Critical recommendation unactioned | SecurityRecommendation | — | High-severity recommendation open for >30 days — correlate with security incidents |
| Compliance drift | SecurityRegulatoryCompliance | — | Resource moved from compliant to non-compliant on MCSB or CIS benchmarks |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection | Defender for Cloud is the primary cloud workload threat detection platform |
| **LT-3** Enable logging for security investigation | Security alerts provide investigation-ready context with affected resources, attack descriptions, and remediation steps |
| **GS-3** Align roles and responsibilities | Compliance assessments track governance posture across all defined regulatory standards |
| **AM-2** Use only approved services | Recommendations flag unapproved or insecure resource configurations |
| **IR-4** Detection and analysis | Alerts feed directly into Sentinel incident workflows with full MITRE ATT&CK mapping |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 RA-5 (vulnerability monitoring) and SI-4 (system monitoring), CIS Controls v8 7.5 (vulnerability scanning) and 13.1 (security event alerting), and ASD ACSC enterprise network logging priority #1 (critical systems) and cloud priority #7 (cloud compliance events).

---

## Important Considerations

### Multi-Cloud Coverage

Defender for Cloud supports AWS and GCP through multi-cloud connectors. If you have enabled Defender CSPM or CWP across clouds, alerts from AWS and GCP workloads also flow through the `SecurityAlert` table. This means a single Sentinel connector surfaces cloud security alerts across all three hyperscalers.

### Bi-Directional Incident Sync

When Defender for Cloud alerts are created as Sentinel incidents, remediation actions taken in Defender for Cloud update the Sentinel incident status. Enable **bi-directional sync** in the connector settings to keep both platforms aligned.

### Alert Volume Management

Defender for Cloud can generate significant alert volumes, particularly from Defender for Servers (brute-force on internet-facing VMs). Use **alert suppression rules** in Defender for Cloud to reduce noise from expected behaviour (e.g., known vulnerability scanners, penetration testing IP ranges).

---

## Notes

- `SecurityAlert` is free to ingest — there is no cost justification needed for this connector
- `SecurityRecommendation` and `SecurityRegulatoryCompliance` incur ingestion cost — evaluate whether querying these in Sentinel adds value beyond the Defender for Cloud portal
- If you use **Defender CSPM** (premium), additional tables like `SecurityAttackPath` may become available — these are high-value for proactive hunting
- For Defender for Servers P2 VM-level alerts, ensure that AMA deployment is complete — see the [Defender AMA Coverage](../procedures/defender-ama-coverage.md) procedure

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor SecurityAlert and recommendation ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Defender AMA Coverage** | Workbook | Validate AMA deployment for Defender for Servers | Sentinel Content Hub | [Walkthrough](../procedures/defender-ama-coverage.md) |
| **Microsoft Defender for Cloud** | Solution | 1 analytic rule — provides the tenant-based and subscription-based connectors plus detection content | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect Microsoft Defender for Cloud alerts to Microsoft Sentinel | Connector setup guide — tenant-based vs subscription-based, bi-directional sync | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-defender-for-cloud) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Microsoft Defender for Cloud connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftdefenderforcloudtenantbased.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance on logging priorities for enterprise networks and cloud — informs the ACSC alignment on this page | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
