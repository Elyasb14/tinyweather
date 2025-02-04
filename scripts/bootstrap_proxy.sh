#! /bin/bash

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo -e "\x1b[31mError: Please provide both address and port arguments.\x1b[0m"
    echo -e "\x1b[33mUsage: $0 <address> <port>\x1b[0m"
    exit 1
fi

# Store command line arguments
ADDRESS=$1
PORT=$2

if [[ -f /etc/systemd/system/tinyweather-proxy.service ]]; then 
    systemctl stop tinyweather-proxy.service
    systemctl disable tinyweather-proxy.service
    rm /etc/systemd/system/tinyweather-proxy.service
    systemctl daemon-reload
fi

zig build 
mkdir -p /opt/tinyweather
rm -f /opt/tinyweather/tinyweather-proxy
mv ./zig-out/bin/tinyweather-proxy /opt/tinyweather
touch /etc/systemd/system/tinyweather-proxy.service
echo "
[Unit]
Description=Tinyweather proxy Service
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/tinyweather/tinyweather-proxy --address $ADDRESS --port $PORT 
WorkingDirectory=/opt/tinyweather
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tinyweather-proxy.service

systemctl daemon-reload
systemctl start tinyweather-proxy
systemctl enable tinyweather-proxy
systemctl status tinyweather-proxy
