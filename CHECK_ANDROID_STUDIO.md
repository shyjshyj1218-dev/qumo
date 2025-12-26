# Android Studio 설치 확인 방법

## 확인 방법

### 1. Applications 폴더 확인
```bash
ls -la /Applications/Android\ Studio.app
```
또는 Finder에서:
- **Finder** → **Applications** → **Android Studio** 폴더 확인

### 2. Homebrew 설치 확인
```bash
brew list --cask | grep android-studio
```

### 3. 실행 가능 여부 확인
```bash
open -a "Android Studio"
```

## 설치 완료 후 다음 단계

### 1. Android Studio 실행
```bash
open -a "Android Studio"
```
또는 Applications 폴더에서 직접 실행

### 2. 첫 실행 시 설정
- Welcome 화면에서 **Next** 클릭
- **Standard** 설치 선택 (SDK 자동 설치)
- 설치 완료까지 대기 (시간 소요)

### 3. SDK 경로 확인
Android Studio 실행 후:
- **Preferences** (또는 **Settings**) → **Appearance & Behavior** → **System Settings** → **Android SDK**
- SDK Location 확인 (보통: `~/Library/Android/sdk`)

### 4. Flutter에 SDK 경로 알려주기
```bash
# SDK 경로 설정 (일반적인 경로)
flutter config --android-sdk ~/Library/Android/sdk

# 또는 실제 경로 확인 후
flutter config --android-sdk <실제_SDK_경로>
```

### 5. 라이선스 승인
```bash
flutter doctor --android-licenses
```
모든 라이선스에 `y` 입력

### 6. 확인
```bash
flutter doctor
```

## 빠른 확인 스크립트

터미널에서 실행:
```bash
# Android Studio 설치 확인
if [ -d "/Applications/Android Studio.app" ]; then
    echo "✅ Android Studio 설치됨"
    open -a "Android Studio"
else
    echo "❌ Android Studio가 설치되지 않았습니다"
fi
```

