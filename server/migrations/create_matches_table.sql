-- 매칭 결과 테이블 생성
CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  player2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  player1_progress INTEGER DEFAULT 0,
  player2_progress INTEGER DEFAULT 0,
  player1_correct_count INTEGER DEFAULT 0,
  player2_correct_count INTEGER DEFAULT 0,
  player1_finish_time TIMESTAMP WITH TIME ZONE,
  player2_finish_time TIMESTAMP WITH TIME ZONE,
  result TEXT, -- win, lose, draw, surrender
  winner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'in_progress', -- waiting, in_progress, finished
  mode TEXT DEFAULT '1v1', -- 1v1, tournament, friend_match 등
  questions JSONB, -- 사용된 문제 ID 배열
  game_completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  finished_at TIMESTAMP WITH TIME ZONE
);

-- 인덱스 생성 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_matches_player1_id ON matches(player1_id);
CREATE INDEX IF NOT EXISTS idx_matches_player2_id ON matches(player2_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_mode ON matches(mode);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at);
CREATE INDEX IF NOT EXISTS idx_matches_winner_id ON matches(winner_id);

-- 주석 추가
COMMENT ON TABLE matches IS '실시간 1:1 대전 결과 저장 테이블';
COMMENT ON COLUMN matches.status IS '매칭 상태: waiting(대기), in_progress(진행중), finished(완료)';
COMMENT ON COLUMN matches.mode IS '게임 모드: 1v1(일반 대전), tournament(토너먼트), friend_match(친구 대전)';
COMMENT ON COLUMN matches.questions IS '사용된 문제 ID 배열 (JSON 형식)';
COMMENT ON COLUMN matches.result IS '게임 결과: win(승리), lose(패배), draw(무승부), surrender(기권)';
