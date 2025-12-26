-- 사용자 미션 완료 기록 테이블
CREATE TABLE IF NOT EXISTS user_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress INTEGER DEFAULT 0, -- 미션 진행도 (예: 3번 중 2번 완료)
  target_value INTEGER DEFAULT 1, -- 목표 값 (예: 3번 매칭)
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, mission_id, DATE(completed_at)) -- 같은 미션은 하루에 한 번만 완료 가능
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_missions_user_id ON user_missions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_missions_mission_id ON user_missions(mission_id);
CREATE INDEX IF NOT EXISTS idx_user_missions_completed_at ON user_missions(completed_at);

-- missions 테이블에 미션 타입 추가
ALTER TABLE missions 
ADD COLUMN IF NOT EXISTS mission_type VARCHAR(50) DEFAULT 'daily', -- daily, weekly, achievement
ADD COLUMN IF NOT EXISTS target_value INTEGER DEFAULT 1, -- 목표 값 (예: 3번 매칭)
ADD COLUMN IF NOT EXISTS reset_type VARCHAR(20) DEFAULT 'daily'; -- daily, weekly, never

-- 주석 추가
COMMENT ON TABLE user_missions IS '사용자별 미션 완료 기록';
COMMENT ON COLUMN user_missions.progress IS '미션 진행도 (현재 완료한 횟수)';
COMMENT ON COLUMN user_missions.target_value IS '목표 값 (완료해야 하는 횟수)';
COMMENT ON COLUMN missions.mission_type IS '미션 타입: daily(일일), weekly(주간), achievement(업적)';
COMMENT ON COLUMN missions.target_value IS '목표 값 (예: 3번 매칭, 10문제 풀기 등)';
COMMENT ON COLUMN missions.reset_type IS '리셋 타입: daily(매일), weekly(매주), never(한 번만)';
