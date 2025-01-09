import subprocess
import time



if __name__ == "__main__":
    subprocess.run("source .venv/bin/activate", shell=True, executable="/bin/bash")
    result = subprocess.run(["zig", "build"], check=True)
    assert result != 0, "zig build failed"
    time.sleep(1)
    print("\x1b[32mzig build ran\x1b[0m")

    subprocess.Popen(["./zig-out/bin/tinyweather-node"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(1)
    print("\x1b[32mnode started...\x1b[0m")

    subprocess.Popen(["./zig-out/bin/tinyweather-proxy"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(1)
    print("\x1b[32mproxy started...\x1b[0m")

    subprocess.run([
        'curl',
        # '--parallel',
        # 'localhost:8081/metrics',
        # 'localhost:8081/metrics',
        # 'localhost:8081/metrics',
        'localhost:8081/metrics',
        '-H', 'sensor:Temp',
        '-H', 'sensor:RainTotalAcc'
    ], check=True)

