# Windows Event Log Size Estimator — Walkthrough

**Tool type:** PowerShell Script · **Source:** [GitHub — mathijsvermaat/GetWinEventlogSize](https://github.com/mathijsvermaat/GetWinEventlogSize)

This guide walks you through running the Windows Event Log size and volume estimator on a local Windows machine — from either the PowerShell console or PowerShell ISE — to size the **Application**, **System**, and **Security** channels *before* onboarding them to Microsoft Sentinel.

---

## Contents

- [When to Use This Script](#when-to-use-this-script)
- [Prerequisites](#prerequisites)
- [Step 1 — Download the Script](#step-1--download-the-script)
- [Step 2 — Run from the PowerShell Console](#step-2--run-from-the-powershell-console)
- [Step 3 — Run from PowerShell ISE](#step-3--run-from-powershell-ise)
- [Step 4 — Interpret the Output](#step-4--interpret-the-output)
- [Step 5 — Convert to GB/day for the Assessment](#step-5--convert-to-gbday-for-the-assessment)
- [Step 6 — Sample Multiple Servers](#step-6--sample-multiple-servers)
- [Accuracy and Limitations](#accuracy-and-limitations)
- [Troubleshooting](#troubleshooting)
- [Related Tools](#related-tools)

---

## When to Use This Script

Use this script when you are planning to onboard [Windows Security Events](../connectors/windows-security-events.md) and need a defensible volume estimate **before** the connector is enabled and before any cost is incurred. It reads the event logs already present on a host and reports events per second, average event size, and a projected monthly volume.

Typical questions it answers:

- How much will `SecurityEvent` cost if we onboard this server estate?
- Is the configured maximum log size large enough for the volume this host produces?
- Which server roles are the noisy ones — domain controllers, file servers, or member servers?

If the connector is **already enabled**, use the [Workspace Usage Report](workspace-usage-report.md) workbook instead — it reports actual ingestion rather than an estimate.

> [!TIP]
> Run this on a representative host per server role rather than on every machine. A domain controller and a member server produce dramatically different Security-channel volumes, so a single sample will not extrapolate cleanly across the estate.

---

## Prerequisites

| Requirement | Details |
|:------------|:--------|
| **PowerShell** | 5.1+ (Windows) or PowerShell 7.x |
| **Elevation** | Run as Administrator — the **Security** channel is not readable otherwise |
| **Cmdlet access** | `Get-WinEvent -LogName <name>` and `Get-WinEvent -ListLog <name>` |
| **Execution policy** | `RemoteSigned` or looser for the current process (see Step 2) |
| **Scope** | Runs against the **local** machine only — no remoting or agent required |

---

## Step 1 — Download the Script

Clone the repository, or download `GetWinEventLog.ps1` directly:

```powershell
git clone https://github.com/mathijsvermaat/GetWinEventlogSize.git
cd GetWinEventlogSize
```

If Git is unavailable, download the raw file:

```powershell
Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/mathijsvermaat/GetWinEventlogSize/main/GetWinEventLog.ps1' `
  -OutFile "$env:USERPROFILE\Downloads\GetWinEventLog.ps1"
```

> [!WARNING]
> Review any script downloaded from the internet before running it, and unblock it explicitly with `Unblock-File` rather than lowering the machine-wide execution policy.

---

## Step 2 — Run from the PowerShell Console

1. Right-click **Windows PowerShell** and choose **Run as administrator**.
2. Unblock the downloaded file and allow script execution for this session only:

   ```powershell
   Unblock-File .\GetWinEventLog.ps1
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
   ```

3. Run the script:

   ```powershell
   .\GetWinEventLog.ps1
   ```

The `-Scope Process` switch keeps the relaxed execution policy to the current window — it reverts as soon as you close it, leaving machine policy untouched.

---

## Step 3 — Run from PowerShell ISE

PowerShell ISE is useful on servers where you want to read the script before running it, or tweak the `$logNames` array to add channels.

1. Open **Windows PowerShell ISE** as administrator (right-click > **Run as administrator**).
2. **File** > **Open** > select `GetWinEventLog.ps1`.
3. Press **F5** to run the whole script, or select a block and press **F8** to run just that selection.
4. Results appear in the ISE output pane as a formatted table.

To measure additional channels, edit the first line before running:

```powershell
$logNames = @("Application", "System", "Security", "Windows PowerShell")
```

> [!NOTE]
> PowerShell ISE is deprecated and does not exist on Windows Server Core. On Core installations, use the console method in Step 2. ISE also cannot run PowerShell 7 — it is bound to Windows PowerShell 5.1.

---

## Step 4 — Interpret the Output

The script prints one row per channel:

```text
Hostname LogName     EPS     FirstEvent           LastEvent            TotalEvents AvgEventSize_Bytes EstimatedMonthlyEvents EstimatedMonthlySize_MB LogConfiguredSize_MB
-------- -------     ---     ----------           ---------            ----------- ------------------ ---------------------- ----------------------- --------------------
HOST123  Security    0.0891  13/11/2025 13:00:12  14/11/2025 11:21:30  987654      392.18             231624                  86.42                   2048
```

| Field | Meaning | What to watch for |
|:------|:--------|:------------------|
| `EPS` | Events per second across the visible window | Compare across roles — DCs are typically an order of magnitude higher |
| `FirstEvent` / `LastEvent` | Oldest and newest events still retained | A window of only a few hours means the log is wrapping fast — see Limitations |
| `TotalEvents` | Records currently in the channel | Not a monthly figure — it is only what has not yet been overwritten |
| `AvgEventSize_Bytes` | `FileSize / RecordCount` | On-disk EVTX size, **not** the ingested size in Sentinel |
| `EstimatedMonthlyEvents` | `EPS` projected over a fixed 30 days | The headline volume number |
| `EstimatedMonthlySize_MB` | `EstimatedMonthlyEvents × AvgEventSize_Bytes` | Starting point for cost estimation |
| `LogConfiguredSize_MB` | Configured maximum channel size | If close to the monthly estimate, the log wraps within the month |

> [!IMPORTANT]
> If `LogConfiguredSize_MB` is small relative to `EstimatedMonthlySize_MB`, the host is discarding events before anyone can collect them. That is a finding in its own right — increase the maximum log size, or accept that forensic evidence is lost between agent polls.

---

## Step 5 — Convert to GB/day for the Assessment

The [assessment checklist](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html) records planned ingestion in **GB/day**. The script reports **MB/month**, so convert:

$$\text{GB/day} = \frac{\text{EstimatedMonthlySize\_MB}}{1024 \times 30}$$

Then multiply by the number of hosts of that role:

| Step | Example |
|:-----|:--------|
| Security channel on a sampled DC | 8,600 MB/month |
| Convert to GB/day | 8,600 ÷ 1024 ÷ 30 = **0.28 GB/day** per DC |
| Multiply by DC count | 0.28 × 12 = **3.36 GB/day** |
| Repeat per role and sum | DCs + member servers + file servers |

Enter the total against **Windows Security Events** in the checklist when the connector is marked *To be added*.

> [!TIP]
> Do this **before** applying a DCR filter. The script measures everything in the channel; a `Common` or `Minimal` DCR preset will collect substantially less. Treat the script output as the unfiltered ceiling, then reduce according to the preset you intend to deploy — see [Windows Security Events](../connectors/windows-security-events.md) for the per-preset event ID breakdown.

---

## Step 6 — Sample Multiple Servers

To collect from several hosts, export each result and combine them. Append to the end of the script:

```powershell
$results | Export-Csv -NoTypeInformation -Path ".\EventLog_Estimates_$env:COMPUTERNAME.csv" -Encoding UTF8
```

Or run it remotely against a set of servers, provided PowerShell remoting is enabled:

```powershell
$servers = 'DC01','DC02','FS01','APP01'
Invoke-Command -ComputerName $servers -FilePath .\GetWinEventLog.ps1 |
    Export-Csv -NoTypeInformation -Path .\EventLog_Estimates_All.csv -Encoding UTF8
```

The script already stamps each row with `Hostname`, so the combined CSV pivots cleanly by host and channel.

---

## Accuracy and Limitations

> [!WARNING]
> `AvgEventSize_Bytes` is derived from the **EVTX file on disk**, not from what Sentinel bills. Ingested `SecurityEvent` rows carry parsed columns and metadata, so the ingested size per event commonly differs from the on-disk size. Treat the output as a **relative sizing and comparison** tool, and validate against real ingestion once a pilot host is onboarded.

Further caveats:

- **The visible window drives everything.** EPS is calculated between the oldest and newest events still in the channel. On a host with a small maximum log size and high volume, that window can be minutes — which over-represents a burst and inflates the monthly projection.
- **A fixed 30-day month** is used for projections (2,592,000 seconds).
- **Point-in-time sample.** Logon volumes vary by weekday and business cycle; a Sunday sample will understate a Monday morning.
- **No DCR filtering is applied.** The figure is the full channel, not what the connector will actually collect.
- **Local machine only** unless invoked via `Invoke-Command`.
- If a channel is empty, or the first and last timestamps are identical, EPS and the estimates are reported as `0`.

---

## Troubleshooting

| Symptom | Cause | Resolution |
|:--------|:------|:-----------|
| `Failed to process log 'Security'` | Not running elevated | Relaunch PowerShell or ISE as administrator |
| Script will not run — "not digitally signed" | Execution policy | `Unblock-File .\GetWinEventLog.ps1` then `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned` |
| EPS looks implausibly high | Narrow visible window from log rollover | Check `FirstEvent`/`LastEvent`; increase the maximum log size and re-sample after a few days |
| Very slow on a large channel | `Get-WinEvent` still has to enumerate records | Expected on multi-GB channels — let it finish, or sample a quieter host |
| Empty result for a channel | Channel disabled or never written to | Confirm with `Get-WinEvent -ListLog <name>` |

---

## Related Tools

| Tool | Use it for |
|:-----|:-----------|
| [Linux Log Size Estimator](linux-log-size.md) | The equivalent sizing exercise on Linux hosts |
| [Defender AMA Coverage](defender-ama-coverage.md) | Confirming which hosts actually have AMA deployed once onboarded |
| [Workspace Usage Report](workspace-usage-report.md) | Actual ingestion volumes after the connector is live |

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)
