#!/bin/bash

CONTAINER_NAME="redroid_v7"
ADB_TARGET="localhost:5555"
IMAGE_TAG="redroid/redroid:7.1.1-latest"

echo "==========================================="
echo "🐉 Redroid v7 (Android 7.1.1) 설치 및 설정"
echo "==========================================="

# 1. 기존 컨테이너 정리
echo "[*] 기존 컨테이너($CONTAINER_NAME) 제거 중..."
sudo docker stop $CONTAINER_NAME &> /dev/null
sudo docker rm $CONTAINER_NAME &> /dev/null

# 2. Redroid v7 컨테이너 실행
echo "[*] Redroid v7 컨테이너 실행 중..."
sudo docker run -d --privileged \
    --name $CONTAINER_NAME \
    -p 5555:5555 \
    $IMAGE_TAG \
    androidboot.redroid_fps=60 \
    androidboot.redroid_gpu_mode=guest \
    ro.product.model=SM-G950N \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung

echo "[*] 안드로이드 7.1.1 부팅 대기 중 (30초)..."
sleep 30

# 3. ADB 자동 연결
echo "[*] ADB 연결 시도: $ADB_TARGET"
adb disconnect $ADB_TARGET &> /dev/null
adb connect $ADB_TARGET
sleep 5

echo "==========================================="
echo "[+] Redroid v7 환경 구성 완료!"
echo "==========================================="
