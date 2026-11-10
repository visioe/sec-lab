#!/bin/bash
# Kali 攻击机 · 192.168.56.10
# 用法：放到 Kali 里 chmod +x 后执行，或直接复制粘贴到终端
set -e

echo "[1/4] 查看网卡（应为 eth0=NAT, eth1=Host-Only）"
ip -br a

echo "[2/4] 配置 Host-Only 静态 IP"
sudo nmcli con mod "Wired connection 2" ipv4.addresses 192.168.56.10/24 ipv4.method manual
sudo nmcli con up "Wired connection 2"

echo "[3/4] 换清华源（默认源在国外，慢到不可用）"
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
echo "deb https://mirrors.tuna.tsinghua.edu.cn/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

echo "[4/4] 验证"
sudo apt update
ip -br a
ping -c 2 192.168.56.1
