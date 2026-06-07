#!/bin/bash
# =============================================================================
# restic-maintenance.sh — Apply retention policy, then prune the repository.
#
# Run on a SLOW cadence (daily or weekly), NEVER on every backup. `prune` is
# by far the most API-expensive restic operation: it lists and rewrites pack
# and index files. Running it hourly will burn through the transaction caps on
# metered object stores (Backblaze B2 free tier = 2,500 Class B calls/day).
#
# Scoped by tag + host so it only affects this machine's automated backups and
# leaves any manual/other snapshots in the same repo untouched.
#
# Credentials are read from /etc/restic/env (same file as restic-backup.sh).
# =============================================================================
set -uo pipefail

# ---- Configuration ----------------------------------------------------------
TAG="auto"
HOST="$(hostname -s)"
KEEP_HOURLY=24
KEEP_DAILY=30
KEEP_MONTHLY=12
# -----------------------------------------------------------------------------

set -a; source /etc/restic/env; set +a

restic forget --verbose=1 --tag "${TAG}" --host "${HOST}" \
    --keep-hourly  "${KEEP_HOURLY}" \
    --keep-daily   "${KEEP_DAILY}" \
    --keep-monthly "${KEEP_MONTHLY}" \
    --prune
exit $?
