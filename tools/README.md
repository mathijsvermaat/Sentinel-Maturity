# Tools

Executable helper scripts maintained in this repository. Scripts hosted in their own repositories are listed in the [main README Tools table](../README.md#tools) instead.

| Script | Type | Purpose |
|:-------|:-----|:--------|
| [sentinel-collector.sh](sentinel-collector.sh) | Bash | Read-only collection of workspace retention, per-table retention overrides, data connectors, installed content packages and deployed workbooks, exported as JSON for import into the [Assessment Checklist](https://mathijsvermaat.github.io/sentinel-maturity-assessment.html) |

---

## sentinel-collector.sh

```bash
chmod +x sentinel-collector.sh
./sentinel-collector.sh -g <resource-group> -w <workspace-name>
```

Run `./sentinel-collector.sh -h` for the full option list.

> [!TIP]
> `bash: ./sentinel-collector.sh: Permission denied` means the executable bit was lost in transit — Cloud Shell uploads and copy-paste both drop it. Run `chmod +x sentinel-collector.sh` once, or invoke it as `bash sentinel-collector.sh …` instead.

**Requires:** Azure CLI (signed in with `az login`) and `jq`. Both are pre-installed in Azure Cloud Shell.

**Permissions:** Log Analytics Reader and Microsoft Sentinel Reader on the workspace, plus Reader on the subscription for the workbook inventory.

> [!IMPORTANT]
> The script only performs read operations. It never creates, modifies or deletes anything, and it does not write to the workspace.

> [!NOTE]
> Sections that cannot be collected — usually because of missing permissions — are reported as `null` with an entry in the `warnings` array. The importer treats `null` as *unknown* and marks the corresponding checklist items **To verify**; it never marks anything as *Not configured* on the basis of missing data.

---

[← Back to Sentinel Maturity Model](../README.md)
