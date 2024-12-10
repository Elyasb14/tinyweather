#! /bin/bash

echo -e "\x1b[33mBootstrapping Prometheus on system"


# WARNING: this needs npm (sigh) 
# Ensure you have Go installed for ARM64
# Clone Prometheus
git clone https://github.com/prometheus/prometheus.git
cd prometheus

# Build specifically for ARM64
GOOS=linux GOARCH=arm64 make build
