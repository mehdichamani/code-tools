import os
import sys
import subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import shutil

SCRIPT_DIR = Path(__file__).resolve().parent
LINKS_FILE = SCRIPT_DIR / "links.txt"
COOKIES_FILE = SCRIPT_DIR / "cookies.txt"
OUT_DIR = Path.home() / "downloads"

OUT_DIR.mkdir(exist_ok=True)

def download(url: str) -> tuple[bool, str, str | None]:
    cmd = [
        "yt-dlp",
        "--cookies", str(COOKIES_FILE),
        "-f", "best",
        "-o", str(OUT_DIR / "%(title)s [%(id)s].%(ext)s"),
        url
    ]
    try:
        subprocess.run(cmd, check=True)
        return True, url, None
    except subprocess.CalledProcessError as e:
        return False, url, str(e)

def main() -> int:
    if shutil.which("yt-dlp") is None:
        print("yt-dlp not found. Install it with: pip install -U yt-dlp")
        return 1
    if not LINKS_FILE.exists():
        print(f"links.txt not found at: {LINKS_FILE}")
        return 1
    if not COOKIES_FILE.exists():
        print(f"cookies.txt not found at: {COOKIES_FILE}")
        return 1

    lines = [ln.strip() for ln in LINKS_FILE.read_text(encoding="utf-8").splitlines()]
    urls = [ln for ln in lines if ln and not ln.startswith("#")]
    if not urls:
        print("No URLs to download in links.txt")
        return 0

    max_workers = min(4, (os.cpu_count() or 1))
    with ThreadPoolExecutor(max_workers=max_workers) as ex:
        futures = {ex.submit(download, url): url for url in urls}
        for fut in as_completed(futures):
            ok, url, err = fut.result()
            if ok:
                print("Downloaded:", url)
            else:
                print("Failed:", url, err)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())