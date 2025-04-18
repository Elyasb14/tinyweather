#!/bin/bash

usage() {
    echo -e "\x1b[33mUsage: $0 \\"
    echo -e "  --prom-listen-address <prom-listen-address> \\"
    echo -e "  --proxy-address <proxy-address> \\"
    echo -e "  --node-address <node-address> \\"
    echo -e "  --node-port <node-port> \\"
    echo -e "  --sensors <sensor1,sensor2,...>\x1b[0m \\"
    echo -e "  --tsdb-retention <time>"
    echo -e "\x1b[33mExample: $0 \\"
    echo -e "  --prom-listen-address 127.0.0.1:9090 \\"
    echo -e "  --proxy-address 127.0.0.1:8081 \\"
    echo -e "  --node-address 127.0.0.1 \\"
    echo -e "  --node-port 8080 \\"
    echo -e "  --sensors \"RG15,BME680\"\x1b[0m \\"
    echo -e "  --tsdb-retention 15d"
    exit 1
}

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

PROM_LISTEN_ADDRESS=""
PROXY_ADDRESS=""
NODE_ADDRESS=""
NODE_PORT=""
SENSORS=""
TSDB_RETENTION_TIME=""

if [ "$#" -lt 10 ]; then
  echo -e "\x1b[31m10 arguments are needed, $# provided.\x1b[0m"
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prom-listen-address)
            PROM_LISTEN_ADDRESS="$2"
            shift 2
            ;;
        --proxy-address)
            PROXY_ADDRESS="$2"
            shift 2
            ;;
        --node-address)
            NODE_ADDRESS="$2"
            shift 2
            ;;
        --node-port)
            NODE_PORT="$2"
            shift 2
            ;;
        --sensors)
            SENSORS="$2"
            shift 2
            ;;
        --tsdb-retention)
            TSDB_RETENTION_TIME="$2"
            shift 2
            ;;
        *)
            echo -e "\x1b[31mError: Unknown argument $1\x1b[0m"
            usage
            ;;
    esac
done

if [[ -f /etc/systemd/system/prometheus.service ]]; then 
    systemctl stop prometheus.service
    systemctl disable prometheus.service
    rm /etc/systemd/system/prometheus.service
    systemctl daemon-reload
    echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
fi

wget --quiet https://github.com/prometheus/prometheus/releases/download/v3.1.0/prometheus-3.1.0.linux-${ARCH}.tar.gz
tar xf prometheus-3.1.0.linux-${ARCH}.tar.gz

touch prometheus.yml
IFS=',' read -ra SENSOR_ARRAY <<< "$SENSORS"
SENSOR_LIST=$(printf '"%s",' "${SENSOR_ARRAY[@]}")
SENSOR_LIST=${SENSOR_LIST%,}

echo "global:
  scrape_interval: 15s
scrape_configs:
  - job_name: node $NODE_ADDRESS:$NODE_PORT 
    static_configs:
      - targets: [\"$PROXY_ADDRESS\"]
    http_headers:
      Address: 
        values: [\"$NODE_ADDRESS\"]
      Port: 
        values: [\"$NODE_PORT\"]
      Sensor:
        values: [$SENSOR_LIST]" >> ./prometheus.yml

./prometheus-3.1.0.linux-${ARCH}/promtool check config prometheus.yml
rm -rf /opt/prometheus
mkdir -p /opt/prometheus
mv ./prometheus.yml /opt/prometheus/prometheus.yml
mv ./prometheus-3.1.0.linux-${ARCH}/prometheus /opt/prometheus/prometheus

touch /etc/systemd/system/prometheus.service
echo "
[Unit]
Description=prometheus Node Service
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/prometheus/prometheus --web.listen-address=\"$PROM_LISTEN_ADDRESS\" --storage.tsdb.retention.time $TSDB_RETENTION_TIME --config.file=./prometheus.yml 
WorkingDirectory=/opt/prometheus
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/prometheus.service

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

mv ./prometheus-3.1.0.linux-${ARCH}/promtool /opt/prometheus/promtool
rm -rf prometheus*

systemctl status prometheus
