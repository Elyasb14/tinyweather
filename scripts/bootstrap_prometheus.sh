#! /bin/bash

ARCH=$(uname -m)

if [[ $ARCH == 'x86_64' ]]; then
    ARCH=$amd64
fi

if [ $# -ne 1 ]; then
    echo -e "\x1b[31mError: Please provide the web listen address.\x1b[0m"
    echo -e "\x1b[33mUsage: $0 <web-listen-address>\x1b[0m"
    echo -e "\x1b[33mExample: $0 10.0.2.14:9090\x1b[0m"
    exit 1
fi

WEB_LISTEN_ADDRESS=$1

if [[ -f /etc/systemd/system/prometheus.service ]]; then 
    systemctl stop prometheus.service
    systemctl disable prometheus.service
    rm /etc/systemd/system/prometheus.service
    systemctl daemon-reload
    echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"
fi

wget --quiet https://github.com/prometheus/prometheus/releases/download/v3.1.0/prometheus-3.1.0.linux-$ARCH.tar.gz
tar xf prometheus-3.1.0.linux-$ARCH.tar.gz
touch prometheus.yml

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

./prometheus-3.1.0.linux-$ARCH/promtool check config prometheus.yml
rm -rf /opt/prometheus
mkdir -p /opt/prometheus
mv ./prometheus.yml /opt/prometheus/prometheus.yml
mv ./prometheus-3.1.0.linux-$ARCH/prometheus /opt/prometheus/prometheus
touch /etc/systemd/system/prometheus.service
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

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
mv ./prometheus-3.1.0.linux-$ARCH/promtool /opt/prometheus/promtool
rm -rf prometheus*
systemctl status prometheus
