import express from "express";
import http from "http";
import { Server } from "socket.io";
import { randomUUID } from "crypto";
import pkg from "pg";
import dotenv from "dotenv";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

// .env 파일 로드 (프로젝트 루트의 .env)
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: join(__dirname, "..", ".env") });

const { Pool } = pkg;

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",   // 개발 중 무조건 *
    methods: ["GET", "POST"],
  },
  transports: ["websocket"],
});

// PostgreSQL 연결 설정
const dbUrl = process.env.DATABASE_URL || process.env.SUPABASE_DB_URL;
let pool = null;

if (dbUrl) {
  pool = new Pool({
    connectionString: dbUrl,
    ssl: dbUrl.includes("supabase") ? { rejectUnauthorized: false } : false,
  });
  
  pool.on("error", (err) => {
    console.error("❌ PostgreSQL 연결 오류:", err);
  });
  
  console.log("✅ PostgreSQL 연결 설정 완료");
} else {
  console.log("⚠️ DATABASE_URL이 설정되지 않았습니다. DB 저장 기능이 비활성화됩니다.");
}

// 매칭 큐 (배열로 관리)
let queue = []; // { socket, userId, rating, joinedAt, range }

// 게임 상태 관리 (roomId별로 관리)
const gameRooms = new Map(); // { roomId: { questions, answers: { userId: { questionIndex: answer } }, finished: Set<userId> } }

// 매칭 로직: 레이팅 범위 내에서 상대방 찾기
function findMatch(user) {
  const now = Date.now();
  
  for (let i = 0; i < queue.length; i++) {
    const opponent = queue[i];
    const waitTime = (now - opponent.joinedAt) / 1000; // 초 단위
    const range = 100 + Math.floor(waitTime / 5) * 50; // 5초마다 50씩 범위 확장
    
    if (Math.abs(opponent.rating - user.rating) <= range) {
      queue.splice(i, 1); // 큐에서 제거
      return opponent;
    }
  }
  
  return null;
}

// 랜덤 문제 여러 개 가져오기
async function getRandomQuestions(count = 10) {
  if (!pool) {
    console.log("⚠️ DB 연결이 없어 문제를 가져올 수 없습니다.");
    return [];
  }

  try {
    const result = await pool.query(
      `SELECT id, question, options, answer, category, difficulty, created_at, updated_at
       FROM quiz_questions
       ORDER BY RANDOM()
       LIMIT $1`,
      [count]
    );
    
    if (result.rows.length === 0) {
      console.log("⚠️ 문제가 없습니다.");
      return [];
    }
    
    const questions = result.rows.map((row) => ({
      id: row.id.toString(),
      question: row.question,
      options: row.options, // jsonb는 이미 배열로 파싱됨
      answer: row.answer,
      category: row.category,
      difficulty: row.difficulty || 'beginner',
    }));
    
    console.log(`📚 문제 ${questions.length}개 가져오기 성공`);
    return questions;
  } catch (error) {
    console.error("❌ 문제 가져오기 실패:", error.message);
    return [];
  }
}

// 매칭 기록 DB 저장
async function saveMatchToDB(roomId, player1Id, player2Id, player1Rating, player2Rating, questionIds) {
  if (!pool) {
    console.log("⚠️ DB 연결이 없어 매칭 기록을 저장할 수 없습니다.");
    return;
  }

  try {
    const result = await pool.query(
      `INSERT INTO matches (id, player1_id, player2_id, status, mode, questions, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING id`,
      [roomId, player1Id, player2Id, "in_progress", "1v1", JSON.stringify(questionIds)]
    );
    
    console.log(`💾 매칭 기록 저장 완료: ${result.rows[0].id}`);
  } catch (error) {
    console.error("❌ 매칭 기록 저장 실패:", error.message);
    // DB 저장 실패해도 게임은 계속 진행
  }
}

