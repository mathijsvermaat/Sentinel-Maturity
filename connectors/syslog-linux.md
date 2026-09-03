# Syslog for Linux Servers

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party (AMA) · **Free ingestion:** No (paid ingestion)

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Key Events to Monitor](#key-events-to-monitor)
- [Example Detections](#example-detections)
- [MITRE Detection Strategies](#mitre-detection-strategies)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Recommended Configuration](#recommended-configuration)
- [Notes](#notes)
  - [Why Layered Logging Matters for Linux Servers](#why-layered-logging-matters-for-linux-servers)
- [Tools](#tools)
- [References](#references)

---

## Overview

Syslog is the **standard logging mechanism for Linux systems** and provides essential visibility into authentication, system events, and service activity. For Linux servers in Azure or hybrid environments, syslog data ingested into Sentinel provides the foundational audit trail for detecting unauthorized access, privilege escalation, and persistence on Linux workloads.

Like Windows Security Events, this connector has moved from the legacy Log Analytics Agent (MMA) to the Azure Monitor Agent (AMA) with Data Collection Rules.

| Method | Agent | Table | Status |
|:-------|:------|:------|:-------|
| **Syslog via AMA** | Azure Monitor Agent (AMA) | `Syslog` | **Recommended** |
| Legacy (MMA) | Log Analytics Agent (MMA) | `Syslog` | **Deprecated — migrate to AMA** |

### Licensing Benefits

| Sentinel cost classification | Microsoft Sentinel benefit |
|:-----------------------------|:---------------------------|
| **No (paid ingestion)** | No built-in Sentinel ingestion benefit is documented for this connector; ingestion is billed based on enabled data types and volume. |

> [!NOTE]
> This is a connector-level Sentinel classification used for cost planning.

---

## Tables and Rationale

### Syslog Table

The Syslog table ingests messages from Linux syslog facilities. The key facilities to collect depend on your security monitoring requirements:

#### Authentication and Access

| Facility | Severity | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:---------|:---------|:------------|:------------------------|:----------|:---------------|:------------------|
| **auth** | Info and above | Authentication events (login, su, sudo) | Analytics: 90d / Lake: 365d | **Core Linux security logging.** Captures SSH logons, `su` and `sudo` usage, PAM events. Essential for detecting brute-force, credential abuse, and privilege escalation. | Full authentication timeline on Linux hosts — proves who logged in, when, from where, and which privilege escalation commands were used | SSH brute-force, Unauthorized sudo usage |
| **authpriv** | Info and above | Private authentication messages (PAM, SSH) | Analytics: 90d / Lake: 365d | Detailed authentication internals — key accepted/rejected, PAM session opened/closed, auth failures. Often contains more detail than `auth` for SSH-based attacks. | Granular SSH forensics — proves which SSH keys were used or rejected and exact PAM session lifecycle | PAM authentication failure, SSH key rejected from unknown source |

#### System and Kernel

| Facility | Severity | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:---------|:---------|:------------|:------------------------|:----------|:---------------|:------------------|
| **kern** | Warning and above | Kernel messages | Analytics: 90d / Lake: 365d | Detects kernel-level attacks (module loading, exploit attempts), hardware issues, and firewall events (iptables/nftables logged via kern). | Evidence of kernel-level compromise — proves rootkit module loading and kernel exploit attempts that no user-space tool can reliably detect | Unexpected kernel module loaded — rootkit detection |
| **daemon** | Info and above | System daemon messages | Analytics: 90d / Lake: 365d | Covers services like sshd, cron, systemd, and custom daemons. Service starts/stops, crashes, and configuration changes are logged here. | Trace service-level persistence — proves when services were created, started, or modified by an attacker | New systemd service created and started |
| **cron** | Info and above | Cron job execution | Analytics: 90d / Lake: 365d | Persistence detection — cron jobs are a primary Linux persistence mechanism. Tracks when cron jobs execute and whether they succeed or fail. | Prove cron-based persistence — shows exactly when cron jobs were added and executed, linking persistence to attack timeline | New cron entry executing suspicious binary from /tmp |
| **syslog** | Info and above | General system messages | Analytics: 90d / Lake: 365d | Catch-all for messages not routed to other facilities. Provides general operational context. | General operational evidence — captures logging service state changes that indicate anti-forensic activity | rsyslog service stopped — potential anti-forensic activity |

#### Application and Network

| Facility | Severity | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:---------|:---------|:------------|:------------------------|:----------|:---------------|:------------------|
| **local0 – local7** | Varies | Custom application logging | Analytics: 90d / Lake: 365d | Many security-relevant applications (firewalls, proxies, network appliances) use local facilities. Configure based on your environment. | Environment-specific forensic data — network appliance and application logs that provide additional context during investigations | Firewall deny events from network appliance forwarding via local facility |
| **user** | Warning and above | User-level application messages | Analytics: 90d / Lake: 365d | Application-specific events. Lower priority but may contain relevant security context. | Supplementary application context — may correlate with suspicious activity observed in other telemetry sources | Application error correlated with suspicious activity |

---

## Key Events to Monitor

### SSH and Authentication

| Event Pattern | Source | MITRE ATT&CK | Description |
|:--------------|:-------|:-------------|:------------|
| `Failed password for` | auth/authpriv | T1110 | SSH brute-force attempts — multiple failures from same source |
| `Accepted publickey for` / `Accepted password for` | auth/authpriv | T1078 | Successful SSH logon — baseline for anomaly detection |
| `Invalid user` | auth/authpriv | T1110.001 | Logon attempt with non-existent username — credential stuffing |
| `session opened for user root` (via su/sudo) | auth | T1548.003 | Privilege escalation via `su` or `sudo` |
| `sudo:` commands | auth/authpriv | T1548.003 | All `sudo` command execution with user and command details |
| `pam_unix.*authentication failure` | auth/authpriv | T1110 | PAM authentication failures across any authentication method |
| `COMMAND=` (sudoers) | auth/authpriv | T1548.003 | Detailed sudo command execution logging |

### Persistence and Execution

| Event Pattern | Source | MITRE ATT&CK | Description |
|:--------------|:-------|:-------------|:------------|
| `CRON.*CMD` | cron | T1053.003 | Cron job execution — watch for unusual commands or new cron entries |
| `systemd.*Started` / `systemd.*Stopped` | daemon | T1543.002 | Service lifecycle — detects new or restarted services (potential persistence) |
| `kernel:.*module.*loaded` | kern | T1547.006 | Kernel module loading — rootkit detection |
| `useradd` / `usermod` / `userdel` | auth/authpriv | T1136.001 | Account management events — new accounts or group changes |
| `groupadd` / `groupmod` | auth/authpriv | T1098 | Group membership changes — privilege escalation via group addition |

### System Integrity

| Event Pattern | Source | MITRE ATT&CK | Description |
|:--------------|:-------|:-------------|:------------|
| `rsyslogd.*start` / `rsyslogd.*exiting` | syslog | T1562.006 | Log service restart or shutdown — potential anti-forensic activity |
| `iptables` / `nftables` | kern | T1562.004 | Firewall rule modifications |
| `audit.*type=` | kern/auth | Various | auditd events (if forwarded via syslog) |

---

## Example Detections

| Detection | Facility | MITRE ATT&CK | Description |
|:----------|:---------|:-------------|:------------|
| SSH brute-force | auth/authpriv | T1110 | >10 failed SSH logons from a single IP within 5 minutes |
| Successful logon after brute-force | auth/authpriv | T1078 | Successful SSH logon from an IP that previously generated failures |
| Unauthorized sudo usage | auth/authpriv | T1548.003 | `sudo` commands executed by non-admin users or from unexpected source |
| New cron job (persistence) | cron | T1053.003 | New cron entry executing a suspicious binary or script (e.g., from /tmp, curl/wget) |
| Kernel module loaded | kern | T1547.006 | Unexpected kernel module load — potential rootkit |
| New service created | daemon | T1543.002 | New systemd service unit created and started |
| User created / modified | auth/authpriv | T1136.001 | New local user created, especially if added to sudo/wheel group |
| Syslog service stopped | syslog | T1562.006 | rsyslog or syslog-ng stopped — attacker may be disabling logging |
| SSH key-based logon from unusual source | auth/authpriv | T1078.004 | Public key authentication from an IP not in baseline |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page. The **MITRE Log Sources (Linux)** column lists the exact log channels and event codes referenced by the analytic of each strategy on the Linux platform — taken verbatim from the strategy's published `log_sources` field in the [ATT&CK STIX bundle](https://github.com/mitre-attack/attack-stix-data).

| Technique | Detection Strategy | MITRE Log Sources (Linux) |
|:----------|:-------------------|:-----------|
| [T1014](https://attack.mitre.org/techniques/T1014/) | [DET0377](https://attack.mitre.org/detectionstrategies/DET0377/) &mdash; Detection of Kernel/User-Level Rootkit Behavior Across Platforms | `auditd:EXECVE` &middot; `linux:osquery`: file_events &middot; `linux:syslog`: kmod |
| [T1053.003](https://attack.mitre.org/techniques/T1053/003/) | [DET0290](https://attack.mitre.org/detectionstrategies/DET0290/) &mdash; Cross-Platform Detection of Cron Job Abuse for Persistence and Execution | `auditd:SYSCALL`: execve, write |
| [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) &mdash; Detection of Valid Account Abuse Across Platforms | `auditd:SYSCALL`: execve &middot; `NSM:Connections`: sshd or PAM logins |
| [T1078.004](https://attack.mitre.org/techniques/T1078/004/) | [DET0546](https://attack.mitre.org/detectionstrategies/DET0546/) &mdash; Detection of Abused or Compromised Cloud Accounts for Access and Persistence | *MITRE has not published a Linux analytic for this strategy* |
| [T1098](https://attack.mitre.org/techniques/T1098/) | [DET0096](https://attack.mitre.org/detectionstrategies/DET0096/) &mdash; Account Manipulation Behavior Chain Detection | `auditd:PATH`: /etc/passwd or /etc/group file write &middot; `auditd:SYSCALL`: usermod, groupmod, passwd |
| [T1110](https://attack.mitre.org/techniques/T1110/) | [DET0463](https://attack.mitre.org/detectionstrategies/DET0463/) &mdash; Brute Force Authentication Failures with Multi-Platform Log Correlation | `auditd:USER_LOGIN`: USER_AUTH |
| [T1110.001](https://attack.mitre.org/techniques/T1110/001/) | [DET0551](https://attack.mitre.org/detectionstrategies/DET0551/) &mdash; Password Guessing via Multi-Source Authentication Failure Correlation | `linux:syslog`: sshd[pid]: Failed password |
| [T1136.001](https://attack.mitre.org/techniques/T1136/001/) | [DET0447](https://attack.mitre.org/detectionstrategies/DET0447/) &mdash; Local Account Creation Across Platforms | `auditd:SYSCALL`: useradd or adduser executed, write operation on /etc/passwd or /etc/shadow |
| [T1543.002](https://attack.mitre.org/techniques/T1543/002/) | [DET0253](https://attack.mitre.org/detectionstrategies/DET0253/) &mdash; Detection of Systemd Service Creation or Modification on Linux | `auditd:SYSCALL`: execution of systemctl or service with enable/start parameters; fork/exec of service via PID 1 (systemd); modification of existing .service file; write, open, or rename to /etc/systemd/system/*.service &middot; `linux:osquery`: newly registered unit file with ExecStart pointing to unknown binary |
| [T1547.006](https://attack.mitre.org/techniques/T1547/006/) | [DET0450](https://attack.mitre.org/detectionstrategies/DET0450/) &mdash; Detection Strategy for Kernel Modules and Extensions Autostart Execution | `auditd:SYSCALL`: access or modification to /lib/modules or creation of .ko files; execution of insmod, modprobe, or rmmod commands by non-standard users or outside expected timeframes &middot; `linux:osquery`: new or modified kernel object files (.ko) within /lib/modules directory |
| [T1548.003](https://attack.mitre.org/techniques/T1548/003/) | [DET0052](https://attack.mitre.org/detectionstrategies/DET0052/) &mdash; Behavioral Detection Strategy for Abuse of Sudo and Sudo Caching | `auditd:SYSCALL`: execve call for modification of /etc/sudoers or writing to /var/db/sudo; execve call for sudo where euid != uid |
| [T1562.004](https://attack.mitre.org/techniques/T1562/004/) *(revoked &rarr; [T1686](https://attack.mitre.org/techniques/T1686/))* | [DET0145](https://attack.mitre.org/detectionstrategies/DET0145/) &mdash; Detection of Disabled or Modified System Firewalls across OS Platforms | `auditd:SYSCALL`: execve: iptables, nft, firewall-cmd modifications &middot; `linux:osquery`: execution of known firewall binaries |
| [T1562.006](https://attack.mitre.org/techniques/T1562/006/) *(revoked &rarr; [T1685](https://attack.mitre.org/techniques/T1685/))* | [DET0497](https://attack.mitre.org/detectionstrategies/DET0497/) &mdash; Detection of Defense Impairment through Disabled or Modified Tools across OS Platforms | `auditd:CONFIG_CHANGE`: delete: modification of systemd unit files or config for security agents &middot; `auditd:SYSCALL`: execve: systemctl stop, service stop, or kill -9 on security daemons (e.g., falcon-sensor, auditd) |

> [!NOTE]
> **Log sources are verbatim from MITRE.** The third column is generated directly from each strategy's published `x_mitre_log_source_references` field in the [ATT&CK STIX 2.1 bundle](https://github.com/mitre-attack/attack-stix-data) — it is **not** a hand-picked list of "events that look related on this connector page". Where MITRE has not published a Linux analytic, the cell says so explicitly.

> [!NOTE]
> **MITRE legacy technique IDs.** Some technique IDs cited on this page are *legacy* IDs that MITRE has revoked and remapped: T1562.004 &rarr; T1686; T1562.006 &rarr; T1685. Published Detection Strategies are attached to the current technique IDs only; the table above follows the `revoked-by` chain so each strategy still applies to the legacy ID cited above.

> [!TIP]
> Detection Strategies are MITRE-published *pseudo-code analytics*, not vendor rules — they tell you **what** to correlate across data sources. Use them to validate that your Sentinel analytic rules and KQL hunting queries cover the published correlation logic.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **IM-1** Centralise identity management | SSH and PAM authentication events provide Linux identity visibility |
| **PA-1** Protect privileged users | `sudo` and `su` events track privilege usage on Linux |
| **LT-1** Enable threat detection | Syslog is the primary detection data source for Linux servers |
| **LT-3** Enable logging for security investigation | Auth, kern, and daemon facilities provide comprehensive forensic data |
| **LT-6** Configure log storage retention | Sentinel extends retention beyond native syslog rotation |
| **ES-1** Use endpoint detection and response | Complements MDE on Linux with native OS-level telemetry |
| **IR-4** Detection and analysis | Auth logs are the primary evidence source for Linux investigations |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-2 (audit events) and AU-12 (audit generation), CIS Controls v8 8.2 (collect audit logs), and ASD ACSC enterprise network logging priority #11 (servers) and #14 (database servers).

---

## Recommended Configuration

### Data Collection Rule — Minimum Facilities

| Facility | Minimum Severity | Rationale |
|:---------|:-----------------|:----------|
| **auth** | LOG_INFO | All authentication events |
| **authpriv** | LOG_INFO | Detailed auth internals (SSH, PAM) |
| **cron** | LOG_INFO | Cron execution (persistence detection) |
| **daemon** | LOG_INFO | Service lifecycle events |
| **kern** | LOG_WARNING | Kernel events (module loads, firewall) |
| **syslog** | LOG_WARNING | General system messages |
| **local0** | LOG_INFO | *If used by security appliances* |

### rsyslog Configuration

Ensure the Linux server's rsyslog (or syslog-ng) is configured to generate the required facility messages. Key configurations:

> [!WARNING]
> Ensure `sudo` is configured to log via syslog. Add `Defaults logfile=/var/log/sudo.log` or ensure `Defaults syslog=auth` is set in `/etc/sudoers`. Without this, sudo command details may not appear in syslog.

- Enable detailed SSH logging: `LogLevel VERBOSE` in `/etc/ssh/sshd_config`
- Ensure PAM session messages are not filtered by rsyslog
- For auditd events forwarded to syslog, configure the `audisp-syslog` plugin

---

## Notes

- **Migrate from MMA to AMA** — the Log Analytics Agent is deprecated; use Azure Monitor Agent with DCR
- Linux syslog does **not natively log process execution** like Windows 4688 — for process-level visibility, rely on MDE's DeviceProcessEvents or deploy `auditd` with process tracking rules (Tier 2 consideration)
- For **containers and Kubernetes nodes**, syslog captures host-level events but not container-internal activity — consider Container Insights for Tier 2
- If you use **CEF-formatted logs** from network appliances forwarded via Linux syslog, these go to the `CommonSecurityLog` table — that's a separate connector consideration
- For high-security environments, consider deploying **auditd** with STIG-compliant rules and forwarding via syslog (Tier 2/3) — this provides process execution, file access, and syscall monitoring comparable to Windows Security Events. A maintained community baseline is [Neo23x0/auditd](https://github.com/Neo23x0/auditd/releases) by Florian Roth — v0.2.0 (telemetry-first, simplified) and v0.1.0 (broad historic baseline) are both released and CI-validated
- Volume is typically much lower than Windows Security Events, but note that **neither** the general `Syslog` table **nor** `LinuxAuditLog` is covered by the Defender for Servers P2 pooled allowance — both are billed at standard ingestion rates. For cost-sensitive deployments, rely on DCR filtering (facility/severity), KQL transformations, and Basic / Auxiliary log tiers rather than the P2 benefit

### Why Layered Logging Matters for Linux Servers

Just as with Windows, relying solely on EDR for Linux server security leaves gaps. Native syslog provides an independent audit trail that captures authentication, privilege escalation, and persistence events even if MDE is tampered with:

| Title | Description | Link |
|:------|:------------|:-----|
| The Evolution of EDR Bypasses | EDR bypass techniques are not limited to Windows — Linux EDR evasion is an active research area | [CovertSwarm](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) |
| Sentinel Data Connectors: What Actually Matters | Practical guidance on prioritizing Sentinel data connectors including Syslog | [IT Professor](https://www.itprofessor.cloud/sentinel-data-connectors-what-actually-matters/) |

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor `Syslog` and `LinuxAuditLog` ingestion volumes per server (note: neither table is covered by the Defender for Servers P2 pooled allowance — both are billed as regular ingestion) | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Defender AMA Coverage** | Workbook | Validate AMA agent deployment and Syslog collection coverage on Linux servers | [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) | [Walkthrough](../procedures/defender-ama-coverage.md) · [Blog](https://www.linkedin.com/pulse/closing-telemetry-gap-how-we-built-kql-query-workbook-mathijs-vermaat-rzfbe/) |
| **SOC Handbook** | Solution | Identity & Access workbook, Investigation Insights workbook, MITRE ATT&CK workbook — Syslog authentication events feed identity-based detections | Sentinel Content Hub | — |
| **Linux Log Size Estimator** | Script | Measure GB/day, events per second, and monthly volume from a host's own logs — sizes the connector before onboarding (neither table is covered by the P2 pooled allowance, so this translates directly into cost) | [GitHub — mathijsvermaat/GetLinuxEventLogSize](https://github.com/mathijsvermaat/GetLinuxEventLogSize) | [Walkthrough](../procedures/linux-log-size.md) |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Ingest syslog and CEF messages to Microsoft Sentinel with the Azure Monitor Agent | Connector setup guide — Syslog via AMA with DCR-based filtering | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/connect-cef-syslog-ama) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — Syslog via AMA connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/syslogama.md) |
| Neo23x0/auditd releases | Florian Roth | Maintained auditd ruleset baseline — v0.2.0 is the streamlined telemetry-first ruleset (detection logic moved downstream to SIGMA/SIEM); v0.1.0 preserves the broad historic master baseline. A solid starting point for `LinuxAuditLog` collection via AMA | [github.com](https://github.com/Neo23x0/auditd/releases) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
