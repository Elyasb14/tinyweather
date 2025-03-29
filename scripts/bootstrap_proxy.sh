#! /bin/bash

usage() {
    echo -e "\x1b[31mUsage: $0 \x1b[0m"
    echo -e "\x1b[33m  --address <address>\x1b[0m"
    echo -e "\x1b[33m  --port <port>\x1b[0m"
    echo -e "\x1b[31mExample: $0 \x1b[0m"
    echo -e "\x1b[33m  --address 127.0.0.1\x1b[0m" 
    echo -e "\x1b[33m  --port 8081\x1b[0m"
    exit 1
}

ADDRESS=""
PORT=""

if [ "$#" -lt 4 ]; then
  echo -e "\x1b[31m4 arguments are needed, $# provided.\x1b[0m"
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --address)
            ADDRESS="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
            ;;
        *)
            echo -e "\x1b[31mError: Unknown argument $1\x1b[0m"
            usage
            ;;
    esac
done

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