// 카테고리별 능력치 계산 함수들
const CATEGORIES = ["생활", "사회", "과학", "지리", "역사", "IT", "스포츠", "문화"];
const DIFFICULTY_WEIGHTS = {
  "초급": 1,
  "beginner": 1,
  "중급": 2,
  "intermediate": 2,
  "상급": 3,
  "advanced": 3,
  "최상급": 4,
  "expert": 4,
};

// 세션 점수 계산 (카테고리별)
function calculateSessionScore(questions, answers) {
  const sessionScore = {};
  CATEGORIES.forEach((cat) => {
    sessionScore[cat] = 0;
  });

  questions.forEach((question, index) => {
    const answer = answers[index];
    const isCorrect = answer && answer === question.answer;
    let category = question.category || null;
    const difficulty = question.difficulty || "beginner";
    
    // 카테고리 이름 정규화 (예: "상식 생활" -> "생활", "생활" -> "생활")
    if (category) {
      for (const cat of CATEGORIES) {
        if (category.includes(cat) || category === cat) {
          category = cat;
          break;
        }
      }
    }
    
    // 카테고리가 없거나 매칭되지 않으면 기본값 "생활" 사용
    if (!category || !CATEGORIES.includes(category)) {
      category = "생활";
    }
    
    if (isCorrect && CATEGORIES.includes(category)) {
      const weight = DIFFICULTY_WEIGHTS[difficulty] || 1;
      sessionScore[category] = (sessionScore[category] || 0) + weight;
    }
  });

  return sessionScore;
}

// EMA alpha 값 계산 (판수에 따라 감소)
function calculateAlpha(gamesPlayed) {
  // 초반(10판까지): 0.4, 이후 점점 감소
  if (gamesPlayed < 10) {
    return 0.4;
  }
  // 10판 이후: 지수적으로 감소 (최소 0.15)
  const alpha = 0.4 * Math.exp(-(gamesPlayed - 10) / 20);
  return Math.max(0.15, alpha);
}

// EMA 업데이트
function updateEMA(prevEMA, sessionScore, alpha) {
  const newEMA = {};
  CATEGORIES.forEach((cat) => {
    const prevValue = prevEMA[cat] || 0;
    const sessionValue = sessionScore[cat] || 0;
    newEMA[cat] = alpha * sessionValue + (1 - alpha) * prevValue;
  });
  return newEMA;
}

// 정규화 (0~100 범위)
function normalizeEMA(ema) {
  const MAX_SCORE = 40; // 10문제 * 최상급(4점) = 40점
  const normalized = {};
  CATEGORIES.forEach((cat) => {
    const value = ema[cat] || 0;
    normalized[cat] = Math.max(0, Math.min(100, (value / MAX_SCORE) * 100));
  });
  return normalized;
}

