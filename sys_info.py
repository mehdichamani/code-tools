import platform
import sys
import os

try:
    import psutil
except ImportError:
    print("psutil not found. Please install it with 'pip install psutil'")
    sys.exit(1)

# Try to import GPUtil for GPU info
try:
    import GPUtil
    gputil_available = True
except ImportError:
    gputil_available = False

def get_cpu_info():
    if sys.platform.startswith('linux') or sys.platform == 'win32':
        return platform.processor() or platform.uname().processor
    elif sys.platform.startswith('android'):
        try:
            with open('/proc/cpuinfo') as f:
                for line in f:
                    if 'Hardware' in line or 'model name' in line:
                        return line.strip()
        except Exception:
            return 'Unknown CPU'
    return 'Unknown CPU'

def get_ram_info():
    mem = psutil.virtual_memory()
    return f"Total: {mem.total // (1024**2)} MB, Available: {mem.available // (1024**2)} MB"

def get_gpu_info():
    if gputil_available:
        gpus = GPUtil.getGPUs()
        if gpus:
            return [f"{gpu.name} ({gpu.memoryTotal}MB)" for gpu in gpus]
        else:
            return ['No GPU found']
    # Android or fallback
    if sys.platform.startswith('android'):
        try:
            with os.popen('dumpsys | grep GLES') as f:
                lines = f.readlines()
                return [line.strip() for line in lines if line.strip()]
        except Exception:
            return ['Unknown GPU']
    return ['Unknown GPU']

def main():
    print(f"System: {platform.system()} {platform.release()}")
    print(f"CPU: {get_cpu_info()}")
    print(f"RAM: {get_ram_info()}")
    print("GPU:")
    for gpu in get_gpu_info():
        print(f"  {gpu}")

if __name__ == "__main__":
    main()
