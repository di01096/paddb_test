import os
import subprocess
import zlib
import struct
import json
import shutil

# --- 설정 (환경에 맞게 수정 가능) ---
PACKAGE_NAME = "jp.gungho.padKO"  # 대소문자 구분: jp.gungho.padKO
REMOTE_PATH = f"/data/data/{PACKAGE_NAME}/files/mon2/" # 실제 데이터 저장 위치
LOCAL_TMP_DIR = "tmp_pad_data"
OUTPUT_JSON = "pad_monster_data.json"

def run_waydroid(cmd):
    """Waydroid 명령어를 실행하고 결과를 반환합니다."""
    try:
        result = subprocess.run(f"waydroid {cmd}", shell=True, check=True, capture_output=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"[!] 명령어 실패: {cmd}\n[!] 에러: {e.stderr}")
        return None

def check_waydroid():
    """Waydroid 상태를 확인합니다."""
    print("[*] Waydroid 상태 확인 중...")
    try:
        status = run_waydroid("status")
        if "RUNNING" not in status:
            print("[!] Waydroid 세션이 실행 중이 아닙니다. 'waydroid session start'를 먼저 실행하세요.")
            return False
        return True
    except:
        return False

def extract_files_via_waydroid():
    """Waydroid shell을 통해 데이터를 추출합니다."""
    if not os.path.exists(LOCAL_TMP_DIR):
        os.makedirs(LOCAL_TMP_DIR)

    print(f"[*] {PACKAGE_NAME}에서 데이터 파일 추출 중...")

    # Waydroid 내부에서 임시 경로로 복사
    run_waydroid("shell mkdir -p /sdcard/Download/pad_tmp/")
    run_waydroid(f"shell cp {REMOTE_PATH}cards_KO*.bin /sdcard/Download/pad_tmp/")

    # 호스트의 Waydroid 데이터 경로에서 직접 파일을 가져옵니다.
    user_home = os.path.expanduser("~")
    # Waydroid 기본 데이터 경로 (사용자마다 다를 수 있음)
    host_tmp_path = os.path.join(user_home, ".local/share/waydroid/data/media/0/Download/pad_tmp")
    
    if not os.path.exists(host_tmp_path):
        # 다른 가능성 있는 경로 확인
        host_tmp_path = "/var/lib/waydroid/data/media/0/Download/pad_tmp"

    if os.path.exists(host_tmp_path):
        print(f"[*] 호스트 경로에서 파일 복사 중: {host_tmp_path}")
        for item in os.listdir(host_tmp_path):
            s = os.path.join(host_tmp_path, item)
            d = os.path.join(LOCAL_TMP_DIR, item)
            if os.path.isfile(s):
                shutil.copy2(s, d)
        return True
    else:
        print("[!] 호스트 데이터 경로를 찾을 수 없습니다. 수동 확인이 필요합니다.")
        return False

def parse_bin_to_json():
    """추출된 .bin 파일들을 파싱하여 JSON으로 변환합니다."""
    all_monsters = []
    
    if not os.path.exists(LOCAL_TMP_DIR):
        print("[!] 로컬 임시 폴더가 없습니다.")
        return

    files = [f for f in os.listdir(LOCAL_TMP_DIR) if f.endswith('.bin')]
    if not files:
        print("[!] 파싱할 .bin 파일이 없습니다.")
        return

    print(f"[*] {len(files)}개의 파일 파싱 시작...")
    
    for filename in files:
        path = os.path.join(LOCAL_TMP_DIR, filename)
        with open(path, 'rb') as f:
            data = f.read()
            
        try:
            header = data[:32]
            monster_count = struct.unpack('<I', header[24:28])[0]
            decompressed = zlib.decompress(data[32:])
            record_size = 438
            
            for i in range(monster_count):
                offset = 32 + (i * record_size)
                if offset + record_size > len(decompressed): break
                
                record = decompressed[offset : offset + record_size]
                m_id = struct.unpack('<H', record[0:2])[0]
                
                if m_id > 0:
                    all_monsters.append({
                        "id": m_id,
                        "hp": struct.unpack('<I', record[4:8])[0],
                        "atk": struct.unpack('<I', record[8:12])[0],
                        "rcv": struct.unpack('<I', record[12:16])[0],
                    })
        except Exception as e:
            print(f"[!] {filename} 처리 중 오류: {e}")

    with open(OUTPUT_JSON, 'w', encoding='utf-8') as f:
        json.dump(all_monsters, f, indent=2, ensure_ascii=False)
    
    print(f"[+] 완료! {len(all_monsters)}개의 데이터를 {OUTPUT_JSON}에 저장했습니다.")

if __name__ == "__main__":
    if check_waydroid():
        if extract_files_via_waydroid():
            parse_bin_to_json()
