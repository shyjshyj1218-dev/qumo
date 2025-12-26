# 다음 단계 가이드

## ✅ 완료된 작업

1. 데이터베이스 컬럼 추가 완료
   - `users.last_game_time` (마지막 게임 시간)
   - `matches.game_completed_at` (게임 완료 시간)
   - `matches.mode` (게임 모드)

2. 서버 코드 업데이트 완료
   - 매칭 생성 시 `mode` 컬럼에 '1v1' 저장
   - 게임 시작 시 사용자의 `last_game_time` 업데이트
   - 게임 완료 시 `game_completed_at` 업데이트

## 🚀 다음 단계

### 1. Redis 설치 및 실행

```bash
# macOS
brew install redis
brew services start redis

# Linux
sudo apt-get install redis-server
sudo systemctl start redis

# Windows (WSL 또는 Docker)
docker run -d -p 6379:6379 redis
```

### 2. 백엔드 서버 설정 및 실행

```bash
cd server
npm install
```

`.env` 파일 생성:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres
REDIS_HOST=localhost
REDIS_PORT=6379
PORT=3001
```

서버 실행:
```bash
npm run dev  # 개발 모드 (nodemon 사용)
# 또는
npm start    # 프로덕션 모드
```

### 3. Flutter 클라이언트 설정

`.env` 파일에 Socket.io 서버 URL 추가:
```env
SOCKET_URL=http://localhost:3001
```

또는 `lib/utils/constants.dart`에서 직접 설정:
```dart
static String get socketUrl => 'http://localhost:3001';
```

### 4. 테스트

1. **서버 실행 확인**
   - 터미널에 "서버가 포트 3001에서 실행 중입니다" 메시지 확인

2. **Flutter 앱 실행**
   ```bash
   flutter run
   ```

3. **매칭 테스트**
   - 두 개의 디바이스/에뮬레이터에서 앱 실행
   - 각각 "시작하기" 버튼 클릭
   - 매칭 성공 확인
   - 게임 진행 및 결과 확인

## 📝 확인 사항

### 데이터베이스 확인

```sql
-- users 테이블에 last_game_time이 업데이트되는지 확인
SELECT id, nickname, last_game_time FROM users ORDER BY last_game_time DESC LIMIT 10;

-- matches 테이블에 mode와 game_completed_at이 저장되는지 확인
SELECT id, mode, game_completed_at, finished_at, status FROM matches ORDER BY created_at DESC LIMIT 10;
```

### 서버 로그 확인

- 매칭 요청 로그
- 게임 진행 상황 로그
- 레이팅 업데이트 로그
- 오류 메시지 확인

## 🔧 문제 해결

### Redis 연결 오류
- Redis가 실행 중인지 확인: `redis-cli ping` (응답: PONG)
- 포트 확인: 기본값 6379

### 데이터베이스 연결 오류
- `.env` 파일의 `DATABASE_URL` 확인
- Supabase 연결 정보 확인

### Socket.io 연결 오류
- 서버가 실행 중인지 확인
- Flutter 앱의 `SOCKET_URL` 확인
- 방화벽 설정 확인

## 📚 추가 리소스

- `IMPLEMENTATION_GUIDE.md`: 전체 구현 가이드
- `server/README.md`: 서버 설정 가이드
- `DATABASE_UPDATES.md`: 데이터베이스 업데이트 가이드








