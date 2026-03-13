#!/bin/bash

# --- 설정 ---
PACKAGE_NAME="jp.gungho.padKO"
APK_FILE="pad_ko.apk"

echo "==========================================="
echo "🌀 Waydroid 가상 세션 기동 및 APK 설치"
echo "==========================================="

# 1. SSH 환경을 위한 가상 그래픽 세션(Weston) 구성
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export $(dbus-launch)

# 기존 프로세스 정리 후 가상 서버 실행
sudo pkill -9 weston &> /dev/null
rm -f $XDG_RUNTIME_DIR/wayland-1*
weston --backend=headless-backend.so --socket=wayland-1 --width=1080 --height=1920 &
sleep 5

# 2. Waydroid 세션 시작
echo "[*] Waydroid 세션 시작 중..."
waydroid session start &
sleep 20

# 3. APK 설치
if [ -f "$APK_FILE" ]; then
    echo "[*] APK 설치 진행: $APK_FILE"
    waydroid app install "$APK_FILE"
    echo "[+] 앱 설치 명령 완료."
else
    echo "[!] $APK_FILE 파일이 없습니다. 설치를 건너뜁니다."
fi

# 4. 보안 및 루트 은폐 설정 (RuntimeError 방지를 위해 sudo 추가)
echo "[*] 보안 우회 설정 주입 중 (Root 권한 사용)..."
sudo waydroid shell setprop ro.debuggable 0
sudo waydroid shell setprop ro.secure 1
sudo waydroid shell setprop ro.build.tags release-keys

echo "==========================================="
echo "[+] 모든 세션 및 설치 작업 완료!"
echo "[*] 이제 'waydroid status'로 실행 상태를 확인하세요."
echo "==========================================="
