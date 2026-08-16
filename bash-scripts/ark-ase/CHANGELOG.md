# gamectl changelog

Releases are annotated git tags (`vX.Y.Z`) in this repository. Downstream
automation pins a tag plus a `sha256` of the script and verifies it at deploy
time, so tags are immutable — a fix ships as a new tag and a pin bump, never as
a moved tag. The deployed version is auditable at runtime with
`gamectl version`.

Tags through `v1.5` were two-part (`v1.1`, `v1.2`, ...); `v1.5.1` onward are
three-part. 1.0 predates tagging and has no tag. Existing tags stay as they
are — the immutability rule applies to them too.

`gamectl` and `gamectl.conf` ship together whenever the conf contract changes
(a new variable, a changed meaning). Script-only releases leave the conf alone.

---

## 1.6.4 — 2026-08-16

- **MIT attribution for ported code.** `extract_mod()` — the UE `.z` chunk
  inflation and `<id>.mod` metadata handling — is ported from ark-server-tools
  (arkmanager), which is MIT-licensed. An inline comment named the source, but
  the copyright and permission notice appeared nowhere in the script or the
  repository. MIT asks that the notice accompany substantial portions of the
  work, and this script is distributed as a single file — downstream automation
  fetches the raw script, not the repo — so the notice has to live in the
  header to travel with it.

  No functional change; retagged so downstream pins verify against the new
  bytes. Consumers pinning `v1.6.3` keep working on the old tag until they
  choose to bump.

## 1.6.3 — 2026-08-06

- Added copyright and GPL-3.0-or-later notice to the script header. No
  functional change; retagged so downstream pins verify against the new bytes.

## 1.6.2 — 2026-08-02

- **`rcon` accepts `all`**, like `stop`/`start`/`sync`. Fleet-wide commands no
  longer require knowing which map runs on which host:
  `ansible ark_fleet -a 'gamectl rcon all "DestroyWildDinos"'`.
  A failing instance is reported by name and does not abort the others; the
  exit status reflects whether every instance succeeded.

## 1.6.1 — 2026-08-02

- **Restore the preamble deleted in 1.6.0.** Truncating the header removed
  `set -euo pipefail`, the `gamectl.conf` source, and the `ARK_ROOT`-derived
  path variables along with the changelog comments. `INSTANCES` was therefore
  always empty: `status` printed headers with no rows, and `start`/`stop`
  iterated over nothing. `bash -n` and shellcheck passed throughout — the file
  was valid shell that did nothing.

  *Lesson: deleting a range between two string anchors requires printing what
  falls between them first. A syntax check cannot tell you that code is
  missing.*

## 1.6.0 — 2026-07-31

First public release. No functional change.

- Change history moved out of the script and conf headers into this file, so
  the headers stay a fixed size as the tool ages.

## 1.5.5 — 2026-07-30

- **`mods`: extract from `WindowsNoEditor`, not `LinuxNoEditor`.**
  ASE dedicated servers — Linux included — load Windows-cooked packages. The
  `LinuxNoEditor` tree targets the long-abandoned Linux *client*. Feeding it to
  the server produced `Bad name index N/120` in `LinkerLoad` and a SEGV ~25s
  into startup, identically for **every** mod, with an empty `ShooterGame.log`.
  `ark-server-tools` hardcodes Windows for this reason (`mod_branch` defaults
  to `Windows`); selection is now by `mod.info` presence, matching it.
  New `MOD_BRANCH` conf variable overrides it. Existing installs must be
  re-extracted: `gamectl mods force`.

  *Lesson: the deviation from the reference implementation was the bug. The
  parts ported verbatim were fine; the one place substituted with local
  reasoning ("the servers are Linux, so prefer the Linux tree") is what broke.*

## 1.5.4 — 2026-07-29

- **`mods`: prune undeclared workshop mods.** Declared state is truth. Mods
  removed from `MODS` are now deleted from the template and from stopped
  instances. Previously they accumulated forever, and stale content whose
  assets no longer resolve crashes the server at load. Stock content
  (`111111111`) and the official map DLC (non-numeric directory names) are
  structurally exempt; the prune refuses to run on any path that is not a
  `ShooterGame/Content/Mods` directory.
- **`status`**: fixed `STATE` printing twice for non-active units.
  `systemctl is-active` prints the state *and* exits nonzero, so the
  `|| echo inactive` fallback was appending a second word rather than
  replacing it.

## 1.5.3 — 2026-07-29

- **`mods`: an empty `MODS` list now clears `ActiveMods`** instead of returning
  early. 1.5.2 silently ignored mod *removals* — the config said one thing and
  the instances loaded another.
- **`sync`: returns nonzero when it skips a running instance.** It has always
  refused to rsync over a live server (correctly), but it exited 0, so callers
  could not distinguish "rolled out" from "did nothing".
- **`status`: reports restart count and last-start time.** A crash-looping unit
  reports `active` between deaths; restart count is what exposes it.

## 1.5.2 — 2026-07-26

- **`mods`: flock guard.** Concurrent runs — typically an orphaned async job
  surviving a Ctrl-C — fought over the same directories and shredded each
  other's temp files mid-extract.

## 1.5.1 — 2026-07-26

- **Atomic, size-verified extraction.** Each inflated file is written to a temp
  path, verified against the Workshop's `.uncompressed_size` sidecar (which has
  CRLF line endings), retried once, and only then moved into place. A mod with
  any failing file is reported and **not** installed.
  1.5 swallowed mid-file inflate failures and kept the truncated output, which
  produced `Bad name index` crashes from thousands of half-written assets.

## 1.5 — 2026-07-26

- **`mods` pre-installs Workshop content**: steamcmd `workshop_download_item`,
  `.z` chunk inflation, and `.mod` metadata generation — the binary format
  handling ported from `ark-server-tools`.
- **`-automanagedmods` disabled by default.** The engine's own mod management
  spawns a child process and waits on it with arguments modern glibc rejects
  (`waitid`, `EINVAL`), hard-crashing with SEGV under a second, before any
  content downloads. `ARK_AUTOMANAGED_MODS` re-enables it.
- Requires `perl` with `Compress::Raw::Zlib`.

## 1.4 — 2026-07-25

- **`ARK_EXTRA_QUERY`**: extra `?Key=Value` launch options appended to the
  server URL. Launch options override `GameUserSettings.ini`, so settings set
  this way survive ARK rewriting that file on shutdown.

## 1.3 — 2026-07-13

- **Fixed `ARK_BRANCH`.** The branch flag must be passed as separate `argv`
  elements (`+app_update 376030 -beta preaquatica validate`). Quoting it into
  one argument is silently ignored: steamcmd parses the leading app id,
  discards the rest, and updates the live branch while reporting success.

## 1.2 — 2026-07-12

- **`ARK_BRANCH`**: pin server files to a Steam beta branch (e.g.
  `preaquatica`). Client and server major versions must match or servers are
  silently hidden from the in-game browser.

## 1.1 — 2026-07-12

- **`STEAM_RETRIES`**: steamcmd retries on failure, resuming between attempts.
  Large downloads fail often enough that a single attempt is not a strategy.
- **`version` subcommand**: makes the deployed version auditable at runtime.

## 1.0 — 2026-07-04

Initial release. Install, run, cluster, back up, and update ARK: Survival
Evolved dedicated server instances on Linux. Design inspired by LHammonds'
ark-bash toolkit.
