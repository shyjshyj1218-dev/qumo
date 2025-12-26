# 데이터베이스 스키마 설명

## 테이블 구조 및 존재 이유

### 1. `users` - 사용자 정보 테이블

**존재 이유:**
- 앱의 핵심 사용자 데이터를 저장
- 인증된 사용자의 프로필 정보 관리
- 게임 내 재화(코인, 티켓) 및 레이팅 관리

**주요 필드:**
- `id`: 사용자 고유 ID (Supabase Auth의 user.id와 연결)
- `email`: 이메일 주소 (로그인용)
- `nickname`: 닉네임 (게임 내 표시명)
- `coins`: 코인 (게임 내 화폐)
- `tickets`: 티켓 (특별 아이템 구매용)
- `rating`: 레이팅 (ELO 시스템, 매칭에 사용)
- `profile_image`: 프로필 이미지 URL

**사용되는 곳:**
- 로그인/회원가입 시 프로필 생성
- 홈 화면 헤더에 사용자 정보 표시
- 프로필 화면에서 정보 수정
- 랭킹 시스템에서 순위 계산
- 매칭 시스템에서 레이팅 기반 매칭

---

### 2. `quiz_questions` - 퀴즈 문제 테이블

**존재 이유:**
- 모든 퀴즈 문제를 중앙에서 관리
- 난이도별, 카테고리별 문제 필터링
- 문제 재사용 및 통계 수집 가능

**주요 필드:**
- `id`: 문제 고유 ID
- `question`: 문제 텍스트
- `options`: 선택지 배열 (보통 4개)
- `answer`: 정답
- `category`: 카테고리 (선택사항)
- `difficulty`: 난이도 (beginner, intermediate, advanced, expert)

**사용되는 곳:**
- 퀴즈방 화면에서 문제 로드
- 난이도 선택 화면에서 필터링
- 실시간 매칭 게임에서 문제 세트 생성
- 도전 모드에서 문제 제공

---

### 3. `quiz_rooms` - 퀴즈방 테이블

**존재 이유:**
- 퀴즈방 세션 관리
- 난이도별 방 구분
- 방 상태 추적 (대기 중, 진행 중, 완료)

**주요 필드:**
- `id`: 방 고유 ID
- `difficulty`: 난이도
- `status`: 상태 (waiting, in_progress, finished)
- `created_at`: 생성 시간

**사용되는 곳:**
- 난이도별 퀴즈방 입장
- 방 상태 관리
- (향후 확장) 멀티플레이어 퀴즈방 지원 가능

**참고:** 현재는 단일 사용자 모드로 사용되지만, 향후 여러 사용자가 같은 방에 입장할 수 있도록 확장 가능

---

### 4. `matches` - 매칭 결과 테이블

**존재 이유:**
- 실시간 1:1 대전 결과 저장
- 게임 진행 상황 추적
- 승패 결과 및 레이팅 계산에 사용
- 게임 히스토리 관리

**주요 필드:**
- `id`: 매칭 고유 ID
- `player1_id`, `player2_id`: 참가자 ID
- `player1_progress`, `player2_progress`: 진행도 (몇 번째 문제까지 풀었는지)
- `player1_correct_count`, `player2_correct_count`: 정답 개수
- `player1_finish_time`, `player2_finish_time`: 완료 시간
- `result`: 결과 (win, lose, draw)
- `winner_id`: 승자 ID
- `created_at`, `finished_at`: 시작/종료 시간

**사용되는 곳:**
- 실시간 매칭 게임 화면에서 진행 상황 저장
- 게임 종료 후 결과 계산
- 레이팅 업데이트 (승리 시 레이팅 증가)
- 게임 히스토리 조회 (향후 기능)

**특징:**
- Socket.io와 연동하여 실시간으로 업데이트
- 두 플레이어 모두 완료하면 자동으로 결과 계산

---

### 5. `missions` - 미션 테이블

**존재 이유:**
- 일일/주간 미션 관리
- 사용자 참여 유도
- 보상 시스템 관리

