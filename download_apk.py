import requests
import os
import sys

def download_pad_apk(package_name="jp.gungho.padKO", output_filename="pad_ko.apk"):
    """
    Aptoide API를 사용하여 패키지 이름으로 최신 APK 다운로드 링크를 찾고 다운로드합니다.
    """
    print(f"[*] '{package_name}' 최신 버전 찾는 중...")
    
    # Aptoide API v7 검색 엔드포인트
    api_url = f"https://ws75.aptoide.com/api/7/apps/search?query=package:{package_name}&limit=1"
    
    try:
        response = requests.get(api_url)
        response.raise_for_status()
        data = response.json()
        
        datalist = data.get('datalist', {}).get('list', [])
        if not datalist:
            print(f"[!] 에러: 해당 패키지를 찾을 수 없습니다. ({package_name})")
            return False
            
        # 다운로드 URL 추출
        app_data = datalist[0]
        file_info = app_data.get('file', {})
        download_url = file_info.get('path')
        version = file_info.get('vername')
        
        if not download_url:
            print("[!] 다운로드 링크를 추출하지 못했습니다.")
            return False
            
        print(f"[+] 최신 버전 확인: {version}")
        print(f"[*] 다운로드 시작: {download_url}")
        
        # 파일 다운로드
        with requests.get(download_url, stream=True) as r:
            r.raise_for_status()
            total_size = int(r.headers.get('content-length', 0))
            downloaded = 0
            
            with open(output_filename, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size > 0:
                            done = int(50 * downloaded / total_size)
                            sys.stdout.write(f"\r[{'=' * done}{' ' * (50-done)}] {downloaded/1024/1024:.2f}MB / {total_size/1024/1024:.2f}MB")
                            sys.stdout.flush()
        
        print(f"\n[+] 다운로드 완료: {output_filename}")
        return True
        
    except Exception as e:
        print(f"[!] 다운로드 중 오류 발생: {e}")
        return False

if __name__ == "__main__":
    download_pad_apk()
