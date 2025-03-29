# To Run a Node 

You will need to install the following dependencies

- zig version 0.13.0 [link](https://ziglang.org/learn/getting-started/)
- python3 >= version 3.11
- python3-venv python3-pip
 
## Installing the node software

There is a script located at `./scripts/bootstrap_node.sh`. This will build and install `tinyweather-node` as a systemd service. This script also creates a virtual python environment for the systemd service to run under. In this virtual environment it installs python dependencies that the node uses to get data from the bme680. Run the following command from the root of tinyweather to run a node that listens on 127.0.0.1:8080:

```bash
sudo ./scripts/bootstrap_node.sh 127.0.0.1 8080
```
