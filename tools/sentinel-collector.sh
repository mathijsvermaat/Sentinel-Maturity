#!/usr/bin/env bash
#
# sentinel-collector.sh — Sentinel Maturity Model workspace collector
#
# Read-only. Collects workspace retention, per-table retention overrides, data
# connectors, installed content packages, deployed workbooks and (optionally)
# per-table last-seen timestamps, then writes a JSON file for import into the
# Sentinel Maturity Assessment Checklist.
#
#   https://mathijsvermaat.github.io/sentinel-maturity-assessment.html
#
# The script performs GET/POST-query operations only. It never creates,
# modifies or deletes anything.
#
# Licensed under the MIT License. See LICENSE in the repository root.

set -uo pipefail

SCRIPT_VERSION="0.1.0"
SCHEMA_VERSION="1.0"

API_WORKSPACE="2023-09-01"
API_TABLES="2022-10-01"
API_SECURITYINSIGHTS="2024-03-01"
API_WORKBOOKS="2018-06-17-preview"

ARM="https://management.azure.com"
LA_RESOURCE="https://api.loganalytics.io"

SUBSCRIPTION=""
RESOURCE_GROUP=""
WORKSPACE=""
OUTPUT=""
LOOKBACK_DAYS=30
SKIP_ACTIVITY=0

usage() {
    cat <<'EOF'
sentinel-collector.sh — read-only Microsoft Sentinel workspace collector

USAGE
  ./sentinel-collector.sh -s <subscription-id> -g <resource-group> -w <workspace-name>

REQUIRED
  -g <name>   Resource group containing the Log Analytics workspace
  -w <name>   Log Analytics workspace name

OPTIONS
  -s <guid>   Subscription ID. Optional, but pass it: without -s the script uses
              whichever subscription az currently has selected, which is rarely
              the right one when you can reach more than one tenant. List them
              with: az account list -o table
  -o <path>   Output file (defaults to ./sentinel-collector-<workspace>-<timestamp>.json)
  -d <days>   Look-back window for table activity (default 30, max 90)
  -Q          Skip the table-activity query (ARM reads only)
  -h          Show this help

PREREQUISITES
  az CLI, logged in with 'az login'
  jq

PERMISSIONS
  Log Analytics Reader     on the workspace  — workspace and table settings
  Microsoft Sentinel Reader on the workspace — data connectors, content packages
  Reader                   on the subscription — deployed workbooks

  The table-activity query additionally needs query rights on the workspace
  (included in Log Analytics Reader). Use -Q to skip it if the query API is
  blocked; every other section is collected regardless.

OUTPUT
  A JSON document matching the collector contract (schemaVersion 1.0). Sections
  that could not be collected are reported in the "warnings" array rather than
  omitted silently — the importer treats missing data as "unknown", never as
  "not configured".
EOF
}

while getopts ":s:g:w:o:d:Qh" opt; do
    case "$opt" in
        s) SUBSCRIPTION="$OPTARG" ;;
        g) RESOURCE_GROUP="$OPTARG" ;;
        w) WORKSPACE="$OPTARG" ;;
        o) OUTPUT="$OPTARG" ;;
        d) LOOKBACK_DAYS="$OPTARG" ;;
        Q) SKIP_ACTIVITY=1 ;;
        h) usage; exit 0 ;;
        :) echo "Error: -$OPTARG requires a value." >&2; exit 2 ;;
        \?) echo "Error: unknown option -$OPTARG." >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$RESOURCE_GROUP" || -z "$WORKSPACE" ]]; then
    echo "Error: -g and -w are required." >&2
    usage >&2
    exit 2
fi

if ! [[ "$LOOKBACK_DAYS" =~ ^[0-9]+$ ]] || (( LOOKBACK_DAYS < 1 || LOOKBACK_DAYS > 90 )); then
    echo "Error: -d must be a whole number between 1 and 90." >&2
    exit 2
fi

for dep in az jq; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Error: '$dep' is required but was not found on PATH." >&2
        exit 3
    fi
done

if ! az account show --only-show-errors >/dev/null 2>&1; then
    echo "Error: not signed in. Run 'az login' first." >&2
    exit 3
fi

SUB_DEFAULTED=""
if [[ -z "$SUBSCRIPTION" ]]; then
    SUBSCRIPTION=$(az account show --only-show-errors --query id -o tsv 2>/dev/null)
    if [[ -z "$SUBSCRIPTION" ]]; then
        echo "Error: could not determine the current subscription. Pass -s explicitly." >&2
        exit 3
    fi
    SUB_DEFAULTED="  [defaulted — pass -s to override]"
fi

COLLECTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="./sentinel-collector-${WORKSPACE}-$(date -u +%Y%m%d-%H%M%S).json"
fi

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t sentinel-collector)
trap 'rm -rf "$TMP"' EXIT
WARN_FILE="$TMP/warnings.ndjson"
: > "$WARN_FILE"

LAST_ERR=""

log()  { printf '%s\n' "$*" >&2; }
step() { printf '  → %s\n' "$*" >&2; }

warn() {
    local code="$1" message="$2"
    jq -nc --arg c "$code" --arg m "$message" '{code:$c,message:$m}' >> "$WARN_FILE"
    printf '  ! %s\n' "$message" >&2
}

# Collapses an az error blob into a single trimmed line so it survives JSON encoding.
flatten_err() {
    printf '%s' "$1" | tr '\n\r\t' '   ' | sed 's/  */ /g' | cut -c1-400
}

arm_get() {
    local url="$1" out="$2"
    LAST_ERR=""
    if LAST_ERR=$(az rest --method get --url "$url" --only-show-errors -o json 2>&1 1>"$out"); then
        [[ -s "$out" ]] && return 0
        LAST_ERR="empty response"
    fi
    : > "$out"
    return 1
}

# Reads a normalised fragment, or 'null' when the section could not be collected.
frag() {
    local f="$TMP/$1"
    if [[ -s "$f" ]]; then cat "$f"; else printf 'null'; fi
}

WS_ID="/subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.OperationalInsights/workspaces/${WORKSPACE}"
SI="${ARM}${WS_ID}/providers/Microsoft.SecurityInsights"

SUB_NAME=$(az account show --subscription "$SUBSCRIPTION" --only-show-errors --query name -o tsv 2>/dev/null)

log ""
log "Sentinel Maturity Model — collector v${SCRIPT_VERSION} (read-only)"
log "  Subscription:   ${SUBSCRIPTION}${SUB_NAME:+  (${SUB_NAME})}${SUB_DEFAULTED}"
log "  Resource group: ${RESOURCE_GROUP}"
log "  Workspace:      ${WORKSPACE}"
log ""

# A wrong subscription, resource group or workspace name is a targeting error,
# not a permissions one: every later call would fail the same way and the output
# would be meaningless, so stop here with something actionable.
fail_target() {
    log ""
    log "Error: that workspace could not be found."
    log "  Subscription:   ${SUBSCRIPTION}${SUB_NAME:+  (${SUB_NAME})}${SUB_DEFAULTED}"
    log "  Resource group: ${RESOURCE_GROUP}"
    log "  Workspace:      ${WORKSPACE}"
    log ""
    log "  $(flatten_err "$1")"
    log ""
    log "If the workspace lives in another subscription, pass it with -s. If it lives in"
    log "another tenant, sign in there first with 'az login --tenant <tenant-id>'."
    log ""
    log "Subscriptions you can currently see:"
    az account list --only-show-errors --query "[].{Name:name, SubscriptionId:id, TenantId:tenantId}" -o table >&2 2>/dev/null
    log ""
    exit 4
}

