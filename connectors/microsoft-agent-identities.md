# Microsoft Agent Identities (Preview)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No (paid ingestion; verify current entitlement) · **Conditional:** Applicable to organisations using supported agent identities and agent identity blueprints

---

## Contents

- [Overview](#overview)
  - [Licensing Benefits](#licensing-benefits)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
  - [Identity and Governance Checks](#identity-and-governance-checks)
- [MITRE Detection Strategies](#mitre-detection-strategies)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Important Considerations](#important-considerations)
  - [Collection and Validation](#collection-and-validation)
  - [Inventory History and Retention](#inventory-history-and-retention)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)
  - [Official Documentation](#official-documentation)
  - [Community & Third-Party Resources](#community--third-party-resources)
  - [Admin portal](#admin-portal)

---

## Overview

The **Microsoft Agent Identities** connector provides a central view of agent and agent blueprint identities. The official Sentinel connector catalogue describes identity and asset ingestion for understanding ownership, analysing relationships and correlating identities with activity and risk signals, including graph-based investigations.

This is **conditional Tier 2 visibility** under **Identity & Access (Extended)**. It helps investigators establish which identity represents an agent, how it relates to a blueprint and who is responsible for it. It is not a replacement for the [Microsoft Entra ID](microsoft-entra-id.md) connector's authentication and directory-change logs or [Agent 365 Observability](agent-365-observability.md)'s runtime and tool-use evidence.

> [!IMPORTANT]
> **Preview connector.** Microsoft's connector definition marks this connector as Preview and lists four sources for ingestion into Microsoft Sentinel Lake. It is included in the Agent 365 solution. Confirm availability and the current schema in the target tenant.

### Licensing Benefits

| Sentinel cost classification | Microsoft Sentinel benefit |
|:-----------------------------|:---------------------------|
| **No (paid ingestion)** | No connector-specific free Sentinel ingestion benefit is documented in the linked connector entry. Verify applicable ingestion, storage and query charges for the enabled service; Microsoft Entra or Agent 365 product entitlement does not by itself establish a Sentinel ingestion benefit. |

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| `EntraAgentIdentities` | Agent identity inventory | Analytics: N/A / Lake: 365d (recommendation; verify source retention controls) | Add agent identity context to investigations | Identify the agent identity associated with observed activity | Agent identity absent from the approved inventory |
| `EntraAgentIdentityBlueprintPrincipals` | Agent identity blueprint principal inventory | Analytics: N/A / Lake: 365d (recommendation; verify source retention controls) | Add blueprint principal context to identity analysis | Identify blueprint principals associated with the investigation | Blueprint principal absent from the approved inventory |
| `EntraAgentIdentityBlueprints` | Agent identity blueprint inventory | Analytics: N/A / Lake: 365d (recommendation; verify source retention controls) | Add blueprint context to agent investigations | Identify the relevant agent identity blueprint | Blueprint absent from the approved inventory |
| `EntraAgentUsers` | Agent user inventory | Analytics: N/A / Lake: 365d (recommendation; verify source retention controls) | Add agent user context to identity analysis | Identify an agent user associated with the investigation | Agent user absent from the approved inventory |

These names come from Microsoft's connector setup definition. The source is Lake-only; the definition does not publish detailed schemas, retention controls or historical snapshot behaviour. The 365-day Lake period is a model recommendation, not a documented service default. Inventory is not an immutable event history.

---

## Example Detections

### Identity and Governance Checks

These are **governance checks and investigation patterns**, not built-in analytic rules. Inventory provides context; separate audit and activity evidence is needed to establish what changed or what an agent did.

| Detection | Table(s) / Event ID(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:-----------------------|:-------------|:-------------------|:------------|
| Agent without a verified responsible party | Connector inventory plus the authoritative identity record | Not assigned from missing metadata alone | Not mapped | Compare available ownership information with the authoritative record. Distinguish an actual governance gap from a field the connector does not collect. |
| Unexpected agent-to-blueprint relationship | Connector inventory plus an approved baseline | Not assigned from a relationship alone | Not mapped | Confirm identifiers and observation times, then compare with the approved deployment. Use directory audit evidence before attributing a change to an actor. |
| Ownership or permission change associated with suspicious activity | Connector inventory plus relevant Entra audit and activity logs | Depends on the corroborated action | Not mapped | Use inventory to resolve the agent; establish the change, actor and timing from audit records and review subsequent activity. Do not infer a permission change from an inventory relationship alone. |
| Risk signal associated with an agent identity | Connector inventory plus the originating risk or alert source | Depends on the corroborated action | Not mapped | Resolve the identity and related blueprint, identify the responsible team and investigate the underlying signal. A relationship does not prove that every related agent is compromised. |

---

## MITRE Detection Strategies

| Technique | Detection Strategy |
|:----------|:-------------------|
| No standalone technique assigned to inventory or ownership gaps | Select a strategy only after activity and audit evidence establish a specific adversary behaviour; use the relevant identity or workload connector's mapping. |

> [!NOTE]
> The two-column format is intentional: identity assets are not raw authentication or audit events. The checks above do not establish an ATT&CK technique merely because an agent is new, has incomplete ownership metadata or is related to a risky identity. "Not mapped" does not mean that MITRE has no strategy for a subsequently confirmed behaviour.

> [!TIP]
> MITRE Detection Strategies describe correlation logic, not vendor rules. Agent inventory can enrich a detection; it does not substitute for the event evidence that the strategy requires.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **IM-1** Centralise identity management | Resolve agent identities and their relationships to the organisation's authoritative identity records |
| **LT-5** Centralise security log management and analysis | Enrich activity and risk investigations with agent identity context |
| **LT-6** Configure log storage retention | Record whether historical identity context is available and how long it remains accessible |

---

## Important Considerations

### Collection and Validation

- **Connector setup.** Install the Agent 365 solution from Content Hub and enable Microsoft Agent Identities. The connector definition lists `GlobalAdmin` and `SecurityAdmin` tenant permissions and explicitly marks the connector as Preview.
- **Compare known objects.** Select an existing agent and its associated blueprint in the authoritative identity system. Confirm that the expected identities, relationship and available ownership fields appear in Sentinel, recording the query surface and observation time.
- **Preserve identifier meaning.** Distinguish application IDs, object IDs, agent IDs and blueprint IDs. Establish their mapping before joining to Entra logs, runtime telemetry or alerts; display names alone are not reliable join keys.
- **Check freshness and coverage.** Document the observed refresh behaviour, supported identity types and any missing fields. An empty inventory or absent workspace Usage record is not, on its own, proof that no agents exist or that the connector is disconnected.
- **Verify lifecycle handling.** Where an approved test is available, check how creation, updates and deletion become visible. Determine whether old records are retained, replaced or removed rather than assuming an immutable change history.

### Inventory History and Retention

A current inventory answers **what is known now**, not necessarily **what was true during an incident**. Establish whether the source retains historical versions, timestamps changes or only refreshes current state. Preserve the relevant observation time when using inventory as incident evidence.

Apply the normal model retention targets only to stores and history mechanisms that demonstrably support them. Document any fixed service retention or unavailable history as a forensic limitation. Maintain authentication, directory audit and runtime evidence through their own connectors and retention policies.

---

## Notes

- **Ownership is not activity attribution.** An owner or sponsor is not necessarily the person who invoked an agent, approved its permissions or performed an observed change. Keep those roles distinct.
- **Relationships are not effective permissions.** Confirm access rights, inherited permissions and consent against the authoritative identity and resource configuration; an agent-to-blueprint relationship is not a complete access review.
- **Coverage is conditional.** Do not assume that every AI application, traditional service principal or unregistered agent is represented in this inventory.
- **Do not assume rule compatibility.** Graph or inventory visibility does not establish that the source is directly queryable by scheduled or near-real-time Analytics rules. Verify the supported investigation and detection paths before deployment.
- **Keep collection read-only during assessment.** Review existing objects and evidence; creation, permission changes and lifecycle tests require separate approval.

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| Sentinel identity and graph investigations | Portal | Inspect available agent assets and relationships and correlate them with investigation evidence | Microsoft Defender portal | [Collection and Validation](#collection-and-validation) |
| Entra agent identity administration | Portal | Compare connector records with the authoritative identity and available ownership information | Microsoft Entra admin centre | [What are agent identities?](https://learn.microsoft.com/en-us/entra/agent-id/what-are-agent-identities) |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Microsoft Agent Identities (Sentinel data connectors reference) | Connector purpose: agent and blueprint identity assets, ownership and relationship analysis | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/data-connectors-reference#microsoft-agent-identities) |
| Microsoft Agent Identities connector definition | Microsoft-maintained source for Preview status, four Data Lake source names and tenant permissions | [github.com](https://github.com/Azure/Azure-Sentinel/blob/master/Solutions/Agent%20365/Data%20Connectors/EntraNHIAssets_DataConnectorDefinition.json) |
| What are agent identities? | Microsoft Entra identity concepts, autonomous and delegated access, product availability and licensing distinctions | [learn.microsoft.com](https://learn.microsoft.com/en-us/entra/agent-id/what-are-agent-identities) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja - Microsoft Agent Identities | Ofer Shezaf (Microsoft) | Connector reference with links to the Microsoft definition and Agent 365 solution | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/entranhiassets.md) |
| Securing Enterprise AI Agents with Microsoft Sentinel | Santosh Pargi (Microsoft) | Positions agent identity and asset inventory alongside runtime telemetry, audit activity and Defender signals | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/securing-enterprise-ai-agents-with-microsoft-sentinel/4542583) |

### Admin portal

- [Microsoft Defender portal](https://security.microsoft.com/) - review the connector and available Sentinel agent identity and relationship views.
- [Microsoft Entra admin centre](https://entra.microsoft.com/) - verify the authoritative agent identity, blueprint association and available ownership information.

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)