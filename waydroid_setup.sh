#!/bin/bash

echo "==========================================="
echo "🌀 Waydroid 환경 구축 시작 (Ubuntu)"
echo "==========================================="

# 1. 필수 패키지 설치
sudo apt update
sudo apt install -y curl ca-certificates

# 2. Waydroid 저장소 추가 및 설치
export DISTRO=$(lsb_release -sc)
sudo curl https://repo.waydroid.net/waydroid.gpg > /usr/share/keyrings/waydroid.gpg
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydroid.net/ $DISTRO main" | sudo tee /etc/apt/sources.list.d/waydroid.list
sudo apt update
sudo apt install -y waydroid

# 3. Waydroid 초기화 (이미지 다운로드)
echo "[*] Waydroid 초기화 중 (시간이 다소 걸립니다)..."
sudo waydroid init -s GAPPS -f

# 4. 서비스 시작
sudo systemctl enable --now waydroid-container
waydroid session start &

echo "[+] Waydroid 설정 완료! 이제 게임을 설치할 수 있습니다."
