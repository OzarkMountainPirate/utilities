#!/bin/bash
# =============================================================================
# restic-backup.sh — Offsite backup of ZFS datasets to a restic repository.
#
# Takes an atomic, recursive ZFS snapshot and backs up each child dataset's
# snapshot view via restic. Reading from a snapshot guarantees a consistent,
# point-in-time copy across every dataset even while services keep writing.
#
# Retention/pruning is intentionally NOT performed here — that lives in
# restic-maintenance.sh and runs on a slower cadence. See the README for why
# this split matters (it keeps metered object stores like Backblaze B2 under
# their daily transaction caps).
#
# Credentials and repository location are read from /etc/restic/env. See
# env.example for the expected variables.
# =============================================================================
set -uo pipefail

# ---- Configuration ----------------------------------------------------------
ROOT="tank/data"                  # Parent ZFS dataset to back up (recursive)
TAG="auto"                        # restic tag applied to these snapshots
HOST="$(hostname -s)"             # restic --host value (groups snapshots per machine)

# Datasets to skip: high-churn caches, scratch space, search indexes, or
# anything cheaply reproducible. Use full dataset paths. Empty array = back
# up everything under $ROOT.
EXCLUDE_DATASETS=(
    # "${ROOT}/elasticsearch/data"
    # "${ROOT}/some-cache"
)
# -----------------------------------------------------------------------------

SNAP="restic-$(date -u +%Y%m%dT%H%M%SZ)"

# Always destroy the ephemeral snapshot on exit — success, failure, or signal.
cleanup() { zfs destroy -r "${ROOT}@${SNAP}" 2>/dev/null || true; }
trap cleanup EXIT

# Load restic credentials + repo location (sourced as environment variables).
set -a; source /etc/restic/env; set +a

# Atomic recursive snapshot across all children.
zfs snapshot -r "${ROOT}@${SNAP}"

# Build the list of snapshot paths to back up, skipping excluded datasets.
declare -a PATHS
while IFS= read -r ds; do
    skip=0
    for ex in "${EXCLUDE_DATASETS[@]}"; do
        [[ "$ds" == "$ex" ]] && skip=1 && break
    done
    [[ $skip -eq 1 ]] && continue
    mp=$(zfs get -H -o value mountpoint "$ds")
    snap_path="${mp}/.zfs/snapshot/${SNAP}"
    [[ -d "$snap_path" ]] && PATHS+=("$snap_path")
done < <(zfs list -H -o name -r "${ROOT}")

# Run the backup. Increase --verbose for more detail during diagnostics.
restic backup --verbose=1 --tag "${TAG}" --host "${HOST}" "${PATHS[@]}"
exit $?
