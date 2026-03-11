import os
import subprocess
import time
from download_apk import download_pad_apk

# --- 설정 ---
PACKAGE_NAME = "jp.gungho.padKO"
MAIN_ACTIVITY = "jp.gungho.padKO/.AppDelegate"
DATA_PATH = f"/data/data/{PACKAGE_NAME}/files/mon2" # 몬스터 데이터 경로
APK_FILE = "pad_ko.apk" # 로컬에 있는 APK 파일명

def run_waydroid(cmd):
    full_cmd = f"waydroid {cmd}"
    res = subprocess.run(full_cmd, shell=True, capture_output=True, text=True)
    return res.stdout.strip()

def check_package_installed():
    print("[*] 패키지 설치 확인 중...")
    res = run_waydroid(f"app list")
    return PACKAGE_NAME in res

def install_apk():
    if not os.path.exists(APK_FILE):
        print(f"[!] {APK_FILE} 파일이 없습니다. 자동 다운로드를 시도합니다...")
        if not download_pad_apk(PACKAGE_NAME, APK_FILE):
            print("[!] APK 다운로드에 실패했습니다. 수동으로 파일을 준비해 주세요.")
            return False
            
    print(f"[*] {APK_FILE} 설치 시작... (시간이 걸릴 수 있습니다)")
    run_waydroid(f"app install {APK_FILE}")
    return True

def ensure_data_exists():
    """폴더가 없으면 게임을 실행하고 클릭 매크로를 돌려 데이터를 생성시킵니다."""
    print("[*] 데이터 폴더 존재 여부 확인 중...")
    # Waydroid에서는 shell을 통해 파일 시스템 접근 가능
    res = run_waydroid(f"shell ls -d {DATA_PATH}")
    
    if "No such file" in res or not res:
        print("[!] 데이터 폴더가 없습니다. 게임을 실행하여 다운로드를 시작합니다.")
        
        # 1. 게임 실행 (Waydroid 전용 런칭 명령어)
        run_waydroid(f"app launch {PACKAGE_NAME}")
        time.sleep(15) # 부팅 대기
        
        # 2. 클릭 매크로 (Waydroid shell input tap 사용)
        print("[*] 다운로드 승인 버튼 클릭 시도 중...")
        run_waydroid("shell input tap 540 1500") 
        time.sleep(2)
        run_waydroid("shell input tap 540 1100")
        
        print("[*] 데이터 다운로드 중... (10분 이상 대기)")
        return False
    else:
        print("[+] 데이터 폴더 확인 완료: " + res)
        return True

if __name__ == "__main__":
    if not check_package_installed():
        if not install_apk():
            exit(1)
            
    if ensure_data_exists():
        print("[*] 이제 'direct_extract_ubuntu.py'를 실행하여 데이터를 추출할 수 있습니다.")
    else:
        print("[!] 데이터를 다운로드 중입니다. 잠시 후 다시 실행해 주세요.")
