# ZFS 3-2-1 Backup Stack

A self-hosted, fully auditable 3-2-1 backup system for ZFS hosts, built from
small composable pieces rather than a monolithic tool. Every component is a
plain shell script or systemd unit you can read in a minute and modify without
fighting an abstraction layer.

The design centers on two patterns most homegrown setups get wrong:

1. **Backup and prune are separate jobs on separate schedules.** Pruning is the
   single most expensive operation against a remote repository. Coupling it to
   every backup is what blows through transaction caps on metered object stores.
2. **Off-host copies are encrypted such that the destination never holds the
   key.** Local snapshots replicate *raw* (ciphertext) to the on-site target,
   and the offsite repository is encrypted client-side. A compromise of either
   destination exposes nothing.

---

## The 3-2-1 model, concretely

```
                      ┌──────────────────────────────────────────────┐
                      │  SOURCE HOST (ZFS pool: tank/data)            │
                      │                                              │
   live data  ───►    │  [1] Sanoid                                  │
   (copy #1)          │      hourly local ZFS snapshots              │
                      │        │                                     │
                      │        ├──► [2] Syncoid ──(raw/encrypted)────┼──► ON-SITE NAS
                      │        │       hourly replication            │    (copy #2, ciphertext,
                      │        │                                     │     holds no key)
                      │        └──► [3] Restic ──(client-encrypted)──┼──► OFFSITE OBJECT STORE
                      │                hourly backup, daily prune    │    (copy #3, e.g. Backblaze B2)
                      └──────────────────────────────────────────────┘

   3 copies:   live data + NAS replica + offsite repo
   2 media:    local disks (source + NAS) and remote object storage
   1 offsite:  the object-store repository
```

| Tier | Tool   | Cadence            | Destination            | Protects against         |
|------|--------|--------------------|------------------------|--------------------------|
| 1    | Sanoid | hourly (15-min checks) | local pool         | fat-finger, bad upgrade  |
| 2    | Syncoid| hourly             | on-site NAS (raw send) | source disk/host failure |
| 3    | Restic | hourly + daily prune | offsite object store | fire, theft, site loss   |

---

## Contents

```
backup/
├── README.md
├── sanoid/
│   └── sanoid.conf.example            # Tier 1 — local snapshot policy
├── syncoid/
│   ├── syncoid-replicate.service      # Tier 2 — raw replication to NAS
│   └── syncoid-replicate.timer
├── restic/
│   ├── restic-backup.sh               # Tier 3 — hourly backup (no prune)
│   ├── restic-maintenance.sh          #          daily forget + prune
│   ├── restic-backup.service
│   ├── restic-backup.timer
│   ├── restic-maintenance.service
│   ├── restic-maintenance.timer
│   └── env.example                    #          credentials template
└── nas-prune/
    └── prune-replicated-backups.sh    # retention on a NAS that can't run sanoid
```

Every placeholder uses the same conventions: source dataset `tank/data`, source
hostname `myhost`, NAS dataset `backup/backups/myhost/data`. Search-and-replace
those to match your environment.

---

## Prerequisites

