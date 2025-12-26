// .env 파일 경로 설정 (루트 디렉토리의 .env 사용)
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const redis = require('redis');
const { Pool } = require('pg');
const { Glicko2 } = require('glicko2');

const app = express();
const server = http.createServer(app);

// CORS 설정
const io = new Server(server, {
  cors: {
    origin: "*", // 프로덕션에서는 특정 도메인으로 제한
    methods: ["GET", "POST"]
  }
});

// PostgreSQL 연결
const dbUrl = process.env.DATABASE_URL || process.env.SUPABASE_DB_URL;
console.log('데이터베이스 URL 확인:', dbUrl ? '설정됨' : '설정 안됨');

// Supabase 연결 설정 (IPv4만 사용)
const pool = new Pool({
  connectionString: dbUrl,
  ssl: dbUrl && dbUrl.includes('supabase') ? { 
    rejectUnauthorized: false
  } : false,
  connectionTimeoutMillis: 30000,
  max: 10,
});

// PostgreSQL 연결 테스트
pool.on('error', (err) => {
  console.error('PostgreSQL 연결 오류:', err);
});

pool.query('SELECT NOW()').then(() => {
  console.log('PostgreSQL 연결 성공');
}).catch((err) => {
  console.error('PostgreSQL 연결 실패:');
  console.error('에러 메시지:', err.message);
  console.error('에러 코드:', err.code);
  console.error('전체 에러:', err);
  console.log('데이터베이스 연결 없이 계속 진행합니다...');
});

// Redis 클라이언트
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379
});

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err.message);
  console.log('Redis 연결 실패 - 매칭 기능이 제한될 수 있습니다.');
});

// Redis 연결 (실패해도 서버는 계속 실행)
redisClient.connect().catch((err) => {
  console.error('Redis 연결 실패:', err.message);
  console.log('Redis 없이 서버를 계속 실행합니다. 매칭 기능이 제한될 수 있습니다.');
});

// Glicko-2 설정
const glickoSettings = {
  tau: 0.5,
  rating: 1500,
  rd: 350,
  vol: 0.06
};

const ranking = new Glicko2(glickoSettings);

// 매칭 큐 관리
const matchQueue = new Map(); // userId -> { socketId, rating, startTime, range }
const activeMatches = new Map(); // matchId -> match data
const userSockets = new Map(); // userId -> socketId

// 매칭 범위 확장 함수
function expandMatchRange(userId) {
  const user = matchQueue.get(userId);
  if (!user) return;
  
  // 매칭 범위를 점차 확장: ±25, ±50, ±75, ±100, ...
  const expansions = [25, 50, 75, 100, 150, 200, 300, 500];
  const currentRange = user.range || 25;
  const nextIndex = expansions.findIndex(r => r > currentRange);
  
  if (nextIndex !== -1) {
    user.range = expansions[nextIndex];
    console.log(`매칭 범위 확장: 사용자 ${userId}, 새 범위: ±${user.range}`);
  }
}

// 메모리 기반 매칭 (Redis 없을 때 사용)
function _tryMatchFromMemory(userId, minRating, maxRating) {
  for (const [otherUserId, otherUser] of matchQueue.entries()) {
    if (otherUserId === userId) continue;
    
    if (otherUser.rating >= minRating && otherUser.rating <= maxRating) {
      // 매칭 성공!
      matchQueue.delete(userId);
      matchQueue.delete(otherUserId);
      
      return {
        userId: otherUser.userId,
        socketId: otherUser.socketId,
        rating: otherUser.rating
      };
    }
  }
  
  return null;
}

