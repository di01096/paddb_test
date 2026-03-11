#!/bin/bash

# --- 설정 ---
PYTHON_EXTRACT_SCRIPT="direct_extract_ubuntu.py"

echo "==========================================="
echo "🐉 PAD 데이터 자동 업데이트 (Waydroid 기반)"
echo "==========================================="

# 1. Waydroid 설치 확인
if ! command -v waydroid &> /dev/null; then
    echo "[!] Waydroid가 설치되어 있지 않습니다. waydroid_setup.sh를 먼저 실행하세요."
    exit 1
fi

# 2. Waydroid 세션 확인 및 시작
STATUS=$(waydroid status | grep "Session")
if [[ $STATUS == *"not running"* ]]; then
    echo "[*] Waydroid 세션을 시작합니다..."
    waydroid session start &
    sleep 10
else
    echo "[+] Waydroid 세션이 이미 실행 중입니다."
fi

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