// 사용자 카테고리별 능력치 업데이트
async function updateUserCategoryStats(userId, questions, answers) {
  if (!pool) {
    console.log("⚠️ DB 연결이 없어 능력치를 업데이트할 수 없습니다.");
    return;
  }

  try {
    // 1. 현재 능력치 조회
    const currentStats = await pool.query(
      `SELECT games_played, "생활", "사회", "과학", "지리", "역사", "IT", "스포츠", "문화"
       FROM user_category_stats
       WHERE user_id = $1`,
      [userId]
    );

    let gamesPlayed = 0;
    let prevEMA = {};
    
    if (currentStats.rows.length > 0) {
      gamesPlayed = currentStats.rows[0].games_played || 0;
      CATEGORIES.forEach((cat) => {
        prevEMA[cat] = currentStats.rows[0][cat] || 0;
      });
    } else {
      // 첫 게임인 경우 초기값 설정
      CATEGORIES.forEach((cat) => {
        prevEMA[cat] = 0;
      });
    }

    // 2. 세션 점수 계산
    const sessionScore = calculateSessionScore(questions, answers);
    console.log(`📊 세션 점수 (${userId}):`, sessionScore);

    // 3. Alpha 계산
    const alpha = calculateAlpha(gamesPlayed);
    console.log(`📈 Alpha (${userId}, ${gamesPlayed}판):`, alpha);

    // 4. EMA 업데이트
    const newEMA = updateEMA(prevEMA, sessionScore, alpha);
    console.log(`📈 새로운 EMA (${userId}):`, newEMA);

    // 5. 정규화 (0~100)
    const normalized = normalizeEMA(newEMA);
    console.log(`📊 정규화된 능력치 (${userId}):`, normalized);

    // 6. DB 저장 (UPSERT)
    const updateFields = CATEGORIES.map((cat, index) => `"${cat}" = $${index + 3}`).join(", ");
    const values = [userId, gamesPlayed + 1, ...CATEGORIES.map((cat) => newEMA[cat])];

    await pool.query(
      `INSERT INTO user_category_stats (user_id, games_played, ${CATEGORIES.map((c) => `"${c}"`).join(", ")}, updated_at)
       VALUES ($1, $2, ${CATEGORIES.map((_, i) => `$${i + 3}`).join(", ")}, NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         games_played = EXCLUDED.games_played,
         ${updateFields},
         updated_at = NOW()`,
      values
    );

    console.log(`✅ 능력치 업데이트 완료 (${userId}): ${gamesPlayed + 1}판`);
    return normalized;
  } catch (error) {
    console.error(`❌ 능력치 업데이트 실패 (${userId}):`, error.message);
    return null;
  }
}

// 방 생성 및 매칭 성공 알림
async function createRoom(socket1, socket2, user1, user2) {
  const roomId = randomUUID();
  
  // 두 소켓을 같은 방에 입장시킴
  socket1.join(roomId);
  socket2.join(roomId);
  
  console.log(`✅ 방 생성: ${roomId}`);
  console.log(`  - 사용자 1: ${user1.userId} (레이팅: ${user1.rating})`);
  console.log(`  - 사용자 2: ${user2.userId} (레이팅: ${user2.rating})`);
  
  // 문제 10개 가져오기
  const questions = await getRandomQuestions(10);
  
  // DB에 매칭 기록 저장
  if (questions.length > 0) {
    const questionIds = questions.map((q) => q.id);
    await saveMatchToDB(
      roomId,
      user1.userId,
      user2.userId,
      user1.rating,
      user2.rating,
      questionIds
    );
  }
  
  // 게임 상태 초기화
  gameRooms.set(roomId, {
    questions: questions,
    answers: {},
    finished: new Set(),
  });
  
  // 두 사용자에게 매칭 성공 알림 (문제 배열 포함)
  io.to(roomId).emit("match-found", {
    roomId: roomId,
    players: [
      {
        userId: user1.userId,
        rating: user1.rating,
      },
      {
        userId: user2.userId,
        rating: user2.rating,
      },
    ],
    questions: questions, // 문제 배열 포함
  });
  
  return roomId;
}

