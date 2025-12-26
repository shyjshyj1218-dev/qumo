import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/colors.dart';
import '../../models/quiz_question.dart';
import '../../providers/quiz_provider.dart';
import '../../services/quiz_service.dart';
import '../../widgets/quiz/question_card.dart';
import '../../widgets/quiz/answer_button.dart';
import '../../widgets/quiz/progress_bar.dart';

class QuizRoomScreen extends ConsumerStatefulWidget {
  final String difficulty;

  const QuizRoomScreen({
    super.key,
    required this.difficulty,
  });

  @override
  ConsumerState<QuizRoomScreen> createState() => _QuizRoomScreenState();
}

class _QuizRoomScreenState extends ConsumerState<QuizRoomScreen> {
  String? _selectedAnswer;
  bool _showResult = false;
  Map<int, bool> _results = {};

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      quizQuestionsProvider({
        'difficulty': widget.difficulty,
        'limit': 10,
      }),
    );
    final currentIndex = ref.watch(currentQuestionIndexProvider);
    final currentQuestion = ref.watch(currentQuestionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('퀴즈방'),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text('문제를 불러올 수 없습니다'),
            );
          }

          if (currentQuestion == null) {
            return const Center(
              child: Text('모든 문제를 완료했습니다'),
            );
          }

          return Column(
            children: [
              ProgressBar(
                current: currentIndex + 1,
                total: questions.length,
              ),
              QuestionCard(
                question: currentQuestion.question,
                questionNumber: currentIndex + 1,
                totalQuestions: questions.length,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.options.length,
                  itemBuilder: (context, index) {
                    final option = currentQuestion.options[index];
                    final isSelected = _selectedAnswer == option;
                    final isCorrect = option == currentQuestion.answer;

                    return AnswerButton(
                      answer: option,
                      index: index,
                      isSelected: isSelected,
                      isCorrect: isCorrect,
                      showResult: _showResult,
                      onTap: () {
                        if (!_showResult) {
                          setState(() {
                            _selectedAnswer = option;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_showResult) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _results[currentIndex] =
                                _selectedAnswer == currentQuestion.answer;
                            if (currentIndex < questions.length - 1) {
                              ref
                                  .read(currentQuestionIndexProvider.notifier)
                                  .state = currentIndex + 1;
                              setState(() {
                                _selectedAnswer = null;
                                _showResult = false;
                              });
                            } else {
                              // 퀴즈 완료
                              _showResults(context, questions);
                            }
                          },
                          child: Text(
                            currentIndex < questions.length - 1
                                ? '다음 문제'
                                : '결과 보기',
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedAnswer == null
                              ? null
                              : () {
                                  setState(() {
                                    _showResult = true;
                                  });
                                },
                          child: const Text('정답 확인'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류: $error'),
        ),
      ),
    );
  }

  void _showResults(BuildContext context, List<QuizQuestion> questions) {
    final correctCount = _results.values.where((r) => r).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('퀴즈 결과'),
        content: Text('정답: $correctCount / ${questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

