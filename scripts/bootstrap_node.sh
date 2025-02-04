#! /bin/bash

if [ $# -ne 2 ]; then
    echo -e "\x1b[31mError: Please provide both address and port arguments.\x1b[0m"
    echo -e "\x1b[33mUsage: $0 <address> <port>\x1b[0m"
    echo -e "\x1b[33mExample: $0 127.0.0.1 8080\x1b[0m"
    exit 1
fi

ADDRESS=$1
PORT=$2

if [[ -f /etc/systemd/system/tinyweather-node.service ]]; then 
    systemctl stop tinyweather-node.service
    systemctl disable tinyweather-node.service
    rm /etc/systemd/system/tinyweather-node.service
    systemctl daemon-reload
    echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
fi

zig build 
mkdir -p /opt/tinyweather
rm -f /opt/tinyweather/tinyweather-node
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
touch /etc/systemd/system/tinyweather-node.service

echo "
[Unit]
Description=Tinyweather Node Service
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/tinyweather/tinyweather-node --address $ADDRESS --port $PORT 
WorkingDirectory=/opt/tinyweather
Environment=\"PATH=/opt/tinyweather/.venv/bin:/usr/bin\"
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tinyweather-node.service

systemctl daemon-reload
systemctl start tinyweather-node
systemctl enable tinyweather-node
systemctl status tinyweather-node
