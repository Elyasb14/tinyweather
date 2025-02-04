#! /bin/bash

if [[ -d /opt/grafana ]]; then 
  rm -rf /opt/grafana
fi

wget https://dl.grafana.com/oss/release/grafana-11.5.1.linux-arm64.tar.gz
tar -zxvf grafana-11.5.1.linux-arm64.tar.gz

rm -rf grafana-11.5.1.linux-arm64.tar.gz

mv grafana* /opt/grafana

if [[ -f /etc/systemd/system/grafana.service ]]; then 
  rm /etc/systemd/system/grafana.service
fi

touch /etc/systemd/system/grafana.service

echo "
[Unit]
Description=Grafana
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/grafana/bin/grafana-server
WorkingDirectory=/opt/grafana
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/grafana.service

systemctl start grafana.service
systemctl enable grafana.service
