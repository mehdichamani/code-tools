import psutil

# Get CPU information
cpu_info = psutil.cpu_times_percent(interval=1)
print("CPU Information:")
print(f"User time: {cpu_info.user}")
print(f"System time: {cpu_info.system}")
print(f"IOWait time: {cpu_info.iowait}")
print(f"Idle time: {cpu_info.idle}")

# Get RAM information
ram_info = psutil.virtual_memory()
print("RAM Information:")
print(f"Total memory: {ram_info.total / (1024**3):.2f} GB")
print(f"Available memory: {ram_info.available / (1024**3):.2f} GB")
print(f"Used memory: {ram_info.used / (1024**3):.2f} GB")
print(f"Percentage used: {ram_info.percent}%")

# Get GPU information
try:
    import wmi
    gpu = wmi.WMI().Win32_PowerManagementWmiPowerCap()
    print("GPU Information:")
    print(f"Bus speed: {gpu.BusSpeed:.2f} MHz")
    print(f"Clock speed: {gpu.ClockSpeed:.2f} MHz")
    print(f"Heat dissipation: {gpu.HeatDissipation:.2f}")
except ModuleNotFoundError:
    print("GPU information is not available on this system.")
```

This code uses the `psutil` library to gather CPU, RAM, and GPU information on different operating systems such as Windows, Linux, and Android. The `wmi` library is used to access the GPU information on Windows, but it may not be available on all systems.