- ZFS on the source host (`zfsutils-linux` or equivalent).
- [sanoid/syncoid](https://github.com/jimsalterjrs/sanoid) installed on the
  source host (`apt install sanoid` on Debian/Ubuntu, or from the project repo).
- [restic](https://restic.net/) 0.16+ on the source host.
- A remote target for replication (any host that can `zfs receive`) and an
  object-storage bucket for restic (Backblaze B2, S3, etc.).
- SSH key auth from the source host to the NAS, with the NAS user permitted to
  run `zfs receive` (and `zfs destroy`/`zfs rollback` for the prune script).

---

## Tier 1 — Local snapshots (Sanoid)

```bash
sudo apt install sanoid
sudo install -m 644 sanoid/sanoid.conf.example /etc/sanoid/sanoid.conf
sudo "${EDITOR:-vi}" /etc/sanoid/sanoid.conf      # set your dataset + excludes
sudo systemctl enable --now sanoid.timer          # ships with the sanoid package
```

The `production` template keeps 36 hourly / 30 daily / 12 monthly snapshots.
High-churn or reproducible children (search indexes, scratch caches) get the
`ignore` template so they are neither snapshotted nor pruned.

Verify:

```bash
zfs list -t snapshot -o name,creation -s creation -r tank/data | tail
```

---

## Tier 2 — On-site replication (Syncoid)

Replicates the local snapshots to a second machine. The `--sendoptions=w`
("raw") flag means encrypted source datasets are sent as ciphertext: the NAS
stores your data but **cannot read it** and never needs your encryption key.

```bash
sudo install -m 644 syncoid/syncoid-replicate.service /etc/systemd/system/
sudo install -m 644 syncoid/syncoid-replicate.timer   /etc/systemd/system/
sudo "${EDITOR:-vi}" /etc/systemd/system/syncoid-replicate.service   # fix placeholders
sudo systemctl daemon-reload
sudo systemctl enable --now syncoid-replicate.timer
```

Edit the `ExecStart` line to set your source dataset, NAS user/host, destination
dataset, and the `--exclude` regex. **Remove `--sendoptions=w` if your source
datasets are not encrypted** (raw send of an unencrypted dataset is fine, but
the flag is only meaningful for encrypted ones).

### Pruning the NAS copy

Syncoid replicates sanoid's snapshots but does not prune them on the target, so
they pile up. If the NAS runs sanoid too, point it at the received datasets with
`autosnap = no` and let it prune. If the NAS *can't* run sanoid (e.g. TrueNAS,
where package installs are unsupported), use the included script instead:

```bash
# On the NAS — dry run first, always:
sudo DRY_RUN=1 DATASET=backup/backups/myhost/data ./nas-prune/prune-replicated-backups.sh

# When the candidate list looks right, schedule it (cron, or TrueNAS Cron Job):
#   0 4 * * *  DATASET=backup/backups/myhost/data /path/to/prune-replicated-backups.sh
```

It keeps the N newest of each period **per dataset** and recognizes sanoid's
`autosnap_YYYY-MM-DD_HH:MM:SS_<period>` naming. Syncoid's own `syncoid_*` sync
bookmarks are never touched — syncoid manages those itself.

---

## Tier 3 — Offsite (Restic)

```bash
# Credentials
sudo mkdir -p /etc/restic
sudo install -m 600 restic/env.example /etc/restic/env
sudo "${EDITOR:-vi}" /etc/restic/env                 # repo + backend creds
openssl rand -base64 32 | sudo tee /etc/restic/password >/dev/null
sudo chmod 600 /etc/restic/password
sudo mkdir -p /var/cache/restic && sudo chmod 700 /var/cache/restic

# Initialize the repository (once)
sudo bash -c 'set -a; source /etc/restic/env; set +a; restic init'

# Scripts
sudo install -m 755 restic/restic-backup.sh      /usr/local/sbin/
sudo install -m 755 restic/restic-maintenance.sh /usr/local/sbin/
sudo "${EDITOR:-vi}" /usr/local/sbin/restic-backup.sh        # set ROOT + excludes

# Units
sudo install -m 644 restic/restic-backup.service      /etc/systemd/system/
sudo install -m 644 restic/restic-backup.timer        /etc/systemd/system/
sudo install -m 644 restic/restic-maintenance.service /etc/systemd/system/
sudo install -m 644 restic/restic-maintenance.timer   /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now restic-backup.timer restic-maintenance.timer
```

### Why backup and prune are separate

This is the core lesson of the repo. Restic's `prune` lists and rewrites pack
and index files across the whole repository — it is dramatically more
API-intensive than a `backup`, which mostly just uploads new blobs.

Backblaze B2's free tier allows 2,500 Class B (list/metadata) transactions per
day. Rough per-run cost:

| Operation              | Class B calls (approx) |
|------------------------|------------------------|
| `restic backup` (incremental) | tens             |
| `restic forget`        | tens                   |
| `restic prune`         | **hundreds**           |

Running `backup + forget + prune` every hour means ~24 prunes/day, which alone
can exceed the cap. Splitting them — `backup` hourly, `forget --prune` once
daily — keeps you comfortably under it while preserving a tight (hourly) backup
window. The two timers here implement exactly that split.

> **Tip:** set `RESTIC_CACHE_DIR` (done in `env.example`) so restic's local
> cache persists across runs. Under systemd there's no stable `$HOME`, and
> without an explicit cache dir restic may rebuild its cache from the remote on
> every run, wasting transactions.

---

## Restore

**From a local snapshot** (fastest; undo a bad change):

```bash
zfs rollback tank/data/<child>@autosnap_<...>        # destructive, reverts dataset
# or, non-destructively, mount a clone:
zfs clone tank/data/<child>@autosnap_<...> tank/restore-tmp
```

**From the NAS replica** (source disk/host loss). The replica is ciphertext, so
you load your key after pulling it back:

```bash
# Pull the dataset back to a rebuilt source host:
syncoid --sendoptions=w BACKUP_USER@NAS:backup/backups/myhost/data/<child> tank/data/<child>
zfs load-key tank/data            # supply your key/passphrase
zfs mount -a
```

**From the offsite repo** (site loss). On any machine with the repo password and
backend credentials:

```bash
set -a; source /etc/restic/env; set +a
restic snapshots                                     # find the snapshot ID
restic restore <snapshot-id> --target /restore
```

---

## ⚠️ Back up your keys separately

Raw replication and client-side encryption are what make the off-host copies
safe to store on untrusted infrastructure — but they also mean **the copies are
worthless without the keys.** Store, completely separate from the source host
and from the backup destinations:

- the **ZFS encryption key/passphrase** for the source datasets, and
- the **restic repository password** plus the backend credentials.

A printed copy in a safe and/or an encrypted (e.g. LUKS) flash drive kept
off-site is the classic approach. If the source host dies and these are gone,
every backup you have is unrecoverable ciphertext.

**Never commit `/etc/restic/env`, `/etc/restic/password`, or any key material to
this (or any) repository.**

---

## Customization reference

| Placeholder                        | Meaning                              | Where |
|------------------------------------|--------------------------------------|-------|
| `tank/data`                        | source parent dataset                | sanoid.conf, restic-backup.sh, syncoid unit |
| `myhost`                           | source hostname                      | syncoid unit, nas-prune DATASET |
| `backup/backups/myhost/data`       | destination dataset on NAS           | syncoid unit, nas-prune script |
| `BACKUP_USER@BACKUP_HOST`          | SSH user/host of the NAS             | syncoid unit |
| `b2:your-bucket-name:hostname`     | restic repository URL                | env.example |
| `EXCLUDE_DATASETS` / `--exclude`   | high-churn datasets to skip          | restic-backup.sh, syncoid unit, sanoid.conf |
| `KEEP_*`                           | retention counts                     | restic-maintenance.sh, nas-prune script |

---

## License

See the repository root `LICENSE`. The scripts are provided as-is; test with
`DRY_RUN=1` (where supported) and against non-production data before relying on
them. You are responsible for verifying your own restores — an untested backup
is not a backup.
