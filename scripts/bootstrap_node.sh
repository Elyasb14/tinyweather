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
        *)
            echo -e "\x1b[31mError: Unknown argument $1\x1b[0m"
            usage
            ;;
    esac
done

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
