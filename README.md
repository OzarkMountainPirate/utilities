# utilities

A small collection of self-hosting and Linux system-administration utilities —
backup automation, server administration, game-server management, audio routing,
and media tooling. Each lives in its own directory with its own README;
everything is plain shell or Python, kept readable and easy to adapt.

Most of these were built for a privacy-respecting, self-hosted homelab and then
generalized so they're useful on any modern Linux box.

## Contents

| Directory | Description |
|-----------|-------------|
| [`backup`](backup/) | A 3-2-1 backup stack for ZFS hosts: Sanoid (local snapshots) → Syncoid (raw-encrypted replication to an on-site NAS) → Restic (client-encrypted offsite repo, e.g. Backblaze B2). Includes systemd timers and a NAS-side retention pruner for replication targets that can't run Sanoid. |
| [`bash-scripts/ark-ase`](bash-scripts/ark-ase/) | `gamectl` — a single-command toolkit for **ARK: Survival Evolved** dedicated servers on Ubuntu Server 24.04: install, multi-map clustering, mods via `-automanagedmods`, save-safe template updates, backups, and RCON. Shipped as annotated tags so downstream automation can pin a version plus a sha256 and verify it at deploy time. |
| [`bash-scripts/servers`](bash-scripts/servers/) | Ubuntu Server administration scripts — service control, LVM storage checks, scheduled patching and maintenance, reboot handling, and backups — organized under a common `/var/scripts` layout (`common`/`data`/`prod`). A GPL-3.0 fork of LHammonds' `ubuntu-bash`, adapted for 24.04; see the folder README for attribution and localization steps. |
| [`audio-linux-linein-generic`](audio-linux-linein-generic/) | Route a USB audio device's line-in (e.g. a console over 3.5mm) to its own output via a persistent PipeWire loopback — hardware-agnostic, survives reboots and replug. Tested on Ubuntu 24.04 + PipeWire. |
| [`audio-linux-linein-sbx3`](audio-linux-linein-sbx3/) | The device-specific version of the above for the Creative Sound Blaster X3, mixing Nintendo Switch line-in with PC audio through the same DAC. |
| [`yt-dlp`](yt-dlp/) | Two Python wrappers around [yt-dlp](https://github.com/yt-dlp/yt-dlp) — audio pulled to high-quality MP3, and best video+audio merged to MKV — with sensible defaults baked in and optional `cookies.txt` support. |

## Conventions

- **Shell + Python, minimal dependencies.** Read a script before you run it.
- Each utility is **self-contained** in its own directory with its own README and setup steps.
- Scripts that touch real data or system state favor explicit configuration and, where relevant, dry-run modes — check the per-directory README.
- `gamectl` is linted with [ShellCheck](https://www.shellcheck.net/) in CI on every push and pull request; the intentional exceptions are documented in [`.shellcheckrc`](.shellcheckrc).

## Related

- [`ark-fleet`](https://github.com/OzarkMountainPirate/ark-fleet) — Ansible automation that deploys and pins `gamectl` across an ARK host fleet.

## License

Licensed under the [GNU General Public License v3.0](LICENSE).

## Disclaimer

These tools operate on real systems — filesystems, audio stacks, backups. They
work in the environments they were built for, but setups differ. Read the
relevant README, understand what a script does, and test against non-critical
data before relying on it. Provided as-is, with no warranty; see the license.
