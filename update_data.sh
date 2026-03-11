#!/bin/bash

# --- 설정 ---
CONTAINER_NAME="redroid"
ADB_TARGET="localhost:5555"
PYTHON_EXTRACT_SCRIPT="direct_extract_ubuntu.py"

echo "==========================================="
echo "🐉 PAD 데이터 자동 업데이트 시작"
echo "==========================================="

# 1. Docker 컨테이너 상태 확인 및 실행
if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=$CONTAINER_NAME)" ]; then
        echo "[*] 중지된 컨테이너를 다시 시작합니다..."
        docker start $CONTAINER_NAME
    else
        echo "[*] 새 Redroid 컨테이너를 생성합니다..."
        docker run -d --privileged -p 5555:5555 --name $CONTAINER_NAME redroid/redroid:11.0.0-latest
    fi
    echo "[*] 부팅 대기 중 (15초)..."
    sleep 15
else
    echo "[+] 컨테이너가 이미 실행 중입니다."
fi

# 2. ADB 연결 확인
echo "[*] ADB 연결 시도: $ADB_TARGET"
adb connect $ADB_TARGET
sleep 2

# 연결 상태 검증
ADB_STATUS=$(adb devices | grep "$ADB_TARGET")
if [[ $ADB_STATUS == *"device"* ]]; then
    echo "[+] ADB 연결 성공!"
else
    echo "[!] ADB 연결에 실패했습니다. 환경을 확인해 주세요."
    exit 1
fi

# 3. (옵션) 게임 실행 및 업데이트 대기
# 실제 게임 내 패치 다운로드가 필요한 경우 여기에 동작을 추가할 수 있습니다.
# echo "[*] 게임 실행 및 업데이트 대기 중..."
# adb -s $ADB_TARGET shell am start -n jp.gungho.padko/jp.gungho.padko.Pad
# sleep 60 # 업데이트 다운로드 시간을 위해 충분히 대기

# 4. 데이터 추출 및 파싱 스크립트 실행
if [ -f "$PYTHON_EXTRACT_SCRIPT" ]; then
    echo "[*] 데이터 추출 및 JSON 변환 시작..."
    python3 $PYTHON_EXTRACT_SCRIPT
else
    echo "[!] $PYTHON_EXTRACT_SCRIPT 파일을 찾을 수 없습니다."
    exit 1
fi

# 5. 결과 확인
if [ -f "pad_monster_data.json" ]; then
    echo "==========================================="
    echo "[+] 업데이트 완료: pad_monster_data.json"
    ls -lh pad_monster_data.json
    echo "==========================================="
else
    echo "[!] 데이터 생성 실패!"
    exit 1
fi