// 매칭 시도 함수
async function tryMatch(userId) {
  const user = matchQueue.get(userId);
  if (!user) return null;

  const minRating = user.rating - user.range;
  const maxRating = user.rating + user.range;

  // Redis에서 매칭 가능한 사용자 찾기
  try {
    // Redis 연결 확인
    if (!redisClient.isOpen) {
      // Redis가 연결되지 않았으면 메모리 큐만 사용
      return _tryMatchFromMemory(userId, minRating, maxRating);
    }
    
  const queueKey = 'match_queue';
  const allUsers = await redisClient.hGetAll(queueKey);
  
  for (const [otherUserId, data] of Object.entries(allUsers)) {
    if (otherUserId === userId) continue;
    
    const otherUser = JSON.parse(data);
    if (otherUser.rating >= minRating && otherUser.rating <= maxRating) {
      // 매칭 성공!
      await redisClient.hDel(queueKey, userId, otherUserId);
      matchQueue.delete(userId);
      matchQueue.delete(otherUserId);
      
      return otherUser;
    }
    }
  } catch (err) {
    // Redis 오류 시 메모리 큐 사용
    console.error('Redis 매칭 오류, 메모리 큐 사용:', err.message);
    return _tryMatchFromMemory(userId, minRating, maxRating);
  }
  
  return null;
}

// 문제 랜덤 선택 함수
async function getRandomQuestions(count = 10) {
  const query = `
    SELECT id, question, options, answer, category, difficulty
    FROM quiz_questions
    ORDER BY RANDOM()
    LIMIT $1
  `;
  
  const result = await pool.query(query, [count]);
  return result.rows;
}

