import os
import json
import paramiko
from stat import S_ISDIR

def load_config():
    with open('sftp_config.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def upload_files():
    config = load_config()
    
    print(f"[*] 서버 연결 중: {config['host']}...")
    transport = paramiko.Transport((config['host'], config['port']))
    transport.connect(username=config['username'], password=config['password'])
    
    sftp = paramiko.SFTPClient.from_transport(transport)
    
    # 원격 경로 생성 (없을 경우)
    try:
        sftp.mkdir(config['remote_path'])
    except:
        pass

    print(f"[*] 파일 업로드 시작: {config['local_path']} -> {config['remote_path']}")
    
    local_dir = config['local_path']
    for file in os.listdir(local_dir):
        if file.endswith('.bin') or file.endswith('.json'):
            local_path = os.path.join(local_dir, file)
            remote_path = os.path.join(config['remote_path'], file).replace('\\', '/')
            
            print(f"  > {file} 전송 중...")
            sftp.put(local_path, remote_path)
            
    sftp.close()
    transport.close()
    print("[+] 업로드 완료!")

if __name__ == "__main__":
    if os.path.exists('tmp_pad_data'):
        upload_files()
    else:
        print("[!] 업로드할 데이터 폴더(tmp_pad_data)가 없습니다.")
