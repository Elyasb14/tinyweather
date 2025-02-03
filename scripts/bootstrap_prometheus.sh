#! /bin/bash

# Check if the web listen address argument is provided
if [ $# -ne 1 ]; then
    echo -e "\x1b[31mError: Please provide the web listen address.\x1b[0m"
    echo -e "\x1b[33mUsage: $0 <web-listen-address>\x1b[0m"
    echo -e "\x1b[33mExample: $0 10.0.2.14:9090\x1b[0m"
    exit 1
fi

# Store command line argument
WEB_LISTEN_ADDRESS=$1

if [[ -f /etc/systemd/system/prometheus.service ]]; then 
    systemctl stop prometheus.service
    systemctl disable prometheus.service
    rm /etc/systemd/system/prometheus.service
    systemctl daemon-reload
    echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
else
    echo -e "\x1b[32mNo existing prometheus service file found. Skipping removal steps.\x1b[0m"
fi

echo -e "\x1b[33mBootstrapping Prometheus on system"
echo -e "\x1b[33mGet and build prometheus\x1b[0m"
wget --quiet https://github.com/prometheus/prometheus/releases/download/v3.1.0/prometheus-3.1.0.linux-amd64.tar.gz
tar xf prometheus-3.1.0.linux-amd64.tar.gz
touch prometheus.yml
# creates a prometheus config
echo "global:
  scrape_interval: 15s
scrape_configs:
  - job_name: node \"10.0.2.13\" 
    static_configs:
      - targets: [\"10.0.2.14:8081\"]
    http_headers:
      Address: 
        values: [\"10.0.2.13\"]
      Port: 
        values: [\"8080\"]
      Sensor:
        values: [\"Temp\", \"RainTotalAcc\"]" >> ./prometheus.yml

# checks that the config is valid
./prometheus-3.1.0.linux-amd64/promtool check config prometheus.yml
rm -rf /opt/prometheus
echo -e "\x1b[33mPreparing /opt/prometheus directory...\x1b[0m"
mkdir -p /opt/prometheus
mv ./prometheus.yml /opt/prometheus/prometheus.yml
echo -e "\x1b[33mMoving newly built prometheus executable to /opt/prometheus\x1b[0m"
mv ./prometheus-3.1.0.linux-amd64/prometheus /opt/prometheus/prometheus
echo -e "\x1b[33mCreating systemd service file at /etc/systemd/system/prometheus.service...\x1b[0m"
touch /etc/systemd/system/prometheus.service
echo -e "\x1b[33mWriting service configuration to /etc/systemd/system/prometheus.service...\x1b[0m"
echo "
[Unit]
Description=prometheus Node Service
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/prometheus/prometheus --web.listen-address=\"$WEB_LISTEN_ADDRESS\" --config.file=./prometheus.yml 
WorkingDirectory=/opt/prometheus
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/prometheus.service
echo -e "\x1b[32mService configuration written to /etc/systemd/system/prometheus.service\x1b[0m"
echo -e "\x1b[33mReloading systemd daemon to recognize the new prometheus service...\x1b[0m"
systemctl daemon-reload
echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
echo -e "\x1b[33mStarting the prometheus service...\x1b[0m"
systemctl start prometheus
systemctl enable prometheus
echo -e "\x1b[32mprometheus service started.\x1b[0m"
mv ./prometheus-3.1.0.linux-amd64/promtool /opt/prometheus/promtool
rm -rf prometheus*
systemctl status prometheus
