#!/bin/bash

# --- 설정 ---
CONTAINER_NAME="redroid"
ADB_TARGET="localhost:5555"

echo "==========================================="
echo "[*] 자원 정리 시작 (수동)"
echo "==========================================="

# 1. ADB 연결 해제
if command -v adb &> /dev/null; then
    echo "[*] ADB 연결 해제 ($ADB_TARGET)..."
    adb disconnect $ADB_TARGET &> /dev/null
else
    echo "[!] ADB가 설치되어 있지 않습니다. 해제를 건너뜁니다."
fi

# 2. Docker 컨테이너 중지
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "[*] Docker 컨테이너 중지 ($CONTAINER_NAME)..."
    docker stop $CONTAINER_NAME &> /dev/null
else
    echo "[!] 실행 중인 $CONTAINER_NAME 컨테이너가 없습니다."
fi

echo "==========================================="
echo "[+] 정리 완료."
echo "==========================================="
