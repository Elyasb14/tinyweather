#!/bin/bash

echo -e "\x1b[32mBeginning the bootstrapping of tinyweather-node\x1b[0m"
zig build
echo -e "\x1b[32mBuilt tinyweather-node, executable in ./zig-out/bin/tinyweather-node\x1b[0m"

if [[ ! -d "/opt/tinyweather" ]]; then
    echo -e "\x1b[32mCreating directory:\x1b[0m \x1b[35m/opt/tinyweather\x1b[0m"
    mkdir /opt/tinyweather
fi

echo -e "\x1b[32mMoving executable ./zig-out/bin/tinyweather-node to /opt/tinyweather/tinyweather-node\x1b[0m"
cp ./zig-out/bin/tinyweather-node /opt/tinyweather
