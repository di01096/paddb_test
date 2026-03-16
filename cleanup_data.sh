#!/bin/bash

CONTAINER_NAME="redroid"

echo "==========================================="
echo "🌀 Redroid 자원 정리 (Cleanup)"
echo "==========================================="

# 1. 컨테이너 중지
if [ "$(sudo docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "[*] 컨테이너 중지 중 ($CONTAINER_NAME)..."
    sudo docker stop $CONTAINER_NAME &> /dev/null
fi

# 2. ADB 연결 해제
echo "[*] ADB 연결 해제 중..."
adb disconnect localhost:5555 &> /dev/null

echo "==========================================="
echo "[+] 모든 자원이 정리되었습니다."
echo "==========================================="
