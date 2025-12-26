# Supabase 설정 가이드

## 1. Supabase 프로젝트 정보 확인

이전 프로젝트에서 사용하던 Supabase 프로젝트를 재사용할 수 있습니다.

### Supabase 프로젝트 정보 찾는 방법:

1. Supabase 대시보드 (https://app.supabase.com)에 로그인
2. 프로젝트 선택
3. Settings → API 메뉴로 이동
4. 다음 정보를 확인:
   - **Project URL**: `https://xxxxx.supabase.co` 형식
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` 형식

## 2. 환경 변수 설정

### 방법 1: .env 파일 사용 (권장)

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
API_BASE_URL=https://your-api-url.com
SOCKET_URL=https://your-socket-url.com
```

**중요**: `.env` 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다.

### 방법 2: constants.dart에 직접 설정

`.env` 파일을 사용하지 않으려면 `lib/utils/constants.dart`를 직접 수정하세요:

```dart
static String get supabaseUrl => 'https://your-project.supabase.co';
static String get supabaseAnonKey => 'your-anon-key-here';
```

## 3. 필요한 테이블 확인

Supabase 대시보드에서 다음 테이블들이 있는지 확인하세요:

- `users` - 사용자 정보
- `quiz_questions` - 퀴즈 문제
- `quiz_rooms` - 퀴즈방
- `matches` - 매칭 결과
- `missions` - 미션
- `shop_items` - 상점 아이템
- `quiz_results` - 퀴즈 결과

테이블이 없다면 SQL Editor에서 생성하세요. (README.md 참고)

## 4. Row Level Security (RLS) 설정

Supabase의 보안을 위해 RLS 정책을 설정해야 합니다.

### users 테이블 예시:

```sql
-- 사용자는 자신의 데이터만 읽을 수 있음
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- 사용자는 자신의 데이터만 업데이트할 수 있음
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);
```

## 5. 앱 실행

설정이 완료되면 앱을 실행하세요:

```bash
flutter pub get
flutter run
```

## 문제 해결

### "Invalid API key" 오류
- Supabase URL과 anon key가 올바른지 확인
- Supabase 대시보드에서 API 키가 활성화되어 있는지 확인

### "Table does not exist" 오류
- 필요한 테이블이 모두 생성되었는지 확인
- 테이블 이름이 정확한지 확인 (대소문자 구분)

### "Permission denied" 오류
- RLS 정책이 올바르게 설정되었는지 확인
- 인증된 사용자인지 확인

