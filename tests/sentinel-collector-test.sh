#!/usr/bin/env bash
set -euo pipefail

COLLECTOR=${1:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools" && pwd)/sentinel-collector.sh"}
REAL_JQ=${COLLECTOR_TEST_JQ:-$(command -v jq)}
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export REAL_JQ

jq() {
    case "${COLLECTOR_TEST_SCENARIO:-}:${*: -1}" in
        malformed:*/connectors.raw) printf '{invalid\n'; return 0 ;;
        empty-fragment:*/connectors.raw) return 0 ;;
    esac
    "$REAL_JQ" "$@"
}

mv() {
    if [[ "${COLLECTOR_TEST_SCENARIO:-}" == publish-failure ]]; then
        printf 'Simulated output rename failure\n' >&2
        return 1
    fi
    command mv "$@"
}

az() {
    if [[ "$1" == account && "$2" == show ]]; then
        case " $* " in
            *" --query name "*) printf 'Offline test subscription\n' ;;
            *) printf '{}\n' ;;
        esac
        return 0
    fi
    if [[ "$1" != rest ]]; then
        printf 'Unexpected mocked az command\n' >&2
        return 1
    fi
    local url="" scenario="${COLLECTOR_TEST_SCENARIO:-normal}"
    while (( $# )); do
        case "$1" in
            --url) url="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    case "$scenario:$url" in
        unavailable:*|partial:*/dataConnectors\?*|partial:*/contentPackages\?*|activity-failure:*/query)
            printf 'AuthorizationFailed: simulated read denial\n' >&2
            return 1
            ;;
    esac
    case "$url" in
        */tables\?*)
            jq -nc '{value:[
                {name:"SecurityEvent",properties:{plan:"Analytics",retentionInDays:90,retentionInDaysAsDefault:false,totalRetentionInDays:365,totalRetentionInDaysAsDefault:false}},
                {name:"DefaultTable",properties:{plan:"Analytics",retentionInDaysAsDefault:true,totalRetentionInDaysAsDefault:true}}
            ]}'
            ;;
        */onboardingStates/default\?*)
            if [[ "$scenario" == not-onboarded ]]; then
                printf '404 NotFound\n' >&2
                return 1
            fi
            printf '{}\n'
            ;;
        */dataConnectors\?*)
            local count=2
            [[ "$scenario" != large ]] || count=12000
            [[ "$scenario" != empty ]] || count=0
            jq -nc --argjson count "$count" '{value:[range($count) | {
                kind:"Office365",name:("connector-" + tostring),
                properties:{dataTypes:{OfficeActivity:{state:"Enabled"},OtherStream:{state:"Disabled"}}}
            }]}'
            ;;
        */contentPackages\?*)
            jq -nc '{value:[{properties:{contentId:"test-package",displayName:"Test solution",version:"1.0",contentKind:"Solution"}}]}'
            ;;
        */Microsoft.Insights/workbooks\?*)
            jq -nc '{value:[{properties:{displayName:"Test workbook",category:"sentinel"}}]}'
            ;;
        */query)
            jq -nc '{tables:[{name:"PrimaryResult",columns:[{name:"name"},{name:"lastSeen"}],rows:[["SecurityEvent","2026-11-17T00:00:00Z"]]}]}'
            ;;
        */Microsoft.OperationalInsights/workspaces/test-workspace\?*)
            jq -nc --arg scenario "$scenario" '{name:"test-workspace",id:"/subscriptions/test-subscription/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-workspace",location:"westeurope",properties:{customerId:(if $scenario == "no-customer-id" then null else "test-customer-id" end),sku:{name:"PerGB2018"},retentionInDays:90,workspaceCapping:{dailyQuotaGb:10},features:{}}}'
            ;;
        *) printf 'Unexpected mocked az URL: %s\n' "$url" >&2; return 1 ;;
    esac
}
export -f az jq mv

collect() {
    local scenario="$1"
    shift
    COLLECTOR_TEST_SCENARIO="$scenario" bash "$COLLECTOR" \
        -s test-subscription -g test-rg -w test-workspace -o "$output" "$@" \
        > "$TEST_TMP/$scenario.stdout" 2> "$TEST_TMP/$scenario.log"
}

run_case() {
    output="$TEST_TMP/$1.json"
    if ! collect "$@"; then
        cat "$TEST_TMP/$1.log" >&2
        exit 1
    fi
}

check() {
    if ! jq -e "$2" "$output" > /dev/null; then
        printf 'FAIL: %s\n' "$1" >&2
        exit 1
    fi
    printf 'PASS: %s\n' "$1"
}

