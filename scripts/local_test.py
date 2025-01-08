import subprocess
import time
import sys

def run_zig_build():
    result = subprocess.run(['zig', 'build'], check=True)
    if result.returncode != 0:
        print("Failed to build project")
        sys.exit(1)

def start_process(cmd):
    return subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

def run_curl_commands():
    curl_cmd = [
        'curl',
        '--parallel',
        'localhost:8081/metrics',
        'localhost:8081/metrics',
        'localhost:8081/metrics',
        'localhost:8081/metrics',
        '-H', 'sensor:Temp',
        '-H', 'sensor:RainTotalAcc'
    ]
    result = subprocess.run(curl_cmd, check=True)
    assert result != 0, f"curl command failed: {result}"



def main():
    # Store processes to clean up later
    processes = []
    
    try:
        # Build the project
        run_zig_build()
        time.sleep(1)
        
        # Start the node process
        node_process = start_process(
            ['./zig-out/bin/tinyweather-node'],
        )
        processes.append(node_process)
        
        
        # Start the proxy process
        proxy_process = start_process(
            ['./zig-out/bin/tinyweather-proxy'],
        )
        processes.append(proxy_process)
        
        
        # Run curl commands
        run_curl_commands()
        
            
    except KeyboardInterrupt:
        print("\nShutting down...")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        # Clean up processes
        for process in processes:
            if process.poll() is None:  # If process is still running
                process.terminate()
                try:
                    process.wait(timeout=5)  # Wait up to 5 seconds for graceful shutdown
                except subprocess.TimeoutExpired:
                    process.kill()  # Force kill if it doesn't shut down gracefully
        
        print("All processes stopped")

if __name__ == "__main__":
    main()
