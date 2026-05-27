# Microsoft Copilot / AI Governance

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No · **Conditional:** Requires Copilot licensing

---

## Contents

- [Microsoft Copilot / AI Governance](#microsoft-copilot--ai-governance)
	- [Contents](#contents)
	- [Overview](#overview)
		- [Current AI Log Sources](#current-ai-log-sources)
		- [Licensing Benefits](#licensing-benefits)
	- [Tables and Rationale](#tables-and-rationale)
	- [Example Detections](#example-detections)
		- [M365 Copilot](#m365-copilot)
		- [Azure OpenAI](#azure-openai)
	- [MITRE Detection Strategies](#mitre-detection-strategies)
	- [MCSB Control Mapping](#mcsb-control-mapping)
	- [Notes](#notes)
	- [Tools](#tools)
	- [References](#references)

---

## Overview

As organisations adopt AI assistants across the Microsoft ecosystem — Microsoft 365 Copilot, Microsoft Security Copilot, Azure OpenAI Service — logging AI interactions becomes a new security and governance requirement. These logs track **who is using AI, what they are asking, and whether AI is exposing data that users shouldn't have access to**.

The Copilot/AI governance logging story in Sentinel is evolving rapidly. This page covers the current state and emerging data sources.

### Current AI Log Sources

| Product | Log Source | Sentinel Table |
|:--------|:----------|:---------------|
| **Microsoft 365 Copilot** | Purview Audit | `CopilotActivity` |
| **Microsoft Security Copilot** | Diagnostic settings | Audit logs via Azure diagnostic settings |
| **Azure OpenAI Service** | Azure diagnostic settings | `AzureDiagnostics` (Cognitive Services) |

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Microsoft 365 E5 + Copilot** | M365 Copilot interaction audit events in OfficeActivity |
| **Security Copilot** | Security Copilot session and query audit logs |
| **Azure OpenAI Service** | Prompt and completion logging via diagnostic settings |

> [!NOTE]
> AI governance logging is an evolving area. New tables and connector capabilities are being released regularly. Check the Sentinel Content Hub for the latest AI-related solutions.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **CopilotActivity** | M365 Copilot interactions — user, application (Word, Teams, Excel), query metadata | Analytics: 90d / Lake: 365d | Tracks AI usage patterns — detects data oversharing via Copilot, unusual query patterns, and policy violations. | Proves which users interacted with Copilot, in which application, and whether the interaction surfaced sensitive content. Essential for investigating data leakage via AI. | User Copilot query surfacing confidential documents the user shouldn't access |
| **AzureDiagnostics** (Cognitive Services) | Azure OpenAI API calls — model, token count, caller identity, HTTP status | Analytics: 90d / Lake: 365d | Tracks Azure OpenAI usage — detects prompt injection, excessive token usage, and unauthorized API access. MCSB LT-3. | Audit trail of all Azure OpenAI API calls — proves who called the API, with which model, and consumption patterns. | Unusual Azure OpenAI API usage pattern — potential prompt injection or data extraction (T1059) |

---

## Example Detections

### M365 Copilot

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Copilot surfacing restricted content | OfficeActivity | [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) — Multi-Platform Cloud Storage Exfiltration Behavior Chain | Copilot responding with content from restricted SharePoint sites — indicates permission gap |
| Excessive Copilot usage by single user | OfficeActivity | — | — | Abnormally high interaction volume — may indicate data harvesting via AI |
| Copilot used during incident | OfficeActivity + SigninLogs | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Detection of Valid Account Abuse Across Platforms | Compromised account using Copilot to enumerate internal knowledge bases |

### Azure OpenAI

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| Prompt injection attempt | AzureDiagnostics | [T1059](https://attack.mitre.org/techniques/T1059/) | [DET0516](https://attack.mitre.org/detectionstrategies/DET0516/) — Behavioral Detection of Command and Scripting Interpreter Abuse | Request patterns indicative of prompt injection — unusual system message overrides |
| Unauthorized API caller | AzureDiagnostics | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Detection of Valid Account Abuse Across Platforms | Azure OpenAI API called from unexpected service principal or IP |
| Excessive token consumption | AzureDiagnostics | [T1496](https://attack.mitre.org/techniques/T1496/) | [DET0267](https://attack.mitre.org/detectionstrategies/DET0267/) — Resource Hijacking Detection Strategy | Abnormal token usage — potential abuse of AI compute resources |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page.

| Technique | Detection Strategy |
|:----------|:-------------------|
| [T1059](https://attack.mitre.org/techniques/T1059/) | [DET0516](https://attack.mitre.org/detectionstrategies/DET0516/) &mdash; Behavioral Detection of Command and Scripting Interpreter Abuse |
| [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) &mdash; Multi-Platform Cloud Storage Exfiltration Behavior Chain |
| [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) &mdash; Detection of Valid Account Abuse Across Platforms |
| [T1496](https://attack.mitre.org/techniques/T1496/) | [DET0267](https://attack.mitre.org/detectionstrategies/DET0267/) &mdash; Resource Hijacking Detection Strategy |

> [!NOTE]
> This page intentionally omits the third MITRE-evidence column. It combines `OfficeActivity`, `SigninLogs`, and `AzureDiagnostics` across Copilot and Azure OpenAI, so MITRE source names do not map 1:1 to the telemetry shown here.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-3** Enable logging for security investigation | AI interaction logs provide the audit trail for AI governance |
| **DP-2** Monitor anomalies and threats that target sensitive data | AI assistants may surface and expose sensitive data |
| **IM-1** Centralise identity management | Copilot interactions are tied to user identity — usage monitoring |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-2 (audit events) and SI-4 (system monitoring), CIS Controls v8 8.2 (collect audit logs), and ASD ACSC cloud logging priority #4 (administrative configuration changes). As AI governance standards evolve, additional framework mappings will be added.

---

## Notes

- AI governance logging is **evolving rapidly** — revisit this page as new Sentinel connectors and tables become available
- M365 Copilot interactions are also audited in the `OfficeActivity` table (already a Tier 1 free connector), giving partial AI audit coverage at no extra cost. The dedicated Microsoft Copilot data connector adds structured `CopilotActivity` events — this is **paid ingestion** and requires the Copilot licence
- The primary security concern with M365 Copilot is **data oversharing** — Copilot surfaces everything the user has access to, making over-permissioned accounts a higher risk
- For Azure OpenAI, enable **diagnostic settings** on the Cognitive Services resource to capture API call logs
- Consider deploying Purview **Copilot governance policies** alongside Sentinel monitoring for preventive + detective controls
- The Microsoft Copilot solution ships four **built-in analytic rules** out of the box covering the highest-value detection categories: `CopilotFileUploadsDisabled` (policy tampering), `CopilotJailbreakAttempt` (adversarial prompt manipulation, parses `LLMEventData.Messages[0].JailbreakDetected`), `CopilotPluginCreatedByNonAdmin` (unauthorised plugin extension), and `CopilotPluginTampering` (plugin supply-chain / insider risk). Deploy these first, then layer custom KQL on `CopilotActivity` for volume, geographic, and after-hours anomalies
- The `LLMEventData` dynamic field carries the AI interaction context (model, workload, jailbreak signals) that no traditional log source provides — parsing and correlating it is the core skill for Copilot detection engineering

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor AI-related log ingestion | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Microsoft Copilot** | Solution | Provides the Microsoft Copilot connector for ingesting CopilotActivity logs | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Microsoft Copilot data connector (Sentinel data connectors reference) | Official Sentinel data connector entry — `CopilotActivity` table, prerequisites (Security Administrator or Global Administrator), Lake-only ingestion note | [learn.microsoft.com](https://learn.microsoft.com/azure/sentinel/data-connectors-reference#microsoft-copilot) |
| Microsoft Copilot data connector for Microsoft Sentinel | Connector setup guide — CopilotActivity table via Purview audit pipeline | [techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/microsoftsentinelblog/the-microsoft-copilot-data-connector-for-microsoft-sentinel-is-now-in-public-pre/4491986) |

### Admin portal

- [Microsoft Defender portal](https://security.microsoft.com/) — review Microsoft Copilot signals via the Sentinel Copilot data connector.
- [Microsoft Azure portal](https://portal.azure.com/) — configure diagnostic settings on Azure OpenAI / Cognitive Services resources to route logs to Log Analytics.

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Microsoft Copilot connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/microsoftcopilot.md) |
| Bringing Microsoft Copilot Data Connector into your SOC | Shakirabdul31 (Medium) | Overview of the GA Copilot solution and walkthrough of the four built-in analytic rules (`CopilotFileUploadsDisabled`, `CopilotJailbreakAttempt`, `CopilotPluginCreatedByNonAdmin`, `CopilotPluginTampering`) | [medium.com](https://medium.com/@shakirabdul31/bringing-microsoft-copilot-data-connector-into-your-soc-3e6811fc2135) |
| Defending the AI Layer using Microsoft Sentinel’s Copilot Detection Use Cases | Shakirabdul31 (Medium) | Three custom scheduled-analytics rules against `CopilotActivity` — high-volume interaction spike, anomalous geographic region, and after-hours elevated volume; introduces parsing patterns for `LLMEventData` | [medium.com](https://medium.com/@shakirabdul31/defending-the-ai-layer-using-microsoft-sentinels-copilot-detection-use-cases-cd002c5bc29a) |
| Monitor & detect Microsoft Copilot activity in Sentinel | Samik Roy (LinkedIn) | Practitioner walkthrough of the Microsoft Copilot connector and SOC monitoring patterns | [linkedin.com](https://www.linkedin.com/pulse/monitor-detect-microsoft-copilot-activity-sentinel-samik-roy-fklzc/) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
