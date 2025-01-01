# To Run a Proxy

You will need to install the following dependencies

- zig version 0.13.0 [link](https://ziglang.org/learn/getting-started/)
- nginx [link](https://nginx.org/)
- go version 1.17 or greater [link](https://go.dev/doc/install)
- npm version 7 or greater

## Installing Prometheus

There is a script, `scripts/bootstrap_prometheus.sh`. This builds prometheus from source (warning this takes a while) and starts prometheus as a systemd service.

## Installing the proxy

There is a sript `scripts/bootstrap_proxy.sh`. This will start `tinyweather-proxy` as a systemd service. 

## NGINX proxies

For prometheus to be able to talk to nodes through the proxy, we need to be able to pass custom headers to the proxy. Unfortunately Prometheus doesn't support this, so we need to have nginx between prometheus and the proxy. There is a script that will install a shell version of what you want here, it is located at `./scripts/bootstrap_nginx.sh`. You should read that script and make sure the configs make sense for what you are trying to do.  

# BASIC TINYWEATHER USAGE

The first thing you need is zig. From there, build the project. To see what's happening there read `build.zig`. To build the project you can run 

```bash
zig build -Doptimize=ReleaseFast
```

To start, you need to spin up a node. Tinyweather stations run the node software (node.zig). The node is responsible for serving sensor data. To run a node, use the following command: 

```bash
./zig-out/bin/tinyweather-node --address 127.0.0.1 --port 8080

# you should see this
info: Node TCP Server listening on: 127.0.0.1:8080
```

This will start a tcp server listening on the port you pass it.

Then, you need to set up a proxy. The proxys job is to take in requests for sensor data, ask a node for that sensor data, and send it back to the client. To start a proxy, run the following:

```bash
./zig-out/bin/tinyweather-proxy --listen-addr 127.0.0.1 --listen-port 8081 

# you should see this
info: Proxy TCP Server listening on: 127.0.0.1:8081
```

Currently, you can make an http request to the proxy at the endpoint /metrics and you will get a prometheus readable string of sensor data back. You define what sensor data you want with http headers, the following example gets RainTotalAcc and Temp: 

```bash
curl localhost:8081/metrics -H "sensor:RainTotalAcc" -H "sensor:Temp" -H "address:127.0.0.1" -H "port:8080" 

# you might see something like this

# HELP RainTotalAcc RainTotalAcc
# TYPE RainTotalAcc gauge
RainTotalAcc nan

# HELP Temp Temp
# TYPE Temp gauge
Temp 17.13
```