**주요 필드:**
- `id`: 미션 고유 ID
- `title`: 미션 제목
- `description`: 미션 설명
- `reward_coins`: 보상 코인
- `reward_tickets`: 보상 티켓
- `created_at`: 생성 시간

**사용되는 곳:**
- 미션 화면에서 미션 목록 표시
- 미션 완료 시 보상 지급
- 사용자 참여 동기 부여

**예시 미션:**
- "오늘 10문제 풀기" → 100 코인 보상
- "3연승 달성" → 500 코인 + 1 티켓 보상
- "랭킹 대전 참여" → 200 코인 보상

---

### 6. `shop_items` - 상점 아이템 테이블

**존재 이유:**
- 게임 내 상점 아이템 관리
- 코인/티켓으로 구매 가능한 아이템 목록
- 아이템 정보 중앙 관리

**주요 필드:**
- `id`: 아이템 고유 ID
- `name`: 아이템 이름
- `description`: 아이템 설명
- `price_coins`: 코인 가격 (선택사항)
- `price_tickets`: 티켓 가격 (선택사항)
- `image_url`: 아이템 이미지 URL
- `created_at`: 생성 시간

**사용되는 곳:**
- 상점 화면에서 아이템 목록 표시
- 아이템 구매 처리
- 사용자 인벤토리 관리 (향후 기능)

**예시 아이템:**
- 힌트 티켓 (코인으로 구매)
- 프리미엄 테마 (티켓으로 구매)
- 특별 배경 (코인/티켓으로 구매)

---

### 7. `quiz_results` - 퀴즈 결과 테이블

**존재 이유:**
- 사용자의 퀴즈 풀이 기록 저장
- 통계 및 분석 데이터 수집
- 개인 성적 추적
- 오답 노트 기능 (향후)

**주요 필드:**
- `id`: 결과 고유 ID
- `user_id`: 사용자 ID
- `difficulty`: 난이도
- `correct_count`: 정답 개수
- `total_count`: 전체 문제 수
- `time_spent`: 소요 시간 (초)
- `created_at`: 완료 시간

**사용되는 곳:**
- 퀴즈 완료 시 결과 저장
- 통계 화면에서 성적 조회 (향후)
- 오답 노트에서 틀린 문제 추적 (향후)
- 개인 성장 그래프 (향후)

**특징:**
- 매칭 게임이 아닌 일반 퀴즈 풀이 결과만 저장
- 사용자의 학습 패턴 분석 가능

---

## 테이블 간 관계도

```
users (사용자)
  ├── matches (매칭 결과) - player1_id, player2_id
  ├── quiz_results (퀴즈 결과) - user_id
  └── (향후) user_missions (사용자 미션 완료 기록)
      └── missions (미션)

quiz_questions (문제)
  ├── quiz_rooms (퀴즈방) - difficulty로 연결
  └── (Socket.io를 통해 matches에 전달)

shop_items (상점 아이템)
  └── (향후) user_inventory (사용자 인벤토리)
      └── users
```

## 데이터 흐름 예시

### 1. 사용자 로그인 → 퀴즈 풀이
```
users (로그인) 
  → quiz_questions (문제 조회)
  → quiz_results (결과 저장)
  → users (코인/티켓 업데이트)
```

### 2. 실시간 매칭 게임
```
users (매칭 요청)
  → Socket.io (매칭 서버)
  → matches (매칭 생성)
  → quiz_questions (문제 세트 생성)
  → matches (진행 상황 업데이트)
  → matches (결과 계산)
  → users (레이팅 업데이트)
```

### 3. 미션 완료
```
missions (미션 조회)
  → (사용자 행동)
  → missions (완료 처리)
  → users (보상 지급)
```

## 향후 확장 가능한 테이블

1. **`user_missions`** - 사용자별 미션 완료 기록
2. **`user_inventory`** - 사용자 인벤토리 (구매한 아이템)
3. **`friends`** - 친구 관계
4. **`achievements`** - 업적 시스템
5. **`daily_challenges`** - 일일 챌린지
6. **`notifications`** - 알림 시스템

