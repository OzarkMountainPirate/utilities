# utilities

A small collection of self-hosting and Linux system-administration utilities —
backup automation, audio routing, and media tooling. Each lives in its own
directory with its own README; everything is plain shell or Python, kept
readable and easy to adapt.

Most of these were built for a privacy-respecting, self-hosted homelab and then
generalized so they're useful on any modern Linux box.

## Contents

| Directory | Description |
|-----------|-------------|
| [`backup`](backup/) | A 3-2-1 backup stack for ZFS hosts: Sanoid (local snapshots) → Syncoid (raw-encrypted replication to an on-site NAS) → Restic (client-encrypted offsite repo, e.g. Backblaze B2). Includes systemd timers and a NAS-side retention pruner for replication targets that can't run Sanoid. |
| [`audio-linux-linein-generic`](audio-linux-linein-generic/) | Route a USB audio device's line-in (e.g. a console over 3.5mm) to its own output via a persistent PipeWire loopback — hardware-agnostic, survives reboots and replug. Tested on Ubuntu 24.04 + PipeWire. |
| [`audio-linux-linein-sbx3`](audio-linux-linein-sbx3/) | The device-specific version of the above for the Creative Sound Blaster X3, mixing Nintendo Switch line-in with PC audio through the same DAC. |
| [`yt-dlp`](yt-dlp/) | Configuration and helper scripting for [yt-dlp](https://github.com/yt-dlp/yt-dlp) media downloading. |

## Conventions

- **Shell + Python, minimal dependencies.** Read a script before you run it.
- Each utility is **self-contained** in its own directory with its own README and setup steps.
- Scripts that touch real data or system state favor explicit configuration and, where relevant, dry-run modes — check the per-directory README.

## License

Licensed under the [GNU General Public License v3.0](LICENSE).

## Disclaimer

These tools operate on real systems — filesystems, audio stacks, backups. They
work in the environments they were built for, but setups differ. Read the
relevant README, understand what a script does, and test against non-critical
data before relying on it. Provided as-is, with no warranty; see the license.
