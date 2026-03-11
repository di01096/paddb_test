#!/bin/bash

CONTAINER_NAME="redroid"
ADB_TARGET="localhost:5555"
IMAGE_TAG="redroid/redroid:8.1.0-latest"

echo "==========================================="
echo "🐉 Redroid v8 (Android 8.1.0) 설치 및 보안 설정"
echo "==========================================="

# 1. 기존 컨테이너 정리
echo "[*] 기존 컨테이너($CONTAINER_NAME) 제거 중..."
sudo docker stop $CONTAINER_NAME &> /dev/null
sudo docker rm $CONTAINER_NAME &> /dev/null

# 2. Redroid 컨테이너 실행
echo "[*] Redroid 8.1.0 컨테이너 실행 중..."
sudo docker run -d --privileged \
    --name $CONTAINER_NAME \
    -p 5555:5555 \
    $IMAGE_TAG \
    androidboot.redroid_fps=60 \
    androidboot.redroid_gpu_mode=guest \
    ro.adb.secure=0 \
    ro.debuggable=0 \
    ro.secure=1 \
    ro.build.tags=release-keys \
    ro.build.type=user \
    ro.product.model=SM-G950N \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung

echo "[*] 안드로이드 8.1.0 부팅 대기 중 (30초)..."
sleep 30

# 3. ADB 자동 연결
echo "[*] ADB 연결 시도: $ADB_TARGET"
adb disconnect $ADB_TARGET &> /dev/null
adb connect $ADB_TARGET
sleep 5

# 4. 루트 권한 숨기기 (보안 우회)
echo "[*] 보안 우회: 시스템 루트 파일(su) 은폐 작업 중..."
sudo docker exec -it $CONTAINER_NAME sh -c "mount -o remount,rw / && [ -f /system/bin/su ] && mv /system/bin/su /system/bin/su_hide; [ -f /system/xbin/su ] && mv /system/xbin/su /system/xbin/su_hide" || true

# 5. 추가 보안 설정 (USB 디버깅 숨기기)
echo "[*] 보안 우회: ADB 디버깅 설정 숨김..."
adb -s $ADB_TARGET shell settings put global adb_enabled 0

echo "==========================================="
echo "[+] Redroid 환경 구성 완료! (Android 8.1.0)"
echo "[!] 이제 'python verify_and_install.py'를 실행하여 게임을 설치하세요."
echo "==========================================="
