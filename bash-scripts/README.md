# bash-scripts

BASH scripts for administering an Ubuntu Server, organized under the
`/var/scripts` layout used by the [Ubuntu Server 24.04 LTS guide](https://codex.alcott.dev).

## Attribution

Forked from **LHammonds' [`ubuntu-bash`](https://github.com/LHammonds/ubuntu-bash)**,
licensed **GPL-3.0**. Original author: **LHammonds** — full credit for the
foundation. This fork is maintained by **OzarkMountainPirate** as part of the
`utilities` repo, adapted for Ubuntu Server 24.04 LTS.

Each script preserves its original header and change log; the fork point and any
changes from it forward are recorded in each script's header (`OMP` entries) and
in git history. Distributed under **GPL-3.0**, the same license as upstream — see
[`LICENSE`](LICENSE).

## Layout

```
common/   Shared config imported by the scripts
  standard.conf     <- localize this (Company, MyDomain, emails, paths)
data/     Data files
  crontab.root      <- the root cron schedule
prod/     Production scripts
  setup-folders.sh  servicestop.sh  servicestart.sh  servicerestart.sh
  reboot.sh  shutdown.sh  apt-upgrade.sh  reboot-check.sh
  check-storage.sh  opm.sh  en-firewall.sh  togglemount.sh  back-parts.sh
```

## Install

On a fresh server, `prod/setup-folders.sh` (run as root) creates
`/var/scripts/{common,data,prod,test}`. Then copy this tree into place. The
guide's *Scripting & Automation* chapter covers install and scheduling in full.

## Localize before use

Edit `common/standard.conf` — `Company`, `MyDomain`, `AdminEmail`,
`ReportEmail`, `BackupDir`, `OffsiteDir`, `ArchiveMethod` — to match your
environment. Several `prod/` scripts (`servicestop.sh`, `servicestart.sh`,
`en-firewall.sh`) are intentional stubs you fill in per server.
