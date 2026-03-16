#!/bin/bash

# --- 설정 ---
ADB_TARGET="localhost:5555"
# 설치할 APK 조각들 리스트
APK_FILES=("pad_ko.apk" "pad_ko_1.apk" "pad_ko_2.apk" "pad_ko_3.apk" "pad_ko_4.apk")
PACKAGE_NAME="jp.gungho.padKO"
MAIN_ACTIVITY="jp.gungho.padKO/.AppDelegate"

echo "==========================================="
echo "📦 Redroid Split APK 통합 설치 및 실행"
echo "==========================================="

# 1. ADB 연결 확인
echo "[*] ADB 연결 확인 ($ADB_TARGET)..."
adb connect $ADB_TARGET &> /dev/null
sleep 2

if ! adb devices | grep -q "$ADB_TARGET.*device"; then
    echo "[!] ADB 연결 실패! 'redroid_setup.sh'를 먼저 실행하세요."
    exit 1
fi

# 2. 통합 설치 (install-multiple)
echo "[*] 모든 APK 조각 통합 설치 시작..."
# -r: 기존 앱 유지/업데이트, -g: 모든 권한 자동 승인
adb -s $ADB_TARGET install-multiple -r -g "${APK_FILES[@]}"

if [ $? -eq 0 ]; then
    echo "[+] 설치 성공! 게임을 실행합니다."
    
    # 3. 게임 실행
    echo "[*] 앱 실행: $PACKAGE_NAME"
    adb -s $ADB_TARGET shell am start -n "$MAIN_ACTIVITY"
    
    echo "==========================================="
    echo "[+] 모든 작업 완료!"
    echo "==========================================="
else
    echo "[!] 설치 실패! 모든 APK 조각이 현재 폴더에 있는지 확인하세요."
    exit 1
fi
