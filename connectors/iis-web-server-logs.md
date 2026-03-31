# IIS / Web Server Logs

**Tier:** 3 (Advanced) · **Connector type:** Microsoft first-party (AMA) · **Free ingestion:** No

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

IIS (Internet Information Services) logs record HTTP request activity on Windows web servers — every request, response code, client IP, user agent, and URI. These logs provide **application-layer visibility** for internally hosted web applications and APIs that may not sit behind Azure WAF or a reverse proxy.

For organisations hosting custom web applications, internal portals, or APIs on IIS, these logs are the primary source for detecting web-based attacks: brute-force against login pages, directory traversal, SQL injection attempts, and suspicious scanning. Unlike network firewalls that see connections, IIS logs see the full HTTP request path.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **Any Azure subscription** | Full IIS log collection via Azure Monitor Agent and Data Collection Rules |
| **Defender for Servers P2** | 500 MB/day/server ingestion benefit applies to IIS logs collected via AMA |

> [!NOTE]
> IIS logs can generate **significant volume** on busy web servers. Use DCR transformations to filter out health probes, static asset requests, and known-good traffic to manage cost.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **W3CIISLog** | Standard IIS access logs — HTTP method, URI, status code, client IP, user agent, bytes transferred | Analytics: 90d / Lake: 365d | Primary source for web application attack detection and user activity auditing on Windows web servers | During investigations, recreates attacker request patterns — which pages were accessed, what payloads were sent, and from which IPs | SQL injection attempts via URI parameters (T1190) |

---

## Example Detections

| Detection | Table(s) | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| Excessive 401/403 responses | W3CIISLog | T1110 | Brute-force or credential stuffing against web application login endpoints |
| Directory traversal attempts | W3CIISLog | T1083 | Requests containing `../` path traversal sequences targeting file system access |
| SQL injection patterns in URI | W3CIISLog | T1190 | Requests containing SQL keywords (`UNION SELECT`, `OR 1=1`, `DROP TABLE`) in query strings |
| Web shell access patterns | W3CIISLog | T1505.003 | Repeated requests to unusual file paths (.aspx, .ashx) from a single IP — indicates web shell deployment |
| Anomalous user agent strings | W3CIISLog | T1071.001 | Requests with known malicious or tool-specific user agents (sqlmap, Nikto, Cobalt Strike) |

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-1** Enable threat detection capabilities | IIS logs enable application-layer threat detection for web workloads |
| **LT-3** Enable logging for security investigation | Web server access logs are foundational for investigating web application compromises |
| **NS-6** Deploy web application firewall | IIS logs complement WAF by providing visibility even when WAF is not deployed |

---

## Important Considerations

- **Volume management:** High-traffic web servers can generate gigabytes of logs per day. Use DCR transformations to exclude health probes (`/health`, `/ready`), static assets (`.css`, `.js`, `.png`), and monitoring endpoints
- **AMA configuration:** Requires Azure Monitor Agent with a Data Collection Rule targeting `Microsoft-W3CIISLog`
- **Log format:** Ensure IIS is configured for W3C Extended Log Format with all fields enabled (client IP, user agent, cookie, referrer)
- **Sensitive data:** URI parameters may contain sensitive data (tokens, session IDs). Consider DCR transformations to sanitise query strings

---

## Notes

- IIS logs are particularly valuable for organisations hosting internal portals, SharePoint on-premises, or custom LOB applications on Windows Server
- Complements Azure WAF (Tier 2) — WAF protects internet-facing apps; IIS logs cover internal applications and apps without WAF
- Consider pairing with Windows Security Events (Tier 1) for correlation between web requests and process execution

### Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| [Workspace Usage Report](../procedures/workspace-usage-report.md) | Workbook | Verify IIS log volumes and ingestion | Sentinel Maturity Model | [Procedure guide](../procedures/workspace-usage-report.md) |

---

## References

| Source | Link |
|:-------|:-----|
| Collect IIS logs with Azure Monitor Agent | [Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-iis) |
| W3CIISLog table reference | [Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/w3ciislog) |
| IIS log file formats | [Learn](https://learn.microsoft.com/en-us/previous-versions/iis/6.0-sdk/ms525807(v=vs.90)) |

---

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
