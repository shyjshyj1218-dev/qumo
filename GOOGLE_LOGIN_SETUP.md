# Supabase 구글 로그인 설정 가이드

## 📋 전체 설정 단계

### 1단계: Google Cloud Console 설정

#### 1-1. Google Cloud Console 접속
1. https://console.cloud.google.com 접속
2. Google 계정으로 로그인

#### 1-2. 새 프로젝트 생성 (또는 기존 프로젝트 선택)
1. 상단 프로젝트 선택 드롭다운 클릭
2. "새 프로젝트" 클릭
3. 프로젝트 이름 입력 (예: `qumo-app`)
4. "만들기" 클릭

#### 1-3. OAuth 동의 화면 설정
1. 왼쪽 메뉴에서 **"API 및 서비스"** → **"OAuth 동의 화면"** 클릭
2. **"외부"** 선택 → **"만들기"** 클릭
3. 필수 정보 입력:
   - **앱 이름**: `Qumo` (또는 원하는 이름)
   - **사용자 지원 이메일**: 본인 이메일 선택
   - **앱 로고**: (선택사항)
   - **앱 도메인**: (선택사항)
   - **개발자 연락처 정보**: 본인 이메일 입력
4. **"저장 후 계속"** 클릭
5. **"범위"** 화면에서 **"저장 후 계속"** 클릭 (기본 범위 사용)
6. **"테스트 사용자"** 화면에서 (선택사항) **"저장 후 계속"** 클릭
7. **"요약"** 화면에서 **"대시보드로 돌아가기"** 클릭

#### 1-4. OAuth 2.0 클라이언트 ID 생성
1. 왼쪽 메뉴에서 **"API 및 서비스"** → **"사용자 인증 정보"** 클릭
2. 상단 **"+ 사용자 인증 정보 만들기"** 클릭
3. **"OAuth 클라이언트 ID"** 선택
4. **애플리케이션 유형**: **"웹 애플리케이션"** 선택
5. **이름**: `Qumo Web Client` (또는 원하는 이름)
6. **승인된 리디렉션 URI**에 다음 URL 추가:
   ```
   https://zrmxmcffqzpdhwqsrnzt.supabase.co/auth/v1/callback
   ```
   ⚠️ **중요**: `zrmxmcffqzpdhwqsrnzt` 부분을 본인의 Supabase 프로젝트 ID로 변경하세요!
   
   Supabase 프로젝트 ID 확인 방법:
   - Supabase 대시보드 → Settings → API
   - Project URL에서 확인: `https://[프로젝트ID].supabase.co`
   
7. **"만들기"** 클릭
8. **클라이언트 ID**와 **클라이언트 보안 비밀번호** 복사 (나중에 필요)

---

### 2단계: Supabase 설정

#### 2-1. Supabase 대시보드 접속
1. https://app.supabase.com 접속
2. 프로젝트 선택 (또는 새 프로젝트 생성)

#### 2-2. Authentication 설정
1. 왼쪽 메뉴에서 **"Authentication"** 클릭
2. 상단 탭에서 **"Providers"** 클릭

#### 2-3. Google Provider 활성화
1. **"Google"** 섹션 찾기
2. **"Enable Google provider"** 토글을 **ON**으로 변경
3. 다음 정보 입력:
   - **Client ID (for OAuth)**: Google Cloud Console에서 복사한 클라이언트 ID
   - **Client Secret (for OAuth)**: Google Cloud Console에서 복사한 클라이언트 보안 비밀번호
4. **"Save"** 클릭

#### 2-4. Redirect URLs 설정
1. **"Authentication"** → **"URL Configuration"** 메뉴로 이동
2. **"Redirect URLs"** 섹션에서 다음 URL들을 추가:

   **웹 개발용 (로컬호스트)**:
   ```
   http://localhost:*
   http://127.0.0.1:*
   ```
   
   **프로덕션용 (실제 도메인)**:
   ```
   https://yourdomain.com/**
   ```
   
   ⚠️ **중요**: 
   - `*`는 와일드카드로 모든 포트를 허용합니다
   - 개발 중에는 `http://localhost:*`를 추가하면 됩니다
   - 실제 배포 시에는 정확한 도메인을 입력하세요

