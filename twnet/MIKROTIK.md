# Mikrotik Router Config

This is an in detail doc about configuring routers for twnet. The first thing to do is start with a fresh router by running `/system/reset-configuration`.  


## Bridge & Loopback and some other misc stuff

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
/ip address add address=10.0.1.0/32 interface=loopback0
/routing/id add name=loopback0 id=10.0.1.0 select-from-vrf=main select-dynamic-id=only-loopback

#verification
/interface bridge print
/ip address print where interface=loopback
/routing/id print
```

Create interface lists used in firewall rules. Adjust interfaces accordingly:

```
/interface list add name=LAN
/interface list member add interface=bridge1 list=LAN
/interface list add name=WAN
/interface list member add interface=ether1 list=WAN

# IF YOU HAVE A STATIC PUBLIC IP
/ip address add address=<your_public_ip>/24 interface=ether1
/ip route add gateway=<your_gateway_ip>

# IF USING DHCP
/ip dhcp-client add interface=ether1 use-peer-dns=no add-default-route=yes
```

set correct NTP by running

```
/system clock set time-zone-name=UTC
/system ntp client set enabled=yes primary-ntp=132.163.96.1 secondary-ntp=132.163.97.1
```

Set dns addresses

```
/ip dns set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes
```
## Wireguard

Wireguard is used for vpn. First step is to make a wireguard interface called `wg0` and give it an address of `10.0.3.1/24`

```
/interface wireguard add name=wg0 listen-port=13231 # this command also generates the public and private key used in wireguard
/ip address add address=10.0.3.1/24 interface=wg0
```

Then we need to set up our peers with address 10.0.3.2/32 and port 14008

```
/interface wireguard peers add allowed-address=10.0.3.2/32 endpoint-port=14008 interface=wg0 name=wg0 persistent-keepalive=25s public-key=<peer_publickey>
```

Generate `peer_publickey` by running `wg genkey | tee privatekey | wg pubkey > publickey` on the peer. Verify with `/interface wireguard print`.

## OSPF

Ospf is used for dynamic routing. Create an area and ospf instance by running

```
/routing/ospf/area/ add name=backbone instance=backbone area-id=0.0.0.0 type=default
/routing/ospf/instance/add name=backbone version=2 vrf=main router-id=10.0.1.0
```

Create your interface templates 

```
/routing/ospf/interface-template/add interfaces=bridge area=backbone networks=10.0.2.0/24 type=broadcast
/routing/ospf/interface-template/add interfaces=wg0 area=backbone networks=10.0.3.0/24 type=broadcast
/routing/ospf/interface-template/add interfaces=loopback0 area=backbone networks=10.0.1.0/32 type=broadcast
```

## Firewall

Add the following rules to the firewall 

```
# delete all rules before
/ip firewall filter remove [find where dynamic=no]

# INPUT CHAIN
/ip firewall filter
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade comment="NAT for internet access"
add chain=input action=accept connection-state=established,related,untracked comment="defconf: accept established,related,untracked"
add chain=input action=accept protocol=udp dst-port=4500 comment="allow IPsec NAT"
add chain=input action=accept protocol=udp dst-port=500 comment="allow IKE"
add chain=input action=accept protocol=udp dst-port=1701 comment="allow l2tp"
add chain=input action=drop connection-state=invalid comment="defconf: drop invalid"
add chain=input action=accept protocol=icmp comment="defconf: accept ICMP"
add chain=input action=accept dst-address=127.0.0.1 comment="defconf: accept to local loopback (for CAPsMAN)"
add chain=input action=accept protocol=udp dst-port=13231 comment="Allow WireGuard"
add chain=input action=accept src-address=10.0.3.0/24 comment="Allow WG subnet"
add chain=input action=accept in-interface-list=LAN protocol=tcp dst-port=8291 comment="Allow Winbox from LAN"
add chain=input action=accept in-interface-list=LAN protocol=tcp dst-port=22 comment="Allow SSH from LAN"
add chain=input action=accept in-interface-list=LAN protocol=tcp dst-port=23 comment="Allow Telnet from LAN"
add chain=input action=drop in-interface-list=!LAN comment="Drop all input not from LAN"

# FORWARD CHAIN
add chain=forward action=accept ipsec-policy=in,ipsec comment="defconf: accept in ipsec policy"
add chain=forward action=accept ipsec-policy=out,ipsec comment="defconf: accept out ipsec policy"
add chain=forward action=fasttrack-connection connection-state=established,related hw-offload=yes comment="defconf: fasttrack"
add chain=forward action=accept connection-state=established,related,untracked comment="defconf: accept established,related, untracked"
add chain=forward action=drop connection-state=invalid comment="defconf: drop invalid"
add chain=forward action=drop connection-state=new connection-nat-state=!dstnat in-interface-list=WAN comment="defconf: drop all from WAN not DSTNATed"

# Get rid of unused services
/ip service disable telnet
/ip service disable ftp
```

