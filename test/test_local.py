import subprocess
import time
import os
import platform


if __name__ == "__main__":
    # Get the current working directory
    cwd = os.getcwd()
    # Path to the activation script
    activation_script = os.path.join(cwd, ".venv/bin/activate")
    venv_python = os.path.join(cwd, ".venv/bin/python")
    venv_pip = os.path.join(cwd, ".venv/bin/pip")

    # Ensure the virtual environment exists
    if not os.path.exists(activation_script):
        print("\x1b[32mCreating Python3 virtual environment...\x1b[0m")
        subprocess.run(["python3", "-m", "venv", ".venv"], check=True)

    if platform.system == "Linux":
        # Use the virtual environment's pip to install dependencies
        subprocess.run([venv_pip, "install", "adafruit-circuitpython-bme680", "adafruit-blinka", "RPi.GPIO"], check=True)

    # Run zig build
    result = subprocess.run(["zig", "build"], check=True)
    assert result.returncode == 0, "zig build failed"
    time.sleep(1)
    print("\x1b[32mzig build ran successfully\x1b[0m")

    # Start the tinyweather-node
    subprocess.Popen(["./zig-out/bin/tinyweather-node"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(1)
    print("\x1b[32mNode started...\x1b[0m")

    # Start the tinyweather-proxy
    subprocess.Popen(["./zig-out/bin/tinyweather-proxy"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(1)
    print("\x1b[32mProxy started...\x1b[0m")

    # Run the curl command
    subprocess.run([
        'curl',
        'localhost:8081/metrics',
        '-H', 'sensor:Temp',
        '-H', 'sensor:RainTotalAcc'
    ], check=True)

