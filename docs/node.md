# To Run a Node 

You will need to install the following dependencies

- zig version 0.14.0 [link](https://ziglang.org/learn/getting-started/)
- python3 >= version 3.11
- python3-venv python3-pip
 
## Installing the node software

There is a script located at `./scripts/bootstrap_node.sh`. This will build and install `tinyweather-node` as a systemd service. This script also creates a virtual python environment for the systemd service to run under. In this virtual environment it installs python dependencies that the node uses to get data from the bme680.  
