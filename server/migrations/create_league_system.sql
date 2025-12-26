-- 리그 시스템 테이블 생성

-- 1. 리그 테이블 (주간 리그 정보)
CREATE TABLE IF NOT EXISTS leagues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier VARCHAR(20) NOT NULL, -- bronze, silver, gold, sapphire, ruby, diamond, crystal
  week_start_date DATE NOT NULL, -- 리그 시작일 (월요일)
  week_end_date DATE NOT NULL, -- 리그 종료일 (일요일)
  season_number INTEGER NOT NULL DEFAULT 1, -- 시즌 번호
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tier, week_start_date) -- 같은 티어에서 같은 주는 중복 불가
);

-- 2. 리그 랭킹 테이블 (사용자의 주간 리그 점수)
CREATE TABLE IF NOT EXISTS league_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  league_id UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
  rating_at_start INTEGER NOT NULL, -- 리그 시작 시 레이팅
  rating_at_end INTEGER, -- 리그 종료 시 레이팅 (NULL이면 진행 중)
  league_score INTEGER DEFAULT 0, -- 리그 점수 (rating_at_end - rating_at_start)
  rank INTEGER, -- 리그 내 순위 (NULL이면 아직 계산 안됨)
  promoted BOOLEAN DEFAULT FALSE, -- 승급 여부
  demoted BOOLEAN DEFAULT FALSE, -- 강등 여부
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, league_id) -- 한 사용자는 한 리그에 한 번만 참여
);

-- 3. users 테이블에 리그 필드 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS current_league_tier VARCHAR(20) DEFAULT 'bronze',
ADD COLUMN IF NOT EXISTS current_league_id UUID REFERENCES leagues(id);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_league_rankings_user_id ON league_rankings(user_id);
CREATE INDEX IF NOT EXISTS idx_league_rankings_league_id ON league_rankings(league_id);
CREATE INDEX IF NOT EXISTS idx_league_rankings_league_score ON league_rankings(league_id, league_score DESC);
CREATE INDEX IF NOT EXISTS idx_leagues_week_start ON leagues(week_start_date);
CREATE INDEX IF NOT EXISTS idx_users_league_tier ON users(current_league_tier);

-- 주석 추가
COMMENT ON TABLE leagues IS '주간 리그 정보 테이블';
COMMENT ON TABLE league_rankings IS '사용자의 주간 리그 랭킹 및 점수';
COMMENT ON COLUMN users.current_league_tier IS '현재 사용자가 속한 리그 티어';
COMMENT ON COLUMN users.current_league_id IS '현재 사용자가 참여 중인 리그 ID';
