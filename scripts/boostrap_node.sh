#!/bin/bash

if [[ -f /etc/systemd/system/tinyweather-node.service ]];then 
    systemctl stop tinyweather-node.service
    systemctl disable tinyweather-node.service
    rm /etc/systemd/system/tinyweather-node.service
    systemctl daemon-reload
    systemctl daemon-reload
fi

echo -e "\x1b[32mBeginning the bootstrapping of tinyweather-node\x1b[0m"
zig build
echo -e "\x1b[32mBuilt tinyweather-node, executable in ./zig-out/bin/tinyweather-node\x1b[0m"

if [[ ! -d "/opt/tinyweather" ]]; then
    echo -e "\x1b[32mCreating directory:\x1b[0m \x1b[35m/opt/tinyweather\x1b[0m"
    mkdir /opt/tinyweather
fi

if [[ ! -f /opt/tinyweather/tinyweather-node ]]; then
    rm /opt/tinyweather/tinyweather-node
fi

echo -e "\x1b[32mMoving executable ./zig-out/bin/tinyweather-node to /opt/tinyweather/tinyweather-node\x1b[0m"
mv ./zig-out/bin/tinyweather-node /opt/tinyweather

touch /etc/systemd/system/tinyweather-node.service

echo "
[Unit]
Description=Tinyweather Node Service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/opt/tinyweather/tinyweather-node
WorkingDirectory=/opt/tinyweather

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tinyweather-node.service

systemctl daemon-reload
systemctl start tinyweather-node
