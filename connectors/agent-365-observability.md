# Microsoft Agent 365 Observability (Preview)

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No (paid ingestion; planning baseline, verify current entitlement) · **Conditional:** Applicable to supported AI agents emitting Agent 365 telemetry

---

## Contents

- [Overview](#overview)
  - [Licensing Benefits](#licensing-benefits)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
  - [Runtime and Tool Activity](#runtime-and-tool-activity)
- [MITRE Detection Strategies](#mitre-detection-strategies)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Important Considerations](#important-considerations)
  - [Collection and Validation](#collection-and-validation)
  - [Data Lake and Retention](#data-lake-and-retention)
- [Notes](#notes)
- [Tools](#tools)
- [References](#references)
  - [Official Documentation](#official-documentation)
  - [Community & Third-Party Resources](#community--third-party-resources)
  - [Admin portal](#admin-portal)

---

## Overview

The **Agent 365** data connector brings AI agent runtime telemetry into Microsoft Sentinel Data Lake. The official connector catalogue describes activity from Agent 365, Foundry and Copilot, supporting investigation of agent behaviour, tool usage and execution. Coverage depends on the supported host and the telemetry it actually emits; enabling the connector does not instrument every AI application in the organisation.

> [!IMPORTANT]
> **Preview connector.** Availability, schemas and supported capabilities may change. Verify the current connector documentation and validate behaviour in your tenant before production use.

This is **conditional Tier 2 visibility** for organisations using supported agents. It complements [Microsoft Copilot / AI Governance](copilot-ai-governance.md), which covers Copilot audit activity, and [Microsoft Defender XDR](microsoft-defender-xdr.md), which provides security signals and alerts. Runtime telemetry helps reconstruct what an agent did; it does not replace agent ownership/inventory, identity logs, resource audit logs or security verdicts.

### Licensing Benefits

| Sentinel cost classification | Microsoft Sentinel benefit |
|:-----------------------------|:---------------------------|
| **No (paid ingestion)** | Budget as paid unless a current entitlement explicitly covers this source. The linked connector reference does not establish a connector-specific free ingestion benefit. Verify applicable ingestion, storage and query charges separately from Agent 365 product licensing. |

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| `UnifiedAgentObservability` | Agent activity, tool usage and execution telemetry | Analytics: N/A / Lake: 365d (recommendation; verify source retention controls) | Preserve runtime evidence that audit records and alerts alone may not contain | Reconstruct an agent's recorded execution sequence and identify called tools | Investigate a newly observed tool accessing an unexpected resource, corroborated with destination audit logs |

> [!IMPORTANT]
> **Lake-only source.** Microsoft's connector definition explicitly lists `UnifiedAgentObservability` in its setup instructions for ingestion into Microsoft Sentinel Lake. It does not publish the detailed schema or retention settings. The retention period above is a model recommendation, not a documented service default.

---

## Example Detections

### Runtime and Tool Activity

These are **hunting and correlation patterns**, not supplied or tenant-tested analytic rules. Baseline expected activity and validate the available fields before turning a pattern into an alert.

| Detection | Table(s) / Event ID(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:-----------------------|:-------------|:-------------------|:------------|
| Agent tool accessing unexpected cloud-stored data | `UnifiedAgentObservability` plus destination resource audit logs | [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) - Multi-Platform Cloud Storage Exfiltration Behavior Chain | Compare recorded tool targets with the agent's authorised scope; use destination logs to establish actual access. A request alone does not prove collection or exfiltration. |
| New tool usage by an established agent | `UnifiedAgentObservability` | Not assigned from novelty alone | Not mapped | Compare with a known baseline and approved tool inventory. Planned changes, low activity and incomplete historical collection can all explain a first-seen tool. |
| Repeated tool failures or unexpected targets | `UnifiedAgentObservability` | Not assigned from errors alone | Not mapped | Review available error details and resource targets, then correlate with identity and resource logs. Distinguish configuration faults from suspicious probing. |
| Agent activity associated with an AI safety signal | `UnifiedAgentObservability` plus relevant `CloudAppEvents` or security alerts | Depends on the corroborated action | Not mapped | Validate source-specific agent/session identifiers and timing before associating a safety event with tool execution. A missing match is not proof that an action was blocked. |

---

## MITRE Detection Strategies

| Technique | Detection Strategy |
|:----------|:-------------------|
| [T1530](https://attack.mitre.org/techniques/T1530/) - Data from Cloud Storage | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) - Multi-Platform Cloud Storage Exfiltration Behavior Chain |

> [!NOTE]
> This page uses the two-column mapping because agent runtime events do not map directly to MITRE's raw log sources. The cloud-storage mapping applies only when corroborating evidence supports that behaviour; tool novelty, prompt keywords and errors alone are not ATT&CK techniques.

> [!TIP]
> Detection Strategies are MITRE-published pseudo-code analytics, not vendor rules. Use their correlation logic to assess a proposed detection, with agent runtime evidence as one input rather than proof of the complete behaviour.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-3** Enable logging for security investigation | Capture and validate available agent execution and tool-use evidence |
| **LT-5** Centralise security log management and analysis | Correlate runtime evidence with identity, resource and security logs |
| **LT-6** Configure log storage retention | Document the supported retention policy and any gap against the investigation target |

---

## Important Considerations

### Collection and Validation

- **Connector setup.** Install the Agent 365 solution from Content Hub and enable the Agent 365 connector. The connector definition lists `GlobalAdmin` tenant permissions. Validate source eligibility and instrumentation separately using the observability documentation.
- **Use current integration guidance.** Microsoft recommends its OpenTelemetry Distro for new integrations; the older Agent 365 Observability SDK is deprecated. First-party hosts and custom integrations need different collection validation.
- **Exercise a representative run.** Confirm the expected invocation and tool activity arrives, with useful agent identity, timestamps and correlation identifiers. Where appropriate, include a controlled failed tool call. Check freshness and missing spans, not only row counts.
- **Validate downstream evidence.** The observability service can return HTTP success while rejecting spans. The documented root `invoke_agent` span is important for downstream experiences; confirm the expected records in Sentinel independently of producer-side success.
- **Record evidence and gaps.** Note the agent/host tested, query scope, test time, received event types and unavailable fields. Absence from a workspace Usage query or an ARM table inventory is not sufficient evidence that a Data Lake system source is disconnected.

### Data Lake and Retention

This connector ingests into Data Lake. The model recommends 365 days of retained history where the source supports it and the data-handling policy permits it. Confirm the actual retention controls; the connector definition does not document them. Analytics retention is not part of this connector's direct ingestion configuration.

Do not assume ordinary scheduled or near-real-time Analytics rules can query this source directly. If a supported detection design requires Analytics data, evaluate a [KQL job](https://learn.microsoft.com/en-us/azure/sentinel/datalake/kql-jobs) to promote a minimal, validated result set. Check source support, permissions, schema, event-time preservation, duplicate handling, latency and costs before deployment. Promotion does not make the original collection real-time or complete.

---

## Notes

- **Protect content.** Prompts, tool arguments and results may contain personal data, credentials or business-sensitive content. Restrict access and exports, minimise copied payloads and align retention with the organisation's policy.
- **Do not promise full transcripts.** Captured content and identifiers vary by agent host and instrumentation. Missing fields may be expected or may indicate a collection issue; distinguish the two using a known test run.
- **Keep sources separate.** `CopilotActivity` audit records, `CloudAppEvents` security metadata, agent inventory and runtime spans are complementary. Do not assume equal row counts or interchangeable IDs across them.
- **Correlate carefully.** Names and broad time windows can associate unrelated runs. Establish source-specific identity and session mappings and document ambiguous matches.
- **Revalidate before production use.** The linked hunting examples are implementation references, not guarantees of a stable schema, complete coverage or confirmed malicious behaviour.

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| Sentinel Data Lake querying | Portal | Validate available runtime records and reconstruct an observed run in the supported query scope | Microsoft Defender portal | See Collection and Validation above |
| KQL jobs | Data Lake capability | Optionally promote a selected result set for a supported downstream investigation or detection design | Microsoft Sentinel | [Official documentation](https://learn.microsoft.com/en-us/azure/sentinel/datalake/kql-jobs) |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Agent 365 (Sentinel data connectors reference) | Connector scope and Data Lake destination; no table list or DCR support currently published in this entry | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/data-connectors-reference#agent-365) |
| Agent 365 connector definition | Microsoft-maintained source for the connector's Data Lake setup, source name and tenant permissions | [github.com](https://github.com/Azure/Azure-Sentinel/blob/master/Solutions/Agent%20365/Data%20Connectors/A365_DataConnectorDefinition.json) |
| Agent 365 observability concepts | Integration paths, identity, licensing, span acceptance and downstream visibility | [learn.microsoft.com](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/observability-concepts) |
| KQL jobs in Microsoft Sentinel Data Lake | Supported processing and promotion workflow, permissions and limitations | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/datalake/kql-jobs) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja - Agent 365 | Ofer Shezaf (Microsoft) | Connector reference with links to the Microsoft definition and Agent 365 solution | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/a365.md) |
| Securing Enterprise AI Agents with Microsoft Sentinel | Santosh Pargi (Microsoft) | Cross-source architecture and linked hunting examples for runtime telemetry, agent identity, Copilot audit records and Defender signals | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/securing-enterprise-ai-agents-with-microsoft-sentinel/4542583) |

### Admin portal

- [Microsoft Defender portal](https://security.microsoft.com/) - review the Agent 365 connector and validate runtime evidence through the available Microsoft Sentinel Data Lake experiences.

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)