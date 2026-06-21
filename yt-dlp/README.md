# yt-dlp helpers

Two small Python wrappers around [yt-dlp](https://github.com/yt-dlp/yt-dlp) that encode sensible defaults so you don't have to remember a long flag string every time:

- **`ytAudioExtract.py`** — pull the audio from a video and save it as a high-quality MP3.
- **`ytVideo.py`** — download the best available video+audio and merge it into a single MKV file.

Both accept a URL on the command line or prompt for one interactively, and both will automatically use a `cookies.txt` file if you place one next to the script (needed for age-restricted, members-only, or login-gated content, and helpful when YouTube throws bot checks).

Tested with yt-dlp on Python 3.9+ on both Linux and Windows. Both scripts run as-is on either platform — `ytVideo.py` locates your Node.js install automatically.

---

## What each script does

### `ytAudioExtract.py`

Runs yt-dlp with audio extraction enabled, converts the result to MP3 at the highest quality setting, and names the file after the video title. This script is fully cross-platform with no edits required.

Equivalent yt-dlp command:

```
yt-dlp -x --audio-format=mp3 --audio-quality=0 --output="%(title)s.%(ext)s" <URL>
```

### `ytVideo.py`

Downloads the best video and best audio streams, merges them into an MKV container, and retries up to 5 times on network hiccups. It automatically detects your Node.js runtime (used by yt-dlp to help with YouTube extraction) wherever it's installed, so it works on Linux, macOS, and Windows without edits.

Equivalent yt-dlp command (the `node:` path is filled in automatically based on where Node is found):

```
yt-dlp --js-runtimes node:<auto-detected> --extractor-args youtube:player_client=android \
       -f bestvideo+bestaudio/best --merge-output-format mkv \
       --output="%(title)s.%(ext)s" --retries 5 <URL>
```

---

## Prerequisites

You need three things on your system: **Python**, **yt-dlp**, and **FFmpeg** (yt-dlp uses FFmpeg under the hood to convert audio and merge video+audio streams). `ytVideo.py` additionally expects **Node.js** to be available as a JavaScript runtime for yt-dlp.

Install instructions per platform are below.

---

## Linux

### 1. Install dependencies

```bash
# Debian / Ubuntu / Mint
sudo apt update
sudo apt install -y python3 ffmpeg nodejs

# Fedora
sudo dnf install -y python3 ffmpeg nodejs

# Arch
sudo pacman -S python ffmpeg nodejs
```

Install yt-dlp itself. The most reliable way to get a current version is pip, because distro packages are often outdated and yt-dlp updates frequently to keep up with site changes:

```bash
python3 -m pip install -U yt-dlp
```

If your distro complains about an externally-managed environment, either use `pipx install yt-dlp` or add `--break-system-packages` to the pip command.

Verify everything is reachable:

```bash
yt-dlp --version
ffmpeg -version | head -1
node --version
```

### 2. Run

```bash
cd yt-dlp

# Audio → MP3
python3 ytAudioExtract.py "https://www.youtube.com/watch?v=VIDEO_ID"

# Video → MKV
python3 ytVideo.py "https://www.youtube.com/watch?v=VIDEO_ID"
```

Or run with no argument and the script will prompt you to paste a URL:

```bash
python3 ytAudioExtract.py
# Enter YouTube URL: ...
```

Files are written to whatever directory you run the script from, named after the video title.

### Optional: make them runnable as commands

Both scripts have a shebang line, so you can mark them executable and call them directly:

```bash
chmod +x ytAudioExtract.py ytVideo.py
./ytAudioExtract.py "https://youtu.be/VIDEO_ID"
```

If you want them on your `PATH`, symlink them into `~/.local/bin` (assuming that's on your PATH):

```bash
ln -s "$(pwd)/ytAudioExtract.py" ~/.local/bin/yt-audio
ln -s "$(pwd)/ytVideo.py" ~/.local/bin/yt-video
# then from anywhere:
yt-audio "https://youtu.be/VIDEO_ID"
```

---

## Windows

### 1. Install dependencies

The cleanest path on Windows is [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (built into Windows 10/11). Open PowerShell and run:

```powershell
winget install Python.Python.3.12
winget install Gyan.FFmpeg
winget install yt-dlp.yt-dlp
winget install OpenJS.NodeJS
```

Close and reopen PowerShell afterward so the new PATH entries take effect.

If you don't use winget, the manual equivalents are:
- **Python** from <https://www.python.org/downloads/> — during install, check **"Add python.exe to PATH"**.
- **FFmpeg** from <https://www.gyan.dev/ffmpeg/builds/> — download a release build, unzip it, and add its `bin` folder to your PATH.
- **yt-dlp** from <https://github.com/yt-dlp/yt-dlp/releases> — grab `yt-dlp.exe` and put it somewhere on your PATH.
- **Node.js** from <https://nodejs.org/> — the installer adds it to PATH automatically.

Verify in a fresh PowerShell window:

```powershell
python --version
yt-dlp --version
ffmpeg -version
node --version
```

The `node --version` check matters for `ytVideo.py` — it locates Node automatically as long as Node is on your PATH (the official installer and the winget package both add it). If `node --version` works in a fresh terminal, the script will find it.

### 2. Run

From PowerShell or Command Prompt, in the folder containing the scripts:

```powershell
cd yt-dlp

# Audio → MP3
python ytAudioExtract.py "https://www.youtube.com/watch?v=VIDEO_ID"

# Video → MKV
python ytVideo.py "https://www.youtube.com/watch?v=VIDEO_ID"
```

Wrap the URL in quotes — YouTube URLs contain `&` and `?` characters that the shell will otherwise try to interpret.

Run with no argument to be prompted instead:

```powershell
python ytAudioExtract.py
# Enter YouTube URL: ...
```

Downloaded files appear in the current folder, named after the video title.

---

## Using a cookies file (optional but useful)

Some videos won't download anonymously — age-restricted content, members-only uploads, private/unlisted videos you have access to, or cases where YouTube demands you "sign in to confirm you're not a bot." Supplying your browser cookies to yt-dlp makes it act as your logged-in session.

Both scripts look for a file named **`cookies.txt` in the same directory as the script**. If it's there, it's used automatically; if not, the script just tries without it and tells you so.

### How to produce `cookies.txt`

Use a browser extension that exports cookies in the Netscape format yt-dlp expects:

- **Firefox**: the "cookies.txt" extension (e.g. *cookies.txt* by Lennon Hill).
- **Chrome / Edge**: "Get cookies.txt LOCALLY" or a similar reputable extension.

Steps:

1. Log into YouTube in your browser.
2. With a YouTube tab focused, click the extension and export/save.
3. Save the file as `cookies.txt` directly inside the `yt-dlp` folder next to the scripts.

The script will then print `[+] Using cookies from .../cookies.txt` on its next run.

### A note on cookie hygiene

`cookies.txt` contains your live YouTube/Google session tokens — it's effectively a key to your logged-in account. Treat it like a password:

- It's already covered by the repo's `.gitignore` patterns for secrets — **never commit it**. Double-check with `git status` that it isn't staged.
- Don't share it or sync it to untrusted locations.
- If you suspect it leaked, log out of Google in that browser to invalidate the session, then re-export a fresh file if you still need one.

---

## Troubleshooting

### `yt-dlp: command not found` / `'yt-dlp' is not recognized`

yt-dlp isn't on your PATH. On Linux, confirm the pip install location is on PATH (`python3 -m pip show yt-dlp`), or call it as `python3 -m yt_dlp`. On Windows, make sure `yt-dlp.exe` is in a PATH folder and that you opened a fresh terminal after installing.

### `ffmpeg not found` / audio won't convert, video won't merge

FFmpeg isn't installed or isn't on PATH. Both scripts depend on it — MP3 conversion and MKV merging are FFmpeg operations. Install it (see prerequisites) and reopen your terminal.

### `ERROR: Sign in to confirm you're not a bot` or age/login errors

This is the cookies case. Export `cookies.txt` as described above and drop it next to the script. Make sure you were logged into YouTube in the browser you exported from.

### Windows: `ytVideo.py` fails with a Node/JS runtime error

The script autodetects Node on your PATH, so this almost always means Node isn't installed or isn't on PATH. Confirm `node --version` works in a fresh terminal; if it doesn't, install Node (see prerequisites) and reopen the terminal. If Node is installed to a non-standard location that isn't on PATH, add that folder to your PATH and the script will pick it up.

### Downloads are slow or keep stalling

`ytVideo.py` already retries 5 times. If a specific video consistently fails, update yt-dlp first — site changes break old versions constantly:

```bash
python3 -m pip install -U yt-dlp     # Linux
```
```powershell
winget upgrade yt-dlp.yt-dlp         # Windows (or re-download yt-dlp.exe)
```

### Filename has weird characters or the download errors on saving

Video titles can contain characters your filesystem dislikes. yt-dlp usually sanitizes these, but if you hit a wall you can change the output template in the script (the `--output`/`%(title)s` part) to something like `%(id)s.%(ext)s` to name files by video ID instead.

---

## How it works

Both scripts are thin wrappers: they assemble a yt-dlp command as a list of arguments, optionally append `--cookies` if a `cookies.txt` is present, append the URL, and hand the whole thing to `subprocess.run()`. Output isn't captured, which is deliberate — it lets yt-dlp's live progress bar render in your terminal as the download runs. On failure, yt-dlp's non-zero exit is caught and reported rather than dumping a Python traceback.

The defaults baked in are the parts worth not retyping:

- **Audio script**: `-x` (extract audio) + `--audio-format=mp3` + `--audio-quality=0` (best) gives you a clean MP3 every time.
- **Video script**: `-f bestvideo+bestaudio/best` grabs the highest-quality separate streams and `--merge-output-format mkv` muxes them; MKV is used because it cleanly contains essentially any codec combination yt-dlp might fetch. The `--extractor-args youtube:player_client=android` and the Node.js JS runtime are workarounds for YouTube's periodic changes to how streams are exposed — and the script finds Node for you via `shutil.which()` plus a few common install paths, so the same code works on Linux, macOS, and Windows. If no Node is found, the script omits the runtime flag and lets yt-dlp fall back on its own.
