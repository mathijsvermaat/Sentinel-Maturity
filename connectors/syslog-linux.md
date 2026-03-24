# Syslog for Linux Servers

**Tier:** 1 (Bare Minimum) · **Connector type:** Microsoft first-party (AMA) · **Free ingestion:** 500 MB/day per server (Defender for Servers P2)

---

## Contents

- [Overview](#overview)
- [Tables and Rationale](#tables-and-rationale)
- [Key Events to Monitor](#key-events-to-monitor)
- [Example Detections](#example-detections)
- [MCSB Control Mapping](#mcsb-control-mapping)
- [Recommended Configuration](#recommended-configuration)
- [Notes](#notes)
  - [Why Layered Logging Matters for Linux Servers](#why-layered-logging-matters-for-linux-servers)
  - [Tools](#tools)

---

## Overview

Syslog is the **standard logging mechanism for Linux systems** and provides essential visibility into authentication, system events, and service activity. For Linux servers in Azure or hybrid environments, syslog data ingested into Sentinel provides the foundational audit trail for detecting unauthorized access, privilege escalation, and persistence on Linux workloads.

Like Windows Security Events, this connector has moved from the legacy Log Analytics Agent (MMA) to the Azure Monitor Agent (AMA) with Data Collection Rules.

| Method | Agent | Table | Status |
|:-------|:------|:------|:-------|
| **Syslog via AMA** | Azure Monitor Agent (AMA) | `Syslog` | **Recommended** |
| Legacy (MMA) | Log Analytics Agent (MMA) | `Syslog` | **Deprecated — migrate to AMA** |

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **[Defender for Servers P2](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit)** | MDE on Linux + [500 MB/day free ingestion per server](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) (shared with SecurityEvent allowance) |
| **Defender for Servers P1** | MDE on Linux, but no free data ingestion for Sentinel |
| **No Defender for Servers** | Full ingestion cost |

> [!NOTE]
> The **500 MB/day free allowance** from Defender for Servers P2 covers most syslog ingestion for typical servers. Combined with MDE agent on Linux, you get both rich endpoint telemetry and native OS-level logging.

---

## Tables and Rationale

### Syslog Table

The Syslog table ingests messages from Linux syslog facilities. The key facilities to collect depend on your security monitoring requirements:

#### Authentication and Access

| Facility | Severity | Description | Retention Recommendation | Rationale | Example Detection |
|:---------|:---------|:------------|:------------------------|:----------|:------------------|
| **auth** | Info and above | Authentication events (login, su, sudo) | Analytics: 90d / Lake: 365d | **Core Linux security logging.** Captures SSH logons, `su` and `sudo` usage, PAM events. MCSB IM-1 (Centralise identity management). Essential for detecting brute-force, credential abuse, and privilege escalation. | SSH brute-force (T1110), Unauthorized sudo usage (T1548.003) |
| **authpriv** | Info and above | Private authentication messages (PAM, SSH) | Analytics: 90d / Lake: 365d | Detailed authentication internals — key accepted/rejected, PAM session opened/closed, auth failures. Often contains more detail than `auth` for SSH-based attacks. | PAM authentication failure, SSH key rejected from unknown source |

#### System and Kernel

| Facility | Severity | Description | Retention Recommendation | Rationale | Example Detection |
|:---------|:---------|:------------|:------------------------|:----------|:------------------|
| **kern** | Warning and above | Kernel messages | Analytics: 90d / Lake: 365d | Detects kernel-level attacks (module loading, exploit attempts), hardware issues, and firewall events (iptables/nftables logged via kern). MCSB LT-3. | Unexpected kernel module loaded — rootkit detection (T1547.006) |
| **daemon** | Info and above | System daemon messages | Analytics: 90d / Lake: 365d | Covers services like sshd, cron, systemd, and custom daemons. Service starts/stops, crashes, and configuration changes are logged here. | New systemd service created and started (T1543.002) |
| **cron** | Info and above | Cron job execution | Analytics: 90d / Lake: 365d | Persistence detection — cron jobs are a primary Linux persistence mechanism (MITRE T1053.003). Tracks when cron jobs execute and whether they succeed or fail. | New cron entry executing suspicious binary from /tmp (T1053.003) |
| **syslog** | Info and above | General system messages | Analytics: 90d / Lake: 365d | Catch-all for messages not routed to other facilities. Provides general operational context. | rsyslog service stopped — potential anti-forensic activity (T1562.006) |

#### Application and Network

| Facility | Severity | Description | Retention Recommendation | Rationale | Example Detection |
|:---------|:---------|:------------|:------------------------|:----------|:------------------|
| **local0 – local7** | Varies | Custom application logging | Analytics: 90d / Lake: 365d | Many security-relevant applications (firewalls, proxies, network appliances) use local facilities. Configure based on your environment. | Firewall deny events from network appliance forwarding via local facility |
| **user** | Warning and above | User-level application messages | Analytics: 90d / Lake: 365d | Application-specific events. Lower priority but may contain relevant security context. | Application error correlated with suspicious activity |

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
| `kernel:.*module.*loaded` | kern | T1547.006 | Kernel module loading — rootkit detection (MITRE T1014) |
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
- For high-security environments, consider deploying **auditd** with STIG-compliant rules and forwarding via syslog (Tier 2/3) — this provides process execution, file access, and syscall monitoring comparable to Windows Security Events
- Volume is typically much lower than Windows Security Events — the 500 MB/day Defender for Servers P2 allowance is usually more than sufficient

### Why Layered Logging Matters for Linux Servers

Just as with Windows, relying solely on EDR for Linux server security leaves gaps. Native syslog provides an independent audit trail that captures authentication, privilege escalation, and persistence events even if MDE is tampered with:

| Title | Description | Link |
|:------|:------------|:-----|
| The Evolution of EDR Bypasses | EDR bypass techniques are not limited to Windows — Linux EDR evasion is an active research area | [CovertSwarm](https://www.covertswarm.com/post/the-evolution-of-edr-bypasses-a-historical-timeline) |
| Sentinel Data Connectors: What Actually Matters | Practical guidance on prioritizing Sentinel data connectors including Syslog | [IT Professor](https://www.itprofessor.cloud/sentinel-data-connectors-what-actually-matters/) |

### Tools

| Tool | Type | Purpose | Source |
|:-----|:-----|:--------|:-------|
| **Workspace Usage Report** | Workbook | Monitor Syslog ingestion volumes per server and validate the P2 ingestion benefit | [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub) |
| **Defender AMA Coverage** | Workbook | Validate AMA agent deployment and Syslog collection coverage on Linux servers | [GitHub — mathijsvermaat/Defender-AMA-coverage](https://github.com/mathijsvermaat/Defender-AMA-coverage) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
