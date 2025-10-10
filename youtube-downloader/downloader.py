#!/usr/bin/env python3

import subprocess
import json
import os
import sys

# --- ANSI Color Codes ---
class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    # Foreground colors
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    CYAN = '\033[36m'
    # Bright foreground colors
    BRIGHT_RED = '\033[91m'
    BRIGHT_GREEN = '\033[92m'
    BRIGHT_YELLOW = '\033[93m'
    BRIGHT_CYAN = '\033[96m'

# On Windows, this call enables ANSI escape code processing.
if sys.platform == 'win32':
    os.system('')

def format_bytes(byte_count):
    """
    Converts bytes into a human-readable format (KB, MB, GB).
    """
    if byte_count is None or byte_count == 0:
        return "N/A"
    power = 1024
    n = 0
    power_labels = {0: '', 1: 'K', 2: 'M', 3: 'G', 4: 'T'}
    while byte_count >= power and n < len(power_labels):
        byte_count /= power
        n += 1
    return f"{byte_count:.2f} {power_labels[n]}B"

def get_video_info(url, cookies_path):
    """
    Fetches video information using yt-dlp without downloading.
    Returns a dictionary of the video's metadata.
    """
    command = [
        'yt-dlp', '--cookies', cookies_path, '--dump-json', url
    ]
    print(f"{Colors.CYAN}Fetching video information...{Colors.RESET}")
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, check=True, encoding='utf-8'
        )
        return json.loads(result.stdout)
    except FileNotFoundError:
        print(f"\n{Colors.BRIGHT_RED}ERROR: 'yt-dlp' not found.{Colors.RESET}")
        print("Please ensure yt-dlp is installed and in your system's PATH.")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"\n{Colors.BRIGHT_RED}ERROR: yt-dlp failed to fetch video info.{Colors.RESET}")
        print("This could be an invalid URL or a network issue.")
        print(f"{Colors.RED}yt-dlp error output:\n{e.stderr}{Colors.RESET}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"\n{Colors.BRIGHT_RED}ERROR: Failed to parse video information from yt-dlp.{Colors.RESET}")
        sys.exit(1)

def find_best_quality_and_size(info):
    """
    Parses the video info to find the best quality, estimated size,
    and whether a merge operation is needed.
    """
    best_video = None
    best_audio = None
    
    for f in info.get('formats', []):
        if f.get('vcodec') != 'none' and f.get('acodec') == 'none':
            if best_video is None or f.get('height', 0) > best_video.get('height', 0):
                best_video = f
        
        if f.get('acodec') != 'none' and f.get('vcodec') == 'none':
            if best_audio is None or f.get('abr', 0) > best_audio.get('abr', 0):
                best_audio = f

    if best_video and best_audio:
        resolution = f"{best_video.get('width')}x{best_video.get('height')}"
        fps = best_video.get('fps')
        if fps:
            resolution += f" @ {fps}fps"
        
        video_size = best_video.get('filesize') or best_video.get('filesize_approx', 0)
        audio_size = best_audio.get('filesize') or best_audio.get('filesize_approx', 0)
        total_size = video_size + audio_size
        return resolution, True, total_size

    best_combined = None
    for f in info.get('formats', []):
         if f.get('vcodec') != 'none' and f.get('acodec') != 'none':
             if best_combined is None or f.get('height', 0) > best_combined.get('height', 0):
                 best_combined = f
                 
    if best_combined:
        resolution = f"{best_combined.get('width')}x{best_combined.get('height')}"
        fps = best_combined.get('fps')
        if fps:
            resolution += f" @ {fps}fps"
        total_size = best_combined.get('filesize') or best_combined.get('filesize_approx', 0)
        return resolution, False, total_size
        
    return "Unknown", False, 0

def download_video(url, cookies_path):
    """
    Downloads the video with the specified parameters.
    """
    print(f"\n{Colors.CYAN}Starting download... (You will see progress from yt-dlp below){Colors.RESET}")
    command = [
        'yt-dlp', '--cookies', cookies_path,
        '-f', 'bestvideo+bestaudio/best',
        '--merge-output-format', 'mkv',
        url
    ]
    try:
        subprocess.run(command, check=True)
        print(f"\n{Colors.BRIGHT_GREEN}✅ Download complete!{Colors.RESET}")
    except FileNotFoundError:
        print(f"\n{Colors.BRIGHT_RED}ERROR: 'yt-dlp' or 'ffmpeg' not found.{Colors.RESET}")
        print("Please ensure both are installed and in your system's PATH.")
        sys.exit(1)
    except subprocess.CalledProcessError:
        print(f"\n{Colors.BRIGHT_RED}❌ ERROR: Download failed. Please check the yt-dlp output above.{Colors.RESET}")
        sys.exit(1)

def main():
    """
    Main function to run the script.
    """
    cookies_file = os.path.expanduser('~/youtube-cookies.txt')

    if not os.path.exists(cookies_file):
        print(f"{Colors.YELLOW}Warning: Cookie file not found at '{cookies_file}'{Colors.RESET}")
        print(f"{Colors.YELLOW}Downloads may fail for private videos or use lower quality settings.{Colors.RESET}")

    video_url = input(f"{Colors.BOLD}Please enter the YouTube URL: {Colors.RESET}").strip()
    if not video_url:
        print("No URL entered. Exiting.")
        return

    info = get_video_info(video_url, cookies_file)
    title = info.get('title', 'N/A')
    quality, remux_needed, size_in_bytes = find_best_quality_and_size(info)
    display_size = format_bytes(size_in_bytes)

    # Display info to user in color
    header = f"{Colors.BRIGHT_CYAN}{'='*50}{Colors.RESET}"
    print(f"\n{header}")
    print(f"{Colors.BOLD}Video Details:{Colors.RESET}")
    print(f"  {Colors.BRIGHT_YELLOW}Title:{Colors.RESET} {Colors.BRIGHT_GREEN}{title}{Colors.RESET}")
    print(f"  {Colors.BRIGHT_YELLOW}Best Quality:{Colors.RESET} {Colors.BRIGHT_GREEN}{quality}{Colors.RESET}")
    print(f"  {Colors.BRIGHT_YELLOW}Est. Size:{Colors.RESET} {Colors.BRIGHT_GREEN}{display_size}{Colors.RESET}")
    
    if remux_needed:
        action_text = "Download separate video/audio and remux into MKV."
    else:
        action_text = "Download combined stream and convert to MKV if needed."
    print(f"  {Colors.BRIGHT_YELLOW}Action:{Colors.RESET} {Colors.BRIGHT_GREEN}{action_text}{Colors.RESET}")
    print(header + "\n")

    try:
        input(f"{Colors.BOLD}Press ENTER to continue or Ctrl+C to cancel...{Colors.RESET}")
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Operation cancelled by user. Exiting.{Colors.RESET}")
        sys.exit(0)
    
    download_video(video_url, cookies_file)

if __name__ == "__main__":
    main()