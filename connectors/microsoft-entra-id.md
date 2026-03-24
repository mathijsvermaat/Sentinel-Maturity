# Microsoft Entra ID

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes (free data source)

---

## Overview

The Microsoft Entra ID (formerly Azure AD) connector is **essential for every Sentinel deployment**. Identity is the new perimeter — virtually every attack involves some form of identity abuse, whether it is compromised credentials, token theft, or consent phishing. Entra ID logs provide the primary source of truth for authentication and directory change events across your entire Microsoft cloud estate.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Entra ID Free / P1** | SigninLogs, AuditLogs, NonInteractiveUserSignInLogs, ServicePrincipalSignInLogs, ManagedIdentitySignInLogs, ProvisioningLogs |
| **Entra ID P2 (included in E5)** | All of the above + AADRiskyUsers, AADUserRiskEvents (Identity Protection data) |
| **Entra ID with Global Secure Access** | NetworkAccessTraffic (Entra Internet/Private Access) |

> [!NOTE]
> Entra ID sign-in and audit logs are **free data sources** in Microsoft Sentinel. There is no reason not to enable this connector.

---

## Tables and Rationale

### Authentication Tables

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **SigninLogs** | Interactive user sign-ins (browser, desktop apps) | Analytics: 90d / Lake: 365d | **Core identity security table.** Detects compromised accounts, brute-force, password spray, MFA bypass, and impossible travel. MCSB IM-1 (Centralise identity management), IM-4 (Authenticate server and services). Every identity-based investigation starts here. | Brute-force / password spray (T1110.003), Impossible travel (T1078), MFA fatigue (T1621) |
| **AADNonInteractiveUserSignInLogs** | Token refresh, background app authentication | Analytics: 90d / Lake: 365d | Detects token theft and replay attacks, session hijacking. Non-interactive sign-ins often reveal attacker persistence after initial compromise. High volume but critical for AiTM phishing investigation. | AiTM phishing — token use from different IP after interactive sign-in (T1557) |
| **AADServicePrincipalSignInLogs** | Application and service principal authentication | Analytics: 90d / Lake: 365d | Detects compromised application credentials, OAuth abuse, and consent phishing (MITRE T1550.001). MCSB IM-4. Service principals are high-value targets — a compromised app registration can have tenant-wide access. | Service principal auth from unexpected IP or with unusual scope (T1550.001) |
| **AADManagedIdentitySignInLogs** | Managed identity authentication events | Analytics: 90d / Lake: 365d | Detects anomalous use of managed identities by Azure resources. While lower risk than user credentials (no extractable secrets), compromised Azure resources can abuse their managed identity. | Managed identity used from unexpected Azure resource |
| **ADFSSignInLogs** | Active Directory Federation Services sign-in events | Analytics: 90d / Lake: 365d | Critical for hybrid identity environments. Detects Golden SAML attacks (as seen in SolarWinds/Nobelium). MCSB IM-1. If you have ADFS, this table is essential. | Golden SAML — SAML token without corresponding ADFS auth event (T1606.002) |

### Directory and Audit Tables

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **AuditLogs** | Directory changes: user/group/role modifications, app registrations, policy changes | Analytics: 90d / Lake: 365d | **Core governance table.** Tracks privilege escalation (adding Global Admin), persistence (new app registrations, federation changes), and policy tampering. MCSB PA-1 (Protect privileged users), PA-7 (Follow just enough administration). | User added to Global Admin (T1098.003), New app with high-privilege API permissions (T1136.003) |
| **AADProvisioningLogs** | User provisioning events to/from applications | Analytics: 90d / Lake: 365d | Tracks automated account creation/modification in connected apps. Detects provisioning anomalies and unauthorized access propagation. | Unexpected user provisioned to sensitive SaaS application |

### Risk Tables (Entra ID P2)

