# SAP

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party (via SAP agent) · **Free ingestion:** No

---

## Contents

- [SAP](#sap)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
  - [Example Detections](#example-detections)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Important Considerations](#important-considerations)
  - [Notes](#notes)
    - [Tools](#tools)
  - [References](#references)

---

## Overview

Microsoft Sentinel for SAP provides **continuous threat monitoring** for SAP systems — one of the most business-critical and targeted enterprise platforms. The connector deploys a containerised data collector agent that extracts audit logs, change documents, security events, and transactional data from SAP NetWeaver and S/4HANA systems.

SAP systems are high-value targets because they store financial data, HR records, procurement information, and intellectual property. Attackers who gain access to SAP can manipulate transactions, exfiltrate sensitive business data, or escalate privileges across the ERP landscape. Traditional SIEM solutions rarely cover SAP — this connector closes that gap.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft Sentinel for SAP (add-on)** | Full SAP log collection and built-in analytics — priced per SAP system ID (SID) |
| **SAP S-User license** | Required for downloading SAP NetWeaver SDK used by the data collector agent |

> [!NOTE]
> Microsoft Sentinel for SAP is a separately licensed add-on. It includes a comprehensive set of **built-in analytic rules, watchlists, and workbooks** specifically designed for SAP threat detection. See [SAP solution pricing](https://learn.microsoft.com/en-us/azure/sentinel/sap/solution-overview#pricing).

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SAPAuditLog** | SAP Security Audit Log — logons, authorization failures, transaction executions, RFC calls | Analytics: 90d / Lake: 365d | Primary security event source for SAP — captures authentication, authorization, and critical transaction activity | Reconstructs attacker actions in SAP — which transactions were executed, from which client, by which user | Failed logon brute-force against SAP GUI (T1110) |
| **ABAPAuditLog** | ABAP-level audit events — detailed program execution, table access, debug changes | Analytics: 90d / Lake: 365d | Deep application-layer audit trail — detects code injection, debugging in production, and direct table manipulation | Proves code-level manipulation — essential for investigating business logic attacks | Debug/replace operations in production system (T1059) |
| **SAPChangeDocuments** | Master data and configuration change records — vendor master, user master, financial postings | Analytics: 90d / Lake: 365d | Business change audit trail — detects unauthorized modifications to critical master data | Identifies which business data was modified — proves financial fraud or data tampering | Unauthorized vendor master bank account change (T1565.001) |
| **SAPSpoolLog** | Print spool and output events — documents sent to printers or exported | Analytics: 90d / Lake: 365d | Data exfiltration detection — large or sensitive spool jobs may indicate data theft | Tracks what was printed or exported from SAP — proves data exfiltration through print/export channels | Mass spool output of financial reports to unusual destination (T1039) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| SAP_ALL / SAP_NEW profile assigned | SAPAuditLog | T1078, T1098 | Superuser profile assigned to a dialog user — grants unrestricted access to the entire SAP system |
| Debug/replace in production | ABAPAuditLog | T1059 | Developer using debug-with-replace capability in a production system — can modify variables at runtime |
| Critical transaction executed by unusual user | SAPAuditLog | T1078 | Sensitive transactions (SU01, SE16, SM59) executed by a user who normally doesn't use them |
| Vendor master bank account changed | SAPChangeDocuments | T1565.001 | Bank account details modified on a vendor master record — classic financial fraud indicator |
| RFC connection to unknown system | SAPAuditLog | T1021 | RFC (Remote Function Call) connection established to an unrecognised external SAP system |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection capabilities | SAP-specific threat detection for business-critical ERP systems |
| **LT-3** Enable logging for security investigation | SAP audit logs provide the application-layer investigation trail for ERP compromise scenarios |
| **IM-2** Protect identity and authentication systems | SAP user management, authorization, and authentication monitoring |
| **DP-2** Monitor anomalies and threats targeting sensitive data | Change document monitoring detects unauthorized modifications to financial and HR data |

---

## Important Considerations

- **Agent deployment:** The SAP data collector runs as a Docker container on a Linux VM (or AKS) with network access to the SAP system. Size the VM based on the number of SAP SIDs
- **SAP Basis team coordination:** Deploying the connector requires coordination with the SAP Basis team for RFC user creation, audit log configuration, and network access rules
- **Audit log configuration:** SAP Security Audit Log (SM19/RSAU_CONFIG) must be properly configured with the right filters — by default, SAP may not log all events needed for security monitoring
- **Built-in content:** The Sentinel for SAP solution includes 50+ analytic rules, SAP-specific watchlists (critical transactions, sensitive tables, authorisation profiles), and workbooks — deploy the full Content Hub solution

---

## Notes

- SAP is one of the most commonly targeted systems in financial fraud attacks — monitoring SAP closes a critical blind spot
- The solution includes pre-built watchlists for critical SAP transactions, sensitive tables, and high-privilege profiles — customise these for your environment
- Consider pairing with Azure Key Vault (Tier 2) monitoring — SAP connection credentials are often stored in Key Vault

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify SAP log volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |
| SAP — Audit Log Monitor | Workbook | Built-in SAP security monitoring dashboard | Sentinel Content Hub | [SAP solution](https://learn.microsoft.com/en-us/azure/sentinel/sap/deploy-sap-security-content) |

---

## References

| Source | Link |
|:-------|:-----|
| Microsoft Sentinel for SAP overview | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/sap/solution-overview) |
| Deploy SAP data connector agent | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/sap/deploy-data-connector-agent-container) |
| SAP solution security content | [Learn](https://learn.microsoft.com/en-us/azure/sentinel/sap/deploy-sap-security-content) |
| SAP solution pricing | [Learn](https://learn.microsoft.com/azure/sentinel/sap/solution-overview#solution-pricing) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
