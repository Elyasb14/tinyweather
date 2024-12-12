#! /bin/bash

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
git clone https://github.com/prometheus/prometheus.git
cd prometheus
git checkout v3.0.1
make build

touch prometheus.yml

# creates a prometheus config
echo "global:
    scrape_interval: 15s

scrape_configs:
    - job_name: "prometheus"
      static_configs:
        - targets: ["localhost:8081"]" >> ./prometheus.yml

# checks that the config is valid
./promtool check config prometheus.yml

mv ./prometheus.yml /opt/prometheus/prometheus.yml

rm -rf /opt/prometheus

echo -e "\x1b[33mPreparing /opt/prometheus directory...\x1b[0m"
mkdir -p /opt/prometheus

echo -e "\x1b[33mMoving newly built prometheus executable to /opt/prometheus\x1b[0m"
mv ./prometheus /opt/prometheus/prometheus

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
ExecStart=/opt/prometheus/prometheus --config.file=./prometheus.yml 
WorkingDirectory=/opt/prometheus

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/prometheus.service
echo -e "\x1b[32mService configuration written to /etc/systemd/system/prometheus.service\x1b[0m"

echo -e "\x1b[33mReloading systemd daemon to recognize the new prometheus service...\x1b[0m"
systemctl daemon-reload
echo -e "\x1b[32mSystemd daemon reloaded successfully.\x1b[0m"

echo -e "\x1b[33mStarting the prometheus service...\x1b[0m"
systemctl start prometheus
echo -e "\x1b[32mprometheus service started.\x1b[0m"

cd ../ 
rm -rf prometheus

systemctl status prometheus

