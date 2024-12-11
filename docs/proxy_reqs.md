# How To Run a Proxy

You will need to install the following dependencies

- zig version 0.13.0 [link](https://ziglang.org/learn/getting-started/)
- go version 1.17 or greater [link](https://go.dev/doc/install)
- npm version 7 or greater

## installing Prometheus

Turns out its really easy to build Prometheus from source. You also get `promtool` when you build the project, that'll come in handy later. Run the following to build the project 

```bash
git clone https://github.com/prometheus/prometheus.git
cd prometheus

git checkout v3.0.1

make build
./prometheus --config.file=your_config.yml

touch prometheus.yml

# paste this into the prometheus.yml file
"global:
    scrape_interval: 15s

scrape_configs:
    - job_name: "prometheus"
        static_configs:
        - targets: ["localhost:8081"]"

./promtool check config prometheus.yml

# if the command above succeeds run the following to start the database!
./prometheus --config.file=./prometheus.yml
```
