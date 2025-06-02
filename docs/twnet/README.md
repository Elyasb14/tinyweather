# TWNET

The network architecture and documentation for the **TinyWeather Network (TWNET)**.

## Overview

TWNET is built around a lightweight [WireGuard](https://www.wireguard.com) VPN. Nodes act as "peers" and connect to centralized "core" routers over encrypted tunnels. These routers provide access to services like proxies and time-series databases (TSDBs). We also have dynamic routing via OSPF.

## WireGuard Topology

Each VPN tunnel between a **core router** and a **node** is defined using the address space `10.0.3.0/24`.

- Each **core router** gets a unique `/24` subnet.
  - Example: `10.0.3.0/24` for `router1`, `10.0.4.0/24` for `router2`, etc.
- Each **node** is assigned a single `/32` IP from that subnet.
- The router listens on a static port and is the endpoint for multiple node tunnels.

### Example: `router1` and `node1`

#### Addressing
- `router1`: `10.0.3.1/24`
- `node1`: `10.0.3.2/32`

#### Key Exchange
- Each side generates its own private/public key pair.
    - generate that pair on the node by running `wg genkey | tee privatekey | wg pubkey > publickey`
- Public keys are exchanged and used to authenticate the tunnel.

### `node1` WireGuard Config (Linux)

Install wireguard however you want. On Ubuntu you can run the following

```bash
sudo apt update -y && sudo apt upgrade -y
sudo apt install wireguard-tools -y
```
Then, you can add the following configuration to `/etc/wireguard/wg0.conf`:

```ini
[Interface]
PrivateKey = <node1-privatekey>
ListenPort = 14008
Address = 10.0.3.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = <router1-publickey>
AllowedIPs = 0.0.0.0/0
Endpoint = <router1-public-ip>:13231
PersistentKeepalive = 25
```

Then run the following to bring this all up 

```bash
sudo chmod 600 /etc/wireguard/wg0.conf 
sudo wg-quick up wg0
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0
```

Then check the status using

```bash
sudo wg
```

If you need to troubleshoot and completely purge wg from your machine, you can run the following

```bash
sudo wg-quick down wg0
sudo ip link delete wg0  # If wg-quick down doesn't remove it
sudo systemctl stop wg-quick@wg0
sudo systemctl disable wg-quick@wg0
sudo rm -rf /etc/wireguard/*
```

#### Notes:
- `AllowedIPs = 0.0.0.0/0` routes **all traffic** through the VPN (i.e., full tunnel).
- `PersistentKeepalive = 25` helps maintain the tunnel through NAT/firewalls.

### `router1` WireGuard Config (MikroTik RouterOS)

To view an in depth wireguard mikrotk config, you can view [MIKROTIK.md](https://github.com/Elyasb14/tinyweather/blob/main/twnet/MIKROTIK.md). The summary being is that it exposes a wireguard interface for nodes to connect to and for proxies and tsdbs to get data from nodes. 

## Network Diagram

```plaintext
            +-------------+
            |  router1    | (10.0.3.1/24)
            | wg port 13231
            +-------------+
                ▲
         VPN Tunnel
                ▼
      +------------------+
      |     node1        |
      | 10.0.3.2/32       |
      | wg port 14008     |
      +------------------+
```

