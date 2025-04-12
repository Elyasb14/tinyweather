#!/bin/bash

if [[ -f /opt/tinyweather/tinyweather-proxy ]]; then
    rm /opt/tinyweather/tinyweather-proxy
fi

zig build

mv zig-out/bin/tinyweather-proxy /opt/tinyweather/
systemctl restart tinyweather-proxy.service
systemctl enable tinyweather-proxy.service
systemctl status tinyweather-proxy.service 
