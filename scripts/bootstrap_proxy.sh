#! /bin/bash

echo -e "\x1b[33mChecking for existing tinyweather-proxy service file...\x1b[0m"
if [[ -f /etc/systemd/system/tinyweather-proxy.service ]]; then 
    systemctl stop tinyweather-proxy.service
    systemctl disable tinyweather-proxy.service
    rm /etc/systemd/system/tinyweather-proxy.service
    systemctl daemon-reload
    echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
else
    echo -e "\x1b[32mNo existing tinyweather-proxy service file found. Skipping removal steps.\x1b[0m"
fi

echo -e "\x1b[32mBeginning the bootstrapping of tinyweather-proxy\x1b[0m"
echo -e "\x1b[33mBuilding tinyweather-proxy with 'zig build'...\x1b[0m"
zig build


echo -e "\x1b[33mPreparing /opt/tinyweather directory...\x1b[0m"
mkdir -p /opt/tinyweather

echo -e "\x1b[33mRemoving existing tinyweather-proxy binary from /opt/tinyweather (if it exists)...\x1b[0m"
rm -f /opt/tinyweather/tinyweather-proxy

echo -e "\x1b[33mMoving newly built tinyweather-proxy executable to /opt/tinyweather\x1b[0m"
mv ./zig-out/bin/tinyweather-proxy /opt/tinyweather

echo -e "\x1b[33mCreating systemd service file at /etc/systemd/system/tinyweather-proxy.service...\x1b[0m"
touch /etc/systemd/system/tinyweather-proxy.service

echo -e "\x1b[33mWriting service configuration to /etc/systemd/system/tinyweather-proxy.service...\x1b[0m"
echo "
[Unit]
Description=Tinyweather proxy Service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/tinyweather/tinyweather-proxy --address 127.0.0.1 --port 8081 
WorkingDirectory=/opt/tinyweather

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tinyweather-proxy.service
echo -e "\x1b[32mService configuration written to /etc/systemd/system/tinyweather-proxy.service\x1b[0m"

echo -e "\x1b[33mReloading systemd daemon to recognize the new tinyweather-proxy service...\x1b[0m"
systemctl daemon-reload
echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"

echo -e "\x1b[33mStarting the tinyweather-proxy service...\x1b[0m"
systemctl start tinyweather-proxy
echo -e "\x1b[32mtinyweather-proxy service started.\x1b[0m"

systemctl status tinyweather-proxy
