import time
import ctypes
import requests  # Install via pip if needed

# Configuration
JELLYFIN_URL = 'http://localhost:8096'  # Or your WSL/Docker IP:port (e.g., http://172.XX.XX.XX:8096)
API_KEY = 'bea63b9d17d145aab9a01cbe24e2782e'  # From Jellyfin Dashboard > API Keys
CHECK_INTERVAL = 300  # 5 minutes in seconds
INHIBIT_DURATION = 600  # 10 minutes in seconds (adjust if needed)

# Windows API constants for SetThreadExecutionState
ES_CONTINUOUS = 0x80000000
ES_SYSTEM_REQUIRED = 0x00000001
ES_DISPLAY_REQUIRED = 0x00000002  # Optional: keep display on too

def inhibit_sleep():
    """Prevent system sleep by setting thread execution state."""
    ctypes.windll.kernel32.SetThreadExecutionState(
        ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
    )
    print("Sleep inhibited due to active stream.")

def allow_sleep():
    """Allow normal sleep behavior."""
    ctypes.windll.kernel32.SetThreadExecutionState(ES_CONTINUOUS)
    print("No active streams; allowing sleep.")

def check_active_streams():
    """Check Jellyfin API for active playing streams."""
    url = f"{JELLYFIN_URL}/Sessions"
    headers = {
        "X-Emby-Token": API_KEY
    }
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Raise error for bad status codes
        sessions = response.json()
        for session in sessions:
            if 'NowPlayingItem' in session and session.get('PlayState', {}).get('IsPaused') == False:
                return True  # Active stream found
        return False
    except Exception as e:
        print(f"Error fetching sessions: {e}")
        return False  # Assume no streams on error to avoid indefinite inhibition

print("Monitoring Jellyfin for active streams... Press Ctrl+C to stop.")

try:
    while True:
        if check_active_streams():
            inhibit_sleep()
            time.sleep(INHIBIT_DURATION)  # Keep inhibited for 10 min
        else:
            allow_sleep()
        time.sleep(CHECK_INTERVAL)  # Wait 5 min before next check
except KeyboardInterrupt:
    allow_sleep()  # Reset on exit
    print("Script stopped.")
