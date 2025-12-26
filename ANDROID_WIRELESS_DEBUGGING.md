# Android 무선 디버깅 설정 가이드

## 무선 디버깅이란?
USB 케이블 없이 Wi-Fi를 통해 Android 기기를 연결하여 앱을 테스트하는 방법입니다.

## 설정 방법

### 1단계: Android 기기에서 개발자 옵션 활성화

1. **설정** → **휴대전화 정보** (또는 **디바이스 정보**)
2. **빌드 번호**를 7번 연속으로 탭
3. "개발자가 되었습니다!" 메시지 확인

### 2단계: 무선 디버깅 활성화

#### Android 11 이상 (추천 방법)
1. **설정** → **개발자 옵션**
2. **무선 디버깅** 활성화
3. **무선 디버깅** 메뉴 진입
4. **페어링 코드로 기기 페어링** 선택
5. **페어링 코드**와 **IP 주소 및 포트** 확인 (예: 192.168.0.100:12345)

#### Android 10 이하 (ADB over Wi-Fi)
1. **설정** → **개발자 옵션**
2. **USB 디버깅** 활성화
3. **네트워크에서 ADB 디버깅** 활성화 (있는 경우)

### 3단계: Mac에서 페어링

#### 방법 A: Android 11+ 무선 디버깅 (추천)

**먼저 ADB 설치:**
```bash
brew install --cask android-platform-tools
```

**페어링:**
```bash
# 기기에서 표시된 IP 주소와 포트로 페어링
# 예: adb pair 192.168.0.100:12345
adb pair <IP주소>:<포트>

# 페어링 코드 입력 (기기 화면에 표시된 6자리 코드)
# 예: 123456
```

**연결:**
```bash
# 페어링 후 기기에서 표시된 IP 주소와 포트로 연결
# 예: adb connect 192.168.0.100:45678
adb connect <IP주소>:<포트>
```

**연결 확인:**
```bash
adb devices
# 기기가 "device"로 표시되면 성공
```

#### 방법 B: Android 10 이하 (USB로 한 번만 연결 필요)

**처음 한 번만 USB 연결:**
1. USB로 기기 연결
2. USB 디버깅 허용
3. 기기의 IP 주소 확인:
   ```bash
   adb tcpip 5555
   adb shell ip addr show wlan0 | grep "inet "
   # 또는 기기에서: 설정 → Wi-Fi → 연결된 네트워크 → IP 주소 확인
   ```

**USB 분리 후 무선 연결:**
```bash
# 기기의 IP 주소로 연결
adb connect <IP주소>:5555

# 연결 확인
adb devices
```

### 4단계: Flutter 앱 실행

```bash
# 연결된 기기 확인
flutter devices

# 앱 실행
flutter run
```

## 전체 과정 예시

### Android 11+ 무선 디버깅

```bash
# 1. ADB 설치 (처음 한 번만)
brew install --cask android-platform-tools

# 2. 기기에서 무선 디버깅 활성화 후
#    페어링 코드와 IP:포트 확인 (예: 192.168.0.100:12345)

# 3. 페어링
adb pair 192.168.0.100:12345
# 페어링 코드 입력: 123456

# 4. 연결 (기기에서 표시된 새로운 IP:포트 사용)
adb connect 192.168.0.100:45678

# 5. 확인
adb devices

# 6. Flutter 앱 실행
flutter run
```

### Android 10 이하

```bash
# 1. ADB 설치
brew install --cask android-platform-tools

# 2. USB로 연결 (처음 한 번만)
adb devices

# 3. TCP/IP 모드 활성화
adb tcpip 5555

# 4. 기기 IP 주소 확인 (기기에서 확인)
# 설정 → Wi-Fi → 연결된 네트워크

# 5. USB 분리 후 무선 연결
adb connect 192.168.0.100:5555

# 6. 확인
adb devices

# 7. Flutter 앱 실행
flutter run
```

## 중요 사항

### ⚠️ 주의사항
1. **같은 Wi-Fi 네트워크**: Mac과 Android 기기가 같은 Wi-Fi에 연결되어 있어야 합니다
2. **방화벽**: Mac의 방화벽이 ADB 연결을 차단하지 않는지 확인
3. **보안**: 무선 디버깅은 보안상 주의가 필요합니다. 신뢰할 수 있는 네트워크에서만 사용하세요

### 🔄 재연결
- 기기를 재부팅하거나 Wi-Fi를 끄면 연결이 끊어집니다
- 다시 연결하려면:
  ```bash
  adb connect <IP주소>:<포트>
  ```

### 📱 IP 주소 확인 방법
1. **Android 기기에서:**
   - 설정 → Wi-Fi → 연결된 네트워크 → IP 주소
2. **터미널에서 (USB 연결 시):**
   ```bash
   adb shell ip addr show wlan0 | grep "inet "
   ```

## 문제 해결

### "cannot connect to <IP>:<PORT>"
- Mac과 기기가 같은 Wi-Fi에 연결되어 있는지 확인
- 기기의 무선 디버깅이 활성화되어 있는지 확인
- 방화벽 설정 확인

### "device unauthorized"
- 기기에서 "USB 디버깅 허용" 팝업 확인
- "항상 이 컴퓨터에서 허용" 체크

### "no devices/emulators found"
```bash
# 연결 상태 확인
adb devices

# 재연결 시도
adb connect <IP>:<PORT>

# ADB 서버 재시작
adb kill-server
adb start-server
```

## 편리한 스크립트

연결을 쉽게 하기 위한 스크립트를 만들 수 있습니다:

```bash
# ~/.zshrc 또는 ~/.bashrc에 추가
alias adb-connect='adb connect $(adb shell ip addr show wlan0 | grep "inet " | awk "{print \$2}" | cut -d/ -f1):5555'
```

이제 `adb-connect` 명령어로 자동 연결 가능합니다.

