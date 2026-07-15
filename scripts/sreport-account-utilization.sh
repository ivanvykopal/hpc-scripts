#!/usr/bin/env bash
# Report per-user CPU- and GPU-hour utilization for a given account.
# Uses the custom Slurm configuration in .slurm/custom_slurm.conf and pivots
# the sreport output so each user (plus an account total) appears on one row.
#
# Usage: ./scripts/sreport-account-utilization.sh ACCOUNT

set -euo pipefail

print_usage() {
    cat <<EOF
Usage: $0 ACCOUNT

Report per-user CPU- and GPU-hour utilization for a given account.
Uses the custom Slurm configuration in .slurm/custom_slurm.conf and pivots
the sreport output so each user (plus an account total) appears on one row.

Arguments:
  ACCOUNT  Slurm account name

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

PY_PIVOT=$(cat <<'PY'
import csv
import sys
from collections import defaultdict

reader = csv.reader(sys.stdin, delimiter='|')

# Locate the header line.
header = None
for row in reader:
    if row and row[0].strip().lower() == 'cluster':
        header = [h.strip().lower() for h in row]
        break

if header is None:
    print('No sreport data found.', file=sys.stderr)
    sys.exit(1)

col = {name: idx for idx, name in enumerate(header)}

records = defaultdict(lambda: {'cluster': '', 'account': '', 'proper': '', 'cpu': 0, 'gpu': 0})
for row in reader:
    if not row or not row[0].strip():
        continue
    login = row[col['login']].strip()
    cluster = row[col['cluster']].strip()
    account = row[col['account']].strip()
    proper = row[col['proper name']].strip()
    tres = row[col['tres name']].strip()
    try:
        used = int(row[col['used']].strip())
    except ValueError:
        continue

    key = (cluster, account, login)
    rec = records[key]
    rec['cluster'] = cluster
    rec['account'] = account
    rec['proper'] = proper or '(account total)'
    if tres == 'cpu':
        rec['cpu'] = used
    elif tres == 'gres/gpu':
        rec['gpu'] = used

# Sort: account totals first, then by login.
def sort_key(item):
    (cluster, account, login), rec = item
    return (0 if not login else 1, login.lower(), cluster, account)

sorted_records = sorted(records.items(), key=sort_key)

print(f"{'Cluster':<18} {'Account':<14} {'Login':<12} {'Name':<20} {'CPU hrs':>10} {'GPU hrs':>10}")
print('-' * 90)
for (cluster, account, login), rec in sorted_records:
    display_login = login if login else '(total)'
    print(
        f"{cluster:<18} {account:<14} {display_login:<12} "
        f"{rec['proper']:<20} {rec['cpu']:>10} {rec['gpu']:>10}"
    )
PY
)

SLURM_CONF=./.slurm/custom_slurm.conf \
    sreport cluster AccountUtilizationByUser \
        Start=2024-01-01 End=now -t Hour \
        account="${ACCOUNT}" -T cpu,gres/gpu -P |
    python3 -c "$PY_PIVOT"
