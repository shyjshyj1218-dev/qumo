import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';
import '../models/match_user.dart';
import '../models/quiz_question.dart';

class SocketService {
  IO.Socket? _socketInstance;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(String userId) {
    // 기존 연결이 있으면 먼저 정리
    if (_socketInstance != null) {
      _socketInstance!.disconnect();
      _socketInstance!.dispose();
      _socketInstance = null;
    }

    try {
      _socketInstance = IO.io(
        AppConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setTimeout(5000) // 5초 타임아웃
            .build(),
      );

      _socketInstance!.onConnect((_) {
        _isConnected = true;
        print('Socket connected successfully');
        _socketInstance!.emit('user-connected', userId);
      });

      _socketInstance!.onDisconnect((reason) {
        _isConnected = false;
        if (reason == 'io server disconnect') {
          print('서버에 의해 연결이 끊어졌습니다');
        } else {
          print('연결이 끊어졌습니다: $reason');
        }
      });

      _socketInstance!.onConnectError((error) {
        _isConnected = false;
        print('Socket connection error: $error');
        print('서버가 실행 중인지 확인하세요: ${AppConstants.socketUrl}');
        // 연결 실패 시 자동 재연결은 OptionBuilder에서 처리됨
      });

      _socketInstance!.onError((error) {
        print('Socket error: $error');
        _isConnected = false;
      });
    } catch (e) {
      print('Socket initialization error: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _socketInstance?.disconnect();
    _socketInstance?.dispose();
    _isConnected = false;
  }

  // 매칭 관련
  void requestMatch(String userId, int rating) {
    _socketInstance?.emit('request-match', {
      'user_id': userId,
      'rating': rating,
    });
  }

  void cancelMatch() {
    _socketInstance?.emit('cancel-match');
  }

  void onMatchFound(Function(MatchUser opponent, String matchId, List<QuizQuestion> questions) callback) {
    _socketInstance?.on('match-found', (data) {
      final opponent = MatchUser.fromJson(data['opponent']);
      final matchId = data['match_id'];
      final questions = (data['questions'] as List)
          .map((q) => QuizQuestion(
                id: q['id'] ?? '',
                question: q['question'] ?? '',
                options: List<String>.from(q['options'] ?? []),
                answer: q['answer'] ?? '',
                category: q['category'],
                difficulty: q['difficulty'] ?? 'beginner',
                createdAt: q['created_at'] != null
                    ? DateTime.parse(q['created_at'])
                    : DateTime.now(),
                updatedAt: q['updated_at'] != null
                    ? DateTime.parse(q['updated_at'])
                    : DateTime.now(),
              ))
          .toList();
      callback(opponent, matchId, questions);
    });
  }

  void onMatchQueued(Function(int queueSize) callback) {
    _socketInstance?.on('match-queued', (data) {
      callback(data['queue_size'] ?? 0);
    });
  }

  // 게임 진행 관련
  void sendGameProgress({
    required String matchId,
    required String userId,
    required int progress,
    required int correctCount,
  }) {
    _socketInstance?.emit('game-progress', {
      'match_id': matchId,
      'user_id': userId,
      'progress': progress,
      'correct_count': correctCount,
    });
  }

  void sendGameFinished({
    required String matchId,
    required String userId,
    required int correctCount,
    required int totalQuestions,
  }) {
    _socketInstance?.emit('player-finished', {
      'match_id': matchId,
      'user_id': userId,
      'correct_count': correctCount,
      'total_questions': totalQuestions,
    });
  }

  void onOpponentProgress(Function(int progress, int correctCount) callback) {
    _socketInstance?.on('opponent-progress', (data) {
      callback(data['progress'] ?? 0, data['correct_count'] ?? 0);
    });
  }

  void onOpponentFinished(Function(int correctCount, int totalQuestions) callback) {
    _socketInstance?.on('opponent-finished', (data) {
      callback(data['correct_count'] ?? 0, data['total_questions'] ?? 0);
    });
  }

  void onBothFinished(Function(Map<String, dynamic> result) callback) {
    _socketInstance?.on('both-finished', (data) {
      callback(data);
    });
  }

  void surrender(String matchId, String userId) {
    _socketInstance?.emit('surrender', {
      'match_id': matchId,
      'user_id': userId,
    });
  }

  void onOpponentSurrendered(Function() callback) {
    _socketInstance?.on('opponent-surrendered', (_) {
      callback();
    });
  }

  void onOpponentDisconnected(Function() callback) {
    _socketInstance?.on('opponent-disconnected', (_) {
      callback();
    });
  }

  // 이벤트 리스너 제거
  void removeListener(String event) {
    _socketInstance?.off(event);
  }

  // Socket 인스턴스 접근 (내부용)
  IO.Socket? get socket => _socketInstance;
}

