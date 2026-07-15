#!/usr/bin/env bash
#
# Report Slurm jobs for a given account with nicer formatting.
# Usage: ./scripts/slurm_jobs.sh ACCOUNT [STATE]
#   ACCOUNT: Slurm account name
#   STATE: all (default), running, pending, completed, cancelled, failed, etc.
#

set -euo pipefail

print_usage() {
    cat <<EOF
Usage: $0 ACCOUNT [STATE]

Report Slurm jobs for a given account with nicer formatting.

Arguments:
  ACCOUNT  Slurm account name
  STATE    Job state filter: all (default), running, pending, completed,
           cancelled, failed, etc.

Options:
  -h, --help  Show this help message and exit
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    print_usage
    exit 0
fi

if [[ -z "${1:-}" ]]; then
    print_usage >&2
    exit 1
fi

ACCOUNT="$1"
STATE_FILTER="${2:-all}"

# Color codes
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
CYAN="\e[36m"
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
MAGENTA="\e[35m"

# Build squeue state argument
if [[ "$STATE_FILTER" == "all" ]]; then
    STATE_ARG=""
    TITLE="All jobs"
else
    STATE_ARG="-t ${STATE_FILTER}"
    TITLE="${STATE_FILTER} jobs"
fi

# Columns: JobID, Partition, Name, User, State, Time, TimeLimit, NumNodes, NumCPUs, ReasonList, Nodelist
SQUEUE_FORMAT="%.12i %.10P %.18j %.10u %.10T %.10M %.10l %.6D %.5C %.20R %.20N"

print_header() {
    echo -e "${BOLD}${CYAN}=== Slurm ${TITLE} for account ${ACCOUNT} ===${RESET}"
    echo
}

fetch_log_paths() {
    # Populate a global associative array LOGS[job_id]=$'stdout_path\tstderr_path'
    declare -gA LOGS
    LOGS=()

    if ! command -v jq &>/dev/null; then
        echo -e "${YELLOW}Warning: jq not found; log file paths will not be shown.${RESET}" >&2
        return
    fi

    local json
    if ! json=$(squeue --json -A "$ACCOUNT" $STATE_ARG 2>&1); then
        echo -e "${YELLOW}Warning: could not fetch JSON job info; log paths omitted.${RESET}" >&2
        return
    fi

    while IFS=$'\t' read -r job_id stdout stderr; do
        [[ -z "$job_id" ]] && continue
        LOGS["$job_id"]="${stdout}"$'\t'"${stderr}"
    done < <(echo "$json" | jq -r '
        .jobs[] |
        (
            (.stdout_expanded // .standard_output // "") + "\t" +
            (.stderr_expanded // .standard_error // "")
        ) as $logs |
        [(.job_id | tostring), $logs] |
        @tsv
    ')
}

print_job_logs() {
    local job_id="$1"
    local base_id
    base_id=$(echo "$job_id" | sed -E 's/^([0-9]+).*/\1/')

    local logs="${LOGS[$job_id]:-${LOGS[$base_id]:-}}"
    [[ -z "$logs" ]] && return

    local stdout stderr
    IFS=$'\t' read -r stdout stderr <<< "$logs"
    [[ -z "$stdout" ]] && stdout="-"
    [[ -z "$stderr" ]] && stderr="-"

    echo -e "  ${DIM}→ stdout:${RESET} ${stdout}   ${DIM}stderr:${RESET} ${stderr}"
}

print_summary() {
    local output="$1"
    if [[ -z "$output" ]]; then
        return
    fi

    # Skip header line when counting
    local body
    body=$(echo "$output" | tail -n +2)

    local total
    total=$(echo "$body" | wc -l)

    echo
    echo -e "${BOLD}Summary:${RESET}"
    echo -e "  Total jobs shown: ${BOLD}${total}${RESET}"

    # Count by state (the 5th whitespace-separated field in our format)
    echo "$body" | awk '
        { state[$5]++ }
        END {
            for (s in state) {
                printf "  %-12s %3d\n", s ":", state[s]
            }
        }
    ' | sort -t: -k2 -n -r
}

main() {
    if ! command -v squeue &>/dev/null; then
        echo -e "${RED}Error: squeue not found. Load the Slurm environment first.${RESET}" >&2
        exit 1
    fi

    print_header
    fetch_log_paths

    local output
    if ! output=$(squeue -A "$ACCOUNT" $STATE_ARG -o "$SQUEUE_FORMAT" 2>&1); then
        echo -e "${RED}Error running squeue:${RESET} $output" >&2
        exit 1
    fi

    if [[ -z "$(echo "$output" | tail -n +2)" ]]; then
        echo -e "${YELLOW}No ${TITLE,,} found for account ${ACCOUNT}.${RESET}"
        exit 0
    fi

    # Print with colorized header line
    header=$(echo "$output" | head -n 1)
    body=$(echo "$output" | tail -n +2)

    echo -e "${BOLD}${MAGENTA}${header}${RESET}"

    local line job_id
    while IFS= read -r line; do
        echo "$line"
        job_id=$(echo "$line" | awk '{print $1}')
        print_job_logs "$job_id"
    done <<< "$body"

    print_summary "$output"
}

main "$@"
