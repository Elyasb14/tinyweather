import subprocess
import time

def start_process(cmd):
    print(f"Starting: {' '.join(cmd)}")
    return subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

def read_stdout(proc):
    if proc.stdout:
        return proc.stdout.read()
    return ""

def main():
    # Start tinyweather-node
    node_proc = start_process(["./zig-out/bin/tinyweather-node"])
    time.sleep(1)  # Give it time to start (adjust as needed)

    # Start tinyweather-proxy
    proxy_proc = start_process(["./zig-out/bin/tinyweather-proxy"])
    time.sleep(1)  # Give it time to start too

    # Run the curl command
    print("Running curl...")
    try:
        curl_output = subprocess.check_output([
            "curl", "localhost:8081/metrics",
            "-H", "Sensor:RG15",
            "-H", "Sensor:BFROBOT",
            "-H", "Sensor:BME680"
        ], text=True)
        print("Curl output:")
        print(curl_output)
    except subprocess.CalledProcessError as e:
        print("Curl failed:")
        print(e.output)

    # Terminate the node and proxy processes
    node_proc.terminate()
    proxy_proc.terminate()

    # Wait for them to exit
    node_proc.wait()
    proxy_proc.wait()

    # Read their outputs
    print("\n--- tinyweather-node stdout ---")
    print(read_stdout(node_proc))

    print("\n--- tinyweather-proxy stdout ---")
    print(read_stdout(proxy_proc))

if __name__ == "__main__":
    main()

