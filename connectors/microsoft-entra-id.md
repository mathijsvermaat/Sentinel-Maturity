# Microsoft Entra ID

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes (free data source)

---

## Contents

- [Microsoft Entra ID](#microsoft-entra-id)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
    - [Authentication Tables](#authentication-tables)
    - [Directory and Audit Tables](#directory-and-audit-tables)
    - [Risk Tables (Entra ID P2)](#risk-tables-entra-id-p2)
  - [Example Detections](#example-detections)
    - [Authentication-Based](#authentication-based)
    - [Directory-Based](#directory-based)
    - [Risk-Based](#risk-based)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Notes](#notes)
  - [Tools](#tools)
  - [References](#references)
    - [Official Documentation](#official-documentation)
    - [Community \& Third-Party Resources](#community--third-party-resources)

---

## Overview

The Microsoft Entra ID (formerly Azure AD) connector is **essential for every Sentinel deployment**. Identity is the new perimeter — virtually every attack involves some form of identity abuse, whether it is compromised credentials, token theft, or consent phishing. Entra ID logs provide the primary source of truth for authentication and directory change events across your entire Microsoft cloud estate.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Entra ID Free / P1** | SigninLogs, AuditLogs, AADNonInteractiveUserSignInLogs, AADServicePrincipalSignInLogs, AADManagedIdentitySignInLogs, AADProvisioningLogs, ADFSSignInLogs, MicrosoftGraphActivityLogs |
| **Entra ID P2 (included in E5)** | All of the above + AADRiskyUsers, AADUserRiskEvents (Identity Protection data) |
| **Workload Identities Premium** | AADRiskyServicePrincipals, AADServicePrincipalRiskEvents — risk detections for service principals and managed identities |
| **Microsoft 365 E5 / Defender (opt-in)** | EnrichedOffice365AuditLogs — enriched Office 365 audit logs (requires enablement in the Defender portal) |
| **Entra ID with Global Secure Access** | NetworkAccessTraffic (Entra Internet/Private Access) |

> [!NOTE]
> Entra ID sign-in and audit logs are **free data sources** in Microsoft Sentinel. There is no reason not to enable this connector. The table names above are the Log Analytics / Sentinel table names; the corresponding **diagnostic setting log categories** in the Entra portal use the unprefixed names (e.g. `NonInteractiveUserSignInLogs`, `ServicePrincipalSignInLogs`, `ManagedIdentitySignInLogs`, `ADFSSignInLogs`).

> [!TIP]
> If your organisation uses **Global Secure Access** (Entra Internet Access / Entra Private Access), see the dedicated [Global Secure Access](global-secure-access.md) Tier 2 connector page for network traffic logging via `NetworkAccessTraffic`. This page covers **authentication events**; the GSA page covers **what users accessed after authenticating**.

---

## Tables and Rationale

### Authentication Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SigninLogs** | Interactive user sign-ins (browser, desktop apps) | Analytics: 90d / Lake: 365d | **Core identity security table.** Detects compromised accounts, brute-force, password spray, MFA bypass, and impossible travel. MCSB IM-1 (Centralise identity management), IM-4 (Authenticate server and services). Every identity-based investigation starts here. | Reconstruct the full authentication timeline for any user — proves when access was gained, from where, and which MFA method was used or bypassed. The starting point for nearly every identity investigation. | Brute-force / password spray (T1110.003), Impossible travel (T1078), MFA fatigue (T1621) |
| **AADNonInteractiveUserSignInLogs** | Token refresh, background app authentication | Analytics: 90d / Lake: 365d | Detects token theft and replay attacks, session hijacking. Non-interactive sign-ins often reveal attacker persistence after initial compromise. High volume but critical for AiTM phishing investigation. | Proves persistent access via stolen tokens — shows continued session activity from attacker-controlled infrastructure even after password reset. Critical for AiTM phishing forensics. | AiTM phishing — token use from different IP after interactive sign-in (T1557) |
| **AADServicePrincipalSignInLogs** | Application and service principal authentication | Analytics: 90d / Lake: 365d | Detects compromised application credentials, OAuth abuse, and consent phishing (MITRE T1550.001). MCSB IM-4. Service principals are high-value targets — a compromised app registration can have tenant-wide access. | Audit trail for application-level access — proves when a compromised service principal was used, from which IP, and with what scope. Essential for supply chain and OAuth abuse investigations. | Service principal auth from unexpected IP or with unusual scope (T1550.001) |
| **AADManagedIdentitySignInLogs** | Managed identity authentication events | Analytics: 90d / Lake: 365d | Detects anomalous use of managed identities by Azure resources. While lower risk than user credentials (no extractable secrets), compromised Azure resources can abuse their managed identity. | Traces non-human identity usage — proves which Azure resource used its managed identity and when, enabling investigation of compromised infrastructure | Managed identity used from unexpected Azure resource |
| **ADFSSignInLogs** | Active Directory Federation Services sign-in events | Analytics: 90d / Lake: 365d | Critical for hybrid identity environments. Detects Golden SAML attacks (as seen in SolarWinds/Nobelium). MCSB IM-1. If you have ADFS, this table is essential. | Critical for detecting Golden SAML — proves whether a SAML token was legitimately issued via ADFS or forged by an attacker with access to the token-signing certificate | Golden SAML — SAML token without corresponding ADFS auth event (T1606.002) |

### Directory and Audit Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AuditLogs** | Directory changes: user/group/role modifications, app registrations, policy changes | Analytics: 90d / Lake: 365d | **Core governance table.** Tracks privilege escalation (adding Global Admin), persistence (new app registrations, federation changes), and policy tampering. MCSB PA-1 (Protect privileged users), PA-7 (Follow just enough administration). | Complete directory change audit trail — proves exactly who made what change, when, and to which object. Answers "how did the attacker escalate privilege or establish persistence in Entra ID?" | User added to Global Admin (T1098.003), New app with high-privilege API permissions (T1136.003) |
| **AADProvisioningLogs** | User provisioning events to/from applications | Analytics: 90d / Lake: 365d | Tracks automated account creation/modification in connected apps. Detects provisioning anomalies and unauthorized access propagation. | Traces how compromised identity propagated access to connected SaaS applications — shows if attacker-controlled accounts were automatically provisioned to downstream systems | Unexpected user provisioned to sensitive SaaS application |
| **MicrosoftGraphActivityLogs** | API requests made to Microsoft Graph for resources in the tenant (audit and security categories) | Analytics: 30d (high volume) / Lake: 365d | Detects Graph API abuse — mass data reads, enumeration of users/groups/mail, suspicious app activity. Basic log supported (low cost option). Complements SigninLogs by showing *what* the app/user did after authenticating. | Full audit of Graph API calls — proves which identity called which endpoint, from which IP, and with what result. Critical for OAuth abuse and post-compromise data access investigations. | Mass user enumeration via `/users` endpoint (T1087.004), Bulk mailbox reads by compromised app (T1114.002) |
| **EnrichedOffice365AuditLogs** | Office 365 audit logs enriched with Entra ID context (user risk, device, session) | Analytics: 30d / Lake: 365d | Requires opt-in via the Defender portal. Adds identity context to every Office 365 audit event, enabling correlation of M365 activity with risk signals and device posture without expensive joins. | Joins identity risk/device data with Exchange/SharePoint/Teams audit events in a single table — speeds up incident response for M365 data-exfiltration and insider cases. | High-risk user exporting large volumes of SharePoint content (T1213.002) |

### Risk Tables (Entra ID P2)

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AADRiskyUsers** | Users flagged as risky by Entra ID Protection | Analytics: 90d / Lake: 365d | Provides a risk-scored view of users. Enables automated response (e.g., require password change, block access). MCSB IM-1. Critical input for risk-based Conditional Access policies monitored via Sentinel. | Historical risk profile — shows when a user was first flagged, at what risk level, and whether remediation occurred or was delayed. Supports post-incident review of risk-based policy effectiveness. | High-risk user sign-in correlated with suspicious inbox rule |
| **AADUserRiskEvents** | Individual risk detections (leaked credentials, anonymous IP, malware-linked IP, etc.) | Analytics: 90d / Lake: 365d | Detailed risk event telemetry. Enables correlation of risk signals with sign-in activity. Supports investigation of why a user was flagged and the specific indicators involved. | Granular risk detection evidence — proves exactly which risk signal triggered (leaked credentials, anomalous token, etc.) and when, enabling root cause analysis of identity compromise | Leaked credentials detection (T1078), Anomalous token usage (T1550.001) |
| **AADRiskyServicePrincipals** | Service principals flagged as risky by Entra ID Protection | Analytics: 90d / Lake: 365d | Identifies compromised or anomalous application identities. Service principals can have broad tenant access — risk detection is critical for supply chain and OAuth abuse scenarios. | Proves when a service principal was flagged and the associated risk signals — essential for investigating compromised applications | Risky service principal with unusual API access pattern |
| **AADServicePrincipalRiskEvents** | Individual risk detections for service principals | Analytics: 90d / Lake: 365d | Granular risk signals for application identities — anomalous credential usage, suspicious activity patterns. MCSB IM-4. | Detailed evidence of why a service principal was flagged — enables root cause analysis of compromised app registrations and managed identities | Anomalous service principal credential usage from unexpected geography |

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
| Leaked credentials not remediated | AADRiskyUsers, AADUserRiskEvents | T1589.001 | User flagged with leaked credentials but risk state remains "atRisk" beyond remediation SLA |
| Multiple risk detections for single user | AADUserRiskEvents | T1078 | Multiple distinct risk detection types triggered for the same user within a short window — indicates active compromise |
| Atypical travel followed by data access | AADUserRiskEvents, SigninLogs | T1078, T1537 | Atypical travel risk detection followed by successful sign-in and resource access |
| Risky service principal accessing Key Vault | AADRiskyServicePrincipals, AKVAuditLogs | T1078.004, T1552.004 | Service principal flagged as risky that subsequently accessed Key Vault secrets |
| Anomalous service principal credential usage | AADServicePrincipalRiskEvents | T1098.001 | Service principal using credentials from an unusual location or at unusual times |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **IM-1** Centralise identity management | Entra ID is the central identity provider — its logs are the primary source of truth |
| **IM-3** Manage application identities securely and automatically | Workload identity risk detections (AADRiskyServicePrincipals) directly monitor application identity security |
| **IM-4** Authenticate server and services | Service principal logs track application authentication |
| **PA-1** Protect privileged users | AuditLogs track role assignments and privilege changes |
| **PA-7** Follow just enough administration | AuditLogs monitor PIM activations and just-in-time access |
| **LT-1** Enable threat detection | Risk tables provide ML-based threat detection for identity |
| **LT-3** Enable logging for security investigation | Sign-in and audit logs are the foundation of identity forensics |
| **LT-6** Configure log storage retention | Extended retention supports investigation of long-running identity attacks |
| **IR-4** Detection and analysis | Sign-in logs are used in virtually every incident investigation |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AC-2 (account management) and IA-2 (identification and authentication), CIS Controls v8 6.1/6.2 (access control logging), and ASD ACSC enterprise network logging priority #3 (authentication and directory services).

---

## Notes

- **Always enable all sign-in log types** — non-interactive and service principal logs are often overlooked but critical for detecting modern attacks (AiTM, token theft)
- If using **Entra ID P2**, always enable the risk tables — they provide high-fidelity detection signals at no additional query cost
- **Enable all risk log categories:** The Entra ID diagnostic settings must have `RiskyUsers`, `UserRiskEvents`, `RiskyServicePrincipals`, and `ServicePrincipalRiskEvents` categories enabled — they are **not** enabled by default
- **Workload Identities Premium license:** Risk detections for service principals require the Workload Identities Premium add-on (not included in standard E5)
- Risk event volume is typically low (tens to hundreds of events per day for most organisations) — cost impact is minimal
- These risk tables are most valuable when paired with Conditional Access risk-based policies — the risk data explains policy enforcement decisions
- Consider ingesting **Entra ID Provisioning logs** if you use automated provisioning to SaaS apps
- The **NetworkAccessTraffic** table becomes available if you deploy Global Secure Access (Entra Internet/Private Access) — this is a Tier 2+ consideration
- Entra ID sign-in logs in Entra by default retain for **30 days** (P1/P2) — Sentinel provides the extended retention you need for forensic readiness

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor Entra ID table ingestion volumes and retention | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Microsoft Entra ID** | Solution | 3 workbooks (Audit Logs, Sign-in Logs, Provisioning), 73 analytic rules, 11 playbooks — covers identity threat detection, sign-in anomalies, and automated response | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect Microsoft Entra ID to Microsoft Sentinel | Connector setup guide — diagnostic settings for sign-in, audit, and risk logs | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-azure-active-directory) |
| Microsoft Entra audit log reference | Schema reference for all Entra ID audit log categories | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-audit-activities) |
| Microsoft Entra ID Protection overview | Overview of risk-based identity protection features | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/id-protection/overview-identity-protection) |
| Risky users and risk detections | Investigating identity risk signals | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/id-protection/howto-identity-protection-investigate-risk) |
| Workload identity risk | Risk detection for service principals and managed identities | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/id-protection/concept-workload-identity-risk) |
| Microsoft Entra license usage insights | GA experience in **Billing > Licenses** — shows entitlements (Entra ID P1/P2, Entra Suite, standalone SKUs), six-month usage trends, and which identity protections are actively in use vs. licensed-but-unused. Use it to confirm risk-based access policies, Identity Protection, PIM, and other security features are actually enforcing before relying on them in Sentinel detections | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/fundamentals/concept-license-usage-insights) |
| Now generally available: License usage insights in Microsoft Entra | Announcement blog — covers what's new in GA (six-month trends, active vs. guest split, Copilot prompt suggestions) | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/microsoft-entra-blog/now-generally-available-license-usage-insights-in-microsoft-entra/4507463) |

### Admin portal

- [Microsoft Entra admin centre](https://entra.microsoft.com/) — enable diagnostic settings for sign-in, audit, and provisioning logs; review Identity Protection signals; **Billing > Licenses** for license usage insights (verify which Entra protections are licensed and actively in use).
  - Quick links via [cmd.ms](https://cmd.ms/) (see [References §14.6](../references.md#14-admin-portals)): [`enusers.cmd.ms`](https://enusers.cmd.ms/) (Users), [`enca.cmd.ms`](https://enca.cmd.ms/) (Conditional Access), [`enauth.cmd.ms`](https://enauth.cmd.ms/) (Authentication methods), [`enpim.cmd.ms`](https://enpim.cmd.ms/) (PIM), [`enar.cmd.ms`](https://enar.cmd.ms/) (Access reviews), [`enidp.cmd.ms`](https://enidp.cmd.ms/) (Identity Protection), [`ensign.cmd.ms`](https://ensign.cmd.ms/) (Sign-in logs), [`ensynclog.cmd.ms`](https://ensynclog.cmd.ms/) (Entra Connect sync errors).

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Microsoft Entra ID connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azureactivedirectory.md) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
