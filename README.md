# 🐉 PAD 카드 도감 (PAD Card Guide)

퍼즐앤드래곤(PAD)의 몬스터 정보를 한눈에 확인하고 상세하게 검색할 수 있는 웹 기반 카드 도감 서비스입니다.

## 🚀 주요 기능

- **강력한 검색 및 필터링**:
  - 이름 및 도감 번호를 통한 실시간 검색
  - 주속성, 부속성, 제3속성별 필터링
  - 타입(드래곤, 신, 악마 등) 및 레어도별 필터링
  - **다중 각성 스킬 검색**: 원하는 각성 구성을 가진 몬스터를 정교하게 검색 가능
- **정렬 옵션**: 번호순, 레어도순, 능력치(HP, 공격력, 회복력)순 정렬 지원
- **상세 정보 보기**: 모달 창을 통해 몬스터의 상세 스탯, 스킬, 각성 정보를 확인
- **이미지 자동 처리**: `slice_awakenings.py`를 통해 각성 아이콘 스프라이트 이미지를 개별 아이콘으로 자동 분할 및 업데이트

## 🛠 기술 스택

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Backend/Utility**: Python 3.11, Pillow (이미지 처리)
- **Server**: Python Simple HTTP Server (Docker 환경)
- **Deployment**: Docker, Docker Compose

## 📁 프로젝트 구조

```text
.
├── awakenings/           # 분할된 각성 아이콘 이미지 저장소
├── js/                   # 프론트엔드 자바스크립트 로직
│   ├── card-detail.js    # 상세 모달 관련
│   ├── card-list.js      # 목록 렌더링 및 필터링
│   ├── data-loader.js    # 외부 데이터 로딩
│   ├── data-parser.js    # 데이터 가공 및 변환
│   └── main.js           # 앱 초기화 및 메인 로직
├── Dockerfile            # 도커 빌드 설정
├── docker-compose.yml    # 도커 컴포즈 설정
├── index.html            # 메인 페이지
├── index.css             # 스타일시트
├── slice_awakenings.py   # 각성 아이콘 분할 스크립트
└── requirements.txt      # 파이썬 의존성 패키지
```

## ⚙️ 시작하기 (Local)

### 1. 의존성 설치
파이썬이 설치된 환경에서 다음 명령어를 실행합니다.
```bash
pip install -r requirements.txt
```

### 2. 각성 아이콘 분할 (선택 사항)
`awoken.png` 파일에서 최신 각성 아이콘을 추출하려면 실행합니다.
```bash
python slice_awakenings.py
```

### 3. 서버 실행
```bash
python -m http.server 8080
```
브라우저에서 `http://localhost:8080`에 접속합니다.

## 🐳 Docker로 실행하기

Docker와 Docker Compose가 설치되어 있다면 가장 간단하게 실행할 수 있습니다.

```bash
# 컨테이너 빌드 및 실행
docker-compose up -d
```

실행 후 브라우저에서 `http://localhost:8080` (기본 설정 포트)으로 접속하세요.

## 🚀 데이터 추출 및 최초 업데이트 가이드 (Ubuntu/Docker)

이 프로젝트는 안드로이드 환경(물리 기기 또는 Redroid Docker)에서 직접 데이터를 추출하는 기능을 포함합니다.

### 1. 최초 데이터 생성 (Initial Update)
게임을 처음 설치하면 수 GB의 데이터 다운로드가 필요합니다. 헤드리스 환경에서 이를 처리하는 방법입니다.

1.  **APK 준비**: 한국판 퍼즐앤드래곤 APK(`pad_ko.apk`)를 프로젝트 폴더에 준비합니다.
2.  **환경 구성**: `headless_automation_setup.py` 또는 `update_data.sh`를 실행하여 Docker 안드로이드를 띄웁니다.
3.  **설치 및 클릭 매크로 실행**:
    ```bash
    python verify_and_install.py
    ```
    *   이 스크립트는 APK를 설치하고 게임을 실행한 뒤, 화면의 특정 좌표(약관 동의 등)를 자동으로 터치하여 다운로드를 시작시킵니다.
4.  **다운로드 상태 확인**:
    실시간으로 화면을 볼 수 없는 경우, 다음 명령어로 스크린샷을 찍어 확인합니다.
    ```bash
    adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png
    ```
    *   다운로드가 완료되어 로비 화면(또는 튜토리얼 입구)이 보일 때까지 대기합니다. (네트워크에 따라 10~30분 소요)

### 2. 데이터 추출 및 파싱
데이터 폴더가 생성된 후 다음 명령으로 최종 JSON을 생성합니다.
```bash
./update_data.sh
```
*   추출된 결과는 `pad_monster_data.json`으로 저장됩니다.

### 3. 자원 정리
작업이 끝난 후 실행 중인 안드로이드 환경을 종료하려면 다음을 실행합니다.
```bash
./cleanup_data.sh
```

## 📝 라이선스
이 프로젝트는 교육 및 참고 목적으로 제작되었습니다. 퍼즐앤드래곤에 대한 저작권은 GungHo Online Entertainment에 있습니다.
