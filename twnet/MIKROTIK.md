# Mikrotik Router Config

This is an in detail doc about configuring routers for twnet. The first thing to do is start with a fresh router by running `/system/reset-configuration`.  

## Bridge & Loopback

We need a bridge for a LAN and a loopback address for future dynamic routing purposes. Make a bridge with address `10.0.2.1/24` by running

```
# create a bridge and add some ports to it 
/interface bridge add name=bridge1
/interface bridge port add bridge=bridge1 interface=ether2
/interface bridge port add bridge=bridge1 interface=ether3
/ip address add address=10.0.2.1/24 interface=bridge1

# verification
/interface bridge print
/interface bridge port print
/ip address print
```

Make a bridge called loopback address by running

```
# make bridge interface called loopback0, give it an address, make it a routing id
/interface bridge add name=loopback0 disabled=no
/ip address add address=10.0.1.0/32 interface=loopback
/routing/id add name=loopback0 id=10.0.14.1 select-from-vrf=main select-dynamic-id=only-loopback

#verification
/interface bridge print
/ip address print where interface=loopback
/routing/id print
```

## Wireguard

Wireguard is used for vpn. First step is to make a wireguard interface called `wg0` and give it an address of `10.0.3.1/24`

```
/interface wireguard add name=wg0 listen-port=13231 # this command also generates the public and private key used in wireguard
/ip address add address=10.0.3.1/24 interface=wg0
```

Then we need to set up our peers with address 10.0.3.2/32 and port 14008

```
/interface wireguard peers add allowed-address=10.0.3.2/32 endpoint-port=14008 interface=wg0 name=wg0 persistent-keepalive=25s public-key={peer_publickey}
```

Generate `peer_publickey` by running `wg genkey | tee privatekey | wg pubkey > publickey` on the peer. Verify with `/interface wireguard print`.

## OSPF

Ospf is used for dynamic routing. Create an area and ospf instance by running

```
/routing/ospf/area/ add name=backbone instance=backbone area-id=0.0.0.0 type=default
/routing/ospf/instance/add name=backbone version=2 vrf=main router-id=10.0.1.0
```


