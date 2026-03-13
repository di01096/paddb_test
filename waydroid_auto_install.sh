#!/bin/bash

# --- 설정 ---
PACKAGE_NAME="jp.gungho.padKO"
APK_FILE="pad_ko.apk"

echo "==========================================="
echo "🌀 Waydroid Official Guide 기반 설치 (Headless)"
echo "==========================================="

# 1. DNS 설정 (주소 인식 문제 방지)
echo "[*] DNS 최적화 (8.8.8.8)..."
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# 2. 공식 문서 가이드: 필수 패키지 설치
echo "[*] 필수 패키지 설치 중..."
sudo apt update
sudo apt install -y curl ca-certificates lsb-release weston python3-requests

# 3. 공식 문서 가이드: 저장소 자동 등록
# https://docs.waydro.id/usage/install-on-desktops#official-script
echo "[*] Waydroid 공식 저장소 등록 시작..."
curl https://repo.waydroid.net | sudo bash

# 4. 패키지 설치 및 확인
echo "[*] Waydroid 패키지 설치 중..."
sudo apt update
sudo apt install -y waydroid

if ! command -v waydroid &> /dev/null; then
    echo "[!] Waydroid 설치에 실패했습니다."
    exit 1
fi

# 5. 컨테이너 서비스 시작
echo "[*] Waydroid 컨테이너 서비스 시작..."
sudo systemctl enable --now waydroid-container

# 6. 공식 문서 가이드: 초기화 (GAPPS 버전 권장)
# 이미 초기화된 경우를 체크하여 중복 다운로드 방지
if ! waydroid status | grep -q "Initialized: Yes"; then
    echo "[*] 안드로이드 시스템 이미지 다운로드 중 (수 분 소요)..."
    sudo waydroid init -s GAPPS -f
else
    echo "[+] 시스템 이미지가 이미 존재합니다."
fi

# 7. SSH(TTY) 환경을 위한 가상 그래픽 세션 가동
echo "[*] 가상 그래픽 세션(Weston) 구성 중..."
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1

# 기존 찌꺼기 정리 후 Weston 실행 (Headless)
sudo pkill -9 weston &> /dev/null
rm -f $XDG_RUNTIME_DIR/wayland-1*
weston --backend=headless-backend.so --socket=wayland-1 --width=1080 --height=1920 &
sleep 5

# 8. Waydroid 세션 시작
echo "[*] Waydroid 세션 시작..."
waydroid session start &
sleep 20

# 9. APK 설치 및 보안 설정
if [ -f "$APK_FILE" ]; then
    echo "[*] APK 설치 진행: $APK_FILE"
    waydroid app install "$APK_FILE"
    echo "[+] 설치 성공!"
else
    echo "[!] $APK_FILE 파일이 없어 설치를 건너뜁니다."
fi

# Root 탐지 우회 프로퍼티 주입
echo "[*] 보안 우회(Root Hiding) 설정 중..."
waydroid shell setprop ro.debuggable 0
waydroid shell setprop ro.secure 1
waydroid shell setprop ro.build.tags release-keys

echo "==========================================="
echo "[+] 모든 공식 절차 완료!"
echo "[*] 'waydroid status'로 실행 여부를 확인하세요."
echo "==========================================="
