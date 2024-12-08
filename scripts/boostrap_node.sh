#! /bin/bash

echo "\x1b[32mBeginning the bootstrapping of tinyweather-node\x1b[0m"
zig build
echo "\x1b[32mBuilt tinyweather-node, executable in ./zig-out/bin/tinyweather-node\x1b[0m"