io.on("connection", (socket) => {
  console.log("🟢 connected:", socket.id);

  socket.on("request-match", async (user) => {
    console.log("📥 match request:", user.userId, "rating:", user.rating);

    // 소켓에 userId 저장 (나중에 결과 전송 시 사용)
    socket.userId = user.userId;
    socket.data = socket.data || {};
    socket.data.userId = user.userId;

    // 기존 큐에서 같은 사용자 제거 (중복 방지)
    queue = queue.filter((q) => q.userId !== user.userId);

    // 매칭 시도
    const opponent = findMatch(user);

    if (!opponent) {
      // 매칭 실패 → 큐에 추가
      queue.push({
        socket,
        userId: user.userId,
        rating: user.rating,
        joinedAt: Date.now(),
        range: 100, // 초기 범위
      });
      
      socket.emit("match-queued");
      console.log(`⏳ 사용자 대기 중: ${user.userId} (레이팅: ${user.rating}), 큐 크기: ${queue.length}`);
      
      // 주기적으로 매칭 재시도 (5초마다)
      const matchInterval = setInterval(async () => {
        // 큐에서 자신 찾기
        const queueIndex = queue.findIndex((q) => q.userId === user.userId);
        if (queueIndex === -1) {
          // 이미 매칭됨
          clearInterval(matchInterval);
          return;
        }

        // 범위 확장
        const waitTime = (Date.now() - queue[queueIndex].joinedAt) / 1000;
        queue[queueIndex].range = 100 + Math.floor(waitTime / 5) * 50;

        // 매칭 재시도
        const newOpponent = findMatch(user);
        if (newOpponent) {
          clearInterval(matchInterval);
          queue = queue.filter((q) => q.userId !== user.userId);
          
          const opponentUser = {
            userId: newOpponent.userId,
            rating: newOpponent.rating,
          };
          await createRoom(socket, newOpponent.socket, user, opponentUser);
          console.log(`✅ 매칭 성공 (재시도): ${user.userId} <-> ${newOpponent.userId}`);
        }
      }, 5000); // 5초마다 재시도

      // disconnect 시 interval 정리
      socket.on("disconnect", () => {
        clearInterval(matchInterval);
      });
    } else {
      // 매칭 성공
      const opponentUser = {
        userId: opponent.userId,
        rating: opponent.rating,
      };
      await createRoom(socket, opponent.socket, user, opponentUser);
      console.log(`✅ 매칭 성공 (즉시): ${user.userId} <-> ${opponent.userId}`);
    }
  });

  // 답안 제출 (문제별)
  socket.on("submit-answer", async (data) => {
    const { roomId, userId, questionIndex, answer } = data;
    console.log(`📥 답안 제출: roomId=${roomId}, userId=${userId}, questionIndex=${questionIndex}, answer=${answer}`);
    
    const gameRoom = gameRooms.get(roomId);
    if (!gameRoom) {
      console.log(`⚠️ 게임 방을 찾을 수 없습니다: ${roomId}`);
      return;
    }
    
    // 답안 저장
    if (!gameRoom.answers[userId]) {
      gameRoom.answers[userId] = {};
    }
    gameRoom.answers[userId][questionIndex] = answer;
    
    // 정답 확인
    const question = gameRoom.questions[questionIndex];
    const isCorrect = question && question.answer === answer;
    
    // 클라이언트에게 정답 여부 알림
    socket.emit("answer-result", {
      questionIndex: questionIndex,
      isCorrect: isCorrect,
      correctAnswer: question?.answer,
    });
    
    console.log(`  - 정답 여부: ${isCorrect ? '정답' : '오답'}`);
  });
  
  // 게임 완료
  socket.on("game-finished", async (data) => {
    const { roomId, userId } = data;
    console.log(`🏁 게임 완료: roomId=${roomId}, userId=${userId}`);
    
    const gameRoom = gameRooms.get(roomId);
    if (!gameRoom) {
      console.log(`⚠️ 게임 방을 찾을 수 없습니다: ${roomId}`);
      return;
    }
    
    // 완료 플레이어 추가
    gameRoom.finished.add(userId);
    
    // 정답 개수 계산
    let correctCount = 0;
    if (gameRoom.answers[userId]) {
      const answers = gameRoom.answers[userId];
      gameRoom.questions.forEach((question, index) => {
        if (answers[index] === question.answer) {
          correctCount++;
        }
      });
    }
    
    console.log(`  - 정답 개수: ${correctCount}/${gameRoom.questions.length}`);
    
    // 상대방에게 완료 알림
    io.to(roomId).emit("opponent-finished", {
      userId: userId,
      correctCount: correctCount,
      totalQuestions: gameRoom.questions.length,
    });
    
    // 두 플레이어 모두 완료했는지 확인
    if (gameRoom.finished.size === 2) {
      // 두 플레이어의 정답 개수 계산 (각 플레이어별로)
      const playerScores = {};
      const playerIds = Array.from(gameRoom.finished);
      
      for (const playerId of playerIds) {
        let score = 0;
        if (gameRoom.answers[playerId]) {
          const answers = gameRoom.answers[playerId];
          gameRoom.questions.forEach((question, index) => {
            // 답안이 있고 정답이면 점수 추가
            if (answers[index] && answers[index] === question.answer) {
              score++;
            }
          });
        }
        playerScores[playerId] = score;
        console.log(`  - ${playerId} 정답 개수: ${score}/${gameRoom.questions.length}`);
      }
      
      // 승자 결정
      const player1Id = playerIds[0];
      const player2Id = playerIds[1];
      const player1Score = playerScores[player1Id] || 0;
      const player2Score = playerScores[player2Id] || 0;
      
      // 각 플레이어의 결과 결정
      let player1Result = 'draw';
      let player2Result = 'draw';
      let winnerId = null;
      
      if (player1Score > player2Score) {
        player1Result = 'win';
        player2Result = 'lose';
        winnerId = player1Id;
      } else if (player2Score > player1Score) {
        player1Result = 'lose';
        player2Result = 'win';
        winnerId = player2Id;
      }
      
      console.log(`🎯 게임 결과:`);
      console.log(`  - ${player1Id}: ${player1Score}점 (${player1Result})`);
      console.log(`  - ${player2Id}: ${player2Score}점 (${player2Result})`);
      console.log(`  - 승자: ${winnerId || '무승부'}`);
      
      // 각 플레이어의 능력치 업데이트
      for (const playerId of playerIds) {
        const playerAnswers = gameRoom.answers[playerId] || {};
        const answersArray = gameRoom.questions.map((_, index) => playerAnswers[index] || null);
        
        // 능력치 업데이트 (비동기, 실패해도 게임 결과는 전송)
        updateUserCategoryStats(playerId, gameRoom.questions, answersArray).catch((err) => {
          console.error(`⚠️ 능력치 업데이트 실패 (${playerId}):`, err.message);
        });
      }

      // 방에 있는 모든 소켓에게 개별 결과 전송
      const roomSockets = await io.in(roomId).fetchSockets();
      
      for (const roomSocket of roomSockets) {
        // 소켓의 userId 확인 (request-match에서 설정됨)
        const socketUserId = roomSocket.handshake.query?.userId || 
                            roomSocket.data?.userId || 
                            roomSocket.userId;
        
        let myScore, opponentScore, result;
        
        if (socketUserId === player1Id) {
          myScore = player1Score;
          opponentScore = player2Score;
          result = player1Result;
        } else if (socketUserId === player2Id) {
          myScore = player2Score;
          opponentScore = player1Score;
          result = player2Result;
        } else {
          // userId를 찾을 수 없으면 기본값 사용
          myScore = 0;
          opponentScore = 0;
          result = 'draw';
        }
        
        roomSocket.emit("game-result", {
          player1Id: player1Id,
          player2Id: player2Id,
          player1Score: player1Score,
          player2Score: player2Score,
          myScore: myScore,
          opponentScore: opponentScore,
          winnerId: winnerId,
          result: result,
        });
        
        console.log(`  - ${socketUserId}에게 결과 전송: 내 점수=${myScore}, 상대 점수=${opponentScore}, 결과=${result}`);
      }
      
      // 게임 방 정리
      gameRooms.delete(roomId);
    }
  });

  socket.on("disconnect", (reason) => {
    console.log("🔴 disconnected:", socket.id, reason);
    
    // 큐에서 제거
    queue = queue.filter((q) => q.socket.id !== socket.id);
    console.log(`⏳ 큐에서 제거됨, 남은 큐 크기: ${queue.length}`);
  });
});

server.listen(3001, "0.0.0.0", () => {
  console.log("🚀 server running on 3001");
});
