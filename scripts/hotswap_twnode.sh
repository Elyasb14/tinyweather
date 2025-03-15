#! /bin/bash

if [[ -f /opt/tinyweather/tinyweather-node ]]; then
    rm /opt/tinyweather/tinyweather-node 
fi

zig build

mv zig-out/bin/tinyweather-node /opt/tinyweather/
systemctl restart tinyweather-node.service
