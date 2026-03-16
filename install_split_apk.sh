#!/bin/bash

# --- 설정 ---
WAYDROID_IP="192.168.240.112"
# 설치할 APK 조각들 리스트
APK_FILES=("pad_ko.apk" "pad_ko_1.apk" "pad_ko_2.apk" "pad_ko_3.apk" "pad_ko_4.apk")

echo "==========================================="
echo "📦 ADB install-multiple 기반 Split APK 설치"
echo "==========================================="

# 1. ADB 연결 확인
echo "[*] Waydroid ADB 연결 시도 ($WAYDROID_IP)..."
adb disconnect $WAYDROID_IP:5555 &> /dev/null
adb connect $WAYDROID_IP:5555
sleep 2

if ! adb devices | grep -q "$WAYDROID_IP:5555.*device"; then
    echo "[!] ADB 연결 실패! 'waydroid_setup.sh'가 정상 완료되었는지 확인하세요."
    exit 1
fi
echo "[+] ADB 연결 성공!"

# 2. 통합 설치 실행 (install-multiple)
echo "[*] 모든 APK 조각 통합 설치 시작..."
# -r: 재설치/업데이트, -g: 모든 권한 자동 승인
adb -s $WAYDROID_IP:5555 install-multiple -r -g "${APK_FILES[@]}"

if [ $? -eq 0 ]; then
    echo "==========================================="
    echo "[+] 축하합니다! 설치가 성공했습니다."
    echo "[*] 이제 './waydroid_launch_apk.sh'를 실행하세요."
    echo "==========================================="
else
    echo "[!] 설치 실패! 현재 폴더에 모든 APK 조각이 있는지 확인하세요."
    exit 1
fi
