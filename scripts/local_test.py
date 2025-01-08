import subprocess
import time



if __name__ == "__main__":
    result = subprocess.run(["zig", "build"], check=True)
    assert result != 0, "zig build failed"
    time.sleep(1)

    subprocess.Popen(["./zig-out/bin/tinyweather-node"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(1)

    subprocess.Popen(["./zig-out/bin/tinyweather-proxy"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(1)

    subprocess.run([
        'curl',
        '--parallel',
        'localhost:8081/metrics',
        'localhost:8081/metrics',
        'localhost:8081/metrics',
        'localhost:8081/metrics',
        '-H', 'sensor:Temp',
        '-H', 'sensor:RainTotalAcc'
    ], check=True)

