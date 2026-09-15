# Sentinel Collector — Walkthrough

**Tool type:** Bash Script · **Source:** [GitHub — mathijsvermaat/Sentinel-Maturity](https://github.com/mathijsvermaat/Sentinel-Maturity/blob/main/tools/sentinel-collector.sh)

This guide walks you through running the read-only workspace collector against a customer's Microsoft Sentinel workspace and importing its output into the [Assessment Checklist](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html), so that an assessment starts from observed facts rather than a blank form.

---

## Contents

- [When to Use This Script](#when-to-use-this-script)
- [What It Collects](#what-it-collects)
- [Prerequisites](#prerequisites)
- [Step 1 — Open Azure Cloud Shell](#step-1--open-azure-cloud-shell)
- [Step 2 — Download the Script](#step-2--download-the-script)
- [Step 3 — Identify the Subscription](#step-3--identify-the-subscription)
- [Step 4 — Run the Collector](#step-4--run-the-collector)
- [Step 5 — Download the Output](#step-5--download-the-output)
- [Step 6 — Import into the Checklist](#step-6--import-into-the-checklist)
- [Running It Outside Cloud Shell](#running-it-outside-cloud-shell)
- [Interpret the Results](#interpret-the-results)
- [Accuracy and Limitations](#accuracy-and-limitations)
- [Troubleshooting](#troubleshooting)
- [Related Tools](#related-tools)

---

## When to Use This Script

Run it at the **start** of an assessment engagement, before the workshop. Instead of asking the customer to recall which connectors are enabled and what retention is set, you arrive with the answers already recorded and spend the session on the decisions that matter.

Typical questions it answers:

- What is the workspace default retention, and which tables deviate from it?
- Which tables are on the Data Lake tier rather than Analytics?
- Which connectors are demonstrably receiving data right now?
- Which Content Hub solutions and workbooks are already deployed?

It is also useful at the **end** of an engagement, as a second run that evidences what changed.

> [!IMPORTANT]
> The collector performs read operations only. It never creates, modifies or deletes anything, and it does not write to the workspace. It is safe to run in production during business hours.

---

## What It Collects

| Section | Source | Used for |
|:--------|:-------|:---------|
| Workspace settings | `Microsoft.OperationalInsights/workspaces` | Default analytics retention, SKU, daily cap |
| Table retention and plans | `.../tables` | Per-table tier and retention overrides |
| Sentinel onboarding state | `Microsoft.SecurityInsights/onboardingStates` | Confirms Sentinel is enabled on the workspace |
| Data connectors | `.../dataConnectors` | Connector status |
| Content packages | `.../contentPackages` | Installed solution checks |
| Deployed workbooks | `Microsoft.Insights/workbooks` | Workbook checks |
| Table activity | `Usage` table, last 30 days | The **last-seen timestamp** per table |

It deliberately does **not** collect ingestion volumes, agent inventory or analytics rules. Volumes belong to the [Workspace Usage Report](workspace-usage-report.md); agent coverage belongs to [Defender AMA Coverage](defender-ama-coverage.md).

Only tables that deviate from the workspace default are written out, alongside a total count — a workspace with 874 tables typically produces fewer than a dozen rows.

---

## Prerequisites

| Requirement | Details |
|:------------|:--------|
| **Shell** | Bash. Cloud Shell is the path of least resistance; on Windows use WSL or Git Bash |
| **Azure CLI** | Signed in with [`az login`](https://learn.microsoft.com/cli/azure/authenticate-azure-cli). Pre-installed in [Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview) |
| **jq** | Pre-installed in Cloud Shell; install manually elsewhere |
| **Permissions** | Reader on the subscription is sufficient on its own. Otherwise Log Analytics Reader plus Microsoft Sentinel Reader on the workspace, and Reader on the subscription for the workbook inventory — see [roles and permissions](https://learn.microsoft.com/azure/sentinel/roles) |

> [!NOTE]
> Insufficient permissions never stop the run. Each unreadable section is reported as `null` with an entry in the `warnings` array, and collection continues.

---

## Step 1 — Open Azure Cloud Shell

Open [shell.azure.com](https://shell.azure.com), or select the Cloud Shell icon in the Azure portal toolbar. Choose **Bash** rather than PowerShell.

Cloud Shell signs you in automatically, so `az login` is not needed unless the workspace lives in a different tenant from the one Cloud Shell opened against.

---

## Step 2 — Download the Script

```bash
curl -fsSL -o sentinel-collector.sh \
  https://raw.githubusercontent.com/mathijsvermaat/Sentinel-Maturity/main/tools/sentinel-collector.sh
chmod +x sentinel-collector.sh
```

The `chmod` is not optional when the file arrives by download or upload — both drop the executable bit.

Review the script before running it against a customer environment. It is a single file with no dependencies beyond `az` and `jq`, and every call it makes is a `GET` or a read-only query.

---

## Step 3 — Identify the Subscription

This is the step most likely to go wrong, so do it deliberately:

```bash
az account list --query "[].{Name:name, SubscriptionId:id, TenantId:tenantId}" -o table
```

Note the subscription ID that contains the Sentinel workspace. If it is not listed, you are signed in to the wrong tenant:

```bash
az login --tenant <tenant-id>
```

---

## Step 4 — Run the Collector

```bash
./sentinel-collector.sh -s <subscription-id> -g <resource-group> -w <workspace-name>
```

> [!TIP]
> `-s` is optional, but pass it every time. Without it the script uses whichever subscription the CLI currently has selected, which is rarely the right one when you can reach several. The resulting `ResourceGroupNotFound` reads like a permissions problem but is not.

The run prints its progress and finishes with a summary:

```text
Collected:
  Tables scanned .......... 874
  Retention deviations .... 10
  Data connectors ......... 2
  Content packages ........ 52
  Workbooks ............... 50
  Tables with recent data . 41
  Warnings ................ 0
```

Useful options:

| Option | Purpose |
|:-------|:--------|
| `-o <path>` | Write to a specific filename instead of the generated one |
| `-d <days>` | Change the activity look-back window (default 30, maximum 90) |
| `-Q` | Skip the table-activity query entirely, leaving only ARM reads |

Use `-Q` when the Log Analytics query API is blocked. Everything else is still collected, but connector detection becomes far weaker — see [Accuracy and Limitations](#accuracy-and-limitations).

---

## Step 5 — Download the Output

The script writes `sentinel-collector-<workspace>-<timestamp>.json` to the current directory.

In Cloud Shell, retrieve it with **Manage files → Download** in the toolbar and enter the filename.

Open it before sharing it. It contains workspace and table names, subscription and tenant identifiers, and the names of deployed workbooks — treat it as customer configuration data.

---

## Step 6 — Import into the Checklist

1. Open the [Assessment Checklist](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html).
2. Expand **Import collector output**, directly beneath the Save/Load toolbar.
3. Select **Choose collector JSON** and pick the file.
4. Review the preview. Nothing is changed until you select **Apply**.

The preview groups every proposed change and shows three counts: what will be applied, what you have already answered differently, and what already matches.

By default the importer only fills in checks you have not answered. Tick **Overwrite answers that are already set** to let collector findings replace your existing answers — each one is then annotated with the value it replaces.

> [!IMPORTANT]
> The importer only ever upgrades *unknown* to *known*. It never marks a check as **Not configured**, and it never touches your comments. Anything the collector could not determine is left for you to assess.

Re-importing the same file is safe: the second run reports zero changes to apply.

---

## Running It Outside Cloud Shell

1. Install the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and `jq`.
2. Sign in with `az login`, adding `--tenant <tenant-id>` for cross-tenant work.
3. Follow steps 2 to 6 above unchanged.

On Windows use WSL or Git Bash. The script will not run in PowerShell or `cmd`.

---

## Interpret the Results

**Retention deviations** are the highest-value output. Each row states whether a table's interactive and total retention are inherited from the workspace or explicitly overridden. A table pinned to the same value as the workspace default still counts as an override — it will not follow a future change to the workspace default, which is usually unintentional.

**Tables with recent data** is the honest measure of what is actually flowing. A connector configured a year ago that stopped six weeks ago still appears as configured in Azure, but will have no recent activity.

**Warnings** deserve a read every time. A section reported as `null` means *unknown*, not *absent* — the distinction matters when the output feeds an assessment.

---

## Accuracy and Limitations

**Connector configuration under-reports badly.** The ARM `dataConnectors` API returns far fewer connectors than a workspace actually has: connectors created through the Defender portal, through Content Hub solutions, or via diagnostic settings frequently do not appear. A lab workspace with roughly fifteen working connectors returned two. Treat an absent connector as *unknown*.

**Table activity is the stronger signal**, which is why the collector runs the `Usage` query. A table that received data in the last seven days is proof the connector works, regardless of what the connector API says.

**Not every table appears in `Usage`.** It is the billing rollup for Log Analytics ingestion, so tables that land only in the Data Lake tier may be missing. Those fall through to *unknown*.

**Table presence proves nothing.** The tables API returns every table the workspace schema knows about — hundreds — whether or not a single row has ever been written. Only activity distinguishes them.

**A 7-to-30-day gap is reported, not answered.** A table last seen in that window is surfaced as a note asking you to confirm whether it is still expected to flow, rather than being marked either way.

**No volumes.** The collector reports *what* and *when*, never *how much*. Use the [Workspace Usage Report](workspace-usage-report.md) for GB/day, or the [XDR Data Volume Insights](xdr-data-volume-insights.md) query for Defender tables.

---

## Troubleshooting

| Symptom | Cause and fix |
|:--------|:--------------|
| `bash: ./sentinel-collector.sh: Permission denied` | The executable bit was lost. Run `chmod +x sentinel-collector.sh`, or use `bash sentinel-collector.sh …` |
| `ResourceGroupNotFound` | Wrong subscription — pass `-s`. The error lists the subscriptions you can see |
| `$'\r': command not found` | Windows line endings. Run `sed -i 's/\r$//' sentinel-collector.sh` |
| `jq: command not found` | Install `jq`, or run the script in Cloud Shell where it is already present |
| `Microsoft Sentinel does not appear to be enabled` | Genuine when the workspace read succeeded — the workspace is Log Analytics only, with no Sentinel onboarding |
| Sections reported as `null` | A permissions gap on that call. Check the `warnings` array for the exact error |
| Few or no connectors returned | Expected. See [Accuracy and Limitations](#accuracy-and-limitations) |
| Checklist has no import panel | The panel is part of the current checklist. Reload the page, bypassing the browser cache |

---

## Related Tools

| Tool | Use it for |
|:-----|:-----------|
| [Workspace Usage Report](workspace-usage-report.md) | Actual ingestion volumes per table, which the collector deliberately omits |
| [Retention Insights](retention-insights.md) | Cost modelling for the retention changes the collector surfaces |
| [Defender AMA Coverage](defender-ama-coverage.md) | Agent deployment gaps behind a connector that shows no recent data |
| [XDR Data Volume Insights](xdr-data-volume-insights.md) | Sizing Defender XDR tables before moving them between tiers |

---

[← Back to Procedures](README.md) · [← Back to Sentinel Maturity Model](../README.md)
