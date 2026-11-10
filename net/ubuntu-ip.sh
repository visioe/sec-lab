#!/bin/bash
# Ubuntu 目标/跳板机 · 192.168.56.20
set -e

echo "[1/3] 查看网卡（eth0/enp0s3=NAT, eth1/enp0s8=Host-Only）"
ip -br a

echo "[2/3] 配置 Host-Only 静态 IP（桌面版走 NetworkManager）"
sudo nmcli con mod "Wired connection 2" ipv4.addresses 192.168.56.20/24 ipv4.method manual
sudo nmcli con up "Wired connection 2"

# 服务器版（netplan）用下面这段替代上面的 nmcli：
# sudo tee /etc/netplan/99-lab.yaml <<'EOF'
# network:
#   version: 2
#   ethernets:
#     enp0s8:
#       addresses: [192.168.56.20/24]
# EOF
# sudo chmod 600 /etc/netplan/99-lab.yaml
# sudo netplan apply

echo "[3/3] 验证"
ip -br a
ping -c 2 192.168.56.1
ping -c 2 192.168.56.10
