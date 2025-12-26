# 테이블 스키마 변경 사항

## quiz_questions 테이블

### 실제 생성된 스키마
```sql
CREATE TABLE quiz_questions (
    id bigserial PRIMARY KEY,                         -- 자동 증가 기본 키
    question text NOT NULL,                           -- 문제 내용
    options jsonb NOT NULL,                           -- 선택지 배열
    answer text NOT NULL,                             -- 정답
    category text,                                    -- 카테고리 (예: 지리, 역사 등)
    difficulty text,                                  -- 난이도
    created_at timestamp with time zone DEFAULT now(), -- 생성일
    updated_at timestamp with time zone DEFAULT now()  -- 수정일
);
```

### 주요 차이점
1. **id 타입**: UUID → bigserial (자동 증가 정수)
   - 코드에서 `toString()`으로 처리하므로 문제없음
   - 조회 시 `int.tryParse()`로 변환하여 사용

2. **options 타입**: TEXT[] → jsonb
   - Supabase에서 자동으로 JSON 배열로 처리
   - Dart 코드에서 `List<dynamic>`으로 받아서 `List<String>`으로 변환

### 데이터 삽입 예시
```sql
-- JSON 배열 형식으로 삽입
INSERT INTO quiz_questions (question, options, answer, difficulty) VALUES
('1 + 1은?', '["1", "2", "3", "4"]'::jsonb, '2', 'beginner'),
('한국의 수도는?', '["서울", "부산", "대구", "인천"]'::jsonb, '서울', 'beginner');
```

또는 Supabase 대시보드에서:
```json
{
  "question": "1 + 1은?",
  "options": ["1", "2", "3", "4"],
  "answer": "2",
  "difficulty": "beginner"
}
```

## quiz_rooms 테이블

**상태**: 아직 생성하지 않음 (나중에 생성 예정)

현재 코드에서는 `quiz_rooms` 테이블을 사용하지 않으므로 문제없습니다.
퀴즈방 기능은 난이도별로 문제를 조회하는 방식으로 동작합니다.

## 다른 테이블들

나머지 테이블들은 제안한 스키마대로 생성되었다고 가정합니다:
- `users`
- `matches`
- `missions`
- `shop_items`
- `quiz_results`

