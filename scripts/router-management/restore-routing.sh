#!/usr/bin/env bash
# Emergency routing restore script

echo "=== Current IP Forwarding Status ==="
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding

echo -e "\n=== Enabling IP Forwarding ==="
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

echo -e "\n=== Current Routing Table ==="
ip route show

echo -e "\n=== Current nftables Rules ==="
nft list ruleset

echo -e "\n=== Flushing and Restoring Basic nftables ==="
nft flush ruleset
nft add table inet filter
nft add chain inet filter forward { type filter hook forward priority 0\; policy accept\; }
nft add chain inet filter input { type filter hook input priority 0\; policy accept\; }
nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100\; }
nft add rule ip nat postrouting oifname "router-wan" masquerade

echo -e "\n=== New nftables Rules ==="
nft list ruleset

echo -e "\n=== Testing Connectivity ==="
ping -c 2 1.1.1.1 || echo "Still cannot ping 1.1.1.1"

echo -e "\n=== If still broken, restarting systemd-networkd ==="
systemctl restart systemd-networkd
sleep 2
ping -c 2 1.1.1.1 || echo "Still cannot ping after networkd restart"
