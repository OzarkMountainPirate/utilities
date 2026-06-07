#!/bin/bash
# =============================================================================
# prune-replicated-backups.sh — Retention pruning on a replication TARGET that
# cannot run sanoid (e.g. TrueNAS, where adding packages is unsupported).
#
# Syncoid happily replicates sanoid's snapshots to the target, but nothing on
# the target prunes them — so they accumulate forever. This script applies a
# sanoid-style per-period retention to the replicated snapshots.
#
# It recognizes sanoid's snapshot naming:
#       <dataset>@autosnap_YYYY-MM-DD_HH:MM:SS_<period>
#   where <period> is one of: hourly | daily | monthly
# and keeps the N most recent of each period PER DATASET, destroying older ones.
#
# Snapshots NOT matching that pattern (e.g. syncoid's own `syncoid_*` sync
# bookmarks) are never touched — syncoid manages those itself.
#
# Run from cron on the target. Defaults are overridable via environment vars,
# which makes it safe to dry-run first:
#       DRY_RUN=1 ./prune-replicated-backups.sh
# =============================================================================
set -uo pipefail

# ---- Configuration (override via environment) -------------------------------
DATASET="${DATASET:-backup/backups/myhost/data}"   # parent dataset (recursive)
KEEP_HOURLY="${KEEP_HOURLY:-48}"
KEEP_DAILY="${KEEP_DAILY:-60}"
KEEP_MONTHLY="${KEEP_MONTHLY:-24}"
DRY_RUN="${DRY_RUN:-0}"     # 1 = print what would be destroyed, change nothing
# -----------------------------------------------------------------------------

destroy_snap() {
    local snap="$1"
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[dry-run] would destroy: $snap"
    else
        if zfs destroy "$snap"; then
            echo "destroyed: $snap"
        else
            echo "ERROR destroying: $snap" >&2
        fi
    fi
}

# Keep the $keep newest snapshots of $period on dataset $ds; destroy the rest.
prune_period() {
    local ds="$1" period="$2" keep="$3"
    zfs list -H -t snapshot -o name -s creation -r -d 1 "$ds" 2>/dev/null \
        | grep -E "@autosnap_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}_${period}\$" \
        | tac \
        | awk -v k="$keep" 'NR > k' \
        | while IFS= read -r snap; do
            destroy_snap "$snap"
        done
}

# Walk the parent dataset and every child, applying retention to each.
zfs list -H -o name -r "$DATASET" 2>/dev/null | while IFS= read -r ds; do
    prune_period "$ds" hourly  "$KEEP_HOURLY"
    prune_period "$ds" daily   "$KEEP_DAILY"
    prune_period "$ds" monthly "$KEEP_MONTHLY"
done
