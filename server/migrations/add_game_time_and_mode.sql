-- 사용자 테이블에 마지막 게임 시간 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS last_game_time TIMESTAMP WITH TIME ZONE;

-- 매칭 테이블에 게임 완료 시간 및 게임 모드 추가
ALTER TABLE matches
ADD COLUMN IF NOT EXISTS game_completed_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE matches
ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT '1v1';

-- 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_users_last_game_time ON users(last_game_time);
CREATE INDEX IF NOT EXISTS idx_matches_mode ON matches(mode);
CREATE INDEX IF NOT EXISTS idx_matches_game_completed_at ON matches(game_completed_at);

-- 주석 추가
COMMENT ON COLUMN users.last_game_time IS '사용자가 마지막으로 게임을 플레이한 시간';
COMMENT ON COLUMN matches.game_completed_at IS '게임이 완료된 시간';
COMMENT ON COLUMN matches.mode IS '게임 모드 (1v1, tournament, friend_match 등)';








