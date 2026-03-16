#!/bin/bash

# --- 설정 (Waydroid 경로 관리) ---
# 호스트 리눅스상의 Waydroid 사용자 데이터 루트 경로
WAYDROID_HOST_DATA="$HOME/.local/share/waydroid/data/media/0"
# 안드로이드 내부에서 보일 경로 (Download 폴더)
ANDROID_DEST_DIR="/sdcard/Download/pad_install"
# 실제 호스트상에서 파일이 복사될 절대 경로
HOST_DEST_DIR="$WAYDROID_HOST_DATA/Download/pad_install"

# 조각난 APK 파일 리스트
APK_FILES=("pad_ko.apk" "pad_ko_1.apk" "pad_ko_2.apk" "pad_ko_3.apk" "pad_ko_4.apk")

echo "==========================================="
echo "📦 Waydroid 경로 직접 주입형 Split APK 설치"
echo "==========================================="

# 1. 호스트 경로 존재 여부 확인 및 폴더 생성
if [ ! -d "$WAYDROID_HOST_DATA" ]; then
    echo "[!] Waydroid 데이터 경로를 찾을 수 없습니다: $WAYDROID_HOST_DATA"
    echo "[*] Waydroid가 설치되어 있고 한 번이라도 실행되었는지 확인하세요."
    exit 1
fi

echo "[*] Waydroid 데이터 영역으로 파일 복사 중..."
mkdir -p "$HOST_DEST_DIR"

for f in "${APK_FILES[@]}"; do
    if [ -f "$f" ]; then
        cp "$f" "$HOST_DEST_DIR/"
        echo "  > $f 복사 완료"
    else
        echo "  [!] $f 파일이 현재 폴더에 없습니다. 건너뜁니다."
    fi
done

# 2. Waydroid 세션 확인
if ! waydroid status | grep -q "RUNNING"; then
    echo "[!] Waydroid 세션이 실행 중이지 않습니다."
    echo "[*] './waydroid_launch_apk.sh'를 먼저 실행해 주세요."
    exit 1
fi

# 3. 설치 세션 생성
echo "[*] 안드로이드 설치 세션 생성 중..."
SESSION_RAW=$(sudo waydroid shell "pm install-create -r -g")
SESSION_ID=$(echo "$SESSION_RAW" | grep -oE '[0-9]+')

if [ -z "$SESSION_ID" ]; then
    echo "[!] 세션 생성 실패: $SESSION_RAW"
    exit 1
fi
echo "[+] 생성된 세션 ID: $SESSION_ID"

# 4. 세션에 파일 등록 (안드로이드 내부 경로 기준)
for f in "${APK_FILES[@]}"; do
    if [ -f "$f" ]; then
        echo "[*] 세션에 조각 추가: $f"
        sudo waydroid shell "pm install-write $SESSION_ID ${f%.*} $ANDROID_DEST_DIR/$f"
    fi
done

# 5. 설치 확정 (Commit)
echo "[*] 최종 설치 승인(Commit) 중..."
RESULT=$(sudo waydroid shell "pm install-commit $SESSION_ID")

if [[ $RESULT == *"Success"* ]]; then
    echo "==========================================="
    echo "[+] 축하합니다! 설치가 성공했습니다."
    echo "[*] 패키지: jp.gungho.padKO"
    echo "==========================================="
else
    echo "[!] 설치 실패: $RESULT"
fi

# 6. 호스트 임시 파일 정리
echo "[*] 임시 파일 정리 중..."
rm -rf "$HOST_DEST_DIR"
