#!/bin/bash

# --- 설정 ---
PACKAGE_NAME="jp.gungho.padKO"
APK_FILE="pad_ko.apk"

echo "==========================================="
echo "🌀 Waydroid 통합 자동 설치 및 APK 세팅"
echo "==========================================="

# 1. DNS 문제 해결 (주소를 알아낼 수 없습니다 에러 방지)
echo "[*] 네트워크 설정(DNS) 최적화 중..."
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# 2. Waydroid 저장소 강제 등록 (가장 안정적인 Jammy 버전 사용)
echo "[*] Waydroid 저장소 등록 중..."
sudo apt update && sudo apt install -y curl ca-certificates lsb-release
curl -fsSL https://repo.waydroid.net/waydroid.gpg | sudo tee /usr/share/keyrings/waydroid.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydroid.net/ jammy main" | sudo tee /etc/apt/sources.list.d/waydroid.list

# 3. Waydroid 및 필수 도구 설치
echo "[*] Waydroid 및 가상 그래픽 서버(Weston) 설치 중..."
sudo apt update
sudo apt install -y waydroid weston dbus-x11 python3-requests

# 4. Waydroid 초기화 (안드로이드 이미지 다운로드)
if ! waydroid status | grep -q "Initialized: Yes"; then
    echo "[*] Waydroid 초기화 중 (수 분 소요)..."
    sudo waydroid init -s GAPPS -f
else
    echo "[+] Waydroid가 이미 초기화되어 있습니다."
fi

# 5. 가상 그래픽 환경(Headless) 구성
echo "[*] 가상 그래픽 세션 준비 중..."
sudo systemctl enable --now waydroid-container
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export $(dbus-launch)

# 기존 찌꺼기 제거 및 Weston 실행
sudo pkill -9 weston &> /dev/null
rm -f $XDG_RUNTIME_DIR/wayland-1*
weston --backend=headless-backend.so --socket=wayland-1 --width=1080 --height=1920 &
sleep 5

# 6. Waydroid 세션 시작
echo "[*] Waydroid 세션 시작 중..."
waydroid session start &
sleep 20

# 7. APK 설치
if [ -f "$APK_FILE" ]; then
    echo "[*] APK 설치 중: $APK_FILE"
    waydroid app install "$APK_FILE"
    echo "[+] 설치 완료!"
else
    echo "[!] $APK_FILE 파일이 없습니다. 먼저 APK를 준비해 주세요."
fi

# 8. 보안 설정 (Root 탐지 우회)
echo "[*] 보안 우회 설정 주입 중..."
waydroid shell setprop ro.debuggable 0
waydroid shell setprop ro.secure 1
waydroid shell setprop ro.build.tags release-keys

echo "==========================================="
echo "[+] 모든 작업이 완료되었습니다!"
echo "[*] 이제 'waydroid app launch $PACKAGE_NAME'으로 실행 가능합니다."
echo "==========================================="
