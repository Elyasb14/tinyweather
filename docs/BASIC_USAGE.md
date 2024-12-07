# BASIC TINYWEATHER USAGE

To start, you need to spin up a node. Tinyweather stations run the node software (node.zig). The node is responsible for relaying sensor data back to the client that requested it. To run a node, use the following command: 

```bash
zig build run-node

# you should see this
info: Node TCP Server listening on: 127.0.0.1:8080
```

This will start a tcp server listening on the port you pass it.

Then, you need to set up a proxy. The proxys job is to take in requests for sensor data, ask a node for that sensor data, and then reply to the request for data with the data it received. To start a proxy, run the following:

```bash
zig build run-proxy

# you should see this
info: Proxy TCP Server listening on: 127.0.0.1:8081
```

Currently, you can make an http request to the proxy at the endpoint /metrics and you will get a prometheus readable string of sensor data back. You define what sensor data you want with http headers, the following example gets RainTotalAcc: 

```bash
curl localhost:8081/metrics -H "sensor:RainTotalAcc"  

# you might see something like this
# HELP RainTotalAcc RainTotalAcc
# TYPE RainTotalAcc gauge
RainTotalAcc nan
```

