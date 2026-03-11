import os
import subprocess
import zlib
import struct
import json

# --- 설정 (환경에 맞게 수정 가능) ---
PACKAGE_NAME = "jp.gungho.padko"  # 한국판 패키지명 (일판은 jp.gungho.pad)
REMOTE_PATH = f"/data/data/{PACKAGE_NAME}/files/mon2/" # 실제 데이터 저장 위치
LOCAL_TMP_DIR = "tmp_pad_data"
OUTPUT_JSON = "pad_monster_data.json"

def run_command(cmd):
    """쉘 명령어를 실행하고 결과를 반환합니다."""
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"[!] 명령어 실패: {cmd}\n[!] 에러: {e.stderr}")
        return None

def check_adb():
    """ADB 연결 상태를 확인합니다."""
    print("[*] ADB 연결 확인 중...")
    devices = run_command("adb devices")
    if "device" not in devices.split("\n")[1]:
        print("[!] 연결된 안드로이드 기기가 없습니다. USB 디버깅이 켜져 있는지 확인하세요.")
        return False
    return True

def extract_files_via_adb():
    """ADB를 통해 기기에서 .bin 파일을 추출합니다 (Root 권한 필요)."""
    if not os.path.exists(LOCAL_TMP_DIR):
        os.makedirs(LOCAL_TMP_DIR)
    
    print(f"[*] {PACKAGE_NAME}에서 데이터 파일 추출 중...")
    
    # 일반 pull은 권한 문제로 안될 수 있으므로, 임시 폴더로 복사 후 pull 하는 방식을 사용합니다.
    # 이 과정은 기기가 루팅되어 있거나 adb root가 가능해야 합니다.
    cmds = [
        f"adb shell 'su -c \"cp -r {REMOTE_PATH}*.bin /sdcard/Download/pad_tmp/\"'",
        f"adb pull /sdcard/Download/pad_tmp/ {LOCAL_TMP_DIR}/",
        "adb shell 'rm -rf /sdcard/Download/pad_tmp/'"
    ]
    
    # 만약 루팅되지 않은 기기라면 'adb backup'이나 'run-as'를 시도해야 하지만, 
    # 퍼즐앤드래곤은 보안상 일반 run-as가 막혀있을 수 있습니다.
    # 여기서는 깃허브 설명의 '직접 추출' 로직을 우분투용 ADB 명령어로 재현합니다.
    
    print("[*] 기기 내부에서 파일을 복사하고 있습니다 (Root 권한 요청 발생 가능)...")
    run_command("adb shell 'mkdir -p /sdcard/Download/pad_tmp/'")
    run_command(f"adb shell 'su -c \"cp {REMOTE_PATH}cards_KO*.bin /sdcard/Download/pad_tmp/\"'")
    
    print("[*] 우분투로 파일 가져오는 중...")
    run_command(f"adb pull /sdcard/Download/pad_tmp/ {LOCAL_TMP_DIR}")
    
    return True

def parse_bin_to_json():
    """추출된 .bin 파일들을 파싱하여 JSON으로 변환합니다."""
    all_monsters = []
    
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
            # PAD 바이너리 구조: 32바이트 헤더 + zlib 압축 데이터
            header = data[:32]
            # 헤더 24~27바이트는 몬스터 개수
            monster_count = struct.unpack('<I', header[24:28])[0]
            
            decompressed = zlib.decompress(data[32:])
            record_size = 438 # 최신 버전의 일반적인 레코드 크기
            
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
