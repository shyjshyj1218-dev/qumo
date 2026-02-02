import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../models/quiz_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matching_provider.dart';

class SimpleMatchGameScreen extends ConsumerStatefulWidget {
  final String roomId;
  final QuizQuestion question;

  const SimpleMatchGameScreen({
    super.key,
    required this.roomId,
    required this.question,
  });

  @override
  ConsumerState<SimpleMatchGameScreen> createState() => _SimpleMatchGameScreenState();
}

class _SimpleMatchGameScreenState extends ConsumerState<SimpleMatchGameScreen> {
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '실시간 대결',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 문제 카드
            Card(
              color: AppColors.backgroundWhite,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.question.category != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '카테고리: ${widget.question.category}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 선택지
            ...widget.question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedAnswer == option;
              final isCorrectOption = option == widget.question.answer;
              
              Color? backgroundColor;
              Color? textColor;
              
              if (_isAnswered) {
                if (isCorrectOption) {
                  backgroundColor = AppColors.difficultyBeginner;
                  textColor = AppColors.textWhite;
                } else if (isSelected && !isCorrectOption) {
                  backgroundColor = AppColors.difficultyExpert;
                  textColor = AppColors.textWhite;
                } else {
                  backgroundColor = AppColors.backgroundWhite;
                  textColor = AppColors.textPrimary;
                }
              } else {
                backgroundColor = isSelected 
                    ? AppColors.primary 
                    : AppColors.backgroundWhite;
                textColor = isSelected 
                    ? AppColors.textWhite 
                    : AppColors.textPrimary;
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: _isAnswered ? null : () {
                    setState(() {
                      _selectedAnswer = option;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _isAnswered && isCorrectOption
                              ? AppColors.textWhite
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _isAnswered && isCorrectOption
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.difficultyBeginner,
                                  size: 20,
                                )
                              : Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const Spacer(),
            
            // 제출 버튼
            if (!_isAnswered)
              ElevatedButton(
                onPressed: _selectedAnswer == null ? null : () {
                  _submitAnswer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '답안 제출',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            if (_isAnswered)
              Card(
                color: _isCorrect 
                    ? AppColors.difficultyBeginner 
                    : AppColors.difficultyExpert,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: AppColors.textWhite,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isCorrect ? '정답입니다!' : '오답입니다',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = _selectedAnswer == widget.question.answer;
    });
    
    // 서버로 답안 전송
    final socketService = ref.read(socketServiceProvider);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser != null) {
      // simple_match_game_screen은 1개 문제만 처리하므로 questionIndex는 0
      socketService.submitAnswer(
        widget.roomId,
        currentUser.id,
        0, // questionIndex
        _selectedAnswer!,
      );
      debugPrint('📤 답안 제출: $_selectedAnswer, 정답: ${widget.question.answer}');
    }
  }
}

