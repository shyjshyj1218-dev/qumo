# Android Studio SDK 설정 가이드

## 현재 상태
✅ Android Studio 설치됨  
❌ Android SDK 미설치

## 다음 단계

### 1. Android Studio 실행
Android Studio가 열리면:

**처음 실행하는 경우:**
1. Welcome 화면에서 **Next** 클릭
2. **Standard** 설치 타입 선택
3. **Next** → **Finish**
4. SDK 다운로드 및 설치 대기 (시간 소요)

**이미 실행한 적이 있는 경우:**
1. **Preferences** (또는 **Settings**) 열기
   - Mac: `Cmd + ,`
   - 또는 **Android Studio** → **Preferences**
2. **Appearance & Behavior** → **System Settings** → **Android SDK**
3. **SDK Platforms** 탭에서 최신 Android 버전 선택 (예: Android 14, 15)
4. **SDK Tools** 탭에서 다음 확인:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools
   - ✅ Android SDK Platform-Tools
   - ✅ Android Emulator
5. **Apply** → **OK**
6. 설치 완료 대기

### 2. SDK 경로 확인
Android Studio에서:
- **Preferences** → **Appearance & Behavior** → **System Settings** → **Android SDK**
- **Android SDK Location** 확인 (보통: `~/Library/Android/sdk`)

### 3. 터미널에서 SDK 경로 설정
```bash
# SDK 경로 설정
flutter config --android-sdk ~/Library/Android/sdk

# 또는 실제 경로가 다르다면
flutter config --android-sdk <실제_경로>
```

### 4. 라이선스 승인
```bash
flutter doctor --android-licenses
```
모든 라이선스에 `y` 입력하고 Enter

### 5. 확인
```bash
flutter doctor
```
Android 관련 항목이 모두 ✅로 표시되어야 합니다.

### 6. 앱 실행
```bash
flutter run -d "adb-RFCT70T2NHP-uhRIz1._adb-tls-connect._tcp"
```

## 빠른 확인

SDK가 설치되었는지 확인:
```bash
ls ~/Library/Android/sdk
```

SDK가 설치되면 다음 폴더들이 보입니다:
- `platform-tools/`
- `platforms/`
- `build-tools/`
- `cmdline-tools/`

## 문제 해결

### SDK 경로를 찾을 수 없음
- Android Studio에서 SDK를 먼저 설치해야 합니다
- Android Studio → Preferences → Android SDK → SDK 설치

### 라이선스 승인 실패
- SDK가 완전히 설치되지 않았을 수 있습니다
- Android Studio에서 SDK 설치 완료 후 다시 시도

