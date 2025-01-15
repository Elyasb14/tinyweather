#! /bin/bash

echo -e "\x1b[33mChecking for existing tinyweather-node service file...\x1b[0m"
if [[ -f /etc/systemd/system/tinyweather-node.service ]]; then 
    systemctl stop tinyweather-node.service
    systemctl disable tinyweather-node.service
    rm /etc/systemd/system/tinyweather-node.service
    systemctl daemon-reload
    echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
else
    echo -e "\x1b[32mNo existing tinyweather-node service file found. Skipping removal steps.\x1b[0m"
fi

echo -e "\x1b[32mBeginning the bootstrapping of tinyweather-node\x1b[0m"
echo -e "\x1b[33mBuilding tinyweather-node with 'zig build'...\x1b[0m"
zig build -Doptimize=ReleaseSafe


echo -e "\x1b[33mPreparing /opt/tinyweather directory...\x1b[0m"
mkdir -p /opt/tinyweather

echo -e "\x1b[33mRemoving existing tinyweather-node binary from /opt/tinyweather (if it exists)...\x1b[0m"
rm -f /opt/tinyweather/tinyweather-node

echo -e "\x1b[33mMoving newly built tinyweather-node executable to /opt/tinyweather\x1b[0m"
mv ./zig-out/bin/tinyweather-node /opt/tinyweather

if [[ -d .venv ]]; then 
  rm -rf .venv
fi

python3 -m venv .venv
source .venv/bin/activate
pip install adafruit-circuitpython-bme680 adafruit-blinka RPi.GPIO

if [[ -d /opt/tinyweather/.venv/ ]]; then 
  rm -rf /opt/tinyweather/.venv
fi

mv ./.venv /opt/tinyweather

echo -e "\x1b[33mCreating systemd service file at /etc/systemd/system/tinyweather-node.service...\x1b[0m"
touch /etc/systemd/system/tinyweather-node.service

echo -e "\x1b[33mWriting service configuration to /etc/systemd/system/tinyweather-node.service...\x1b[0m"
echo "
[Unit]
Description=Tinyweather Node Service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/tinyweather/tinyweather-node --address 127.0.0.1 --port 8080 
WorkingDirectory=/opt/tinyweather
Environment="PATH=/opt/tinyweather/.venv/bin:/usr/bin"

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tinyweather-node.service
echo -e "\x1b[32mService configuration written to /etc/systemd/system/tinyweather-node.service\x1b[0m"

echo -e "\x1b[33mReloading systemd daemon to recognize the new tinyweather-node service...\x1b[0m"
systemctl daemon-reload
echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"

echo -e "\x1b[33mStarting the tinyweather-node service...\x1b[0m"
systemctl start tinyweather-node
echo -e "\x1b[32mtinyweather-node service started.\x1b[0m"

systemctl status tinyweather-node
