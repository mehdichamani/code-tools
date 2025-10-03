import os
from win10toast import ToastNotifier
import subprocess

notifier = ToastNotifier()
docker_path = r"Z:\docker"
docker_exe = r"C:\Program Files\Docker\Docker\Docker Desktop.exe"

if os.path.exists(docker_path):
    subprocess.Popen([docker_exe])
else:
    notifier.show_toast("هارد اکسترنال پیدا نشد",
                        "برای استفاده از سرور فیلم هارد اکسترنال باید به سیستم متصل باشد.",
                        duration=1, threaded=True)
