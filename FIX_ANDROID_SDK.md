# Android SDK 라이선스 문제 해결

## 문제
Android SDK 라이선스가 승인되지 않아 빌드가 실패했습니다.

## 해결 방법

### 방법 1: Android Studio 설치 (추천) ⭐

**가장 확실한 방법:**

1. **Android Studio 다운로드**
   - https://developer.android.com/studio
   - 또는 Homebrew로 설치:
     ```bash
     brew install --cask android-studio
     ```

2. **Android Studio 실행**
   - 첫 실행 시 SDK 자동 설치
   - SDK Manager에서 필요한 컴포넌트 설치

3. **라이선스 승인**
   ```bash
   flutter doctor --android-licenses
   ```
   - 모든 라이선스에 `y` 입력

4. **환경 변수 설정 (필요시)**
   ```bash
   # Android SDK 경로 확인 (Android Studio 설치 후)
   # 일반적으로: ~/Library/Android/sdk
   
   # Flutter에 SDK 경로 알려주기
   flutter config --android-sdk ~/Library/Android/sdk
   ```

### 방법 2: Android SDK Command-line Tools만 설치

```bash
# 1. Android SDK Command-line Tools 설치
brew install --cask android-commandlinetools

# 2. SDK 경로 설정
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 3. 필요한 패키지 설치
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# 4. 라이선스 승인
sdkmanager --licenses
# 모든 라이선스에 y 입력

# 5. Flutter에 SDK 경로 알려주기
flutter config --android-sdk $ANDROID_HOME
```

## 빠른 해결 (Android Studio 설치)

```bash
# Android Studio 설치
brew install --cask android-studio

# 설치 후 Android Studio 실행하여 SDK 설정 완료
# 그 다음:
flutter doctor --android-licenses
```

## 확인

```bash
# Flutter 환경 확인
flutter doctor

# Android 라이선스 확인
flutter doctor --android-licenses
```

