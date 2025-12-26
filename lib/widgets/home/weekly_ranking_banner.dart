import 'package:flutter/material.dart';
import '../../config/colors.dart';

class WeeklyRankingBanner extends StatelessWidget {
  const WeeklyRankingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140, // 높이 축소
      decoration: BoxDecoration(
        color: AppColors.coin, // 주황색 배경
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 트로피 아이콘과 텍스트
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 40, // 아이콘 크기 축소
                  color: AppColors.textWhite,
                ),
                const SizedBox(height: 8),
                const Text(
                  '랭킹대전',
                  style: TextStyle(
                    fontSize: 20, // 폰트 크기 축소
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '챔피언에 도전해보세요',
                  style: TextStyle(
                    fontSize: 12, // 폰트 크기 축소
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
          // 하단 점 인디케이터
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == 0
                        ? AppColors.textWhite
                        : AppColors.textWhite.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
