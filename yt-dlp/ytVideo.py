#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil

def find_node():
    """Locate a Node.js runtime across platforms.

    yt-dlp can use Node as a JavaScript runtime to help with YouTube's
    signature/extraction logic. We look for it on PATH (works on Linux,
    macOS, and Windows) and fall back to a few common install locations.
    Returns the path as a string, or None if Node isn't found — in which
    case we simply don't pass --js-runtimes and let yt-dlp sort itself out.
    """
    # shutil.which checks PATH and, on Windows, knows about .exe/.cmd.
    node = shutil.which("node")
    if node:
        return node

    # Fallbacks for installs that aren't on PATH for some reason.
    candidates = [
        "/usr/bin/node",
        "/usr/local/bin/node",
        "/opt/homebrew/bin/node",                       # Apple Silicon Homebrew
        r"C:\Program Files\nodejs\node.exe",            # default Windows install
        r"C:\Program Files (x86)\nodejs\node.exe",
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path

    return None

def download_youtube_video(video_url, cookies_file=None):
    command = [
        "yt-dlp",
        "--extractor-args", "youtube:player_client=android",
        "-f", "bestvideo+bestaudio/best",   # Best available combo
        "--merge-output-format", "mkv",     # Output as MKV
        "--output", "%(title)s.%(ext)s",    # Filename format
        "--retries", "5",                   # Retry on network errors
    ]

    # Pass an explicit JS runtime only if we actually found Node.
    node_path = find_node()
    if node_path:
        command[1:1] = ["--js-runtimes", f"node:{node_path}"]
        print(f"[+] Using Node.js runtime at {node_path}")
    else:
        print("[!] Node.js not found on PATH. Letting yt-dlp choose a runtime...")

    # Add cookies if available
    if cookies_file and os.path.isfile(cookies_file):
        command += ["--cookies", cookies_file]
        print(f"[+] Using cookies from {cookies_file}")
    else:
        print("[!] No cookies file found. Trying without login...")

    command.append(video_url)

    try:
        # Don't capture output — allows yt-dlp progress bar to display live
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"[!] Download failed: {e}")

def main():
    # URL via CLI arg or prompt
    if len(sys.argv) > 1:
        video_url = sys.argv[1]
    else:
        video_url = input("Enter YouTube or playlist URL: ").strip()

    # Look for cookies.txt in same directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    cookies_file = os.path.join(script_dir, "cookies.txt")

    download_youtube_video(video_url, cookies_file)

if __name__ == "__main__":
    main()
