import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../utils/helpers.dart';

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('난이도 선택'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDifficultyCard(
            context: context,
            difficulty: 'beginner',
            label: '초급',
            description: '기초 문제로 시작하세요',
            color: AppColors.difficultyBeginner,
          ),
          const SizedBox(height: 16),
          _buildDifficultyCard(
            context: context,
            difficulty: 'intermediate',
            label: '중급',
            description: '조금 더 어려운 문제에 도전하세요',
            color: AppColors.difficultyIntermediate,
          ),
          const SizedBox(height: 16),
          _buildDifficultyCard(
            context: context,
            difficulty: 'advanced',
            label: '상급',
            description: '실력을 테스트해보세요',
            color: AppColors.difficultyAdvanced,
          ),
          const SizedBox(height: 16),
          _buildDifficultyCard(
            context: context,
            difficulty: 'expert',
            label: '최상급',
            description: '최고 난이도에 도전하세요',
            color: AppColors.difficultyExpert,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard({
    required BuildContext context,
    required String difficulty,
    required String label,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz,
              color: AppColors.textWhite,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('/quiz-room?difficulty=$difficulty');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('입장하기'),
          ),
        ],
      ),
    );
  }
}