// 매칭 생성 및 문제 할당
async function createMatch(player1, player2) {
  const matchId = `match_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const questions = await getRandomQuestions(10);
  
  // 사용자 정보 가져오기
  const player1Data = await pool.query(
    'SELECT id, nickname, profile_image FROM users WHERE id = $1',
    [player1.userId]
  );
  const player2Data = await pool.query(
    'SELECT id, nickname, profile_image FROM users WHERE id = $1',
    [player2.userId]
  );
  
  const p1Info = player1Data.rows[0] || { nickname: '플레이어1', profile_image: null };
  const p2Info = player2Data.rows[0] || { nickname: '플레이어2', profile_image: null };
  
  const match = {
    id: matchId,
    player1: {
      userId: player1.userId,
      socketId: player1.socketId,
      rating: player1.rating,
      nickname: p1Info.nickname,
      profileImage: p1Info.profile_image
    },
    player2: {
      userId: player2.userId,
      socketId: player2.socketId,
      rating: player2.rating,
      nickname: p2Info.nickname,
      profileImage: p2Info.profile_image
    },
    questions: questions,
    status: 'in_progress',
    createdAt: new Date(),
    player1Progress: 0,
    player2Progress: 0,
    player1CorrectCount: 0,
    player2CorrectCount: 0,
    player1FinishTime: null,
    player2FinishTime: null
  };
  
  activeMatches.set(matchId, match);
  
  // 데이터베이스에 매칭 저장
  try {
    await pool.query(`
      INSERT INTO matches (
        id, player1_id, player2_id, status, mode, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6)
    `, [
      matchId,
      player1.userId,
      player2.userId,
      'in_progress',
      '1v1', // 게임 모드
      new Date()
    ]);
  } catch (err) {
    // questions 컬럼이 있으면 포함
    if (err.message.includes('column "questions"')) {
      try {
        await pool.query(`
          INSERT INTO matches (
            id, player1_id, player2_id, status, mode, questions, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        `, [
          matchId,
          player1.userId,
          player2.userId,
          'in_progress',
          '1v1',
          JSON.stringify(questions.map(q => q.id)),
          new Date()
        ]);
      } catch (err2) {
        // mode 컬럼이 없으면 제외
        await pool.query(`
          INSERT INTO matches (
            id, player1_id, player2_id, status, questions, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6)
        `, [
          matchId,
          player1.userId,
          player2.userId,
          'in_progress',
          JSON.stringify(questions.map(q => q.id)),
          new Date()
        ]);
      }
    } else {
      throw err;
    }
  }
  
  // 사용자의 마지막 게임 시간 업데이트 (게임 시작 시)
  const gameStartTime = new Date();
  await pool.query(`
    UPDATE users 
    SET last_game_time = $1
    WHERE id IN ($2, $3)
  `, [gameStartTime, player1.userId, player2.userId]).catch(err => {
    // last_game_time 컬럼이 없으면 무시
    if (!err.message.includes('column "last_game_time"')) {
      console.error('last_game_time 업데이트 오류:', err);
    }
  });
  
  return match;
}

// 게임 결과 계산 및 레이팅 업데이트
async function calculateMatchResult(matchId, match) {
  const player1 = match.player1;
  const player2 = match.player2;
  
  // 승자 결정
  let winnerId = null;
  let result = 'draw';
  
  if (match.player1CorrectCount > match.player2CorrectCount) {
    winnerId = player1.userId;
    result = 'win';
  } else if (match.player2CorrectCount > match.player1CorrectCount) {
    winnerId = player2.userId;
    result = 'lose';
  } else {
    // 정답 수가 같으면 시간으로 판단
    if (match.player1FinishTime && match.player2FinishTime) {
      if (match.player1FinishTime < match.player2FinishTime) {
        winnerId = player1.userId;
        result = 'win';
      } else {
        winnerId = player2.userId;
        result = 'lose';
      }
    }
  }
  
  // 데이터베이스에서 현재 레이팅 정보 가져오기
  const player1Data = await pool.query(
    'SELECT rating, rating_deviation, rating_volatility FROM users WHERE id = $1',
    [player1.userId]
  );
  const player2Data = await pool.query(
    'SELECT rating, rating_deviation, rating_volatility FROM users WHERE id = $1',
    [player2.userId]
  );
  
  if (player1Data.rows.length === 0 || player2Data.rows.length === 0) {
    console.error('사용자 데이터를 찾을 수 없습니다');
    return;
  }
  
  const p1Data = player1Data.rows[0];
  const p2Data = player2Data.rows[0];
  
  // Glicko-2 레이팅 계산
  const player1Rating = ranking.makePlayer(
    p1Data.rating || 1500,
    p1Data.rating_deviation || 350,
    p1Data.rating_volatility || 0.06
  );
  
  const player2Rating = ranking.makePlayer(
    p2Data.rating || 1500,
    p2Data.rating_deviation || 350,
    p2Data.rating_volatility || 0.06
  );
  
  // 승부 결과 설정
  let outcome = 0.5; // 무승부
  if (winnerId === player1.userId) {
    outcome = 1; // player1 승리
  } else if (winnerId === player2.userId) {
    outcome = 0; // player2 승리
  }
  
  // 레이팅 업데이트
  player1Rating.updateRating([player2Rating], [outcome]);
  player2Rating.updateRating([player1Rating], [1 - outcome]);
  
  // 데이터베이스 업데이트
  await pool.query(`
    UPDATE users 
    SET rating = $1, rating_deviation = $2, rating_volatility = $3, updated_at = NOW()
    WHERE id = $4
  `, [
    Math.round(player1Rating.getRating()),
    player1Rating.getRd(),
    player1Rating.getVol(),
    player1.userId
  ]);
  
  await pool.query(`
    UPDATE users 
    SET rating = $1, rating_deviation = $2, rating_volatility = $3, updated_at = NOW()
    WHERE id = $4
  `, [
    Math.round(player2Rating.getRating()),
    player2Rating.getRd(),
    player2Rating.getVol(),
    player2.userId
  ]);
  
  // 매칭 결과 업데이트
  const gameCompletedAt = new Date();
  await pool.query(`
    UPDATE matches 
    SET result = $1, winner_id = $2, finished_at = NOW(), game_completed_at = $3, status = 'finished'
    WHERE id = $4
  `, [result, winnerId, gameCompletedAt, matchId]).catch(err => {
    // game_completed_at 컬럼이 없으면 finished_at만 업데이트
    if (err.message.includes('column "game_completed_at"')) {
      return pool.query(`
        UPDATE matches 
        SET result = $1, winner_id = $2, finished_at = NOW(), status = 'finished'
        WHERE id = $3
      `, [result, winnerId, matchId]);
    }
    throw err;
  });
  
  return {
    winnerId,
    result,
    player1NewRating: Math.round(player1Rating.getRating()),
    player2NewRating: Math.round(player2Rating.getRating()),
    player1RatingChange: Math.round(player1Rating.getRating()) - (p1Data.rating || 1500),
    player2RatingChange: Math.round(player2Rating.getRating()) - (p2Data.rating || 1500)
  };
}

// Socket.io 연결 처리
io.on('connection', (socket) => {
  console.log('사용자 연결:', socket.id);
  
  // 사용자 연결
  socket.on('user-connected', async (userId) => {
    userSockets.set(userId, socket.id);
    socket.userId = userId;
    console.log('사용자 연결됨:', userId);
  });
  
  // 매칭 요청
  socket.on('request-match', async (data) => {
    const { user_id, rating } = data;
    
    if (!user_id || !rating) {
      socket.emit('match-error', { message: '잘못된 요청입니다' });
      return;
    }
    
    console.log('매칭 요청:', user_id, rating);
    
    // 매칭 큐에 추가
    const matchData = {
      userId: user_id,
      socketId: socket.id,
      rating: rating,
      startTime: Date.now(),
      range: 25
    };
    
    matchQueue.set(user_id, matchData);
    
    // Redis에 추가 (연결되어 있을 때만)
    try {
      if (redisClient.isOpen) {
        await redisClient.hSet('match_queue', user_id, JSON.stringify({
          userId: user_id,
          rating: rating,
          socketId: socket.id
        }));
      }
    } catch (err) {
      console.error('Redis 저장 오류 (메모리 큐만 사용):', err.message);
    }
    
    socket.emit('match-queued', { queue_size: matchQueue.size });
    
    // 즉시 매칭 시도
    let matched = false;
    let attempts = 0;
    const maxAttempts = 10; // 최대 10초 동안 시도
    
    const matchInterval = setInterval(async () => {
      attempts++;
      
      const opponent = await tryMatch(user_id);
      
      if (opponent) {
        clearInterval(matchInterval);
        matched = true;
        
        // 매칭 성공
        const player1Data = matchQueue.get(user_id) || matchData;
        const player2Data = {
          userId: opponent.userId,
          socketId: opponent.socketId,
          rating: opponent.rating
        };
        
        const player1 = {
          userId: player1Data.userId,
          socketId: player1Data.socketId,
          rating: player1Data.rating
        };
        const player2 = player2Data;
        
        const match = await createMatch(player1, player2);
        
        // 두 사용자에게 매칭 성공 알림
        const socket1 = io.sockets.sockets.get(player1.socketId);
        const socket2 = io.sockets.sockets.get(player2.socketId);
        
        if (socket1) {
          socket1.emit('match-found', {
            match_id: match.id,
            opponent: {
              id: match.player2.userId,
              nickname: match.player2.nickname || '상대방',
              profile_image: match.player2.profileImage,
              rating: match.player2.rating
            },
            questions: match.questions
          });
        }
        
        if (socket2) {
          socket2.emit('match-found', {
            match_id: match.id,
            opponent: {
              id: match.player1.userId,
              nickname: match.player1.nickname || '상대방',
              profile_image: match.player1.profileImage,
              rating: match.player1.rating
            },
            questions: match.questions
          });
        }
      } else if (attempts < maxAttempts) {
        // 매칭 범위 확장
        expandMatchRange(user_id);
      } else {
        clearInterval(matchInterval);
        if (!matched) {
          socket.emit('match-timeout', { message: '매칭 시간이 초과되었습니다' });
        }
      }
    }, 1000); // 1초마다 시도
  });
  
  // 매칭 취소
  socket.on('cancel-match', async () => {
    if (socket.userId) {
      matchQueue.delete(socket.userId);
      try {
        if (redisClient.isOpen) {
          await redisClient.hDel('match_queue', socket.userId);
        }
      } catch (err) {
        console.error('Redis 삭제 오류:', err.message);
      }
      socket.emit('match-cancelled');
    }
  });
  
  // 게임 진행 상황 업데이트
  socket.on('game-progress', async (data) => {
    const { match_id, user_id, progress, correct_count } = data;
    const match = activeMatches.get(match_id);
    
    if (!match) return;
    
    // 진행 상황 업데이트
    if (match.player1.userId === user_id) {
      match.player1Progress = progress;
      match.player1CorrectCount = correct_count;
    } else if (match.player2.userId === user_id) {
      match.player2Progress = progress;
      match.player2CorrectCount = correct_count;
    }
    
    // 상대방에게 진행 상황 전송
    const opponentId = match.player1.userId === user_id 
      ? match.player2.userId 
      : match.player1.userId;
    const opponentSocketId = userSockets.get(opponentId);
    
    if (opponentSocketId) {
      const opponentSocket = io.sockets.sockets.get(opponentSocketId);
      if (opponentSocket) {
        opponentSocket.emit('opponent-progress', {
          progress: progress,
          correct_count: correct_count
        });
      }
    }
    
    // 데이터베이스 업데이트
    const isPlayer1 = match.player1.userId === user_id;
    await pool.query(`
      UPDATE matches 
      SET ${isPlayer1 ? 'player1_progress' : 'player2_progress'} = $1,
          ${isPlayer1 ? 'player1_correct_count' : 'player2_correct_count'} = $2
      WHERE id = $3
    `, [progress, correct_count, match_id]);
  });
  
  // 게임 완료
  socket.on('player-finished', async (data) => {
    const { match_id, user_id, correct_count, total_questions } = data;
    const match = activeMatches.get(match_id);
    
    if (!match) return;
    
    const finishTime = new Date();
    
    // 완료 시간 저장
    if (match.player1.userId === user_id) {
      match.player1FinishTime = finishTime;
      match.player1Progress = total_questions;
      match.player1CorrectCount = correct_count;
    } else if (match.player2.userId === user_id) {
      match.player2FinishTime = finishTime;
      match.player2Progress = total_questions;
      match.player2CorrectCount = correct_count;
    }
    
    // 상대방에게 완료 알림
    const opponentId = match.player1.userId === user_id 
      ? match.player2.userId 
      : match.player1.userId;
    const opponentSocketId = userSockets.get(opponentId);
    
    if (opponentSocketId) {
      const opponentSocket = io.sockets.sockets.get(opponentSocketId);
      if (opponentSocket) {
        opponentSocket.emit('opponent-finished', {
          correct_count: correct_count,
          total_questions: total_questions
        });
      }
    }
    
    // 데이터베이스 업데이트
    const isPlayer1 = match.player1.userId === user_id;
    await pool.query(`
      UPDATE matches 
      SET ${isPlayer1 ? 'player1_finish_time' : 'player2_finish_time'} = $1,
          ${isPlayer1 ? 'player1_progress' : 'player2_progress'} = $2,
          ${isPlayer1 ? 'player1_correct_count' : 'player2_correct_count'} = $3
      WHERE id = $4
    `, [finishTime, total_questions, correct_count, match_id]);
    
    // 두 플레이어 모두 완료했는지 확인
    if (match.player1FinishTime && match.player2FinishTime) {
      const result = await calculateMatchResult(match_id, match);
      
      // 두 사용자에게 결과 전송
      const socket1 = io.sockets.sockets.get(match.player1.socketId);
      const socket2 = io.sockets.sockets.get(match.player2.socketId);
      
      if (socket1) {
        socket1.emit('both-finished', {
          match_id: match_id,
          winner_id: result.winnerId,
          result: result.result,
          player1_id: match.player1.userId,
          player2_id: match.player2.userId,
          player1_correct_count: match.player1CorrectCount,
          player2_correct_count: match.player2CorrectCount,
          player1_new_rating: result.player1NewRating,
          player2_new_rating: result.player2NewRating,
          player1_rating_change: result.player1RatingChange,
          player2_rating_change: result.player2RatingChange
        });
      }
      
      if (socket2) {
        socket2.emit('both-finished', {
          match_id: match_id,
          winner_id: result.winnerId,
          result: result.result,
          player1_id: match.player1.userId,
          player2_id: match.player2.userId,
          player1_correct_count: match.player1CorrectCount,
          player2_correct_count: match.player2CorrectCount,
          player1_new_rating: result.player1NewRating,
          player2_new_rating: result.player2NewRating,
          player1_rating_change: result.player1RatingChange,
          player2_rating_change: result.player2RatingChange
        });
      }
      
      // 활성 매칭에서 제거
      activeMatches.delete(match_id);
    }
  });
  
  // 기권
  socket.on('surrender', async (data) => {
    const { match_id, user_id } = data;
    const match = activeMatches.get(match_id);
    
    if (!match) return;
    
    const opponentId = match.player1.userId === user_id 
      ? match.player2.userId 
      : match.player1.userId;
    const opponentSocketId = userSockets.get(opponentId);
    
    if (opponentSocketId) {
      const opponentSocket = io.sockets.sockets.get(opponentSocketId);
      if (opponentSocket) {
        opponentSocket.emit('opponent-surrendered');
      }
    }
    
    // 매칭 결과 업데이트 (기권 시)
    const gameCompletedAt = new Date();
    await pool.query(`
      UPDATE matches 
      SET result = $1, winner_id = $2, finished_at = NOW(), game_completed_at = $3, status = 'finished'
      WHERE id = $4
    `, ['surrender', opponentId, gameCompletedAt, match_id]).catch(err => {
      // game_completed_at 컬럼이 없으면 finished_at만 업데이트
      if (err.message.includes('column "game_completed_at"')) {
        return pool.query(`
          UPDATE matches 
          SET result = $1, winner_id = $2, finished_at = NOW(), status = 'finished'
          WHERE id = $3
        `, ['surrender', opponentId, match_id]);
      }
      throw err;
    });
    
    activeMatches.delete(match_id);
  });
  
  // 연결 해제
  socket.on('disconnect', async () => {
    console.log('사용자 연결 해제:', socket.id);
    
    if (socket.userId) {
      matchQueue.delete(socket.userId);
      try {
        if (redisClient.isOpen) {
          await redisClient.hDel('match_queue', socket.userId);
        }
      } catch (err) {
        console.error('Redis 삭제 오류:', err.message);
      }
      userSockets.delete(socket.userId);
      
      // 활성 매칭에서 사용자 제거 및 상대방에게 알림
      for (const [matchId, match] of activeMatches.entries()) {
        if (match.player1.userId === socket.userId || match.player2.userId === socket.userId) {
          const opponentId = match.player1.userId === socket.userId 
            ? match.player2.userId 
            : match.player1.userId;
          const opponentSocketId = userSockets.get(opponentId);
          
          if (opponentSocketId) {
            const opponentSocket = io.sockets.sockets.get(opponentSocketId);
            if (opponentSocket) {
              opponentSocket.emit('opponent-disconnected');
            }
          }
          
          activeMatches.delete(matchId);
        }
      }
    }
  });
});

const PORT = process.env.PORT || 3001;

// 서버 시작 (에러 처리)
try {
  server.listen(PORT, () => {
    console.log(`서버가 포트 ${PORT}에서 실행 중입니다`);
  });
  
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`포트 ${PORT}가 이미 사용 중입니다. 다른 포트를 사용하거나 기존 프로세스를 종료하세요.`);
    } else {
      console.error('서버 오류:', err);
    }
    process.exit(1);
  });
} catch (err) {
  console.error('서버 시작 실패:', err);
  process.exit(1);
}

