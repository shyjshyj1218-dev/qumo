# Supabase 연결 테스트

## 설정 완료 ✅

다음 정보로 설정되었습니다:
- **Supabase URL**: https://zrmxmcffqzpdhwqsrnzt.supabase.co
- **Anon Key**: 설정 완료

## 다음 단계

### 1. 앱 실행 테스트

```bash
flutter run
```

앱이 정상적으로 시작되면 Supabase 연결이 성공한 것입니다.

### 2. 필요한 테이블 확인

Supabase 대시보드 (https://app.supabase.com)에서 다음 테이블들이 있는지 확인하세요:

필수 테이블:
- ✅ `users` - 사용자 정보
- ✅ `quiz_questions` - 퀴즈 문제
- ✅ `quiz_rooms` - 퀴즈방
- ✅ `matches` - 매칭 결과
- ✅ `missions` - 미션
- ✅ `shop_items` - 상점 아이템
- ✅ `quiz_results` - 퀴즈 결과

### 3. 테이블이 없다면 생성

Supabase 대시보드의 SQL Editor에서 다음 SQL을 실행하세요:

```sql
-- users 테이블
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  nickname TEXT NOT NULL,
  coins INTEGER DEFAULT 0,
  tickets INTEGER DEFAULT 0,
  rating INTEGER DEFAULT 1000,
  profile_image TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- quiz_questions 테이블
CREATE TABLE IF NOT EXISTS quiz_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question TEXT NOT NULL,
  options TEXT[] NOT NULL,
  answer TEXT NOT NULL,
  category TEXT,
  difficulty TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- matches 테이블
CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  player1_id UUID REFERENCES users(id),
  player2_id UUID REFERENCES users(id),
  player1_progress INTEGER DEFAULT 0,
  player2_progress INTEGER DEFAULT 0,
  player1_correct_count INTEGER DEFAULT 0,
  player2_correct_count INTEGER DEFAULT 0,
  player1_finish_time TIMESTAMP,
  player2_finish_time TIMESTAMP,
  result TEXT,
  winner_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  finished_at TIMESTAMP
);

-- missions 테이블
CREATE TABLE IF NOT EXISTS missions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  reward_coins INTEGER DEFAULT 0,
  reward_tickets INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- shop_items 테이블
CREATE TABLE IF NOT EXISTS shop_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price_coins INTEGER,
  price_tickets INTEGER,
  image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- quiz_results 테이블
CREATE TABLE IF NOT EXISTS quiz_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  difficulty TEXT NOT NULL,
  correct_count INTEGER NOT NULL,
  total_count INTEGER NOT NULL,
  time_spent INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- quiz_rooms 테이블
CREATE TABLE IF NOT EXISTS quiz_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  difficulty TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'waiting',
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 4. Row Level Security (RLS) 설정

보안을 위해 RLS 정책을 설정하는 것을 권장합니다:

```sql
-- users 테이블 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid()::text = id::text);

-- 공개 읽기 가능한 테이블들
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Quiz questions are viewable by everyone" ON quiz_questions
  FOR SELECT USING (true);

ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Missions are viewable by everyone" ON missions
  FOR SELECT USING (true);

ALTER TABLE shop_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Shop items are viewable by everyone" ON shop_items
  FOR SELECT USING (true);
```

## 문제 해결

### "Invalid API key" 오류
- Supabase URL과 anon key가 올바른지 확인
- `.env` 파일이 프로젝트 루트에 있는지 확인

### "Table does not exist" 오류
- 필요한 테이블이 모두 생성되었는지 확인
- 테이블 이름이 정확한지 확인 (대소문자 구분)

### "Permission denied" 오류
- RLS 정책이 올바르게 설정되었는지 확인
- 인증된 사용자인지 확인

