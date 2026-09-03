# Linux Log Size Estimator — Walkthrough

**Tool type:** Bash Script · **Source:** [GitHub — mathijsvermaat/GetLinuxEventLogSize](https://github.com/mathijsvermaat/GetLinuxEventLogSize)

This guide walks you through running the Linux log size estimator on a local Linux host to measure event volume, events per second, and GB/day for the previous full month — sizing [Syslog for Linux](../connectors/syslog-linux.md) *before* onboarding it to Microsoft Sentinel.

---

## Contents

- [When to Use This Script](#when-to-use-this-script)
- [Prerequisites](#prerequisites)
- [Step 1 — Download the Script](#step-1--download-the-script)
- [Step 2 — Choose What to Measure](#step-2--choose-what-to-measure)
- [Step 3 — Run the Script](#step-3--run-the-script)
- [Step 4 — Interpret the Output](#step-4--interpret-the-output)
- [Step 5 — Scale Across the Estate](#step-5--scale-across-the-estate)
- [Accuracy and Limitations](#accuracy-and-limitations)
- [Troubleshooting](#troubleshooting)
- [Related Tools](#related-tools)

---

## When to Use This Script

Use this script when you are planning to onboard [Syslog for Linux](../connectors/syslog-linux.md) and need a volume estimate **before** the connector is enabled. Unlike the Windows equivalent, it reports **GB/day** directly — the unit the assessment checklist and Sentinel pricing both use.

Typical questions it answers:

- How much will `Syslog` and `LinuxAuditLog` cost across our Linux estate?
- Which hosts are the noisy ones — and is `auditd` configured far too broadly?
- What is our real events-per-second rate for sizing collector throughput?

If the connector is **already enabled**, use the [Workspace Usage Report](workspace-usage-report.md) workbook instead — it reports actual ingestion.

> [!IMPORTANT]
> Neither `Syslog` nor `LinuxAuditLog` is covered by the Defender for Servers P2 pooled allowance. Both are billed as regular ingestion, so the estimate produced here translates directly into cost.

---

## Prerequisites

| Requirement | Details |
|:------------|:--------|
| **Shell** | Bash — present on effectively every distribution |
| **Utilities** | `grep`, `wc`, `date`, and `bc` (`bc` is often *not* installed by default) |
| **Privileges** | `sudo` or root — most log paths are not world-readable |
| **Optional** | `journalctl` on systemd hosts, which the script prefers when present |
| **Disk space** | Free space in `/tmp` — the script writes an extracted copy of the month's logs |

> [!WARNING]
> The script writes the extracted month of logs to `/tmp/log_analysis/filtered.log` and does **not** delete it by default. On a busy host that file can be several GB. Check free space before running, and remove the file afterwards.

---

## Step 1 — Download the Script

```bash
git clone https://github.com/mathijsvermaat/GetLinuxEventLogSize.git
cd GetLinuxEventLogSize
chmod +x GetLogSizeforLinux.sh
```

Or fetch the single file directly:

```bash
curl -fsSL -o GetLogSizeforLinux.sh \
  https://raw.githubusercontent.com/mathijsvermaat/GetLinuxEventLogSize/main/GetLogSizeforLinux.sh
chmod +x GetLogSizeforLinux.sh
```

Review the script before running it — it is short enough to read end to end.

---

## Step 2 — Choose What to Measure

This step matters more than it appears, because the script behaves differently depending on the host.

**On systemd hosts (most modern distributions):** if `journalctl` is available, the script uses it and measures the **entire journal** — every unit on the box. It ignores the `LOG_FILES` array completely.

**On non-systemd hosts:** it falls back to `grep` over the files listed at the top of the script:

```bash
LOG_FILES=("/var/log/syslog" "/var/log/auth.log" "/var/log/audit/audit.log")
```

Adjust that array for your distribution:

| Distribution family | General system log | Authentication log |
|:--------------------|:-------------------|:-------------------|
| Debian / Ubuntu | `/var/log/syslog` | `/var/log/auth.log` |
| RHEL / CentOS / Fedora | `/var/log/messages` | `/var/log/secure` |
| Any with auditd | — | `/var/log/audit/audit.log` |

> [!TIP]
> Because the journal path measures everything, it will **over-estimate** what a facility-filtered DCR actually collects. To measure only the facilities you intend to collect, restrict the journal query — for example `journalctl --since … --facility=auth,authpriv` — or run the script on a host without systemd. See [Syslog for Linux](../connectors/syslog-linux.md) for which facilities are worth collecting.

---

## Step 3 — Run the Script

```bash
sudo ./GetLogSizeforLinux.sh
```

The script automatically targets the **previous full calendar month** — so running it in March analyses all of February. No arguments are required.

To analyse a different period, edit the time-range line:

```bash
LAST_MONTH=$(date -d "$(date +%Y-%m-15) -1 month" +%Y-%m)
```

Clean up afterwards:

```bash
sudo rm -f /tmp/log_analysis/filtered.log
```

---

## Step 4 — Interpret the Output

```text
--------------------------------------------------
Analyzed month: 2026-01
Total events: 1234567
Total bytes: 5368709120
Average EPS: 451.97 events/sec
Average GB/day: 5.24 GB
Total ingest (month): 162.45 GB
--------------------------------------------------
```

| Field | Meaning | How to use it |
|:------|:--------|:--------------|
| `Total events` | Log lines in the analysed month | Sanity-check against expectations for the host role |
| `Total bytes` | Raw size of the extracted log text | Basis for the GB figures below |
| `Average EPS` | Events per second across the whole month | Sizing collector and forwarder throughput |
| `Average GB/day` | Daily volume | **Enter this directly in the assessment checklist** |
| `Total ingest (month)` | Full month volume | Monthly cost conversations |

`Average GB/day` is the figure to record against **Syslog for Linux** in the [assessment checklist](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html) when the connector is marked *To be added*.

> [!IMPORTANT]
> Because EPS is averaged across the entire month, it smooths away peaks. A host averaging 450 EPS may burst to several thousand during a patch window or an attack. Size collectors for the peak, not the average.

---

## Step 5 — Scale Across the Estate

Sample one representative host per role, then multiply:

| Role | Sampled GB/day | Hosts | Subtotal |
|:-----|:---------------|:------|:---------|
| Web servers | 5.24 | 20 | 104.8 GB/day |
| Database servers | 1.10 | 6 | 6.6 GB/day |
| Bastion / jump hosts | 0.35 | 2 | 0.7 GB/day |
| **Estate total** | | | **112.1 GB/day** |

To collect from several hosts in one pass:

```bash
for host in web01 web02 db01 bastion01; do
  echo "=== $host ==="
  ssh "$host" 'sudo bash -s' < ./GetLogSizeforLinux.sh
done | tee linux-log-estimates.txt
```

> [!TIP]
> Sample the noisiest role first. On most estates a single application tier accounts for the large majority of Linux log volume, and filtering that one tier at the DCR delivers nearly all of the achievable saving.

---

## Accuracy and Limitations

> [!WARNING]
> `Total bytes` measures the **rendered log text** on the host, not what Sentinel bills. The Azure Monitor Agent forwards structured records with additional columns and metadata, so ingested volume will not match the raw byte count exactly. Treat the output as a sizing and comparison tool, then validate against real ingestion after a pilot host is onboarded.

Further caveats:

- **The journal path measures everything.** On systemd hosts the `LOG_FILES` array is ignored, so the result reflects all units — not the subset a facility-filtered DCR will collect.
- **No DCR filtering is modelled.** Treat the figure as an unfiltered ceiling.
- **The traditional-file fallback is approximate.** It matches lines by month abbreviation at the start of the line. Classic syslog lines carry no year, so lines from the same month in a previous year can be counted if old logs are still present.
- **Log rotation truncates history.** If logs are rotated and compressed weekly, a full previous month may simply not be on disk — the result then understates reality. Check `Total events` against expectations.
- **Rotated `.gz` archives are not read.** Only uncompressed current logs are analysed.
- **A whole-month average** hides both daily peaks and weekday/weekend variation.

---

## Troubleshooting

| Symptom | Cause | Resolution |
|:--------|:------|:-----------|
| `bc: command not found` | Calculator package missing | `sudo apt-get install bc` (Debian/Ubuntu) or `sudo yum install bc` (RHEL/CentOS) |
| Permission denied | Not running with elevation | Re-run with `sudo` |
| `Total events: 0` | Logs rotated away, or wrong paths for the distribution | Confirm the month exists on disk; correct the `LOG_FILES` array (see Step 2) |
| Implausibly high volume | Journal path measured every unit, not just security facilities | Restrict the journal query by facility, or filter at the DCR |
| `/tmp` fills up | Extracted log copy is large and is not auto-deleted | Free space first; remove `/tmp/log_analysis/filtered.log` afterwards |

---

## Related Tools

| Tool | Use it for |
|:-----|:-----------|
| [Windows Event Log Size Estimator](windows-event-log-size.md) | The equivalent sizing exercise on Windows hosts |
| [Defender AMA Coverage](defender-ama-coverage.md) | Confirming which Linux hosts actually have AMA deployed once onboarded |
| [Workspace Usage Report](workspace-usage-report.md) | Actual ingestion volumes after the connector is live |

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)
