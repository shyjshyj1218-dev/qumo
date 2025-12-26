# Flutter 앱 테스트 가이드

## Flutter vs Expo 테스트 방법 비교

### Expo (이전)
- QR 코드 스캔 → Expo Go 앱에서 실행
- 즉시 핫 리로드 가능
- 별도 빌드 불필요

### Flutter (현재)
- 시뮬레이터/에뮬레이터 또는 실제 기기 필요
- 빌드 후 실행
- 핫 리로드 지원 (개발 중)

## 테스트 방법

### 1. iOS 시뮬레이터 (Mac 전용) ⭐ 추천

**장점:**
- 빠른 실행
- 다양한 기기 크기 테스트 가능
- 무료

**실행 방법:**
```bash
# 시뮬레이터 목록 확인
open -a Simulator

# 또는 Flutter로 직접 실행
flutter run
```

**시뮬레이터 선택:**
```bash
# 사용 가능한 기기 목록 확인
flutter devices

# 특정 시뮬레이터 선택
flutter run -d "iPhone 15 Pro"
```

### 2. Android 에뮬레이터

**설정 필요:**
1. Android Studio 설치
2. AVD (Android Virtual Device) 생성

**실행 방법:**
```bash
# Android Studio에서 AVD Manager 열기
# Tools → Device Manager → Create Device

# 에뮬레이터 실행
flutter run
```

### 3. 실제 기기 (USB 연결) ⭐ 실제 테스트에 최적

**iOS (Mac 필요):**
```bash
# 1. iPhone을 Mac에 USB로 연결
# 2. 기기에서 "이 컴퓨터 신뢰" 선택
# 3. Xcode에서 개발자 계정 설정 (무료 계정 가능)
# 4. 실행
flutter run
```

**Android:**
```bash
# 1. Android 기기에서 개발자 옵션 활성화
#    설정 → 휴대전화 정보 → 빌드 번호 7번 탭
# 2. USB 디버깅 활성화
#    설정 → 개발자 옵션 → USB 디버깅
# 3. USB로 연결
# 4. 실행
flutter run
```

### 4. 웹 브라우저 (제한적)

**장점:**
- 빠른 테스트
- 별도 설정 불필요

**단점:**
- 일부 네이티브 기능 제한 (카메라, 푸시 알림 등)
- Supabase WebSocket이 제대로 작동하지 않을 수 있음

**실행:**
```bash
flutter run -d chrome
```

## 빠른 시작 가이드

### 현재 환경 확인
```bash
flutter doctor
flutter devices
```

### 가장 쉬운 방법 (Mac 사용자)
1. **iOS 시뮬레이터 사용** (가장 빠름)
   ```bash
   open -a Simulator
   flutter run
   ```

2. **실제 iPhone 사용** (가장 정확한 테스트)
   - USB 연결
   - Xcode에서 개발자 계정 설정
   - `flutter run`

### Android 사용자
1. **Android 에뮬레이터**
   - Android Studio 설치
   - AVD 생성
   - `flutter run`

2. **실제 Android 기기**
   - USB 디버깅 활성화
   - USB 연결
   - `flutter run`

## 개발 중 유용한 명령어

### 핫 리로드
- 코드 수정 후 저장하면 자동으로 리로드
- 또는 터미널에서 `r` 키 입력

### 핫 리스타트
- 상태 초기화가 필요할 때
- 터미널에서 `R` 키 입력

### 디버그 정보
- 터미널에서 `v` 키 입력 (verbose 모드)

### 앱 종료
- 터미널에서 `q` 키 입력

## 문제 해결

### "No devices found"
```bash
# 기기 목록 확인
flutter devices

# iOS 시뮬레이터 수동 실행
open -a Simulator

# Android 에뮬레이터 수동 실행
# Android Studio → Tools → Device Manager
```

### "Xcode not found" (iOS)
- App Store에서 Xcode 설치 필요
- 또는 Android 에뮬레이터 사용

### "Android SDK not found"
- Android Studio 설치 필요
- 또는 iOS 시뮬레이터 사용 (Mac)

## 추천 워크플로우

1. **개발 중**: iOS 시뮬레이터 또는 Android 에뮬레이터
   - 빠른 테스트
   - 핫 리로드로 즉시 확인

2. **실제 테스트**: 실제 기기
   - 성능 테스트
   - 실제 사용자 경험 확인
   - 네이티브 기능 테스트

3. **최종 확인**: 여러 기기에서 테스트
   - 다양한 화면 크기
   - iOS/Android 모두

