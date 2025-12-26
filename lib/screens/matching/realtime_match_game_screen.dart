import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../config/colors.dart';
import '../../models/match_user.dart';
import '../../models/quiz_question.dart';
import '../../providers/matching_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/socket_service.dart';
import '../../services/matching_service.dart';
import '../../widgets/quiz/question_card.dart';
import '../../widgets/quiz/answer_button.dart';
import '../../utils/helpers.dart';

class RealtimeMatchGameScreen extends ConsumerStatefulWidget {
  final MatchUser? opponent;
  final String? matchId;
  final List<QuizQuestion>? questions;

  const RealtimeMatchGameScreen({
    super.key,
    this.opponent,
    this.matchId,
    this.questions,
  });

  @override
  ConsumerState<RealtimeMatchGameScreen> createState() =>
      _RealtimeMatchGameScreenState();
}

class _RealtimeMatchGameScreenState
    extends ConsumerState<RealtimeMatchGameScreen> {
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  Map<int, String> _answers = {};
  Map<int, bool> _results = {};
  int _timeRemaining = 300; // 5 minutes
  Timer? _timer;
  bool _isFinished = false;
  bool _opponentFinished = false;
  int _opponentCorrectCount = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupSocketListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            _finishGame();
          }
        });
      }
    });
  }

  void _setupSocketListeners() {
    final socketService = ref.read(socketServiceProvider);
    final currentUser = ref.read(currentUserProvider);

    socketService.onOpponentProgress((progress, correctCount) {
      if (mounted) {
        setState(() {
          ref.read(opponentProgressProvider.notifier).state = progress;
          ref.read(opponentCorrectCountProvider.notifier).state = correctCount;
        });
      }
    });

    socketService.onOpponentFinished((correctCount, totalQuestions) {
      if (mounted) {
        setState(() {
          _opponentFinished = true;
          _opponentCorrectCount = correctCount;
        });
      }
    });

    socketService.onBothFinished((result) {
      if (mounted) {
        // 서버에서 이미 player1_id와 player2_id를 포함해서 보내줌
        _showResult(result);
      }
    });

    socketService.onOpponentSurrendered(() {
      if (mounted) {
        _showResult({'result': 'win'});
      }
    });
  }

  void _finishGame() {
    if (_isFinished) return;

    _isFinished = true;
    _timer?.cancel();

    final currentUser = ref.read(currentUserProvider);
    final socketService = ref.read(socketServiceProvider);
    final questions = widget.questions ?? [];

    final correctCount = _results.values.where((r) => r).length;

    socketService.sendGameFinished(
      matchId: widget.matchId ?? '',
      userId: currentUser?.id ?? '',
      correctCount: correctCount,
      totalQuestions: questions.length,
    );

    // 매칭 서비스에 결과 저장
    final matchingService = ref.read(matchingServiceProvider);
    matchingService.finishMatch(
      matchId: widget.matchId ?? '',
      playerId: currentUser?.id ?? '',
      correctCount: correctCount,
      totalQuestions: questions.length,
    );
  }

  void _showResult(Map<String, dynamic> result) {
    _timer?.cancel();
    
    // 결과 화면으로 이동
    if (mounted) {
      final opponent = widget.opponent;
      if (opponent != null) {
        context.push('/match-result', extra: {
          'result': result,
          'opponent': opponent,
          'playerCorrectCount': _results.values.where((r) => r).length,
          'opponentCorrectCount': _opponentCorrectCount,
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions ?? [];
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('문제를 불러올 수 없습니다')),
      );
    }

    if (_currentQuestionIndex >= questions.length) {
      _finishGame();
      return Scaffold(
        body: Center(
          child: _opponentFinished
              ? const Text('결과를 기다리는 중...')
              : const Text('상대방을 기다리는 중...'),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final isAnswered = _answers.containsKey(_currentQuestionIndex);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => _showSurrenderDialog(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              Helpers.formatTime(_timeRemaining),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _showSurrenderDialog(),
            child: const Text(
              '기권',
              style: TextStyle(
                color: AppColors.difficultyExpert,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 플레이어 정보 (상단)
          _buildPlayerInfo(),
          const SizedBox(height: 8),
          // 문제 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  QuestionCard(
                    question: currentQuestion.question,
                    questionNumber: _currentQuestionIndex + 1,
                    totalQuestions: questions.length,
                  ),
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedAnswer == option;
                    final isCorrect = option == currentQuestion.answer;
                    final showResult = isAnswered;

                    return AnswerButton(
                      answer: option,
                      index: index,
                      isSelected: isSelected,
                      isCorrect: isCorrect,
                      showResult: showResult,
                      onTap: () async {
                        if (!isAnswered && !_isFinished) {
                          final isCorrect = option == currentQuestion.answer;
                          
                          setState(() {
                            _selectedAnswer = option;
                            _answers[_currentQuestionIndex] = option;
                            _results[_currentQuestionIndex] = isCorrect;
                          });

                          // match_answers 테이블에 저장
                          final currentUser = ref.read(currentUserProvider);
                          if (currentUser != null && widget.matchId != null) {
                            final matchingService = MatchingService();
                            await matchingService.saveMatchAnswer(
                              matchId: widget.matchId!,
                              userId: currentUser.id,
                              questionId: currentQuestion.id,
                              isCorrect: isCorrect,
                            );
                          }

                          // 소켓으로 진행 상황 전송
                          final socketService = ref.read(socketServiceProvider);
                          socketService.sendGameProgress(
                            matchId: widget.matchId ?? '',
                            userId: currentUser?.id ?? '',
                            progress: _currentQuestionIndex + 1,
                            correctCount: _results.values.where((r) => r).length,
                          );
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          // 하단 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isAnswered
                        ? () {
                            if (_currentQuestionIndex < questions.length - 1) {
                              setState(() {
                                _currentQuestionIndex++;
                                _selectedAnswer = null;
                              });
                            } else {
                              _finishGame();
                            }
                          }
                        : null,
                    child: Text(
                      _currentQuestionIndex < questions.length - 1
                          ? '다음 문제'
                          : '완료',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _showSurrenderDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.difficultyExpert,
                    foregroundColor: AppColors.textWhite,
                  ),
                  child: const Text('기권'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    final playerProgress = _currentQuestionIndex + 1;
    final opponentProgress = ref.watch(opponentProgressProvider);
    final currentUser = ref.read(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundWhite,
      child: Row(
        children: [
          // 내 정보
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userProfile.value?.nickname.substring(0, 1).toUpperCase() ??
                        'U',
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile.value?.nickname ?? '나',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: playerProgress / (widget.questions?.length ?? 1),
                  backgroundColor: AppColors.lightGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.difficultyBeginner),
                ),
                Text(
                  '$playerProgress / ${widget.questions?.length ?? 1}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          // 상대방 정보
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    widget.opponent?.nickname.substring(0, 1).toUpperCase() ??
                        'O',
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.opponent?.nickname ?? '상대방',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: opponentProgress / (widget.questions?.length ?? 1),
                  backgroundColor: AppColors.lightGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.difficultyExpert),
                ),
                Text(
                  '$opponentProgress / ${widget.questions?.length ?? 1}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSurrenderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기권'),
        content: const Text('정말 기권하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final currentUser = ref.read(currentUserProvider);
              final socketService = ref.read(socketServiceProvider);
              socketService.surrender(
                widget.matchId ?? '',
                currentUser?.id ?? '',
              );
              _showResult({'result': 'lose'});
            },
            child: const Text('기권'),
          ),
        ],
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final Map<String, dynamic> result;
  final int playerCorrectCount;
  final int opponentCorrectCount;
  final int timeSpent;
  final VoidCallback onHome;
  final VoidCallback onRetry;

  const _ResultDialog({
    required this.result,
    required this.playerCorrectCount,
    required this.opponentCorrectCount,
    required this.timeSpent,
    required this.onHome,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final resultType = result['result'] ?? 'draw';
    final isWin = resultType == 'win';
    final isLose = resultType == 'lose';

    return AlertDialog(
      title: Text(
        isWin ? '승리!' : isLose ? '패배' : '무승부',
        style: TextStyle(
          color: isWin
              ? AppColors.difficultyBeginner
              : isLose
                  ? AppColors.difficultyExpert
                  : AppColors.textSecondary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내 정답: $playerCorrectCount개'),
          Text('상대 정답: $opponentCorrectCount개'),
          Text('소요 시간: ${Helpers.formatTime(timeSpent)}'),
          if (result['rating_change'] != null)
            Text('레이팅 변화: ${result['rating_change']}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onHome,
          child: const Text('홈으로'),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('다시하기'),
        ),
      ],
    );
  }
}