# --- 1. Workspace -----------------------------------------------------------
step "Workspace settings"
CUSTOMER_ID=""
WORKSPACE_OK=0
if arm_get "${ARM}${WS_ID}?api-version=${API_WORKSPACE}" "$TMP/workspace.raw"; then
    WORKSPACE_OK=1
    jq -c \
        --arg sub "$SUBSCRIPTION" \
        --arg rg "$RESOURCE_GROUP" \
        '{
            subscriptionId: $sub,
            resourceGroup: $rg,
            name: .name,
            resourceId: .id,
            customerId: (.properties.customerId // null),
            location: (.location // null),
            sku: (.properties.sku.name // null),
            retentionInDays: (.properties.retentionInDays // null),
            dailyQuotaGb: (.properties.workspaceCapping.dailyQuotaGb // null),
            features: (.properties.features // {})
        }' "$TMP/workspace.raw" > "$TMP/workspace.frag"
    CUSTOMER_ID=$(jq -r '.customerId // empty' "$TMP/workspace.frag")
else
    case "$LAST_ERR" in
        *SubscriptionNotFound*|*ResourceGroupNotFound*|*ResourceNotFound*|*InvalidSubscriptionId*)
            fail_target "$LAST_ERR" ;;
        *)
            warn "workspace-unavailable" "Could not read the workspace: $(flatten_err "$LAST_ERR")" ;;
    esac
fi

# --- 2. Tables --------------------------------------------------------------
step "Table retention and plans"
if arm_get "${ARM}${WS_ID}/tables?api-version=${API_TABLES}" "$TMP/tables.raw"; then
    # Only tables that deviate from the workspace default are emitted; the rest
    # are fully described by workspace.retentionInDays.
    jq -c '{
        totalCount: (.value | length),
        nonDefault: [
            .value[]
            | select(
                (.properties.retentionInDaysAsDefault != true)
                or (.properties.totalRetentionInDaysAsDefault != true)
                or ((.properties.plan // "Analytics") != "Analytics")
              )
            | {
                name: .name,
                plan: (.properties.plan // null),
                retentionInDays: (.properties.retentionInDays // null),
                # The // operator in jq swallows false, so booleans are read directly.
                retentionIsDefault: .properties.retentionInDaysAsDefault,
                totalRetentionInDays: (.properties.totalRetentionInDays // null),
                totalRetentionIsDefault: .properties.totalRetentionInDaysAsDefault
              }
        ] | sort_by(.name)
    }' "$TMP/tables.raw" > "$TMP/tables.frag"
else
    warn "tables-unavailable" "Could not list workspace tables: $(flatten_err "$LAST_ERR")"
fi

# --- 3. Sentinel onboarding -------------------------------------------------
step "Sentinel onboarding state"
SENTINEL_ONBOARDED="null"
if (( ! WORKSPACE_OK )); then
    warn "onboarding-unavailable" "Onboarding state not checked: the workspace itself could not be read."
elif arm_get "${SI}/onboardingStates/default?api-version=${API_SECURITYINSIGHTS}" "$TMP/onboarding.raw"; then
    SENTINEL_ONBOARDED="true"
else
    case "$LAST_ERR" in
        # A 404 only means "not onboarded" when it is the onboarding resource that
        # is missing — a missing subscription or resource group also returns 404.
        *SubscriptionNotFound*|*ResourceGroupNotFound*)
            warn "onboarding-unavailable" "Could not read the Sentinel onboarding state: $(flatten_err "$LAST_ERR")" ;;
        *NotFound*|*404*)
            SENTINEL_ONBOARDED="false"
            warn "sentinel-not-onboarded" "Microsoft Sentinel does not appear to be enabled on this workspace." ;;
        *)
            warn "onboarding-unavailable" "Could not read the Sentinel onboarding state: $(flatten_err "$LAST_ERR")" ;;
    esac
fi

# --- 4. Data connectors -----------------------------------------------------
step "Data connectors"
if arm_get "${SI}/dataConnectors?api-version=${API_SECURITYINSIGHTS}" "$TMP/connectors.raw"; then
    jq -c '[
        .value[]
        | (.properties.dataTypes // {}) as $dt
        | {
            kind: (.kind // null),
            name: (.name // null),
            enabledStreams:  [ $dt | to_entries[] | select((.value.state // "" | ascii_downcase) == "enabled")  | .key ] | sort,
            disabledStreams: [ $dt | to_entries[] | select((.value.state // "" | ascii_downcase) == "disabled") | .key ] | sort
          }
    ] | sort_by(.kind)' "$TMP/connectors.raw" > "$TMP/connectors.frag"
else
    warn "connectors-unavailable" "Could not list data connectors: $(flatten_err "$LAST_ERR")"
fi

# --- 5. Content packages ----------------------------------------------------
step "Installed content packages"
if arm_get "${SI}/contentPackages?api-version=${API_SECURITYINSIGHTS}" "$TMP/packages.raw"; then
    jq -c '[
        .value[]
        | {
            contentId: (.properties.contentId // null),
            displayName: (.properties.displayName // null),
            version: (.properties.version // null),
            contentKind: (.properties.contentKind // null)
          }
    ] | sort_by(.displayName // "")' "$TMP/packages.raw" > "$TMP/packages.frag"
else
    warn "packages-unavailable" "Could not list installed content packages: $(flatten_err "$LAST_ERR")"
fi

# --- 6. Workbooks -----------------------------------------------------------
step "Deployed workbooks"
WS_ID_ENC="${WS_ID//\//%2F}"
WB_URL="${ARM}/subscriptions/${SUBSCRIPTION}/providers/Microsoft.Insights/workbooks?api-version=${API_WORKBOOKS}&category=sentinel&canFetchContent=false&sourceId=${WS_ID_ENC}"
if arm_get "$WB_URL" "$TMP/workbooks.raw"; then
    jq -c '[
        .value[]
        | {
            displayName: (.properties.displayName // null),
            category: (.properties.category // null)
          }
    ] | sort_by(.displayName // "")' "$TMP/workbooks.raw" > "$TMP/workbooks.frag"
else
    warn "workbooks-unavailable" "Could not list deployed workbooks: $(flatten_err "$LAST_ERR")"
fi

# --- 7. Table activity ------------------------------------------------------
# Shaping is done in KQL rather than jq so the result is a flat name/lastSeen
# projection. 'lastSeen' is reported as-is; thresholds are applied by the
# importer, not here.
if (( SKIP_ACTIVITY )); then
    log "  → Table activity (skipped)"
    warn "activity-skipped" "Table-activity query skipped (-Q). Connector detection falls back to configuration only."
elif [[ -z "$CUSTOMER_ID" ]]; then
    warn "activity-unavailable" "Table-activity query skipped: the workspace ID (customerId) could not be determined."
else
    step "Table activity (last ${LOOKBACK_DAYS} days)"
    KQL="Usage
| where TimeGenerated > ago(${LOOKBACK_DAYS}d)
| summarize lastSeen = max(TimeGenerated) by DataType
| project name = DataType, lastSeen
| order by name asc"
    QUERY_BODY=$(jq -nc --arg q "$KQL" '{query:$q}')
    if LAST_ERR=$(az rest --method post \
            --url "${LA_RESOURCE}/v1/workspaces/${CUSTOMER_ID}/query" \
            --resource "$LA_RESOURCE" \
            --headers "Content-Type=application/json" \
            --body "$QUERY_BODY" \
            --only-show-errors -o json 2>&1 1>"$TMP/activity.raw") && [[ -s "$TMP/activity.raw" ]]; then
        jq -c '
            (.tables // [] | map(select(.name == "PrimaryResult")) | first) as $t
            | if $t == null then []
              else
                ($t.columns | map(.name)) as $cols
                | [ $t.rows[]
                    | . as $row
                    | reduce range(0; ($cols | length)) as $i ({}; . + { ($cols[$i]): $row[$i] })
                  ]
              end
            | map({ name: .name, lastSeen: .lastSeen })
            | sort_by(.name)
        ' "$TMP/activity.raw" > "$TMP/activity.frag"
    else
        warn "activity-unavailable" "Table-activity query failed: $(flatten_err "$LAST_ERR")"
    fi
fi

# --- 8. Assemble ------------------------------------------------------------
jq -n \
    --arg schemaVersion "$SCHEMA_VERSION" \
    --arg scriptVersion "$SCRIPT_VERSION" \
    --arg collectedAt "$COLLECTED_AT" \
    --argjson lookbackDays "$LOOKBACK_DAYS" \
    --argjson sentinelOnboarded "$SENTINEL_ONBOARDED" \
    --argjson workspace "$(frag workspace.frag)" \
    --argjson tables "$(frag tables.frag)" \
    --argjson tableActivity "$(frag activity.frag)" \
    --argjson dataConnectors "$(frag connectors.frag)" \
    --argjson contentPackages "$(frag packages.frag)" \
    --argjson workbooks "$(frag workbooks.frag)" \
    --slurpfile warnings "$WARN_FILE" \
    '{
        schemaVersion: $schemaVersion,
        scriptVersion: $scriptVersion,
        collectedAt: $collectedAt,
        lookbackDays: $lookbackDays,
        workspace: (if $workspace == null then null else $workspace + { sentinelOnboarded: $sentinelOnboarded } end),
        tables: $tables,
        tableActivity: $tableActivity,
        dataConnectors: $dataConnectors,
        contentPackages: $contentPackages,
        workbooks: $workbooks,
        warnings: $warnings
    }' > "$OUTPUT"

if [[ ! -s "$OUTPUT" ]]; then
    echo "Error: failed to write $OUTPUT." >&2
    exit 4
fi

log ""
log "Collected:"
log "  Tables scanned .......... $(jq -r '.tables.totalCount // "n/a"' "$OUTPUT")"
log "  Retention deviations .... $(jq -r 'if .tables then (.tables.nonDefault | length) else "n/a" end' "$OUTPUT")"
log "  Data connectors ......... $(jq -r 'if .dataConnectors then (.dataConnectors | length) else "n/a" end' "$OUTPUT")"
log "  Content packages ........ $(jq -r 'if .contentPackages then (.contentPackages | length) else "n/a" end' "$OUTPUT")"
log "  Workbooks ............... $(jq -r 'if .workbooks then (.workbooks | length) else "n/a" end' "$OUTPUT")"
log "  Tables with recent data . $(jq -r 'if .tableActivity then (.tableActivity | length) else "n/a" end' "$OUTPUT")"
log "  Warnings ................ $(jq -r '.warnings | length' "$OUTPUT")"
log ""
log "Written to: $OUTPUT"
log "Import it via the 'Import collector output' panel in the assessment checklist."
log ""
