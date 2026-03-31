# Azure Kubernetes Service (AKS) Audit

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party (Diagnostic Settings) · **Free ingestion:** No

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

AKS audit logs capture **Kubernetes API server operations**: pod creation, deployment changes, RBAC modifications, secrets access, and namespace management. For organisations running containerised workloads on AKS, these logs are essential for detecting container escape, lateral movement within the cluster, privilege escalation through RBAC, and supply chain attacks via malicious container images.

While Azure Activity Logs (Tier 1) capture AKS cluster-level operations (create, delete, scale), the Kubernetes audit logs capture the *data plane* — what's happening **inside** the cluster. Defender for Containers (Tier 2, via Defender for Cloud) provides alerts; these audit logs provide the detailed investigation trail.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any AKS cluster** | Kubernetes audit log streaming via AKS diagnostic settings |
| **Defender for Containers** | Runtime threat detection and vulnerability scanning for containers (alerts flow through Defender for Cloud → Tier 2) |

> [!NOTE]
> AKS audit logs can generate **very high volume** on active clusters. Use the `kube-audit-admin` category instead of `kube-audit` to exclude informational GET requests and reduce volume by ~80% while retaining security-relevant events.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AKSAudit** | Kubernetes API server audit events (resource-specific mode) — create, update, delete operations for all Kubernetes resources | Analytics: 90d / Lake: 365d | Primary Kubernetes security audit trail — captures all cluster operations including RBAC changes, secret access, and workload modifications | Reconstructs attacker actions within the Kubernetes cluster — which pods were created, what secrets were accessed, what RBAC changes were made | Privileged pod created in default namespace (T1610) |
| **AKSAuditAdmin** | Filtered view of AKS audit events — excludes read-only (GET/LIST) operations, reducing volume significantly | Analytics: 90d / Lake: 365d | Same security value as full audit with dramatically reduced volume — ideal for most security monitoring use cases | Same forensic value for write operations — all mutations are captured | ClusterRoleBinding created granting cluster-admin (T1098) |
| **AKSControlPlane** | AKS control plane component logs — API server, controller manager, scheduler, admission webhooks | Analytics: 30d / Lake: 180d | Operational health and debugging data for the control plane — less security-focused but valuable for troubleshooting | Identifies control plane issues that may indicate compromise — failed admission webhooks, scheduler anomalies | API server admission webhook disabled (T1562.001) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Privileged container created | AKSAudit, AKSAuditAdmin | T1610 | Pod created with privileged security context or host namespace access — potential container escape |
| Secret accessed from unusual pod | AKSAudit | T1552.007 | Kubernetes Secret read by a pod that doesn't normally access secrets |
| ClusterRole or ClusterRoleBinding modified | AKSAuditAdmin | T1098 | RBAC escalation — new ClusterRoleBinding granting cluster-admin or broad permissions |
| Container image from untrusted registry | AKSAudit | T1195.002 | Pod created with a container image from an unapproved registry — supply chain risk |
| Exec into running container | AKSAudit | T1609 | `kubectl exec` into a running container — interactive shell access to a workload |
| Namespace deletion | AKSAuditAdmin | T1485 | Kubernetes namespace deleted — could indicate destructive attack or cleanup after compromise |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection capabilities | AKS audit logs enable Kubernetes-specific threat detection for container workloads |
| **LT-3** Enable logging for security investigation | Kubernetes audit trail is essential for investigating container compromise and lateral movement |
| **NS-2** Secure cloud services with network controls | Monitors network policy changes within the Kubernetes cluster |
| **CT-1** Manage image vulnerabilities | Monitors which container images are deployed — detects untrusted or vulnerable images |

---

## Important Considerations

- **Use kube-audit-admin:** The `kube-audit-admin` diagnostic category excludes GET/LIST operations, reducing volume by ~80% while retaining all security-relevant (create/update/delete) events
- **Resource-specific mode:** Enable resource-specific mode in diagnostic settings to use the dedicated `AKSAudit` / `AKSAuditAdmin` tables instead of the generic `AzureDiagnostics` table
- **Volume management:** Active clusters with many workloads can generate significant audit volume. Consider filtering by namespace in DCR transformations
- **Defender for Containers:** If you have Defender for Cloud (Tier 2), container threat detection alerts already flow through `SecurityAlert`. The audit logs in this Tier 3 connector add the detailed investigation trail

---

## Notes

- AKS audit logs are essential for organisations running production workloads on Kubernetes — container escape and lateral movement within clusters are increasingly common attack patterns
- Pair with VNet Flow Logs (Tier 2) for network-level visibility alongside Kubernetes-level audit data
- The Defender for Containers runtime sensor provides complementary telemetry — process-level events within containers

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify AKS audit log volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| AKS monitoring with diagnostics | [Learn](https://learn.microsoft.com/en-us/azure/aks/monitor-aks) |
| AKS diagnostic settings categories | [Learn](https://learn.microsoft.com/en-us/azure/aks/monitor-aks-reference) |
| Defender for Containers overview | [Learn](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-introduction) |
| Kubernetes threat matrix (MITRE) | [Microsoft](https://www.microsoft.com/en-us/security/blog/2020/04/02/attack-matrix-kubernetes/) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
