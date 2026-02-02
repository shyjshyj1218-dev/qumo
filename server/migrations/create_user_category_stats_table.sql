-- 사용자 카테고리별 능력치 테이블 생성
CREATE TABLE IF NOT EXISTS user_category_stats (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  games_played INTEGER NOT NULL DEFAULT 0,
  생활 DOUBLE PRECISION NOT NULL DEFAULT 0,
  사회 DOUBLE PRECISION NOT NULL DEFAULT 0,
  과학 DOUBLE PRECISION NOT NULL DEFAULT 0,
  지리 DOUBLE PRECISION NOT NULL DEFAULT 0,
  역사 DOUBLE PRECISION NOT NULL DEFAULT 0,
  IT DOUBLE PRECISION NOT NULL DEFAULT 0,
  스포츠 DOUBLE PRECISION NOT NULL DEFAULT 0,
  문화 DOUBLE PRECISION NOT NULL DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_category_stats_user_id ON user_category_stats(user_id);

-- 주석 추가
COMMENT ON TABLE user_category_stats IS '사용자 카테고리별 능력치 (8각형 레이더 그래프용)';
COMMENT ON COLUMN user_category_stats.games_played IS '플레이한 게임 횟수 (EMA 계산용)';
COMMENT ON COLUMN user_category_stats.생활 IS '생활 카테고리 EMA 점수';
COMMENT ON COLUMN user_category_stats.사회 IS '사회 카테고리 EMA 점수';
COMMENT ON COLUMN user_category_stats.과학 IS '과학 카테고리 EMA 점수';
COMMENT ON COLUMN user_category_stats.지리 IS '지리 카테고리 EMA 점수';
COMMENT ON COLUMN user_category_stats.역사 IS '역사 카테고리 EMA 점수';
COMMENT ON COLUMN user_category_stats.IT IS 'IT 카테고리 EMA 점수';
COMMENT ON COLUMN user_category_stats.스포츠 IS '스포츠 카테고리 EMA 점수';
COMMENT ON COLUMN user_category_stats.문화 IS '문화 카테고리 EMA 점수';

