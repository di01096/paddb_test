#!/bin/bash

# --- 설정 ---
# 조각난 APK 파일 리스트
APK_FILES=("pad_ko.apk" "pad_ko_1.apk" "pad_ko_2.apk" "pad_ko_3.apk" "pad_ko_4.apk")
# Waydroid 내부 임시 경로
WAYDROID_TMP="/data/local/tmp/pad_install"

echo "==========================================="
echo "📦 PAD Split APK 통합 설치 시작 (Waydroid)"
echo "==========================================="

# 1. Waydroid 서비스 상태 확인
if ! waydroid status | grep -q "RUNNING"; then
    echo "[!] Waydroid 세션이 실행 중이지 않습니다."
    echo "[*] './waydroid_launch_apk.sh'를 먼저 실행해 주세요."
    exit 1
fi

# 2. 내부 임시 폴더 생성
sudo waydroid shell "mkdir -p $WAYDROID_TMP"

# 3. 파일 전송 (cat 스트리밍 방식)
echo "[*] APK 조각들을 Waydroid 내부로 전송 중..."
for f in "${APK_FILES[@]}"; do
    if [ -f "$f" ]; then
        sudo waydroid shell "cat > $WAYDROID_TMP/$f" < "$f"
        echo "  > $f 전송 완료"
    else
        echo "  [!] $f 파일을 찾을 수 없습니다. 건너뜁니다."
    fi
done

# 4. 설치 세션 생성
echo "[*] 설치 세션 생성 중..."
SESSION_RAW=$(sudo waydroid shell "pm install-create -r -g")
SESSION_ID=$(echo "$SESSION_RAW" | grep -oE '[0-9]+')

if [ -z "$SESSION_ID" ]; then
    echo "[!] 세션 생성 실패: $SESSION_RAW"
    exit 1
fi
echo "[+] 세션 ID: $SESSION_ID"

# 5. 세션에 각 파일 등록 (Write)
for f in "${APK_FILES[@]}"; do
    if [ -f "$f" ]; then
        FILE_LABEL=$(echo "${f%.*}" | tr -d '_') # 특수문자 제거한 라벨
        echo "[*] 세션에 등록: $f"
        sudo waydroid shell "pm install-write $SESSION_ID $FILE_LABEL $WAYDROID_TMP/$f"
    fi
done

# 6. 최종 설치 확정 (Commit)
echo "[*] 최종 설치 승인 중..."
RESULT=$(sudo waydroid shell "pm install-commit $SESSION_ID")

if [[ $RESULT == *"Success"* ]]; then
    echo "==========================================="
    echo "[+] 축하합니다! 설치가 성공했습니다."
    echo "[*] 패키지: jp.gungho.padKO"
    echo "==========================================="
else
    echo "[!] 설치 실패: $RESULT"
fi

# 7. 임시 파일 정리
sudo waydroid shell "rm -rf $WAYDROID_TMP"
