# Azure Activity Logs

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party · **Free ingestion:** Yes (free data source)

---

## Overview

Azure Activity Logs capture **subscription-level events** across all your Azure resources. This includes resource creation and deletion, role assignments, policy changes, service health events, and autoscale operations. It is the **control plane audit trail** for your Azure environment and is indispensable for detecting unauthorized infrastructure changes, privilege escalation via Azure RBAC, and resource abuse (e.g., crypto-mining VMs).

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Azure subscription** | Full activity log data — no additional license required |

> [!NOTE]
> Azure Activity Logs are a **free data source** in Sentinel. Every Azure subscription generates these logs. Connect all subscriptions.

---

## Tables and Rationale

| Table | Category | Description | Retention Recommendation | Rationale |
|:------|:---------|:------------|:------------------------|:----------|
| **AzureActivity** | Administrative | Resource creation, modification, deletion (PUT, PATCH, DELETE operations) | Hot: 90d / Archive: 2y | Detects unauthorized resource deployment (crypto-mining VMs, exfiltration infrastructure), resource deletion (sabotage), and configuration changes. MCSB AM-2 (Use only approved services), LT-3. |
| **AzureActivity** | Security | Security Center / Defender for Cloud alerts and recommendations | Hot: 90d / Archive: 1y | Provides a secondary view of Defender for Cloud alerts at the platform level. |
| **AzureActivity** | ServiceHealth | Azure service incidents, planned maintenance | Hot: 90d / Archive: 6m | Operational context — helps distinguish between attacker activity and platform issues during investigations. |
| **AzureActivity** | Alert | Azure Monitor alert events | Hot: 90d / Archive: 6m | Operational alerting correlated with security context. |
| **AzureActivity** | Policy | Azure Policy evaluation results (compliance/non-compliance) | Hot: 90d / Archive: 1y | Tracks policy violations that may indicate security drift. MCSB GS-3 (Align organisation roles and responsibilities). |
| **AzureActivity** | Autoscale | Autoscale engine events | Hot: 90d / Archive: 6m | Can indicate unusual resource consumption patterns potentially triggered by an attacker. |
| **AzureActivity** | ResourceHealth | Resource health status changes | Hot: 90d / Archive: 6m | Operational context for resource availability investigations. |

---

## Example Detections

### Resource-Based

| Detection | Operation(s) | MITRE ATT&CK | Description |
|:----------|:-------------|:-------------|:------------|
| Crypto-mining VM deployment | Microsoft.Compute/virtualMachines/write | T1496 | Creation of GPU-optimised or high-CPU VMs in unusual regions or resource groups |
| Resource group deletion | Microsoft.Resources/subscriptions/resourceGroups/delete | T1485 | Mass deletion of resource groups — potential sabotage or destructive attack |
| Storage account public access enabled | Microsoft.Storage/storageAccounts/write | T1530 | Storage account configured with public blob/container access |
| Network Security Group rule modified | Microsoft.Network/networkSecurityGroups/securityRules/write | T1562.007 | NSG rules opened to allow inbound traffic from any source (0.0.0.0/0) |
| Virtual Network modification | Microsoft.Network/virtualNetworks/write | T1599 | Unauthorized changes to network topology (peering, subnets) |

### Identity / RBAC

| Detection | Operation(s) | MITRE ATT&CK | Description |
|:----------|:-------------|:-------------|:------------|
| Owner/Contributor role assigned | Microsoft.Authorization/roleAssignments/write | T1098.001 | Privilege escalation via RBAC — assigning Owner or Contributor role at subscription level |
| Custom role created with elevated permissions | Microsoft.Authorization/roleDefinitions/write | T1098 | Creation of custom roles that include wildcard (*) actions |
| Diagnostic settings deleted | Microsoft.Insights/diagnosticSettings/delete | T1562.008 | Attacker disabling logging to cover tracks — anti-forensic activity |
| Policy exemption created | Microsoft.Authorization/policyExemptions/write | T1562.001 | Exempting resources from security policies to bypass controls |

### Key Vault

| Detection | Operation(s) | MITRE ATT&CK | Description |
|:----------|:-------------|:-------------|:------------|
| Key Vault access policy modified | Microsoft.KeyVault/vaults/write | T1552.004 | Unauthorized changes to Key Vault access policies — potential secret exfiltration setup |
| Key Vault deleted / purged | Microsoft.KeyVault/vaults/delete | T1485 | Deletion of key vaults containing cryptographic keys or secrets |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **AM-2** Use only approved services | Activity logs detect deployment of unapproved resource types |
| **LT-1** Enable threat detection | Platform-level threat detection for Azure resource abuse |
| **LT-3** Enable logging for security investigation | Activity logs are the primary audit trail for Azure control plane operations |
| **LT-6** Configure log storage retention | Azure retains activity logs for 90 days natively — Sentinel extends this |
| **PA-7** Follow just enough administration | RBAC assignment tracking ensures least-privilege adherence |
| **GS-3** Align roles and responsibilities | Policy events track security governance compliance |
| **IR-4** Detection and analysis | Activity logs are critical for investigating Azure-based incidents |

---

## Important Considerations

### Log Categories to Enable

Enable **all categories** via the diagnostic settings:

| Category | Priority | Rationale |
|:---------|:---------|:----------|
| Administrative | **Critical** | All resource CRUD operations |
| Security | High | Defender for Cloud alerts at platform level |
| Policy | High | Compliance drift detection |
| ServiceHealth | Medium | Operational context |
| Alert | Medium | Azure Monitor alert correlation |
| Autoscale | Low | Resource consumption anomalies |
| ResourceHealth | Low | Availability context |

### Deployment

> [!WARNING]
> Connect **every Azure subscription** to Sentinel via diagnostic settings. Attackers frequently target development or sandbox subscriptions that have weaker monitoring.

Use Azure Policy to **enforce** diagnostic settings across all subscriptions:

```
Microsoft.Insights/diagnosticSettings — deployIfNotExists
```

This ensures new subscriptions are automatically connected to your Sentinel workspace.

---

## Notes

- Azure natively retains activity logs for **90 days** — Sentinel extends this to your configured retention period
- Activity logs cover the **control plane** only — for data plane operations (e.g., blob access, SQL queries), you need resource-specific diagnostic logs (Tier 2+)
- Consider combining with **Azure Resource Graph** snapshots for point-in-time infrastructure state during investigations
- High-value operations to watchlist: role assignments at subscription/management group scope, diagnostic settings changes, policy exemptions

*[Back to overview](../README.md)*