| Table | Description | Retention Recommendation | Rationale | Example Detection |
|:------|:------------|:------------------------|:----------|:------------------|
| **AADRiskyUsers** | Users flagged as risky by Entra ID Protection | Analytics: 90d / Lake: 365d | Provides a risk-scored view of users. Enables automated response (e.g., require password change, block access). MCSB IM-1. Critical input for risk-based Conditional Access policies monitored via Sentinel. | High-risk user sign-in correlated with suspicious inbox rule |
| **AADUserRiskEvents** | Individual risk detections (leaked credentials, anonymous IP, malware-linked IP, etc.) | Analytics: 90d / Lake: 365d | Detailed risk event telemetry. Enables correlation of risk signals with sign-in activity. Supports investigation of why a user was flagged and the specific indicators involved. | Leaked credentials detection (T1078), Anomalous token usage (T1550.001) |

---

## Example Detections

### Authentication-Based

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Brute-force / password spray | SigninLogs | T1110.003 | High volume of failed sign-ins across multiple accounts from limited source IPs |
| MFA fatigue / push bombing | SigninLogs | T1621 | Repeated MFA prompts followed by an eventual approval from the user |
| Impossible travel | SigninLogs | T1078 | Sign-ins from geographically impossible locations within a short time window |
| AiTM phishing (token theft) | AADNonInteractiveUserSignInLogs, SigninLogs | T1557 | Successful sign-in followed by non-interactive token use from a different IP/location |
| Compromised service principal | AADServicePrincipalSignInLogs | T1550.001 | Service principal authentication from unexpected IPs or with unusual scope |
| Golden SAML attack | ADFSSignInLogs, AuditLogs | T1606.002 | SAML token issued without corresponding ADFS authentication event |

### Directory-Based

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Privilege escalation | AuditLogs | T1098.003 | User added to Global Administrator or other privileged Entra ID roles |
| New application registration with high permissions | AuditLogs | T1136.003 | New app registration with Mail.Read, Files.ReadWrite.All, or similar sensitive Graph API permissions |
| Consent phishing (illicit consent grant) | AuditLogs, SigninLogs | T1528 | User grants OAuth consent to a malicious application |
| Federation domain modification | AuditLogs | T1484.002 | Changes to federation settings — potential backdoor for authentication bypass |
| Conditional Access policy modification | AuditLogs | T1562.001 | Disabling or weakening Conditional Access policies to reduce security controls |

### Risk-Based

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Leaked credentials detection | AADUserRiskEvents | T1078 | Entra ID Protection detects credentials found in dark web dumps or paste sites |
| Anomalous token usage | AADUserRiskEvents | T1550.001 | Unusual token characteristics indicating potential token manipulation |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **IM-1** Centralise identity management | Entra ID is the central identity provider — its logs are the primary source of truth |
| **IM-4** Authenticate server and services | Service principal logs track application authentication |
| **PA-1** Protect privileged users | AuditLogs track role assignments and privilege changes |
| **PA-7** Follow just enough administration | AuditLogs monitor PIM activations and just-in-time access |
| **LT-1** Enable threat detection | Risk tables provide ML-based threat detection for identity |
| **LT-3** Enable logging for security investigation | Sign-in and audit logs are the foundation of identity forensics |
| **LT-6** Configure log storage retention | Extended retention supports investigation of long-running identity attacks |
| **IR-4** Detection and analysis | Sign-in logs are used in virtually every incident investigation |

---

## Notes

- **Always enable all sign-in log types** — non-interactive and service principal logs are often overlooked but critical for detecting modern attacks (AiTM, token theft)
- If using **Entra ID P2**, always enable the risk tables — they provide high-fidelity detection signals at no additional query cost
- Consider ingesting **Entra ID Provisioning logs** if you use automated provisioning to SaaS apps
- The **NetworkAccessTraffic** table becomes available if you deploy Global Secure Access (Entra Internet/Private Access) — this is a Tier 2+ consideration
- Entra ID sign-in logs in Entra by default retain for **30 days** (P1/P2) — Sentinel provides the extended retention you need for forensic readiness

### Useful Workbooks

| Workbook | Purpose | Source |
|:---------|:--------|:-------|
| **Workspace Usage Report** | Monitor Entra ID table ingestion volumes and retention | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
