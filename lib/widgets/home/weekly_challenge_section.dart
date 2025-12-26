import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';

class WeeklyChallengeSection extends StatefulWidget {
  const WeeklyChallengeSection({super.key});

  @override
  State<WeeklyChallengeSection> createState() => _WeeklyChallengeSectionState();
}

class _WeeklyChallengeSectionState extends State<WeeklyChallengeSection> {
  bool _isRegistered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16), // 패딩 축소
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            children: [
              const Icon(
                Icons.star,
                color: AppColors.textWhite,
                size: 20, // 아이콘 크기 축소
              ),
              const SizedBox(width: 6),
              const Text(
                '오늘 랭킹 대전',
                style: TextStyle(
                  fontSize: 16, // 폰트 크기 축소
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Text(
                    '20:00',
                    style: TextStyle(
                      fontSize: 12, // 폰트 크기 축소
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textWhite,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12), // 간격 축소
          // 통계
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: '참여 인원',
                  value: '0명',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.monetization_on,
                  label: '상금',
                  value: '5만',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // 간격 축소
          // 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!_isRegistered) {
                  context.push('/matching');
                  setState(() => _isRegistered = true);
                } else {
                  setState(() => _isRegistered = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundWhite,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 10), // 패딩 축소
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isRegistered ? '신청완료' : '대전 신청',
                style: const TextStyle(
                  fontSize: 14, // 폰트 크기 축소
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    IconData? icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Row(
            children: [
              Icon(icon, color: AppColors.textWhite, size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14, // 폰트 크기 축소
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 14, // 폰트 크기 축소
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10, // 폰트 크기 축소
            color: AppColors.textWhite,
          ),
        ),
      ],
    );
  }
}
