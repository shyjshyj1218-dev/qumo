# 빠른 테스트 시작 가이드

## 현재 사용 가능한 옵션

### ✅ 1. 웹 브라우저 (Chrome) - 가장 빠름! ⭐

**지금 바로 실행 가능:**
```bash
flutter run -d chrome
```

**장점:**
- 즉시 실행 가능
- 별도 설정 불필요
- 빠른 핫 리로드

**단점:**
- 일부 네이티브 기능 제한 (카메라, 푸시 알림 등)
- Supabase WebSocket이 제대로 작동하지 않을 수 있음

### ✅ 2. macOS 데스크톱 앱

```bash
flutter run -d macos
```

**장점:**
- 네이티브 앱처럼 실행
- 빠른 테스트

**단점:**
- 모바일 UI가 아닌 데스크톱 UI

### ⚠️ 3. iOS 시뮬레이터 (설정 필요)

**Xcode 완전 설치 필요:**
1. App Store에서 Xcode 설치 (용량 큼, 시간 소요)
2. 설치 후:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. 실행:
   ```bash
   open -a Simulator
   flutter run
   ```

### ⚠️ 4. Android 에뮬레이터 (설정 필요)

**Android Studio 설치 필요:**
1. https://developer.android.com/studio 에서 다운로드
2. Android Studio 설치 및 AVD 생성
3. 실행:
   ```bash
   flutter run
   ```

## 추천 순서

### 지금 바로 테스트하고 싶다면:
```bash
# 1. 웹 브라우저로 실행 (가장 빠름)
flutter run -d chrome
```

### 모바일 앱처럼 테스트하고 싶다면:

**옵션 A: iPhone이 있다면**
1. iPhone을 Mac에 USB로 연결
2. Xcode 설치 (App Store)
3. Xcode에서 개발자 계정 설정 (무료 계정 가능)
4. `flutter run` 실행

**옵션 B: Android 기기가 있다면**
1. Android Studio 설치
2. Android 기기에서 USB 디버깅 활성화
3. USB 연결
4. `flutter run` 실행

**옵션 C: 시뮬레이터 사용**
1. Xcode 설치 (iOS) 또는 Android Studio 설치 (Android)
2. 시뮬레이터/에뮬레이터 실행
3. `flutter run` 실행

## 개발 중 유용한 단축키

앱이 실행 중일 때 터미널에서:

- `r` - 핫 리로드 (코드 변경 즉시 반영)
- `R` - 핫 리스타트 (앱 재시작)
- `q` - 앱 종료
- `v` - 상세 로그 보기

## 문제 해결

### "No devices found"
```bash
# 사용 가능한 기기 확인
flutter devices

# 웹 브라우저로 실행
flutter run -d chrome
```

### Supabase 연결 오류 (웹)
- 웹에서는 WebSocket이 제대로 작동하지 않을 수 있음
- 실제 모바일 기기나 시뮬레이터에서 테스트 권장

### 빌드 오류
```bash
# 클린 빌드
flutter clean
flutter pub get
flutter run
```

