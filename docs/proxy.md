# To Run a Proxy

You will need to install the following dependencies

- zig version 0.14.0 [link](https://ziglang.org/learn/getting-started/)

## Installing Prometheus

There is a script, `scripts/bootstrap_prometheus.sh`. This pulls a prometheus release and installs it in a reasponable place. See script for details. This installs a basic `prometheus.yml` config file, you should edit it to do what you want.  

## Installing the proxy

There is a sript `scripts/bootstrap_proxy.sh`. This will start `tinyweather-proxy` as a systemd service. 
