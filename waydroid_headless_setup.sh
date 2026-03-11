#!/bin/bash

# --- 설정 ---
UBUNTU_CODENAME="jammy" # 24.04 등 최신 버전에서도 안정적인 설치를 위해 jammy 고정

echo "==========================================="
echo "🌀 Waydroid Headless 통합 설치 및 실행 (Ubuntu)"
echo "==========================================="

# 1. 필수 패키지 및 도구 설치
echo "[*] 필수 도구 설치 중..."
sudo apt update
sudo apt install -y curl ca-certificates lsb-release weston kmod net-tools

# 2. Waydroid 저장소 강제 등록 (Jammy 기반)
echo "[*] Waydroid 저장소 등록 중..."
curl -fsSL https://repo.waydroid.net/waydroid.gpg | sudo tee /usr/share/keyrings/waydroid.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydroid.net/ $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/waydroid.list

# 3. Waydroid 패키지 설치
echo "[*] Waydroid 설치 중..."
sudo apt update
sudo apt install -y waydroid

# 4. Waydroid 초기화 (GAPPS 포함 버전)
if ! command -v waydroid &> /dev/null; then
    echo "[!] Waydroid 설치 실패. 시스템 환경을 확인하세요."
    exit 1
fi

echo "[*] Waydroid 초기화 시작 (이미지 다운로드 - 수 분 소요)..."
sudo waydroid init -s GAPPS -f

# 5. 가상 그래픽 서버(Weston) 띄우기 (tty 환경 대응)
echo "[*] 가상 그래픽 세션(Weston) 시작..."
sudo systemctl enable --now waydroid-container
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Weston 백그라운드 실행 (Headless 백엔드)
weston --backend=headless-backend.so --socket=wayland-1 &
sleep 5
export WAYLAND_DISPLAY=wayland-1

# 6. Waydroid 세션 시작
echo "[*] Waydroid 세션 시작..."
waydroid session start &
sleep 20

# 7. 보안 우회 및 시스템 최적화 (Root 탐지 방지)
echo "[*] 보안 우회 프로퍼티 설정 중..."
waydroid shell setprop ro.debuggable 0
waydroid shell setprop ro.secure 1
waydroid shell setprop ro.build.tags release-keys
waydroid shell setprop ro.build.type user
waydroid shell setprop ro.adb.secure 0

echo "==========================================="
echo "[+] Waydroid 무인 설치 및 실행 완료!"
echo "[!] 이제 'python verify_and_install.py'를 실행하여 게임을 설치하세요."
echo "==========================================="
