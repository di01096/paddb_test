#!/bin/bash

# --- 설정 ---
PACKAGE_NAME="jp.gungho.padKO"
MAIN_ACTIVITY="jp.gungho.padKO/.AppDelegate"

echo "==========================================="
echo "🌀 Waydroid 가상 세션 기동 및 앱 실행"
echo "==========================================="

# 1. 환경 변수 및 가상 디스플레이 설정
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export XDG_SESSION_TYPE=wayland

# 2. 가상 그래픽 서버(Weston) 가동
echo "[*] 가상 그래픽 서버(Weston) 시작..."
sudo pkill -9 weston &> /dev/null
rm -f $XDG_RUNTIME_DIR/wayland-1*
weston --backend=headless-backend.so --socket=wayland-1 --width=1080 --height=1920 &
sleep 5

# 3. Waydroid 세션 시작 및 부팅 대기
echo "[*] Waydroid 세션 시작 및 부팅 대기..."
waydroid session start &

# RUNNING 상태가 될 때까지 감시
timeout 60 bash -c 'until waydroid status | grep -q "RUNNING"; do sleep 2; done'

if waydroid status | grep -q "RUNNING"; then
    echo "[+] 안드로이드 시스템 준비 완료!"
else
    echo "[!] 부팅 시간이 초과되었습니다."
    exit 1
fi

# 4. 게임 실행 (이미 설치되어 있다고 가정)
echo "[*] 게임 실행: $PACKAGE_NAME"
waydroid app launch $PACKAGE_NAME

echo "==========================================="
echo "[+] 모든 프로세스 가동 완료!"
echo "==========================================="
