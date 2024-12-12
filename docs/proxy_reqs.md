# How To Run a Proxy

You will need to install the following dependencies

- zig version 0.13.0 [link](https://ziglang.org/learn/getting-started/)
- go version 1.17 or greater [link](https://go.dev/doc/install)
- npm version 7 or greater

## installing Prometheus

Turns out its really easy to build Prometheus from source. You also get `promtool` when you build the project, that'll come in handy later. Run the following to build the project 
```bash
# get and build prometheus
git clone https://github.com/prometheus/prometheus.git
cd prometheus
git checkout v3.0.1
make build

# creates a prometheus config
echo "global:
    scrape_interval: 15s

scrape_configs:
    - job_name: "prometheus"
      static_configs:
        - targets: ["localhost:8081"]" >> ./prometheus.yml

# checks that the config is valid
./promtool check config prometheus.yml
```

If everything above goes right, you can start the database!
```bash
./prometheus --config.file=./prometheus.yml
```

## Install as a daemon (using systemd)

There is a script, `scripts/bootstrap_prometheus.sh`
