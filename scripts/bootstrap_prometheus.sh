#!/bin/bash

# Function to display usage information
usage() {
    echo -e "\x1b[33mUsage: $0 \\"
    echo -e "  --web-listen-address <web-listen-address> \\"
    echo -e "  --node-address <node-address> \\"
    echo -e "  --target-address <target-address> \\"
    echo -e "  --node-port <node-port> \\"
    echo -e "  --node-sensors <sensor1,sensor2,...>\x1b[0m"
    echo -e "\x1b[33mExample: $0 \\"
    echo -e "  --web-listen-address 10.0.2.14:9090 \\"
    echo -e "  --node-address 10.0.2.13 \\"
    echo -e "  --target-address 10.0.2.14:8081 \\"
    echo -e "  --node-port 8080 \\"
    echo -e "  --node-sensors \"Temp,RainTotalAcc,Hum,Pres,Gas\"\x1b[0m"
    exit 1
}

# Initialize variables with default values
WEB_LISTEN_ADDRESS=""
NODE_ADDRESS=""
TARGET_ADDRESS=""
NODE_PORT=""
NODE_SENSORS=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --web-listen-address)
            WEB_LISTEN_ADDRESS="$2"
            shift 2
            ;;
        --node-address)
            NODE_ADDRESS="$2"
            shift 2
            ;;
        --target-address)
            TARGET_ADDRESS="$2"
            shift 2
            ;;
        --node-port)
            NODE_PORT="$2"
            shift 2
            ;;
        --node-sensors)
            NODE_SENSORS="$2"
            shift 2
            ;;
        *)
            echo -e "\x1b[31mError: Unknown argument $1\x1b[0m"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$WEB_LISTEN_ADDRESS" || -z "$NODE_ADDRESS" || -z "$TARGET_ADDRESS" || -z "$NODE_PORT" || -z "$NODE_SENSORS" ]]; then
    echo -e "\x1b[31mError: All arguments are required.\x1b[0m"
    usage
fi

# Determine architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

# Stop and remove existing Prometheus service if it exists
if [[ -f /etc/systemd/system/prometheus.service ]]; then 
    systemctl stop prometheus.service
    systemctl disable prometheus.service
    rm /etc/systemd/system/prometheus.service
    systemctl daemon-reload
    echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
fi

# Download Prometheus
wget --quiet https://github.com/prometheus/prometheus/releases/download/v3.1.0/prometheus-3.1.0.linux-${ARCH}.tar.gz
tar xf prometheus-3.1.0.linux-${ARCH}.tar.gz

# Create Prometheus configuration
touch prometheus.yml
echo "global:
  scrape_interval: 15s
scrape_configs:
  - job_name: node $NODE_ADDRESS
    static_configs:
      - targets: [\"$TARGET_ADDRESS\"]
    http_headers:
      Address: 
        values: [\"$NODE_ADDRESS\"]
      Port: 
        values: [\"$NODE_PORT\"]
      Sensor:
        values: [$(echo "$NODE_SENSORS" | sed "s/,/\", \"/g")]" >> ./prometheus.yml

# Validate configuration
./prometheus-3.1.0.linux-${ARCH}/promtool check config prometheus.yml

# Prepare Prometheus directories
rm -rf /opt/prometheus
mkdir -p /opt/prometheus
mv ./prometheus.yml /opt/prometheus/prometheus.yml
mv ./prometheus-3.1.0.linux-${ARCH}/prometheus /opt/prometheus/prometheus

# Create systemd service file
touch /etc/systemd/system/prometheus.service
echo "[Unit]
Description=Prometheus Node Service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/prometheus/prometheus --web.listen-address=\"$WEB_LISTEN_ADDRESS\" --config.file=/opt/prometheus/prometheus.yml 
WorkingDirectory=/opt/prometheus

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/prometheus.service

# Reload and start Prometheus service
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

# Move promtool and cleanup
mv ./prometheus-3.1.0.linux-${ARCH}/promtool /opt/prometheus/promtool
rm -rf prometheus*

# Check service status
systemctl status prometheus
