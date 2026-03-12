@echo off
setlocal enabledelayedexpansion

:: --- 설정 ---
set PACKAGE_NAME=jp.gungho.padKO
set REMOTE_DATA_PATH=/data/data/!PACKAGE_NAME!/files/mon2/
set LOCAL_TMP_DIR=tmp_pad_data
set ADB_PORT=5555

echo ===========================================
echo 🐉 PAD 윈도우 데이터 추출 및 SFTP 업로드
echo ===========================================

:: 1. ADB 연결 확인
echo [*] 블루스택 ADB 연결 시도 (localhost:!ADB_PORT!)...
adb connect localhost:!ADB_PORT!
timeout /t 2 > nul

adb devices | findstr "localhost:!ADB_PORT!" > nul
if errorlevel 1 (
    echo [!] 블루스택을 찾을 수 없습니다. ADB 설정을 확인하세요.
    pause
    exit /b
)

:: 2. 데이터 폴더 생성
if not exist !LOCAL_TMP_DIR! mkdir !LOCAL_TMP_DIR!

:: 3. 블루스택 내부에서 파일 복사 (Root 필요)
echo [*] 블루스택 내부 데이터 복제 중...
adb -s localhost:!ADB_PORT! shell "su -c 'mkdir -p /sdcard/Download/pad_tmp/ && cp !REMOTE_DATA_PATH!cards_KO*.bin /sdcard/Download/pad_tmp/'"

:: 4. 윈도우로 가져오기
echo [*] 윈도우로 파일 가져오는 중...
adb -s localhost:!ADB_PORT! pull /sdcard/Download/pad_tmp/ !LOCAL_TMP_DIR!\

:: 5. 파이썬 파싱 및 SFTP 업로드
echo [*] SFTP 업로드 스크립트 실행 중...
python upload_to_server.py

echo ===========================================
echo [+] 모든 작업이 완료되었습니다.
echo ===========================================
pause
