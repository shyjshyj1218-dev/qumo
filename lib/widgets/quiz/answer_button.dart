import 'package:flutter/material.dart';
import '../../config/colors.dart';

class AnswerButton extends StatelessWidget {
  final String answer;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const AnswerButton({
    super.key,
    required this.answer,
    this.index = 0,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = AppColors.backgroundWhite;
    Color textColor = AppColors.textPrimary;
    Color borderColor = AppColors.borderGray;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = AppColors.difficultyBeginner;
        textColor = AppColors.textWhite;
        borderColor = AppColors.difficultyBeginner;
      } else if (isSelected && !isCorrect) {
        backgroundColor = AppColors.difficultyExpert;
        textColor = AppColors.textWhite;
        borderColor = AppColors.difficultyExpert;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.textWhite;
      borderColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getAnswerLabel(),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (showResult && isCorrect)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.textWhite,
                ),
              if (showResult && isSelected && !isCorrect)
                const Icon(
                  Icons.cancel,
                  color: AppColors.textWhite,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAnswerLabel() {
    // A, B, C, D 라벨을 반환
    return String.fromCharCode(65 + index); // 65는 'A'의 ASCII 코드
  }
}

