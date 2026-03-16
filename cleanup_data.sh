#!/bin/bash

echo "==========================================="
echo "🌀 Waydroid 및 가상 세션 완전 정리 (Cleanup)"
echo "==========================================="

# 1. Waydroid 세션 및 프로세스 강제 종료
echo "[*] 모든 Waydroid 및 Weston 프로세스 종료 중..."
sudo waydroid session stop &> /dev/null
sudo pkill -9 waydroid &> /dev/null
sudo pkill -9 weston &> /dev/null

# 2. 시스템 서비스 재시작 (상태 초기화)
echo "[*] Waydroid 컨테이너 서비스 재시작 중..."
sudo systemctl restart waydroid-container

# 3. 가상 디스플레이 찌꺼기 파일 제거
echo "[*] 세션 잠금 파일 및 소켓 정리 중..."
export XDG_RUNTIME_DIR=/run/user/$(id -u)
sudo rm -f $XDG_RUNTIME_DIR/wayland-1*
sudo rm -f /tmp/.wayland-1*

# 4. ADB 연결 해제 (선택 사항)
if command -v adb &> /dev/null; then
    echo "[*] ADB 연결 초기화 중..."
    adb disconnect &> /dev/null
fi

echo "==========================================="
echo "[+] 모든 자원이 정리되었습니다."
echo "[*] 이제 다시 './waydroid_launch_apk.sh'를 실행할 수 있습니다."
echo "==========================================="
