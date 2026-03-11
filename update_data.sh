#!/bin/bash

# --- 설정 ---
CONTAINER_NAME="redroid"
ADB_TARGET="localhost:5555"
PYTHON_EXTRACT_SCRIPT="direct_extract_ubuntu.py"

echo "==========================================="
echo "🐉 PAD 데이터 자동 업데이트 (Redroid 기반)"
echo "==========================================="

# 1. Docker 컨테이너 상태 확인
if [ ! "$(sudo docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "[!] Redroid 컨테이너가 실행 중이지 않습니다."
    echo "[*] redroid_setup.sh를 먼저 실행하여 환경을 구축하세요."
    exit 1
fi

# 2. ADB 연결 확인
echo "[*] ADB 연결 확인: $ADB_TARGET"
adb connect $ADB_TARGET &> /dev/null
sleep 2

# 3. 데이터 추출 및 파싱 스크립트 실행
if [ -f "$PYTHON_EXTRACT_SCRIPT" ]; then
    echo "[*] 데이터 추출 및 JSON 변환 시작..."
    python3 $PYTHON_EXTRACT_SCRIPT
else
    echo "[!] $PYTHON_EXTRACT_SCRIPT 파일을 찾을 수 없습니다."
    exit 1
fi

# 4. 결과 확인
if [ -f "pad_monster_data.json" ]; then
    echo "==========================================="
    echo "[+] 업데이트 완료: pad_monster_data.json"
    ls -lh pad_monster_data.json
    echo "==========================================="
else
    echo "[!] 데이터 생성 실패!"
    exit 1
fi
