import os
import platform
import subprocess
from pathlib import Path

# Define available filters
filters = [
    'crop=1080:1080:700:0',  # Crop1 (ED)
    'crop=1080:1080:0:0',    # Crop2 (AB)
    'eq=brightness=0.15:contrast=1.4:saturation=1.2:gamma=1.1',  # Light Fix
    'hqdn3d=1.5:1.5:6:6',    # Digital Noise Fix
    'unsharp=7:7:1.5:7:7:0.0',  # Strong Sharp & Noise
    'smartblur=1.5:-0.35:-3.5:0.65:0.25:2.0'  # Soft Sharp & Noise
]

filter_names = [
    'Crop1 (ED)',
    'Crop2 (AB)',
    'Light Fix',
    'Digital Noise Fix',
    'Strong Sharp & Noise',
    'Soft Sharp & Noise'
]

def get_input_directory():
    # Always use current working directory, regardless of OS
    input_dir = os.getcwd()
    print(f"Using input directory: {input_dir}")
    return input_dir

def get_filter_and_cpu_selection():
    print("\nAvailable filters:")
    for i, (name, filter_) in enumerate(zip(filter_names, filters), 1):
        print(f"[{i}] {name} : {filter_}")
    
    while True:
        try:
            selection = input("\nEnter filter numbers to apply [default: 1,3,4,5] you can add 'gpu' to use GPU (e.g. 1,3,gpu): ")
            use_gpu = False
            if not selection.strip():
                selected = [1, 3, 4, 5]
            else:
                parts = [x.strip().lower() for x in selection.split(',') if x.strip()]
                if 'gpu' in parts:
                    use_gpu = True
                    parts = [p for p in parts if p != 'gpu']
                selected = []
                for p in parts:
                    if p.isdigit():
                        selected.append(int(p))
            valid_selections = [i-1 for i in selected if 0 < i <= len(filters)]
            if not valid_selections:
                print("No valid filters selected. Please try again.")
                continue
            return valid_selections, use_gpu
        except ValueError:
            print("Invalid input. Please enter numbers separated by commas and/or 'gpu'.")

def process_videos(input_dir, selected_filters, filter_numbers):
    output_dir = os.path.join(input_dir, 'output')
    os.makedirs(output_dir, exist_ok=True)

    # Get all MP4 files
    mp4_files = list(Path(input_dir).glob('*.mp4'))
    if not mp4_files:
        print(f"No MP4 files found in {input_dir}")
        return

    # use_gpu is now passed as an argument

    import sys
    import re
    from datetime import timedelta

    def get_duration(file_path):
        # Use ffprobe to get duration in seconds
        try:
            result = subprocess.run([
                'ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                '-of', 'default=noprint_wrappers=1:nokey=1', str(file_path)
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            duration = float(result.stdout.strip())
            return duration
        except Exception:
            return None

    def format_time(seconds):
        # Format seconds as HH:MM:SS.xx
        try:
            td = timedelta(seconds=float(seconds))
            total_seconds = int(td.total_seconds())
            ms = int((td.total_seconds() - total_seconds) * 100)
            return f"{str(td)}.{ms:02d}" if ms else str(td)
        except Exception:
            return str(seconds)

    total_videos = len(mp4_files)
    for idx, file_path in enumerate(mp4_files, 1):
        output_file = os.path.join(
            output_dir,
            f"{file_path.stem}_new({','.join(map(str, filter_numbers))}).mp4"
        )

        # Get duration (needed for progress, even if skipping)
        duration = get_duration(file_path)
        duration_str = format_time(duration) if duration else "?"

        # Check if output file exists
        if os.path.exists(output_file):
            print(f"\nOutput file exists: {output_file}", flush=True)
            while True:
                resp = input("Overwrite? [y]es/[n]o/[q]uit: ").strip().lower()
                if resp in ('y', 'yes'):
                    break
                elif resp in ('n', 'no'):
                    print(f"Skipping: {file_path.name}")
                    print(f"Skipped: {file_path} -> {output_file}")
                    # Print a progress line for skipped file
                    print(f"Progress: {duration_str} / {duration_str} (100.0%) [{idx}/{total_videos}]  (skipped)")
                    goto_next = True
                    break
                elif resp in ('q', 'quit'):
                    print("Aborted by user.")
                    return
            if 'goto_next' in locals() and goto_next:
                del goto_next
                continue

        # Prepare ffmpeg command
        if platform.system() == 'Windows':
            if process_videos.use_gpu:
                cmd = [
                    'ffmpeg', '-hwaccel', 'dxva2', '-i', str(file_path),
                    '-vf', selected_filters,
                    '-c:v', 'h264_nvenc',
                    '-c:a', 'copy', output_file
                ]
            else:
                cmd = [
                    'ffmpeg', '-i', str(file_path),
                    '-vf', selected_filters,
                    '-c:v', 'libx264', '-crf', '23', '-preset', 'medium',
                    '-c:a', 'copy', output_file
                ]
        else:  # Termux/Android
            if process_videos.use_gpu:
                cmd = [
                    'ffmpeg', '-hwaccel', 'mediacodec', '-i', str(file_path),
                    '-vf', selected_filters,
                    '-c:v', 'h264_mediacodec',
                    '-c:a', 'copy', output_file
                ]
            else:
                cmd = [
                    'ffmpeg', '-i', str(file_path),
                    '-vf', selected_filters,
                    '-c:v', 'libx264', '-crf', '23', '-preset', 'medium',
                    '-c:a', 'copy', output_file
                ]

        # Print processing line after any prompt
        print(f"Processing: {file_path.name} [{idx}/{total_videos}]")
        try:
            process = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.DEVNULL, text=True, bufsize=1)
            time_pattern = re.compile(r'time=([\d:.]+)')
            last_time = ''
            percent = 0
            for line in process.stderr:
                match = time_pattern.search(line)
                if match:
                    last_time = match.group(1)
                    # Convert last_time to seconds for percent
                    def parse_ffmpeg_time(t):
                        try:
                            parts = t.split(':')
                            if len(parts) == 3:
                                h, m, s = parts
                                return float(h) * 3600 + float(m) * 60 + float(s)
                            elif len(parts) == 2:
                                m, s = parts
                                return float(m) * 60 + float(s)
                            else:
                                return float(parts[0])
                        except Exception:
                            return 0
                    elapsed = parse_ffmpeg_time(last_time)
                    if duration:
                        percent = min(100, (elapsed / duration) * 100)
                        percent_str = f"{percent:5.1f}%"
                    else:
                        percent_str = "   ?%"
                    print(f"\rProgress: {last_time} / {duration_str} ({percent_str}) [{idx}/{total_videos}]", end='', flush=True)
            process.wait()
            print(f"\rProgress: {duration_str} / {duration_str} (100.0%) [{idx}/{total_videos}]           ")
            if process.returncode == 0:
                print(f"Processed: {file_path} -> {output_file}")
            else:
                print(f"Error processing {file_path}")
                return
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
            return

def main():
    input_dir = get_input_directory()
    selected_indexes, use_gpu = get_filter_and_cpu_selection()
    # Combine selected filters
    selected_filters = ','.join(filters[i] for i in selected_indexes)
    filter_numbers = [i + 1 for i in selected_indexes]
    process_videos.use_gpu = use_gpu
    process_videos(input_dir, selected_filters, filter_numbers)
    print("\nCompleted!")

if __name__ == '__main__':
    main()