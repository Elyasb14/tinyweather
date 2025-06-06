# TWNET

The network architecture and documentation for the **TinyWeather Network (TWNET)**.

## Overview

TWNET is built around a lightweight [WireGuard](https://www.wireguard.com) VPN. Nodes act as "peers" and connect to centralized "core" routers over encrypted tunnels. These routers provide access to services like proxies and time-series databases (TSDBs).

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

Start with a fresh mikrotik router by running `/system/reset-configuration`. 

#### Create Interface and Assign Address

```shell
/interface/wireguard/add name=wireguard1 listen-port=13231
/ip/address/add address=10.0.3.1/24 interface=wireguard1
```

#### Add Peer (`node1`)

```shell
/interface/wireguard/peers/add interface=wireguard1 public-key=<node1-publickey> allowed-address=10.0.3.2/32 endpoint-port=14008
```

#### View Peer Info

```shell
/interface/wireguard/peers/print
```

Output example:

```
Columns: INTERFACE, PUBLIC-KEY, ENDPOINT-PORT, ALLOWED-ADDRESS
# INTERFACE   PUBLIC-KEY               ENDPOINT-PORT  ALLOWED-ADDRESS
0 wireguard1  <node1-publickey>=       14008          10.0.3.2/32
```

If you have a stock mikrotik firewall you need to add the following rule to the firewall

```shell
/ip firewall filter add chain=input protocol=udp dst-port=13231 action=accept comment="Allow WireGuard"
/ip firewall filter add chain=input connection-state=established,related action=accept comment="Allow established/related"
/ip firewall filter add chain=input src-address=10.0.3.0/24 action=accept comment="Allow WG subnet"
```

## Subnet Roles and Addressing Strategy

- **Router uses `/24`** to allow routing across the full subnet (`10.0.3.0/24`).
- **Node uses `/32`** since it's a single host address within the VPN.

This allows the router to route traffic between nodes and to shared services (e.g., DNS, proxies, TSDBs) while keeping node configurations simple and secure.

## Future Scaling

- Add a second core router using a new subnet like `10.0.4.0/24`.
- Nodes can be reassigned to new subnets if load balancing or failover is needed.
- Possible use of dynamic routing (e.g., BGP) if multi-core support becomes complex.

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

## Security Considerations

- Always keep private keys secret.
- Use `AllowedIPs` carefully—setting it to `0.0.0.0/0` routes **all** traffic through the VPN, including DNS.
- Consider firewall rules on the router to isolate nodes if needed.
