import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';

class GameModeCards extends StatelessWidget {
  const GameModeCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGameCard(
                  context: context,
                  icon: Icons.all_inclusive, // 무한대 모양 아이콘
                  title: '퀴즈방',
                  description: '경쟁하며 문제를 풀어보세요',
                  onTap: () => context.push('/difficulty-selection'),
                ),
              ),
              const SizedBox(width: 12), // 간격 축소
              Expanded(
                child: _buildGameCard(
                  context: context,
                  icon: Icons.assignment, // 문서 아이콘
                  title: '도전',
                  description: '혼자서 문제를 풀어보세요',
                  onTap: () => context.push('/challenge-quiz'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // 간격 축소
          Row(
            children: [
              Expanded(
                child: _buildGameCard(
                  context: context,
                  icon: Icons.people, // 사람 아이콘
                  title: '방만들기',
                  description: '친구랑 같이 해보세요',
                  onTap: () {
                    // 방만들기 기능 (향후 구현)
                  },
                ),
              ),
              const SizedBox(width: 12), // 간격 축소
              Expanded(
                child: _buildGameCard(
                  context: context,
                  icon: Icons.menu_book, // 책 아이콘
                  title: '멘사',
                  description: '새로운 도전을 해보세요',
                  onTap: () {
                    // 멘사 기능 (향후 구현)
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12), // 패딩 축소
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32, // 아이콘 크기 축소
              color: AppColors.textWhite,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14, // 폰트 크기 축소
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 10, // 폰트 크기 축소
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