3. **"Save"** 클릭

---

### 3단계: Flutter 앱 코드 확인

#### 3-1. 현재 코드 확인
현재 `lib/services/auth_service.dart` 파일이 다음과 같이 설정되어 있는지 확인:

```dart
Future<bool> signInWithGoogle() async {
  // 웹: 현재 실행 중인 origin으로 리다이렉트
  // 모바일: 딥링크 사용
  final redirect = kIsWeb
      ? Uri.base
          .replace(path: '/', fragment: '')
          .toString()
      : 'io.supabase.flutterquickstart://login-callback/';

  return await _auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: redirect,
  );
}
```

이 코드는 자동으로 현재 실행 중인 URL을 감지하므로 추가 설정이 필요 없습니다.

---

### 4단계: 테스트

#### 4-1. 앱 실행
```bash
flutter run -d chrome
```

#### 4-2. 구글 로그인 테스트
1. 앱에서 "구글 로그인" 버튼 클릭
2. Google 로그인 창이 열리는지 확인
3. Google 계정 선택 및 로그인
4. 로그인 후 앱으로 자동 리다이렉트되는지 확인
5. 홈 화면으로 이동하는지 확인

---

## 🔧 문제 해결

### 문제 1: "localhost에서 연결을 거부했습니다"
**원인**: Redirect URL이 Supabase에 등록되지 않았거나, 포트가 다릅니다.

**해결 방법**:
1. Supabase 대시보드 → Authentication → URL Configuration
2. Redirect URLs에 `http://localhost:*` 추가
3. 앱 재시작

### 문제 2: "redirect_uri_mismatch" 오류
**원인**: Google Cloud Console의 리디렉션 URI가 Supabase 콜백 URL과 일치하지 않습니다.

**해결 방법**:
1. Google Cloud Console → 사용자 인증 정보
2. OAuth 클라이언트 ID 클릭
3. "승인된 리디렉션 URI"에 다음 추가:
   ```
   https://[본인의-Supabase-프로젝트-ID].supabase.co/auth/v1/callback
   ```
4. 저장 후 다시 시도

### 문제 3: 로그인 후 홈 화면으로 이동하지 않음
**원인**: 로그인 성공 후 리다이렉트 처리가 제대로 되지 않습니다.

**해결 방법**:
1. `lib/screens/auth/auth_screen.dart`의 `_handleGoogleLogin` 메서드 확인
2. 로그인 성공 후 `context.go('/home')`가 호출되는지 확인
3. 브라우저 콘솔에서 오류 확인

---

## 📝 체크리스트

설정이 완료되었는지 확인하세요:

- [ ] Google Cloud Console에서 프로젝트 생성 완료
- [ ] OAuth 동의 화면 설정 완료
- [ ] OAuth 클라이언트 ID 생성 완료
- [ ] Google Cloud Console에 Supabase 콜백 URL 추가 완료
- [ ] Supabase에서 Google Provider 활성화 완료
- [ ] Supabase에 Client ID와 Secret 입력 완료
- [ ] Supabase Redirect URLs에 `http://localhost:*` 추가 완료
- [ ] Flutter 앱에서 구글 로그인 테스트 완료

---

## 💡 추가 팁

### 개발 중 포트 고정하기
매번 다른 포트로 실행되는 것을 방지하려면:

```bash
flutter run -d chrome --web-port 3000
```

그리고 Supabase Redirect URLs에:
```
http://localhost:3000/**
```

### 프로덕션 배포 시
실제 도메인으로 배포할 때는:
1. Google Cloud Console에 프로덕션 도메인 추가
2. Supabase Redirect URLs에 프로덕션 도메인 추가
3. 환경 변수 확인

---

## 📚 참고 자료

- [Supabase Auth 문서](https://supabase.com/docs/guides/auth)
- [Google OAuth 문서](https://developers.google.com/identity/protocols/oauth2)
- [Flutter Supabase 문서](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
