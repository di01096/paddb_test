import os
import subprocess
import time

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

def setup_redroid():
    """우분투에 Docker 기반 안드로이드를 실행하고 ADB로 연결합니다."""
    print("[*] Redroid 컨테이너 시작 중...")
    
    # 1. Redroid 컨테이너 실행 (안드로이드 11 버전 예시)
    # 실제 환경에서는 커널 모듈(binder, ashmem)이 로드되어 있어야 합니다.
    run("docker run -d --privileged -p 5555:5555 --name redroid redroid/redroid:11.0.0-latest")
    
    # 컨테이너 부팅 대기
    time.sleep(10)
    
    # 2. ADB 연결
    print("[*] ADB 연결 시도 중 (localhost:5555)...")
    run("adb connect localhost:5555")
    
    # 3. 연결 확인
    res = run("adb devices")
    if "localhost:5555	device" in res.stdout:
        print("[+] 안드로이드 소프트웨어 환경 구성 완료!")
        return True
    else:
        print("[!] 연결 실패. Docker 로그를 확인하세요.")
        return False

def install_and_run_pad(apk_path):
    """퍼즐앤드래곤 APK 설치 및 실행 자동화"""
    print(f"[*] {apk_path} 설치 중...")
    run(f"adb -s localhost:5555 install {apk_path}")
    
    print("[*] 게임 실행 중...")
    # 한국판 패키지 실행 예시
    run("adb -s localhost:5555 shell am start -n jp.gungho.padko/jp.gungho.padko.Pad")

if __name__ == "__main__":
    if setup_redroid():
        # 여기에 APK 설치나 데이터 추출 로직을 추가하여 
        # 전체 과정을 소프트웨어적으로 자동화할 수 있습니다.
        print("[*] 이제 이 환경에서 direct_extract_ubuntu.py를 실행하면 됩니다.")
