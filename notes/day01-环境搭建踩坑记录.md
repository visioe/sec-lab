# Day 01 · 从零搭一套四机安全实验环境：我踩的 5 个坑

> 2026-11-10 ｜ 大一第一学期 ｜ 环境：Windows 10 22H2 / i7-13700KF / VirtualBox 7.2.22

## 为什么要自己搭

看教程时觉得"装个虚拟机而已"，动手才发现——**卡的从来不是安装，是网络**。
目标很明确：四台机器（Kali、Ubuntu、Windows、Metasploitable）在同一个隔离网段里互相能通，同时都能上网更新工具。这篇文章记录我踩的 5 个坑和最终方案，给同样从零开始的自己留个档案。

## 最终拓扑

- 攻击机 kali：`192.168.56.10`
- 跳板/目标 target-ubuntu：`192.168.56.20`
- Windows 目标 target-win10：`192.168.56.30`
- 经典靶机 metasploitable：`192.168.56.40`
- 宿主机 Host-Only 网卡：`192.168.56.1`

**每台虚拟机两块网卡**：

| 网卡 | 模式 | 用途 |
|---|---|---|
| 1 | NAT | 出网：`apt update`、访问 GitHub |
| 2 | Host-Only | 内网：虚拟机互打，宿主机也能访问 |

## 坑 1：虚拟机之间 ping 不通

**现象**：两台机器都配了 `192.168.56.x`，互相 ping 全是 `Destination Host Unreachable`。

**原因**：VirtualBox 的 NAT 模式下，**每台虚拟机处在一个独立的私有网段**（通常 10.0.2.0/24），网关是 10.0.2.2。它们彼此完全不可见——NAT 是"每台机器各有一个独立出口"，不是"大家连在同一个交换机上"。

**解法**：给每台加第二块网卡，模式选 **Host-Only**（只与宿主机通信的虚拟交换机）。

```powershell
VBoxManage modifyvm "kali" --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"
```

**经验**：只要看到"虚拟机互 ping 不通"，先问自己一句——它们真的在同一个二层网络里吗？

## 坑 2：Windows 靶机能上网，但别人 ping 不通它

**现象**：Windows 目标机能正常上网，Kali 上也 `arping` 得到它，就是 `ping` 超时。

**原因**：Windows 防火墙默认丢弃 ICMP Echo Request。这不是网络问题，是主机防火墙策略。

**解法**（靶机管理员 CMD）：

```cmd
netsh advfirewall firewall add rule name="ICMPv4-In-Allow" protocol=icmpv4:8,any dir=in action=allow
netsh advfirewall set allprofiles state off
```

**注意**：关防火墙只在**隔离实验网段**里做。真实环境里关防火墙是事故。

## 坑 3：Kali 里 `apt update` 卡住不动

**现象**：`apt update` 停在 `0% [Connecting to http.kali.org]`，十分钟没动静。

**原因**：默认源在境外。

**解法**：

```bash
echo "deb https://mirrors.tuna.tsinghua.edu.cn/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list
sudo apt update
```

顺带一个效率经验：**Kali 直接用官网的预构建 VirtualBox 镜像**（`kali-linux-*-virtualbox-amd64.7z`），解压双击导入即可，省掉 40 分钟装系统的时间。默认账号 `kali/kali`，第一件事是 `passwd` 改密码。

## 坑 4：`.7z` 双击打不开

**现象**：Windows 10 双击 7z 文件提示"无法打开此文件"。

**原因**：Win10 不自带 7z 支持（Win11 23H2 之后才内置）。

**解法**：装 7-Zip，或 `winget install 7zip.7zip`。

## 坑 5：四台全开，机器卡死

**现象**：同时启动 4 台虚拟机，宿主机风扇狂转，操作延迟到不可用。

**原因**：内存超分。4+4+4+1 = 13 GB，加上宿主机的系统占用，超出物理内存后开始疯狂换页。

**解法**：

- Windows 靶机内存降到 3072 MB（实验够用）
- 平时只同时开 **Kali + Metasploitable** 两台（这才是最常见的实验组合）
- 给装好的干净系统**打快照**，坏了 30 秒回滚，别重装

```powershell
VBoxManage snapshot "kali" take "clean-install"
```

## 另外两个值得记的点

**Hyper-V 和 VirtualBox 抢 VT-x**。如果开着 WSL2 / Docker Desktop，`bcdedit` 里 `hypervisorlaunchtype` 是 `auto`，VirtualBox 会走 Hyper-V 兼容后端，性能约打七折。用 WSL2 就别关，不用可以关掉换性能。

**镜像来源**：Windows 只从微软评估中心或 Media Creation Tool 拿 ISO。第三方"纯净版/优化版"镜像塞后门是常态——在自己机器上养一个自带后门的靶机，是给自己挖坑。

## 验收

```bash
# Kali 内
ping -c 2 192.168.56.20
ping -c 2 192.168.56.30
ping -c 2 192.168.56.40
curl -I -s -o /dev/null -w "%{http_code}\n" https://www.baidu.com   # 期望 200
```

三条 ping 全通 + 出网 200，环境就算立起来了。

## 下一步

- 打 Metasploitable 2：`nmap -sV 192.168.56.40`，然后从 vsftpd 2.3.4 后门那个经典漏洞开始
- 学一条规矩：**每次开新靶机前先打快照**
- 把这次的脚本整理进 `sec-lab/net/`，下次换机器 10 分钟重建
