import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';

class ChallengeQuizScreen extends StatelessWidget {
  const ChallengeQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('도전'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildChallengeCard(
              context: context,
              icon: Icons.all_inclusive,
              title: '무한문제',
              description: '끝없이 문제를 풀어보세요',
              onTap: () {
                // 무한문제 모드로 이동
              },
            ),
            const SizedBox(height: 16),
            _buildChallengeCard(
              context: context,
              icon: Icons.assignment_late,
              title: '오답풀이',
              description: '틀린 문제를 다시 풀어보세요',
              onTap: () {
                // 오답풀이 모드로 이동
              },
            ),
            const SizedBox(height: 16),
            _buildChallengeCard(
              context: context,
              icon: Icons.quiz,
              title: '난이도 별',
              description: '난이도를 선택하여 문제를 풀어보세요',
              onTap: () {
                context.push('/difficulty-selection');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: const TextStyle(
                      fontSize: 18,
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
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