expect_failure() {
    local scenario="$1" status
    if collect "$scenario"; then
        printf 'FAIL: %s unexpectedly succeeded\n' "$scenario" >&2
        exit 1
    else
        status=$?
    fi
    if [[ "$status" != 4 ]]; then
        printf 'FAIL: %s returned %s instead of 4\n' "$scenario" "$status" >&2
        cat "$TEST_TMP/$scenario.log" >&2
        exit 1
    fi
    if compgen -G "$output.tmp.*" > /dev/null; then
        printf 'FAIL: %s left a temporary output file\n' "$scenario" >&2
        exit 1
    fi
    printf 'PASS: %s fails cleanly\n' "$scenario"
}

run_case normal
check 'schema 1.0 and complete object/array output' '
    .schemaVersion == "1.0" and (.scriptVersion | type == "string") and
    (.collectedAt | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")) and
    .lookbackDays == 30 and
    .workspace == {subscriptionId:"test-subscription",resourceGroup:"test-rg",name:"test-workspace",resourceId:"/subscriptions/test-subscription/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-workspace",customerId:"test-customer-id",location:"westeurope",sku:"PerGB2018",retentionInDays:90,dailyQuotaGb:10,features:{},sentinelOnboarded:true} and
    .tables == {totalCount:2,nonDefault:[{name:"SecurityEvent",plan:"Analytics",retentionInDays:90,retentionIsDefault:false,totalRetentionInDays:365,totalRetentionIsDefault:false}]} and
    .dataConnectors == [range(2) | {kind:"Office365",name:("connector-" + tostring),enabledStreams:["OfficeActivity"],disabledStreams:["OtherStream"]}] and
    .contentPackages == [{contentId:"test-package",displayName:"Test solution",version:"1.0",contentKind:"Solution"}] and
    .workbooks == [{displayName:"Test workbook",category:"sentinel"}] and
    .tableActivity == [{name:"SecurityEvent",lastSeen:"2026-11-17T00:00:00Z"}] and
    .warnings == []'

run_case large
check 'large inventory retains all 12000 connectors' '(.dataConnectors | length) == 12000 and .dataConnectors[-1].name == "connector-11999" and .warnings == []'

run_case skipped -Q -d 7
check 'skip activity retains null and warning' '.tableActivity == null and .lookbackDays == 7 and (.warnings | map(.code)) == ["activity-skipped"]'

run_case partial
check 'partial failures retain both warnings and null sections' '.dataConnectors == null and .contentPackages == null and (.workbooks | length) == 1 and (.warnings | map(.code)) == ["connectors-unavailable","packages-unavailable"]'

run_case unavailable
check 'all unavailable sections remain null' '([.workspace,.tables,.tableActivity,.dataConnectors,.contentPackages,.workbooks] | all(. == null)) and (.warnings | map(.code)) == ["workspace-unavailable","tables-unavailable","onboarding-unavailable","connectors-unavailable","packages-unavailable","workbooks-unavailable","activity-unavailable"]'

run_case activity-failure
check 'activity API failure remains unknown' '.tableActivity == null and (.warnings | map(.code)) == ["activity-unavailable"]'

run_case no-customer-id
check 'missing customer ID skips activity safely' '.workspace.customerId == null and .tableActivity == null and (.warnings | map(.code)) == ["activity-unavailable"]'

run_case empty
check 'successful empty inventory remains an array' '.dataConnectors == [] and .warnings == []'

run_case empty-fragment
check 'empty fragment retains previous null fallback' '.dataConnectors == null'

run_case not-onboarded
check 'false onboarding and retention flags are preserved' '.workspace.sentinelOnboarded == false and .tables.nonDefault[0].retentionIsDefault == false and .tables.nonDefault[0].totalRetentionIsDefault == false'

for scenario in malformed publish-failure; do
    output="$TEST_TMP/$scenario.json"
    printf '{"existing":true}\n' > "$output"
    expect_failure "$scenario"
    check "$scenario preserves existing output" '. == {existing:true}'
done

output="$TEST_TMP/missing-directory/export.json"
expect_failure missing-directory

output="$TEST_TMP/existing-directory"
mkdir "$output"
expect_failure existing-directory
[[ -d "$output" ]]

output="$TEST_TMP/output with spaces.json"
printf '{"existing":true}\n' > "$output"
collect normal
check 'existing output with spaces is replaced successfully' '.schemaVersion == "1.0" and .workspace.name == "test-workspace" and (has("existing") | not)'
if compgen -G "$output.tmp.*" > /dev/null; then
    printf 'FAIL: successful collection left a temporary output file\n' >&2
    exit 1
fi

printf 'All offline collector checks passed.\n'