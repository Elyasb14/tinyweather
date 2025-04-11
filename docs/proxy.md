# To Run a Proxy

You will need to install the following dependencies

- zig version 0.14.0 [link](https://ziglang.org/learn/getting-started/)

## Installing Prometheus

There is a script, `scripts/bootstrap_prometheus.sh`. This pulls a prometheus release and installs it in a reasponable place. See script for details. There are some flags you need to pass, here is an example for a very local setup, you can extrapolate further:

```bash
sudo ./scripts/bootstrap_prometheus.sh \
--prom-listen-address 127.0.0.1:9090 \
--proxy-address 127.0.0.1:8081 \
--node-address 127.0.0.1 \
--node-port 8080 \
--sensors "Temp,RainTotalAcc,Hum,Pres,Gas" \
--tsdb-retention 15d

```

## Installing the proxy

There is a sript `scripts/bootstrap_proxy.sh`. This will start `tinyweather-proxy` as a systemd service. Run the following command from the tinyweather root to run a proxy listening on 127.0.0.1:8081 

```bash
sudo ./scripts/bootstrap_proxy.sh --address 127.0.0.1 --port 8081
```
