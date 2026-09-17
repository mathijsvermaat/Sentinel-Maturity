# Microsoft Entra ID

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party · **Free ingestion:** Ingestion benefit only (conditional) — verify current included data types in [Microsoft Sentinel free data sources](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources) and [Microsoft Sentinel benefit for M365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer)

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
  - [MITRE Detection Strategies](#mitre-detection-strategies)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Hybrid Identity Server Events (AD FS and Entra Connect)](#hybrid-identity-server-events-ad-fs-and-entra-connect)
  - [Notes](#notes)
  - [Tools](#tools)
  - [References](#references)
    - [Official Documentation](#official-documentation)
    - [Admin portal](#admin-portal)
    - [Community \& Third-Party Resources](#community--third-party-resources)

---

## Overview

The Microsoft Entra ID (formerly Azure AD) connector is **essential for every Sentinel deployment**. Identity is the new perimeter — virtually every attack involves some form of identity abuse, whether it is compromised credentials, token theft, or consent phishing. Entra ID logs provide the primary source of truth for authentication and directory change events across your entire Microsoft cloud estate.

### Licensing Benefits

| Sentinel cost classification | Microsoft Sentinel benefit |
|:-----------------------------|:---------------------------|
| **Ingestion benefit only (conditional)** | Entitlement-based Analytics-tier ingestion benefit applies for eligible data types; verify current scope in [Microsoft Sentinel benefit for M365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer). |

> [!NOTE]
> This classification is Sentinel-centric and connector-level. Coverage can change over time.

---

## Tables and Rationale

### Authentication Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **SigninLogs** | Interactive user sign-ins (browser, desktop apps) | Analytics: 90d / Lake: 365d | **Core identity security table.** Detects compromised accounts, brute-force, password spray, MFA bypass, and impossible travel. MCSB IM-1 (Centralise identity management), IM-4 (Authenticate server and services). Every identity-based investigation starts here. | Reconstruct the full authentication timeline for any user — proves when access was gained, from where, and which MFA method was used or bypassed. The starting point for nearly every identity investigation. | Brute-force / password spray, Impossible travel, MFA fatigue |
| **AADNonInteractiveUserSignInLogs** | Token refresh, background app authentication | Analytics: 90d / Lake: 365d | Detects token theft and replay attacks, session hijacking. Non-interactive sign-ins often reveal attacker persistence after initial compromise. High volume but critical for AiTM phishing investigation. | Proves persistent access via stolen tokens — shows continued session activity from attacker-controlled infrastructure even after password reset. Critical for AiTM phishing forensics. | AiTM phishing — token use from different IP after interactive sign-in |
| **AADServicePrincipalSignInLogs** | Application and service principal authentication | Analytics: 90d / Lake: 365d | Detects compromised application credentials, OAuth abuse, and consent phishing. Service principals are high-value targets — a compromised app registration can have tenant-wide access. | Audit trail for application-level access — proves when a compromised service principal was used, from which IP, and with what scope. Essential for supply chain and OAuth abuse investigations. | Service principal auth from unexpected IP or with unusual scope |
| **AADManagedIdentitySignInLogs** | Managed identity authentication events | Analytics: 90d / Lake: 365d | Detects anomalous use of managed identities by Azure resources. While lower risk than user credentials (no extractable secrets), compromised Azure resources can abuse their managed identity. | Traces non-human identity usage — proves which Azure resource used its managed identity and when, enabling investigation of compromised infrastructure | Managed identity used from unexpected Azure resource |
| **ADFSSignInLogs** | Active Directory Federation Services sign-in events | Analytics: 90d / Lake: 365d | Critical for hybrid identity environments. Detects Golden SAML attacks (as seen in SolarWinds/Nobelium). If you have ADFS, this table is essential. | Critical for detecting Golden SAML — proves whether a SAML token was legitimately issued via ADFS or forged by an attacker with access to the token-signing certificate | Golden SAML — SAML token without corresponding ADFS auth event |

### Directory and Audit Tables

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AuditLogs** | Directory changes: user/group/role modifications, app registrations, policy changes | Analytics: 90d / Lake: 365d | **Core governance table.** Tracks privilege escalation (adding Global Admin), persistence (new app registrations, federation changes), and policy tampering. MCSB PA-1 (Protect privileged users), PA-7 (Follow just enough administration). | Complete directory change audit trail — proves exactly who made what change, when, and to which object. Answers "how did the attacker escalate privilege or establish persistence in Entra ID?" | User added to Global Admin, New app with high-privilege API permissions |
| **AADProvisioningLogs** | User provisioning events to/from applications | Analytics: 90d / Lake: 365d | Tracks automated account creation/modification in connected apps. Detects provisioning anomalies and unauthorized access propagation. | Traces how compromised identity propagated access to connected SaaS applications — shows if attacker-controlled accounts were automatically provisioned to downstream systems | Unexpected user provisioned to sensitive SaaS application |
| **MicrosoftGraphActivityLogs** | API requests made to Microsoft Graph for resources in the tenant (audit and security categories) | Analytics: 30d (high volume) / Lake: 365d | Detects Graph API abuse — mass data reads, enumeration of users/groups/mail, suspicious app activity. Basic log supported (low cost option). Complements SigninLogs by showing *what* the app/user did after authenticating. | Full audit of Graph API calls — proves which identity called which endpoint, from which IP, and with what result. Critical for OAuth abuse and post-compromise data access investigations. | Mass user enumeration via `/users` endpoint, Bulk mailbox reads by compromised app |
| **EnrichedOffice365AuditLogs** | Office 365 audit logs enriched with Entra ID context (user risk, device, session) | Analytics: 30d / Lake: 365d | Requires opt-in via the Defender portal. Adds identity context to every Office 365 audit event, enabling correlation of M365 activity with risk signals and device posture without expensive joins. | Joins identity risk/device data with Exchange/SharePoint/Teams audit events in a single table — speeds up incident response for M365 data-exfiltration and insider cases. | High-risk user exporting large volumes of SharePoint content |

### Risk Tables (Entra ID P2)

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AADRiskyUsers** | Users flagged as risky by Entra ID Protection | Analytics: 90d / Lake: 365d | Provides a risk-scored view of users. Enables automated response (e.g., require password change, block access). Critical input for risk-based Conditional Access policies monitored via Sentinel. | Historical risk profile — shows when a user was first flagged, at what risk level, and whether remediation occurred or was delayed. Supports post-incident review of risk-based policy effectiveness. | High-risk user sign-in correlated with suspicious inbox rule |
| **AADUserRiskEvents** | Individual risk detections (leaked credentials, anonymous IP, malware-linked IP, etc.) | Analytics: 90d / Lake: 365d | Detailed risk event telemetry. Enables correlation of risk signals with sign-in activity. Supports investigation of why a user was flagged and the specific indicators involved. | Granular risk detection evidence — proves exactly which risk signal triggered (leaked credentials, anomalous token, etc.) and when, enabling root cause analysis of identity compromise | Leaked credentials detection, Anomalous token usage |
| **AADRiskyServicePrincipals** | Service principals flagged as risky by Entra ID Protection | Analytics: 90d / Lake: 365d | Identifies compromised or anomalous application identities. Service principals can have broad tenant access — risk detection is critical for supply chain and OAuth abuse scenarios. | Proves when a service principal was flagged and the associated risk signals — essential for investigating compromised applications | Risky service principal with unusual API access pattern |
| **AADServicePrincipalRiskEvents** | Individual risk detections for service principals | Analytics: 90d / Lake: 365d | Granular risk signals for application identities — anomalous credential usage, suspicious activity patterns. | Detailed evidence of why a service principal was flagged — enables root cause analysis of compromised app registrations and managed identities | Anomalous service principal credential usage from unexpected geography |

---

## Example Detections

### Authentication-Based

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Brute-force / password spray | SigninLogs | [T1110.003](https://attack.mitre.org/techniques/T1110/003/) | [DET0487](https://attack.mitre.org/detectionstrategies/DET0487/) — Distributed Password Spraying | High volume of failed sign-ins across multiple accounts from limited source IPs |
| MFA fatigue / push bombing | SigninLogs | [T1621](https://attack.mitre.org/techniques/T1621/) | [DET0160](https://attack.mitre.org/detectionstrategies/DET0160/) — MFA Request Generation | Repeated MFA prompts followed by an eventual approval from the user |
| Impossible travel | SigninLogs | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Valid Account Abuse | Sign-ins from geographically impossible locations within a short time window |
| AiTM phishing (token theft) | AADNonInteractiveUserSignInLogs, SigninLogs | [T1557](https://attack.mitre.org/techniques/T1557/) | [DET0296](https://attack.mitre.org/detectionstrategies/DET0296/) — Adversary-in-the-Middle | Successful sign-in followed by non-interactive token use from a different IP/location |
| Compromised service principal | AADServicePrincipalSignInLogs | [T1550.001](https://attack.mitre.org/techniques/T1550/001/) | [DET0185](https://attack.mitre.org/detectionstrategies/DET0185/) — Application Access Token Use | Service principal authentication from unexpected IPs or with unusual scope |
| Golden SAML attack | ADFSSignInLogs, AuditLogs | [T1606.002](https://attack.mitre.org/techniques/T1606/002/) | [DET0148](https://attack.mitre.org/detectionstrategies/DET0148/) — Forged SAML Tokens | SAML token issued without corresponding ADFS authentication event |

### Directory-Based

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Privilege escalation | AuditLogs | [T1098.003](https://attack.mitre.org/techniques/T1098/003/) | [DET0277](https://attack.mitre.org/detectionstrategies/DET0277/) — Role Addition to Cloud Accounts | User added to Global Administrator or other privileged Entra ID roles |
| New application registration with high permissions | AuditLogs | [T1136.003](https://attack.mitre.org/techniques/T1136/003/) | [DET0319](https://attack.mitre.org/detectionstrategies/DET0319/) — Cloud Account Creation | New app registration with Mail.Read, Files.ReadWrite.All, or similar sensitive Graph API permissions |
| Consent phishing (illicit consent grant) | AuditLogs, SigninLogs | [T1528](https://attack.mitre.org/techniques/T1528/) | [DET0515](https://attack.mitre.org/detectionstrategies/DET0515/) — Steal Application Access Token | User grants OAuth consent to a malicious application |
| Federation domain modification | AuditLogs | [T1484.002](https://attack.mitre.org/techniques/T1484/002/) | [DET0458](https://attack.mitre.org/detectionstrategies/DET0458/) — Trust Relationship Modifications | Changes to federation settings — potential backdoor for authentication bypass |
| Conditional Access policy modification | AuditLogs | [T1562.001](https://attack.mitre.org/techniques/T1562/001/) *(revoked &rarr; [T1685](https://attack.mitre.org/techniques/T1685/))* | [DET0497](https://attack.mitre.org/detectionstrategies/DET0497/) — Defense Impairment | Disabling or weakening Conditional Access policies to reduce security controls |

### Risk-Based

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Leaked credentials detection | AADUserRiskEvents | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Valid Account Abuse | Entra ID Protection detects credentials found in dark web dumps or paste sites |
| Anomalous token usage | AADUserRiskEvents | [T1550.001](https://attack.mitre.org/techniques/T1550/001/) | [DET0185](https://attack.mitre.org/detectionstrategies/DET0185/) — Application Access Token Use | Unusual token characteristics indicating potential token manipulation |
| Leaked credentials not remediated | AADRiskyUsers, AADUserRiskEvents | [T1589.001](https://attack.mitre.org/techniques/T1589/001/) | [DET0813](https://attack.mitre.org/detectionstrategies/DET0813/) — Detection of Credentials | User flagged with leaked credentials but risk state remains "atRisk" beyond remediation SLA |
| Multiple risk detections for single user | AADUserRiskEvents | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Valid Account Abuse | Multiple distinct risk detection types triggered for the same user within a short window — indicates active compromise |
| Atypical travel followed by data access | AADUserRiskEvents, SigninLogs | [T1078](https://attack.mitre.org/techniques/T1078/), [T1537](https://attack.mitre.org/techniques/T1537/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) · [DET0573](https://attack.mitre.org/detectionstrategies/DET0573/) — Data Transfer to Cloud Account | Atypical travel risk detection followed by successful sign-in and resource access |
| Risky service principal accessing Key Vault | AADRiskyServicePrincipals, AKVAuditLogs | [T1078.004](https://attack.mitre.org/techniques/T1078/004/), [T1552.004](https://attack.mitre.org/techniques/T1552/004/) | [DET0546](https://attack.mitre.org/detectionstrategies/DET0546/) · [DET0549](https://attack.mitre.org/detectionstrategies/DET0549/) — Cloud Account Abuse / Private Key Access | Service principal flagged as risky that subsequently accessed Key Vault secrets |
| Anomalous service principal credential usage | AADServicePrincipalRiskEvents | [T1098.001](https://attack.mitre.org/techniques/T1098/001/) | [DET0531](https://attack.mitre.org/detectionstrategies/DET0531/) — Additional Cloud Credentials | Service principal using credentials from an unusual location or at unusual times |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page.

| Technique | Detection Strategy |
|:----------|:-------------------|
| [T1110.003](https://attack.mitre.org/techniques/T1110/003/) | [DET0487](https://attack.mitre.org/detectionstrategies/DET0487/) &mdash; Distributed Password Spraying via Authentication Failures Across Multiple Accounts |
| [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) &mdash; Detection of Valid Account Abuse Across Platforms |
| [T1621](https://attack.mitre.org/techniques/T1621/) | [DET0160](https://attack.mitre.org/detectionstrategies/DET0160/) &mdash; Detection Strategy for Multi-Factor Authentication Request Generation (T1621) |
| [T1557](https://attack.mitre.org/techniques/T1557/) | [DET0296](https://attack.mitre.org/detectionstrategies/DET0296/) &mdash; Detect Adversary-in-the-Middle via Network and Configuration Anomalies |
| [T1550.001](https://attack.mitre.org/techniques/T1550/001/) | [DET0185](https://attack.mitre.org/detectionstrategies/DET0185/) &mdash; Behavioral Detection Strategy for Use Alternate Authentication Material: Application Access Token (T1550.001) |
| [T1606.002](https://attack.mitre.org/techniques/T1606/002/) | [DET0148](https://attack.mitre.org/detectionstrategies/DET0148/) &mdash; Detection Strategy for Forged SAML Tokens |
| [T1098.003](https://attack.mitre.org/techniques/T1098/003/) | [DET0277](https://attack.mitre.org/detectionstrategies/DET0277/) &mdash; Detection Strategy for Role Addition to Cloud Accounts |
| [T1136.003](https://attack.mitre.org/techniques/T1136/003/) | [DET0319](https://attack.mitre.org/detectionstrategies/DET0319/) &mdash; Detection Strategy for T1136.003 - Cloud Account Creation across IaaS, IdP, SaaS, Office |
| [T1528](https://attack.mitre.org/techniques/T1528/) | [DET0515](https://attack.mitre.org/detectionstrategies/DET0515/) &mdash; Detection Strategy for T1528 - Steal Application Access Token |
| [T1484.002](https://attack.mitre.org/techniques/T1484/002/) | [DET0458](https://attack.mitre.org/detectionstrategies/DET0458/) &mdash; Detection of Trust Relationship Modifications in Domain or Tenant Policies |
| [T1562.001](https://attack.mitre.org/techniques/T1562/001/) *(revoked &rarr; [T1685](https://attack.mitre.org/techniques/T1685/))* | [DET0497](https://attack.mitre.org/detectionstrategies/DET0497/) &mdash; Detection of Defense Impairment through Disabled or Modified Tools across OS Platforms. |
| [T1589.001](https://attack.mitre.org/techniques/T1589/001/) | [DET0813](https://attack.mitre.org/detectionstrategies/DET0813/) &mdash; Detection of Credentials |
| [T1537](https://attack.mitre.org/techniques/T1537/) | [DET0573](https://attack.mitre.org/detectionstrategies/DET0573/) &mdash; Cross-Platform Detection of Data Transfer to Cloud Account |
| [T1078.004](https://attack.mitre.org/techniques/T1078/004/) | [DET0546](https://attack.mitre.org/detectionstrategies/DET0546/) &mdash; Detection of Abused or Compromised Cloud Accounts for Access and Persistence |
| [T1552.004](https://attack.mitre.org/techniques/T1552/004/) | [DET0549](https://attack.mitre.org/detectionstrategies/DET0549/) &mdash; Detect Suspicious Access to Private Key Files and Export Attempts Across Platforms |
| [T1098.001](https://attack.mitre.org/techniques/T1098/001/) | [DET0531](https://attack.mitre.org/detectionstrategies/DET0531/) &mdash; Detection Strategy for Additional Cloud Credentials in IaaS/IdP/SaaS |
| [T1087.004](https://attack.mitre.org/techniques/T1087/004/) | [DET0386](https://attack.mitre.org/detectionstrategies/DET0386/) &mdash; Cloud Account Enumeration via API, CLI, and Scripting Interfaces |
| [T1114.002](https://attack.mitre.org/techniques/T1114/002/) | [DET0048](https://attack.mitre.org/detectionstrategies/DET0048/) &mdash; Detect Remote Email Collection via Abnormal Login and Programmatic Access |
| [T1213.002](https://attack.mitre.org/techniques/T1213/002/) | [DET0500](https://attack.mitre.org/detectionstrategies/DET0500/) &mdash; Detecting Abnormal SharePoint Data Mining by Privileged or Rare Users |

> [!NOTE]
> This page intentionally omits the third MITRE-evidence column. For identity-provider strategies, MITRE may cite cross-platform or provider-specific source names that do not map 1:1 to Microsoft Entra ID tables; keeping this section as Technique + Detection Strategy avoids a brittle translation layer.

> [!NOTE]
> **MITRE legacy technique IDs.** Some technique IDs cited on this page are *legacy* IDs that MITRE has revoked and remapped: T1562.001 &rarr; T1685. Published Detection Strategies are attached to the current technique IDs only; the table above follows the `revoked-by` chain so each strategy still applies to the legacy ID cited above.

> [!TIP]
> Detection Strategies are MITRE-published *pseudo-code analytics*, not vendor rules — they tell you **what** to correlate across data sources. Use them to validate that your Sentinel analytic rules and KQL hunting queries cover the published correlation logic.

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

## Hybrid Identity Server Events (AD FS and Entra Connect)

The tables above cover the **cloud** side of identity. Where an organisation still runs AD FS or Microsoft Entra Connect, the attack path into the tenant frequently starts on those **on-premises servers** — and none of that activity appears in `SigninLogs` or `AuditLogs`.

[*Detecting and mitigating Active Directory compromises*](https://www.cisa.gov/resources-tools/resources/detecting-and-mitigating-active-directory-compromises) describes two techniques that cross this boundary:

- **Golden SAML** — the AD FS token-signing certificate is stolen, letting an attacker mint SAML tokens for any user. Authentication then succeeds in the cloud without any federated sign-in ever happening, so the tenant sees a valid sign-in and nothing suspicious.
- **Microsoft Entra Connect compromise** — the sync account is abused to change cloud objects, or hard match takeover and soft matching are used to bind an attacker-controlled on-premises object to an existing cloud identity.

These events are in the `Application` and AD FS channels on the servers themselves, so they require a **custom DCR writing to `WindowsEvent`** — they do not arrive through the Entra ID connector or through `SecurityEvent`.

| Event ID | Server | Description | Why it matters |
|:---------|:-------|:------------|:---------------|
| **70** | AD FS | A certificate private key was acquired | Direct precursor to Golden SAML — the token-signing key is the whole attack |
| **307** | AD FS | The Federation Service configuration was changed | Trust or claim-rule tampering |
| **510** | AD FS | Additional detail for configuration-change events | Correlate with 307 for the specifics of what changed |
| **1007** | AD FS | A certificate was exported | Token-signing certificate leaving the server |
| **1102** | AD FS / Entra Connect | The Security audit log was cleared | Post-compromise cleanup |
| **1200** | AD FS | The Federation Service issued a valid token | Baseline for legitimate issuance — tokens accepted by the tenant with **no** matching 1200 indicate forgery |
| **1202** | AD FS | The Federation Service validated a new credential | Credential validation trail |
| **611** | Entra Connect | Password hash synchronisation failed for the domain | Sync disruption, often the first sign of tampering |
| **650, 651** | Entra Connect | Password sync started / finished retrieving passwords from AD DS | Establishes the normal sync rhythm |
| **656, 657** | Entra Connect | Password change detected and synced to Entra ID | Off-schedule activity on privileged accounts |

> [!IMPORTANT]
> **Golden SAML is detected by absence.** A forged token is never issued by AD FS, so there is no 1200 to find. The signal is a successful cloud sign-in for a federated user with **no corresponding token issuance** on the AD FS server — which is only possible if AD FS events are being collected in the first place. Without them the attack is invisible from the tenant side.

> [!TIP]
> Do not synchronise privileged on-premises accounts to Entra ID, and keep separate privileged accounts for AD DS and Entra ID. This removes the sync path as an escalation route entirely and is cheaper than detecting its abuse.

For the domain controller side of these techniques — including event 4662, which detects both DCSync and the directory reads behind Golden SAML — see [Windows Security Events](windows-security-events.md#active-directory-compromise-events-domain-controllers).

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
| Microsoft Sentinel benefit for M365 E5 customers | Official offer details for entitlement-based Sentinel Analytics-tier ingestion benefits | [azure.microsoft.com](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer) |
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
| Detecting and mitigating Active Directory compromises | ASD, CISA, NSA, FBI and international partners | Joint guidance covering Golden SAML and Microsoft Entra Connect compromise, with the AD FS and Entra Connect event IDs to collect (Appendix B, Tables 20–21) | [cisa.gov](https://www.cisa.gov/resources-tools/resources/detecting-and-mitigating-active-directory-compromises) · [PDF](https://www.cyber.gov.au/sites/default/files/2026-09/Detecting%20and%20mitigating%20Active%20Directory%20compromises%20%28September%202026%29.pdf) |
| Sentinel Ninja — Microsoft Entra ID connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/azureactivedirectory.md) |
| AADGraphActivityLogs in Microsoft Sentinel | Truls Dahlsveen (Infernux) | Detecting legacy Azure AD Graph (`graph.windows.net`) traffic via the `AADGraphActivityLogs` table — AADInternals / ROADtools detection queries and correlation with `SigninLogs` | [infernux.no](https://infernux.no/blog/aadgraphactivitylogs/) |
| Now you see me: AADGraphActivityLogs | Fabian Bader (Cloud Brothers) | Deep dive into the `AADGraphActivityLogs` schema and detection opportunities (UserAgent, RequestUri, ResponseSizeBytes), including ROADtools / Ping Castle detection and LLM-assisted hunting | [cloudbrothers.info](https://cloudbrothers.info/en/aadgraphactivitylogs/) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
