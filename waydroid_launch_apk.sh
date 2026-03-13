#!/bin/bash

# --- 설정 ---
PACKAGE_NAME="jp.gungho.padKO"
APK_FILE="pad_ko.apk"

echo "==========================================="
echo "🌀 Waydroid 가상 세션 가동 및 APK 자동 실행"
echo "==========================================="

# 1. 환경 변수 및 가상 디스플레이 설정
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export XDG_SESSION_TYPE=wayland

# 2. 가상 그래픽 서버(Weston) 리셋 및 가동
echo "[*] 가상 그래픽 서버(Weston) 시작 중..."
sudo pkill -9 weston &> /dev/null
rm -f $XDG_RUNTIME_DIR/wayland-1*
weston --backend=headless-backend.so --socket=wayland-1 --width=1080 --height=1920 &
sleep 5

# 3. Waydroid 세션 시작 및 준비 대기
echo "[*] Waydroid 세션 시작 및 부팅 대기 (최대 60초)..."
waydroid session start &

# 부팅 완료 메시지 감시
timeout 60 bash -c 'until waydroid status | grep -q "RUNNING"; do sleep 2; done'

if waydroid status | grep -q "RUNNING"; then
    echo "[+] 안드로이드 시스템 준비 완료!"
else
    echo "[!] 부팅 시간이 초과되었습니다. 상태를 확인하세요."
    exit 1
fi

# 4. APK 설치 (기존에 있으면 스킵 또는 업데이트)
if [ -f "$APK_FILE" ]; then
    echo "[*] APK 설치 진행 중: $APK_FILE"
    waydroid app install "$APK_FILE"
fi

# 5. 보안 우회 설정 (sudo 사용)
echo "[*] 보안 우회 설정 주입 중..."
sudo waydroid shell setprop ro.debuggable 0
sudo waydroid shell setprop ro.secure 1
sudo waydroid shell setprop ro.build.tags release-keys

# 6. 게임 강제 실행
echo "[*] 게임 실행: $PACKAGE_NAME"
waydroid app launch $PACKAGE_NAME

echo "==========================================="
echo "[+] 모든 프로세스가 가동되었습니다!"
echo "[*] 20초 후 매크로 명령어로 다운로드를 시작하세요."
echo "==========================================="

