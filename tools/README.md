# Tools

Executable helper scripts kept inside this repository. Tools that live in their own repositories are listed in the [Tools table of the repository root README](../README.md#tools) instead.

| Script | Type | Purpose |
|:-------|:-----|:--------|
| [sentinel-collector.sh](sentinel-collector.sh) | Bash | Read-only collection of workspace retention, per-table retention overrides, data connectors, installed content packages and deployed workbooks, exported as JSON for import into the [Assessment Checklist](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html) |

---

## sentinel-collector.sh

Full walkthrough: [Sentinel Collector procedure](../procedures/sentinel-collector.md).

> [!IMPORTANT]
> The script only performs read operations. It never creates, modifies or deletes anything, and it does not write to the workspace.

### Run it in Azure Cloud Shell (recommended)

Cloud Shell already has the Azure CLI, `jq` and an authenticated session, so there is nothing to install.

1. Open [shell.azure.com](https://shell.azure.com) or select the **Cloud Shell** icon in the Azure portal toolbar, and choose **Bash**.
2. Download the script:

   ```bash
   curl -fsSL -o sentinel-collector.sh \
     https://raw.githubusercontent.com/mathijsvermaat/Sentinel-Maturity/main/tools/sentinel-collector.sh
   chmod +x sentinel-collector.sh
   ```

3. Find the subscription holding the workspace:

   ```bash
   az account list --query "[].{Name:name, SubscriptionId:id, TenantId:tenantId}" -o table
   ```

4. Run it:

   ```bash
   ./sentinel-collector.sh -s <subscription-id> -g <resource-group> -w <workspace-name>
   ```

5. Download the resulting JSON with **Manage files → Download** in the Cloud Shell toolbar, then load it into the checklist.

### Run it from a local Azure CLI

1. Install the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and `jq`:

   ```bash
   sudo apt-get install -y jq     # Debian / Ubuntu
   brew install jq                # macOS
   ```

2. Sign in. Add `--tenant` when the workspace is in a different tenant from your default:

   ```bash
   az login
   az login --tenant <tenant-id>    # cross-tenant
   ```

3. Download and run the script exactly as in steps 2–4 above.

On Windows, run it from **WSL** or **Git Bash** — it is a Bash script and will not run in PowerShell or `cmd`.

### Options

```text
-s <guid>   Subscription ID
-g <name>   Resource group containing the Log Analytics workspace   (required)
-w <name>   Log Analytics workspace name                            (required)
-o <path>   Output file
-d <days>   Look-back window for table activity (default 30, max 90)
-Q          Skip the table-activity query (ARM reads only)
-h          Show help
```

> [!TIP]
> **Always pass `-s`.** It is technically optional — without it the script uses whichever subscription `az` currently has selected — but that is rarely the one you want if you can reach more than one tenant or subscription. Getting it wrong produces `ResourceGroupNotFound`, which reads like a permissions problem but is not.

---

## Requirements

| Requirement | Details |
|:------------|:--------|
| **Azure CLI** | Signed in with [`az login`](https://learn.microsoft.com/cli/azure/authenticate-azure-cli). Pre-installed in [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview) |
| **jq** | Pre-installed in Cloud Shell; install manually elsewhere |
| **Shell** | Bash. Use WSL or Git Bash on Windows |
| **Permissions** | Log Analytics Reader and Microsoft Sentinel Reader on the workspace, plus Reader on the subscription for the workbook inventory. See [Sentinel roles and permissions](https://learn.microsoft.com/azure/sentinel/roles) |

Reader on the subscription alone already covers every call the script makes, including the table-activity query.

---

## Troubleshooting

| Symptom | Cause and fix |
|:--------|:--------------|
| `Permission denied` | The executable bit was lost in transit — Cloud Shell uploads and copy-paste both drop it. Run `chmod +x sentinel-collector.sh`, or invoke it as `bash sentinel-collector.sh …` |
| `ResourceGroupNotFound` | The wrong subscription, almost always because `-s` was omitted. The error message lists the subscriptions you can currently see |
| `$'\r': command not found` | The file was saved with Windows line endings. Run `sed -i 's/\r$//' sentinel-collector.sh` |
| Sections reported as `null` | Insufficient permissions for that call. The run continues and every gap is listed in the `warnings` array |

> [!NOTE]
> Sections that cannot be collected are reported as `null` with an entry in the `warnings` array. The importer treats `null` as *unknown* and leaves the corresponding checklist items for the assessor; it never marks anything as *Not configured* on the basis of missing data.

---

[← Back to Sentinel Maturity Model](../README.md)
