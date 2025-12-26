# Flutter 앱 실행 가이드

## 기기 선택 프롬프트

Flutter가 여러 기기를 감지했을 때 다음과 같은 메시지가 나타납니다:

```
Please choose one (or "q" to quit):
```

## 선택 방법

### 1. 기기 목록 확인
프롬프트 위에 기기 목록이 표시됩니다:
```
1. macOS (desktop)
2. Chrome (web)
3. SM A336N (wireless) (mobile) • android-arm64
```

### 2. Android 기기 선택
**Android 기기 번호를 입력**하세요 (예: `3`)

### 3. 또는 직접 기기 지정
터미널에서 직접 Android 기기를 지정할 수도 있습니다:

```bash
# 무선으로 연결된 Android 기기로 실행
flutter run -d "adb-RFCT70T2NHP-uhRIz1._adb-tls-connect._tcp"

# 또는 간단하게
flutter run -d SM
```

## 빠른 실행 방법

### 방법 1: 기기 번호 입력
프롬프트에서 Android 기기 번호 입력 (예: `3`)

### 방법 2: 직접 지정하여 실행
```bash
flutter run -d "adb-RFCT70T2NHP-uhRIz1._adb-tls-connect._tcp"
```

### 방법 3: 기기 이름으로 실행
```bash
flutter run -d SM
```

## 앱 실행 후

앱이 실행되면:
- **`r`** - 핫 리로드 (코드 변경 즉시 반영)
- **`R`** - 핫 리스타트 (앱 재시작)
- **`q`** - 앱 종료

