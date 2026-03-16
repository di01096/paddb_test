#!/bin/bash

# --- 설정 ---
WAYDROID_IP="192.168.240.112"
# 설치할 APK 조각들 (현재 폴더에 있어야 함)
APK_FILES=("pad_ko.apk" "pad_ko_1.apk" "pad_ko_2.apk" "pad_ko_3.apk" "pad_ko_4.apk")
PACKAGE_NAME="jp.gungho.padKO"
MAIN_ACTIVITY="jp.gungho.padKO/.AppDelegate"

echo "==========================================="
echo "📦 ADB 기반 Split APK 통합 설치 및 실행"
echo "==========================================="

# 1. ADB 연결 확인
echo "[*] Waydroid ADB 연결 시도 ($WAYDROID_IP)..."
adb disconnect $WAYDROID_IP:5555 &> /dev/null
adb connect $WAYDROID_IP:5555
sleep 2

# 연결 상태 검증
if ! adb devices | grep -q "$WAYDROID_IP:5555.*device"; then
    echo "[!] ADB 연결 실패! 'waydroid_setup.sh'가 정상 완료되었는지 확인하세요."
    exit 1
fi
echo "[+] ADB 연결 성공!"

# 2. Split APK 통합 설치 (install-multiple)
echo "[*] 모든 APK 조각 통합 설치 시작..."
# -r: 기존 유지, -g: 권한 자동 승인
adb -s $WAYDROID_IP:5555 install-multiple -r -g "${APK_FILES[@]}"

if [ $? -eq 0 ]; then
    echo "[+] 설치 성공! 게임을 실행합니다."
    
    # 3. 게임 강제 실행
    echo "[*] 앱 실행: $PACKAGE_NAME"
    adb -s $WAYDROID_IP:5555 shell am start -n "$MAIN_ACTIVITY"
    
    echo "==========================================="
    echo "[+] 실행 완료! 20초 후 매크로를 돌려 다운로드를 시작하세요."
    echo "==========================================="
else
    echo "[!] 설치 실패! APK 파일들이 현재 폴더에 모두 있는지 확인하세요."
    exit 1
fi
