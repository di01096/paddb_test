#!/bin/bash

echo "==========================================="
echo "🌀 Waydroid 및 Weston 완전 제거 시작"
echo "==========================================="

# 1. 실행 중인 프로세스 및 세션 종료
echo "[*] 프로세스 및 세션 종료 중..."
sudo waydroid session stop &> /dev/null
sudo systemctl stop waydroid-container &> /dev/null
sudo pkill -9 waydroid &> /dev/null
sudo pkill -9 weston &> /dev/null

# 2. 패키지 및 설정 파일 삭제 (Purge)
echo "[*] 패키지 삭제 중 (waydroid, weston)..."
sudo apt purge -y waydroid weston dbus-x11 bridge-utils dnsmasq iptables iproute2
sudo apt autoremove -y

# 3. 저장소 목록 및 GPG 키 제거
echo "[*] 저장소 및 키 설정 제거 중..."
sudo rm -f /etc/apt/sources.list.d/waydroid.list
sudo rm -f /usr/share/keyrings/waydroid.gpg

# 4. 사용자 및 시스템 데이터 폴더 삭제 (주의: 모든 데이터 유실)
echo "[*] 데이터 폴더 삭제 중..."
sudo rm -rf /var/lib/waydroid
sudo rm -rf ~/.local/share/waydroid
sudo rm -rf ~/.cache/waydroid
sudo rm -rf /run/user/$(id -u)/wayland-1*

# 5. 네트워크 브릿지 흔적 제거
echo "[*] 네트워크 설정 초기화 중..."
sudo ip link delete waydroid0 &> /dev/null

echo "==========================================="
echo "[+] Waydroid 관련 모든 파일과 설정이 제거되었습니다."
echo "==========================================="
