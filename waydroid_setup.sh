#!/bin/bash

WAYDROID_IP="192.168.240.112"
HOST_GW="192.168.240.1"

echo "==========================================="
echo "🌀 Waydroid 통합 설치 및 네트워크/ADB 복구 (Android 13)"
echo "==========================================="

# 1. 시스템 패키지 설치
echo "[*] 필수 패키지 설치 중..."
sudo apt update && sudo apt install -y waydroid weston curl dbus-x11 net-tools

# 2. 호스트 네트워크 포워딩 및 NAT 설정 (인터넷 공유)
echo "[*] 호스트 NAT 설정 중..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o enp3s0 -j MASQUERADE
sudo iptables -A FORWARD -i enp3s0 -o waydroid0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i waydroid0 -o enp3s0 -j ACCEPT

# 3. Waydroid 서비스 시작 및 가상 디스플레이 기동
sudo systemctl enable --now waydroid-container
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-1
export XDG_SESSION_TYPE=wayland

echo "[*] 가상 그래픽 서버(Weston) 시작..."
sudo pkill -9 weston &> /dev/null
rm -f $XDG_RUNTIME_DIR/wayland-1*
weston --backend=headless-backend.so --socket=wayland-1 --width=1080 --height=1920 &
sleep 5

echo "[*] Waydroid 세션 시작 및 부팅 대기 (30초)..."
waydroid session start &
sleep 30

# 4. 안드로이드 내부 네트워크 및 라우팅 강제 설정
echo "[*] 안드로이드 내부 네트워크 정책 주입 중..."
sudo waydroid shell "ip addr flush dev eth0"
sudo waydroid shell "ip addr add $WAYDROID_IP/24 dev eth0"
sudo waydroid shell "ip link set eth0 up"
sudo waydroid shell "ip route add default via $HOST_GW dev eth0"
sudo waydroid shell "ip rule add from all lookup main pref 1"

# 5. ADB 보안 해제 및 인증 우회 (핵심)
echo "[*] ADB 인증 보안 해제 및 키 주입 중..."
sudo waydroid shell "setprop ro.adb.secure 0"
sudo waydroid shell "settings put global adb_enabled 1"

# 호스트의 ADB 공개키 주입
if [ -f ~/.android/adbkey.pub ]; then
    KEY_CONTENT=$(cat ~/.android/adbkey.pub)
    sudo waydroid shell "mkdir -p /data/misc/adb && echo '$KEY_CONTENT' >> /data/misc/adb/adb_keys"
    sudo waydroid shell "chown system:shell /data/misc/adb/adb_keys && chmod 640 /data/misc/adb/adb_keys"
    echo "[+] ADB 인증키 주입 완료."
else
    echo "[!] 호스트 ADB 키를 찾을 수 없습니다. 'adb devices'를 먼저 실행해 보세요."
fi

echo "==========================================="
echo "[+] 모든 설정이 완료되었습니다!"
echo "[*] 이제 './waydroid_launch_apk.sh'를 실행하세요."
echo "==========================================="
