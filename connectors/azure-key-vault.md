# Azure Key Vault

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No

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

Azure Key Vault stores and manages cryptographic keys, secrets (connection strings, API keys, passwords), and certificates. The diagnostic logs record **every access operation** — who accessed which secret, when, and from which IP. This makes Key Vault one of the most forensically valuable data-plane audit sources in Azure.

In a breach scenario, the first question after *"which accounts were compromised?"* is often *"could they access secrets?"*. Key Vault logs answer this definitively.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Azure subscription** | Full Key Vault diagnostic logging — no additional license required |
| **Defender for Key Vault** | Adds threat detection alerts for anomalous Key Vault access (alerts flow through `SecurityAlert` → Tier 2 Defender for Cloud page) |

> [!NOTE]
> Key Vault diagnostic logs are **not** a free data source. Volume depends on the number of Key Vault operations in your environment. For most organisations, volume is relatively low compared to network or endpoint logs.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AKVAuditLogs** (resource-specific) | All Key Vault operations — secret get/set/delete, key operations, certificate operations, access policy changes | Analytics: 90d / Lake: 365d | **Core secrets audit trail.** Detects unauthorized secret access, bulk secret enumeration, and access policy tampering. MCSB DP-6, LT-3. | Proves exactly which secrets were accessed, by which identity, from which IP, and when. The definitive evidence for determining whether an attacker obtained secret material during a breach. | Mass secret retrieval from unusual IP — potential credential theft (T1552.004) |
| **AzureDiagnostics** (KeyVault) | Legacy diagnostic mode — same data in unstructured format | Analytics: 90d / Lake: 365d | Fallback for Key Vaults not yet migrated to resource-specific mode. | Same forensic value as AKVAuditLogs but harder to query | Same as above |

> [!TIP]
> Use **resource-specific** diagnostic settings to route logs to `AKVAuditLogs` instead of `AzureDiagnostics`. Resource-specific tables are structured, cheaper to query, and easier to write detections against.

---

## Example Detections

### Secret Access

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Mass secret retrieval | AKVAuditLogs | T1552.004 | Single identity retrieving many secrets in a short timeframe — bulk credential theft |
| Secret access from unusual IP | AKVAuditLogs | T1552.004 | Secret retrieval from an IP not seen in baseline vault access patterns |
| Secret access from unexpected identity | AKVAuditLogs | T1078 | Service principal or user accessing secrets they have not accessed before |
| Access denied spike | AKVAuditLogs | T1087 | Sudden increase in 403 responses — may indicate reconnaissance or misconfigured stolen credentials |

### Administrative Changes

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Key Vault access policy modified | AKVAuditLogs + AzureActivity | T1098 | Access policy change granting new identities access to secrets |
| Soft-delete disabled | AKVAuditLogs | T1485 | Disabling soft-delete on a Key Vault — potential preparation for destructive action |
| Key Vault purged | AKVAuditLogs + AzureActivity | T1485 | Deletion of a Key Vault containing cryptographic keys or secrets |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **DP-6** Use a secure key management process | Key Vault is the primary Azure key management service — audit logs track key lifecycle |
| **DP-7** Use a secure certificate management process | Certificate operations are logged in the same audit trail |
| **LT-3** Enable logging for security investigation | Key Vault logs are the data-plane audit trail for secret access |
| **IM-4** Authenticate server and services | Service principal and managed identity access to secrets is tracked |
| **PA-7** Follow just enough administration | Access policy audit trail supports least-privilege enforcement for secrets |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 SC-12 (cryptographic key management) and AU-2 (audit events), CIS Controls v8 3.11 (encrypt sensitive data at rest), and ASD ACSC enterprise network logging priority #7 (privileged systems and secret management).

---

## Important Considerations

### Resource-Specific vs. Azure Diagnostics

| Mode | Table | Recommendation |
|:-----|:------|:---------------|
| **Resource-specific** (recommended) | `AKVAuditLogs` | Structured, cheaper, better performance |
| Azure Diagnostics (legacy) | `AzureDiagnostics` with `ResourceType == "VAULTS"` | Legacy — migrate when possible |

### Coverage

- Configure diagnostic settings on **every Key Vault** in your environment, including development and test vaults
- Use Azure Policy to enforce diagnostic settings: `Microsoft.Insights/diagnosticSettings — deployIfNotExists`
- Key Vaults in dev/test environments are often less protected and may be the first target

### Defender for Key Vault

If you have Defender for Key Vault enabled, anomalous access alerts (unusual IP, unusual volume, Tor access) flow through `SecurityAlert` — see the [Defender for Cloud](microsoft-defender-for-cloud.md) page. The diagnostic logs provide the raw audit trail underneath those alerts.

---

## Notes

- Key Vault log volume is typically low compared to network or endpoint logs — cost is usually manageable
- The combination of Key Vault audit logs + Azure Activity Logs (control plane) provides full vault lifecycle visibility
- For HSM-backed keys, `AzureDiagnostics` may include additional Managed HSM operations
- Key Vault is frequently targeted in cloud-native attacks — after compromising an identity, attackers enumerate accessible Key Vaults for connection strings and API keys

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor Key Vault table ingestion volumes | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

Community and third-party resources that support the guidance on this page.

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — secret and privilege management is Enterprise Networks priority #7 | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
