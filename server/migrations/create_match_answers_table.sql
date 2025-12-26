-- 매칭별 문제 정답 기록 테이블
-- 각 문제별로 사용자가 맞췄는지 틀렸는지 정확히 기록
-- 주의: 이 테이블을 생성하기 전에 matches 테이블이 먼저 생성되어 있어야 합니다.

CREATE TABLE IF NOT EXISTS match_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  question_id BIGINT NOT NULL, -- quiz_questions의 id (bigserial)
  is_correct BOOLEAN NOT NULL, -- 정답 여부
  answered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(match_id, user_id, question_id) -- 같은 매칭에서 같은 사용자가 같은 문제에 중복 답변 불가
);

-- 인덱스 생성 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_match_answers_match_id ON match_answers(match_id);
CREATE INDEX IF NOT EXISTS idx_match_answers_user_id ON match_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_match_answers_question_id ON match_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_match_answers_user_question ON match_answers(user_id, question_id);
CREATE INDEX IF NOT EXISTS idx_match_answers_user_correct ON match_answers(user_id, is_correct);

-- 주석 추가
COMMENT ON TABLE match_answers IS '매칭별 사용자의 문제별 정답 기록';
COMMENT ON COLUMN match_answers.is_correct IS '정답 여부 (true: 정답, false: 오답)';
COMMENT ON COLUMN match_answers.question_id IS 'quiz_questions 테이블의 id (bigserial)';
