#!/usr/bin/env python3
import subprocess
import sys
import os

def download_youtube_video(video_url, cookies_file=None):
    command = [
        'yt-dlp',
        '-x',  # Extract audio
        '--audio-format=mp3',  # Convert to mp3
        '--audio-quality=0',   # Best quality
        '--output=%(title)s.%(ext)s',  # Output filename format
    ]

    # Add cookies if the file exists
    if cookies_file and os.path.isfile(cookies_file):
        command += ['--cookies', cookies_file]
        print(f"[+] Using cookies from {cookies_file}")
    else:
        print("[!] No cookies file found. Trying without login...")

    command.append(video_url)

    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"[!] Download failed: {e}")

def main():
    # Get URL from command line or ask interactively
    if len(sys.argv) > 1:
        video_url = sys.argv[1]
    else:
        video_url = input("Enter YouTube URL: ").strip()

    # Look for cookies.txt in the same directory as this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    cookies_file = os.path.join(script_dir, "cookies.txt")

    download_youtube_video(video_url, cookies_file)

if __name__ == "__main__":
    main()
