# Android 테스트 설정 가이드

## 방법 1: 실제 Android 기기 사용 (추천) ⭐

### 장점
- 가장 빠르게 시작 가능
- 실제 기기 성능 확인
- 별도 소프트웨어 설치 최소화

### 설정 단계

#### 1. Android 기기에서 개발자 옵션 활성화
1. **설정** → **휴대전화 정보** (또는 **디바이스 정보**)
2. **빌드 번호**를 7번 연속으로 탭
3. "개발자가 되었습니다!" 메시지 확인

#### 2. USB 디버깅 활성화
1. **설정** → **개발자 옵션**
2. **USB 디버깅** 활성화
3. 확인 메시지에서 **허용** 선택

#### 3. Android 기기를 Mac에 연결
1. USB 케이블로 연결
2. 기기에서 "USB 디버깅 허용" 팝업이 뜨면 **허용** 선택
3. "항상 이 컴퓨터에서 허용" 체크 (선택사항)

#### 4. 연결 확인
```bash
# ADB 설치 확인 (Android Studio 없이도 가능)
# Homebrew로 설치:
brew install --cask android-platform-tools

# 또는 Android Studio 설치 시 자동 포함됨

# 기기 확인
adb devices
```

#### 5. Flutter 앱 실행
```bash
flutter run
```

---

## 방법 2: Android 에뮬레이터 사용

### 장점
- 다양한 기기 크기 테스트
- 실제 기기 없이도 테스트 가능

### 설정 단계

#### 1. Android Studio 설치
1. https://developer.android.com/studio 에서 다운로드
2. 설치 파일 실행
3. 표준 설치 선택 (Android SDK 포함)

#### 2. Android SDK 설정
1. Android Studio 실행
2. **More Actions** → **SDK Manager**
3. 다음 항목 확인:
   - ✅ Android SDK Platform-Tools
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools

#### 4. AVD (Android Virtual Device) 생성
1. Android Studio에서 **More Actions** → **Virtual Device Manager**
2. **Create Device** 클릭
3. 기기 선택 (예: Pixel 7)
4. 시스템 이미지 선택 (예: Android 13 - API 33)
5. **Finish** 클릭

#### 5. 에뮬레이터 실행
1. Virtual Device Manager에서 생성한 기기 옆 **▶️** 클릭
2. 또는 터미널에서:
   ```bash
   flutter emulators --launch <에뮬레이터_이름>
   ```

#### 6. Flutter 앱 실행
```bash
flutter run
```

---

## 빠른 시작 (실제 기기)

### 1단계: Android 기기 설정
```
설정 → 휴대전화 정보 → 빌드 번호 7번 탭
설정 → 개발자 옵션 → USB 디버깅 활성화
```

### 2단계: ADB 설치 (Android Studio 없이)
```bash
brew install --cask android-platform-tools
```

### 3단계: 기기 연결 및 확인
```bash
# USB로 연결 후
adb devices
# 기기가 목록에 나타나야 함
```

### 4단계: 앱 실행
```bash
flutter run
```

---

## 문제 해결

### "adb: command not found"
```bash
# ADB 설치
brew install --cask android-platform-tools

# 또는 Android Studio 설치
```

### "No devices found"
1. USB 케이블 확인 (데이터 전송 가능한 케이블)
2. USB 디버깅이 활성화되었는지 확인
3. 기기에서 "USB 디버깅 허용" 팝업 확인
4. `adb devices`로 연결 확인

### "Android SDK not found"
```bash
# Android Studio 설치 필요
# 또는 수동으로 SDK 경로 설정:
flutter config --android-sdk /path/to/android/sdk
```

### "License not accepted"
```bash
# Android SDK 라이선스 동의
flutter doctor --android-licenses
```

---

## 현재 상태 확인

```bash
# Flutter 환경 확인
flutter doctor

# 연결된 기기 확인
flutter devices

# 에뮬레이터 목록 확인
flutter emulators
```

---

## 추천 워크플로우

1. **빠른 테스트**: 실제 Android 기기 연결 (가장 빠름)
2. **다양한 기기 테스트**: 여러 에뮬레이터 생성
3. **최종 확인**: 실제 기기에서 성능 테스트

