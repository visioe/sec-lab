@echo off
REM ============================================================
REM Windows 目标机 · 192.168.56.30
REM 用法：把本文件拷进靶机，右键"以管理员身份运行"
REM 注意：网卡名先用 ipconfig 确认真实名称（下面假定"以太网 2"）
REM ============================================================

echo [1/3] 当前网络配置
ipconfig

echo.
echo [2/3] 设置静态 IP 192.168.56.30
netsh interface ip set address name="以太网 2" static 192.168.56.30 255.255.255.0

echo.
echo [3/3] 放行 ICMP（不放行的话别人 ping 你会超时）并关闭防火墙
netsh advfirewall firewall add rule name="ICMPv4-In-Allow" protocol=icmpv4:8,any dir=in action=allow
netsh advfirewall set allprofiles state off

echo.
echo 完成。验证：
ipconfig
pause
