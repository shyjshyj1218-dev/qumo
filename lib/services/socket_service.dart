import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';

class SocketService {
  io.Socket? _socketInstance;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socketInstance;

  void connect(String userId, {Function(String)? onConnected}) {
    // 기존 연결이 있으면 먼저 정리
    if (_socketInstance != null) {
      debugPrint('🔵 기존 소켓 연결 정리 중...');
      _socketInstance!.disconnect();
      _socketInstance!.dispose();
      _socketInstance = null;
      _isConnected = false;
    }

    try {
      final socketUrl = AppConstants.socketUrl;
      debugPrint('🔵 새 소켓 연결 시도: $socketUrl');
      debugPrint('🔵 Transport: websocket');
      
      _socketInstance = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      
      debugPrint('🔵 Socket 인스턴스 생성 완료');
      
      // 이벤트 리스너 등록
      _socketInstance!.onConnect((_) {
        _isConnected = true;
        debugPrint("✅ connected: ${_socketInstance!.id}");
        if (onConnected != null) {
          onConnected(userId);
        }
      });

      _socketInstance!.onDisconnect((reason) {
        _isConnected = false;
        debugPrint("❌ disconnected: $reason");
      });

      _socketInstance!.onConnectError((error) {
        _isConnected = false;
        debugPrint("❌ connection error: $error");
      });

      _socketInstance!.onError((error) {
        debugPrint("❌ socket error: $error");
      });

      // 명시적으로 connect() 호출
      debugPrint('🔵 connect() 호출...');
      _socketInstance!.connect();
    } catch (e) {
      debugPrint('❌ Socket initialization error: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _socketInstance?.disconnect();
    _socketInstance?.dispose();
    _isConnected = false;
  }

  // 매칭 요청
  void requestMatch(String userId, int rating) {
    if (_socketInstance == null || !_isConnected) {
      debugPrint('⚠️ Socket이 연결되지 않아 매칭 요청을 보낼 수 없습니다');
      return;
    }
    debugPrint('🔵 매칭 요청 전송: userId=$userId, rating=$rating');
    _socketInstance!.emit('request-match', {
      'userId': userId,
      'rating': rating,
    });
  }

  // 매칭 큐 상태 리스너
  void onMatchQueued(Function() callback) {
    _socketInstance?.on('match-queued', (_) {
      debugPrint('⏳ queued');
      callback();
    });
  }

  // 매칭 성공 리스너
  void onMatchFound(Function(Map<String, dynamic> data) callback) {
    _socketInstance?.off('match-found'); // 기존 리스너 제거
    _socketInstance?.on('match-found', (data) {
      debugPrint('🎉 match found: $data');
      callback(data);
    });
  }

  // 답안 제출 (문제별)
  void submitAnswer(String roomId, String userId, int questionIndex, String answer) {
    if (_socketInstance == null || !_isConnected) {
      debugPrint('⚠️ Socket이 연결되지 않아 답안을 제출할 수 없습니다');
      return;
    }
    debugPrint('📤 답안 제출: roomId=$roomId, userId=$userId, questionIndex=$questionIndex, answer=$answer');
    _socketInstance!.emit('submit-answer', {
      'roomId': roomId,
      'userId': userId,
      'questionIndex': questionIndex,
      'answer': answer,
    });
  }
  
  // 게임 완료
  void sendGameFinished(String roomId, String userId) {
    if (_socketInstance == null || !_isConnected) {
      debugPrint('⚠️ Socket이 연결되지 않아 게임 완료를 전송할 수 없습니다');
      return;
    }
    debugPrint('🏁 게임 완료 전송: roomId=$roomId, userId=$userId');
    _socketInstance!.emit('game-finished', {
      'roomId': roomId,
      'userId': userId,
    });
  }
  
  // 정답 결과 리스너
  void onAnswerResult(Function(int questionIndex, bool isCorrect, String correctAnswer) callback) {
    _socketInstance?.on('answer-result', (data) {
      callback(
        data['questionIndex'] as int,
        data['isCorrect'] as bool,
        data['correctAnswer'] as String,
      );
    });
  }
  
  // 상대방 완료 리스너
  void onOpponentFinished(Function(int correctCount, int totalQuestions) callback) {
    _socketInstance?.off('opponent-finished');
    _socketInstance?.on('opponent-finished', (data) {
      callback(
        data['correctCount'] as int,
        data['totalQuestions'] as int,
      );
    });
  }
  
  // 게임 결과 리스너
  void onGameResult(Function(Map<String, dynamic> result) callback) {
    _socketInstance?.off('game-result');
    _socketInstance?.on('game-result', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // 답안 제출 이벤트 리스너
  void onAnswerSubmitted(Function(String userId, String answer) callback) {
    _socketInstance?.on('answer-submitted', (data) {
      debugPrint('📥 상대방 답안 제출: ${data['userId']} - ${data['answer']}');
      callback(data['userId'] as String, data['answer'] as String);
    });
  }

  // 이벤트 리스너 제거
  void removeListener(String event) {
    _socketInstance?.off(event);
  }

  // ============================================
  // 게임 진행 관련 메서드 (나중에 구현 예정)
  // ============================================
  
  void sendGameProgress({
    required String matchId,
    required String userId,
    required int progress,
    required int correctCount,
  }) {
    // TODO: 나중에 구현
    debugPrint('⚠️ sendGameProgress: 아직 구현되지 않음');
  }

  void onOpponentProgress(Function(int progress, int correctCount) callback) {
    // TODO: 나중에 구현
    debugPrint('⚠️ onOpponentProgress: 아직 구현되지 않음');
  }

  void onBothFinished(Function(Map<String, dynamic> result) callback) {
    // TODO: 나중에 구현
    debugPrint('⚠️ onBothFinished: 아직 구현되지 않음');
  }

  void surrender(String matchId, String userId) {
    // TODO: 나중에 구현
    debugPrint('⚠️ surrender: 아직 구현되지 않음');
  }

  void onOpponentSurrendered(Function() callback) {
    // TODO: 나중에 구현
    debugPrint('⚠️ onOpponentSurrendered: 아직 구현되지 않음');
  }
}
