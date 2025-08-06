import os
import shutil
import re
import requests

NEW_FOLDER = "D:\\new"
MOVIES_FOLDER = "D:\\Movies"
TV_FOLDER = "D:\\TV Series"

JELLYFIN_URL = "http://localhost:8096"
API_KEY = "2678c632488d415dbc00d3d665478937"

def is_tv_show(filename):
    return bool(re.search(r'[ ._-]S\d{2}E\d{2}', filename, re.IGNORECASE))

def get_target_path(filename):
    if is_tv_show(filename):
        show_name_match = re.match(r"([A-Za-z0-9 ._-]+)[ ._-]S\d{2}E\d{2}", filename, re.IGNORECASE)
        if show_name_match:
            show_name = show_name_match.group(1).replace('.', ' ').replace('_', ' ').strip()
            show_folder = os.path.join(TV_FOLDER, show_name)
            target_path = os.path.join(show_folder, filename)
            return target_path
    else:
        year_match = re.search(r"(\d{4})", filename)
        if year_match:
            year = year_match.group(1)
            year_start = year_match.start()
            movie_name_part = filename[:year_start].rstrip('. _-')
            movie_name = movie_name_part.replace('.', ' ').replace('_', ' ').strip()
            movie_folder_name = f"{movie_name} {year}"
            movie_folder = os.path.join(MOVIES_FOLDER, movie_folder_name)
            target_path = os.path.join(movie_folder, filename)
            return target_path
    return None

def process_file(filename):
    source_path = os.path.join(NEW_FOLDER, filename)
    target_path = get_target_path(filename)
    if target_path:
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        shutil.move(source_path, target_path)
        print(f"✅ Moved: {filename} → {target_path}")
    else:
        print(f"⚠️ Couldn't determine target for: {filename}")

def trigger_jellyfin_scan():
    url = f"{JELLYFIN_URL}/Library/Refresh"
    headers = {
        "X-Emby-Token": API_KEY
    }

    try:
        response = requests.post(url, headers=headers)
        print(f"🔄 Triggered Jellyfin library scan: {response.status_code}")
    except Exception as e:
        print(f"❌ Error triggering Jellyfin scan: {e}")

# اجرای اصلی
media_files = []

for filename in os.listdir(NEW_FOLDER):
    if filename.lower().endswith((".mkv", ".mp4")):
        target = get_target_path(filename)
        if target:
            media_files.append((filename, target))

if not media_files:
    print("📁 No media files (.mkv/.mp4) found for processing.")
    input("🔚 Press Enter to exit...")
    exit()

# پیش‌نمایش تغییرات
print("\n📋 Files to be moved:")
for original, target in media_files:
    print(f"  • {original} → {target}")

# دریافت تائید کاربر
confirm = input("\n❓ Proceed with moving these files? (y/n): ").strip().lower()
if confirm != 'y':
    print("❌ Operation cancelled.")
    input("🔚 Press Enter to exit...")
    exit()

# انجام جابه‌جایی
for original, _ in media_files:
    process_file(original)

trigger_jellyfin_scan()
