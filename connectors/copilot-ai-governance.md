# Microsoft Copilot / AI Governance

**Tier:** 2 (Extended Visibility) · **Connector type:** Microsoft first-party · **Free ingestion:** No · **Conditional:** Requires Copilot licensing

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Example Detections](#example-detections)
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
| **Microsoft 365 Copilot** | Purview Audit → OfficeActivity | `OfficeActivity` (CopilotInteraction events) |
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
| **OfficeActivity** (CopilotInteraction) | M365 Copilot interactions — user, application (Word, Teams, Excel), query metadata | Analytics: 90d / Lake: 365d | Tracks AI usage patterns — detects data oversharing via Copilot, unusual query patterns, and policy violations. | Proves which users interacted with Copilot, in which application, and whether the interaction surfaced sensitive content. Essential for investigating data leakage via AI. | User Copilot query surfacing confidential documents the user shouldn't access |
| **AzureDiagnostics** (Cognitive Services) | Azure OpenAI API calls — model, token count, caller identity, HTTP status | Analytics: 90d / Lake: 365d | Tracks Azure OpenAI usage — detects prompt injection, excessive token usage, and unauthorized API access. MCSB LT-3. | Audit trail of all Azure OpenAI API calls — proves who called the API, with which model, and consumption patterns. | Unusual Azure OpenAI API usage pattern — potential prompt injection or data extraction (T1059) |

---

## Example Detections

### M365 Copilot

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Copilot surfacing restricted content | OfficeActivity | T1530 | Copilot responding with content from restricted SharePoint sites — indicates permission gap |
| Excessive Copilot usage by single user | OfficeActivity | — | Abnormally high interaction volume — may indicate data harvesting via AI |
| Copilot used during incident | OfficeActivity + SigninLogs | T1078 | Compromised account using Copilot to enumerate internal knowledge bases |

### Azure OpenAI

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Prompt injection attempt | AzureDiagnostics | T1059 | Request patterns indicative of prompt injection — unusual system message overrides |
| Unauthorized API caller | AzureDiagnostics | T1078 | Azure OpenAI API called from unexpected service principal or IP |
| Excessive token consumption | AzureDiagnostics | T1496 | Abnormal token usage — potential abuse of AI compute resources |

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
- M365 Copilot interactions appear in the `OfficeActivity` table (already a Tier 1 free connector) — you may already have partial AI audit data
- The primary security concern with M365 Copilot is **data oversharing** — Copilot surfaces everything the user has access to, making over-permissioned accounts a higher risk
- For Azure OpenAI, enable **diagnostic settings** on the Cognitive Services resource to capture API call logs
- Consider deploying Purview **Copilot governance policies** alongside Sentinel monitoring for preventive + detective controls

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor AI-related log ingestion | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) | [Walkthrough](../procedures/workspace-usage-report.md) |

---

## References

Community and third-party resources that support the guidance on this page.

*No community references yet — this is an emerging topic. Contributions welcome.*

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
