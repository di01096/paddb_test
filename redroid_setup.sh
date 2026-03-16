#!/bin/bash

CONTAINER_NAME="redroid"
ADB_TARGET="localhost:5555"

echo "==========================================="
echo "🐉 Redroid 초정밀 보안 위장 및 설치 (S21 Mode)"
echo "==========================================="

# 1. 기존 컨테이너 완전 삭제
echo "[*] 기존 자원 정리 중..."
sudo docker stop $CONTAINER_NAME &> /dev/null
sudo docker rm $CONTAINER_NAME &> /dev/null
adb disconnect $ADB_TARGET &> /dev/null

# 2. Redroid 컨테이너 실행 (강화된 보안 위장 옵션)
echo "[*] Redroid 컨테이너 실행 (정밀 위장 옵션 주입)..."
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
    ro.product.name=o1qks \
    ro.product.device=o1q \
    ro.product.manufacturer=samsung \
    ro.build.fingerprint="samsung/o1qks/o1q:11/RP1A.200720.012/G991NKSU3AUK1:user/release-keys" \
    ro.build.description="o1qks-user 11 RP1A.200720.012 G991NKSU3AUK1 release-keys" \
    ro.boot.flash.locked=1 \
    ro.boot.verifiedbootstate=green \
    ro.expect.recovery_id=0x0000000000000000000000000000000000000000

echo "[*] 안드로이드 부팅 대기 중 (25초)..."
sleep 25

# 3. ADB 키 주입 및 연결
if [ -f ~/.android/adbkey.pub ]; then
    ADB_PUB_KEY=$(cat ~/.android/adbkey.pub)
    sudo docker exec -i $CONTAINER_NAME sh -c "mkdir -p /data/misc/adb && echo '$ADB_PUB_KEY' >> /data/misc/adb/adb_keys"
    sudo docker exec -i $CONTAINER_NAME sh -c "chown system:shell /data/misc/adb/adb_keys && chmod 640 /data/misc/adb/adb_keys"
fi
adb connect $ADB_TARGET
sleep 5

# 4. 루팅 흔적 완전 소거 (핵심: su 파일 삭제)
echo "[*] 보안 우회: 시스템 루트 바이너리(su) 완전 삭제 중..."
sudo docker exec -it $CONTAINER_NAME sh -c "mount -o remount,rw /"
sudo docker exec -it $CONTAINER_NAME sh -c "rm -f /system/bin/su /system/xbin/su /vendor/bin/su /sbin/su"
sudo docker exec -it $CONTAINER_NAME sh -c "rm -rf /system/etc/init/hw/init.debug.rc"

# 5. 추가 보안 설정 (USB 디버깅 상태 은폐)
echo "[*] 보안 우회: USB 디버깅 및 개발자 옵션 은폐..."
adb -s $ADB_TARGET shell settings put global adb_enabled 0
adb -s $ADB_TARGET shell settings put global development_settings_enabled 0

echo "==========================================="
echo "[+] Redroid 정밀 위장 구성 완료!"
echo "[*] 이제 './install_split_apk.sh'를 실행하세요."
echo "==========================================="
