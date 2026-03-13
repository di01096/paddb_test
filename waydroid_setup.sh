#!/bin/bash

echo "==========================================="
echo "🌀 Waydroid 시스템 설치 (Setup)"
echo "==========================================="

# 1. DNS 설정 (주소 인식 문제 방지)
echo "[*] DNS 최적화 (8.8.8.8)..."
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# 2. 공식 저장소 등록 및 패키지 설치
echo "[*] Waydroid 공식 저장소 등록 중..."
curl https://repo.waydroid.net | sudo bash
sudo apt update
sudo apt install -y waydroid weston dbus-x11

# 3. 초기화 (이미 설치되어 있지 않은 경우만)
if ! waydroid status | grep -q "Initialized: Yes"; then
    echo "[*] 안드로이드 시스템 이미지 다운로드 중 (수 분 소요)..."
    sudo waydroid init -s GAPPS -f
else
    echo "[+] 이미 초기화되어 있습니다."
fi

# 4. 컨테이너 서비스 활성화
sudo systemctl enable --now waydroid-container

echo "==========================================="
echo "[+] 설치 및 초기화 완료!"
echo "==========================================="
