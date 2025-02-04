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
