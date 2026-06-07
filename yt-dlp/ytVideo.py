#!/usr/bin/env python3
import subprocess
import sys
import os

def download_youtube_video(video_url, cookies_file=None):
    command = [
        "yt-dlp",
        "--js-runtimes", "node:/usr/bin/node",
        "--extractor-args", "youtube:player_client=android",
        "-f", "bestvideo+bestaudio/best",   # Best available combo
        "--merge-output-format", "mkv",     # Output as MKV
        "--output", "%(title)s.%(ext)s",    # Filename format
        "--retries", "5",                   # Retry on network errors
    ]

    # Add cookies if available
    if cookies_file and os.path.isfile(cookies_file):
        command += ["--cookies", cookies_file]
        print(f"[+] Using cookies from {cookies_file}")
    else:
        print("[!] No cookies file found. Trying without login...")

    command.append(video_url)

    try:
        # Don’t capture output — allows yt-dlp progress bar to display live
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