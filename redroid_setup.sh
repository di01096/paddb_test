#!/bin/bash

CONTAINER_NAME="redroid"
ADB_TARGET="localhost:5555"

echo "==========================================="
echo "🐉 Redroid 통합 설치 및 보안 설정 (Ubuntu)"
echo "==========================================="

# 1. 기존 컨테이너 및 찌꺼기 제거
echo "[*] 기존 자원 정리 중..."
sudo docker stop $CONTAINER_NAME &> /dev/null
sudo docker rm $CONTAINER_NAME &> /dev/null
adb disconnect $ADB_TARGET &> /dev/null

# 2. Redroid 컨테이너 실행 (안드로이드 11, 보안 우회 옵션)
echo "[*] Redroid 컨테이너 실행 중..."
sudo docker run -d --privileged \
    --name $CONTAINER_NAME \
    -p 5555:5555 \
    redroid/redroid:11.0.0-latest \
    androidboot.redroid_fps=60 \
    androidboot.redroid_gpu_mode=guest \
    ro.adb.secure=0 \
    ro.debuggable=0 \
    ro.secure=1 \
    ro.build.tags=release-keys \
    ro.build.type=user \
    ro.product.model=SM-G991N \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung

echo "[*] 안드로이드 부팅 대기 중 (20초)..."
sleep 20

# 3. ADB 자동 연결
echo "[*] ADB 연결 시도: $ADB_TARGET"
adb connect $ADB_TARGET
sleep 5

# 4. 루트 권한 은폐 (퍼즐앤드래곤 보안 통과 핵심)
echo "[*] 보안 우회: 시스템 루트 파일(su) 은폐 작업 중..."
sudo docker exec -it $CONTAINER_NAME sh -c "mount -o remount,rw / && mv /system/bin/su /system/bin/su_hide && mv /system/xbin/su /system/xbin/su_hide"

# 5. USB 디버깅 상태 숨기기
echo "[*] 보안 우회: ADB 디버깅 설정 숨김..."
adb -s $ADB_TARGET shell settings put global adb_enabled 0

echo "==========================================="
echo "[+] Redroid 환경 구성 완료! (localhost:5555)"
echo "[*] 이제 './install_split_apk.sh'를 실행하세요."
echo "==========================================="
