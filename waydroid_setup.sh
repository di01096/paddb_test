#!/bin/bash

echo "==========================================="
echo "🌀 Waydroid 공식 설치 및 초기화 (Ubuntu)"
echo "==========================================="

# 1. 필수 도구 설치
sudo apt update
sudo apt install -y curl ca-certificates lsb-release

# 2. Waydroid 공식 자동 설치 스크립트 실행
# 이 스크립트는 배포판 버전을 자동으로 감지하여 최적의 저장소를 등록해줍니다.
echo "[*] Waydroid 저장소 등록 및 설치 시작..."
curl https://repo.waydroid.net | sudo bash

# 3. 실제 패키지 설치
if ! command -v waydroid &> /dev/null; then
    echo "[*] 패키지 설치 중..."
    sudo apt update
    sudo apt install -y waydroid
fi

# 4. 설치 확인 및 초기화
if command -v waydroid &> /dev/null; then
    echo "[+] Waydroid 설치 성공!"
    echo "[*] Waydroid 초기화 중 (이미지 다운로드 - 수 분 소요)..."
    # GAPPS(구글 서비스 포함) 버전으로 초기화
    sudo waydroid init -s GAPPS -f
    
    # 서비스 시작
    sudo systemctl enable --now waydroid-container
    echo "==========================================="
    echo "[!] 이제 터미널에서 'waydroid session start'를 실행하여 세션을 띄우세요."
    echo "==========================================="
else
    echo "[!] Waydroid 설치에 실패했습니다. 시스템 환경(Ubuntu 버전 등)을 확인해 주세요."
    exit 1
fi
