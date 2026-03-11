import os
import subprocess
import zlib
import struct
import json

# --- 설정 (환경에 맞게 수정 가능) ---
PACKAGE_NAME = "jp.gungho.padKO"  # 대소문자 구분
REMOTE_PATH = f"/data/data/{PACKAGE_NAME}/files/mon2/" # 실제 데이터 저장 위치
LOCAL_TMP_DIR = "tmp_pad_data"
OUTPUT_JSON = "pad_monster_data.json"

def run_command(cmd):
    """쉘 명령어를 실행하고 결과를 반환합니다."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        print(f"[!] 명령어 실패: {cmd}\n[!] 에러: {e}")
        return None

def check_adb():
    """ADB 연결 상태를 확인합니다."""
    print("[*] ADB 연결 확인 중...")
    devices = run_command("adb devices")
    if "device" not in devices.split("\n")[1]:
        print("[!] 연결된 안드로이드 기기가 없습니다. 'adb connect localhost:5555'를 확인하세요.")
        return False
    return True

def extract_files_via_adb():
    """ADB를 통해 기기에서 .bin 파일을 추출합니다 (Root 권한 필요)."""
    if not os.path.exists(LOCAL_TMP_DIR):
        os.makedirs(LOCAL_TMP_DIR)
    
    print(f"[*] {PACKAGE_NAME}에서 데이터 파일 추출 중...")
    
    # Redroid 컨테이너 내부의 루트 권한을 사용하여 파일을 sdcard로 복사 후 가져옴
    # su를 su_hide로 바꿨을 수 있으므로 유연하게 대처
    run_command("adb -s localhost:5555 shell 'mkdir -p /sdcard/Download/pad_tmp/'")
    
    # docker exec를 직접 사용하면 su 이름 변경과 상관없이 루트 접근 가능
    print("[*] Docker를 통해 직접 파일 복제 시도...")
    subprocess.run(f"sudo docker exec redroid sh -c 'cp {REMOTE_PATH}cards_KO*.bin /sdcard/Download/pad_tmp/'", shell=True)
    
    print("[*] 우분투로 파일 가져오는 중...")
    run_command(f"adb -s localhost:5555 pull /sdcard/Download/pad_tmp/ {LOCAL_TMP_DIR}/")
    
    return True

def parse_bin_to_json():
    """추출된 .bin 파일들을 파싱하여 JSON으로 변환합니다."""
    all_monsters = []
    
    if not os.path.exists(LOCAL_TMP_DIR) or not os.listdir(LOCAL_TMP_DIR):
        print("[!] 파싱할 파일이 없습니다. 추출이 실패했을 수 있습니다.")
        return

    files = [f for f in os.listdir(LOCAL_TMP_DIR) if f.endswith('.bin')]
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
    if check_adb():
        if extract_files_via_adb():
            parse_bin_to_json()
