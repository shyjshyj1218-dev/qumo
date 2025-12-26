import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class Header extends ConsumerWidget {
  final VoidCallback? onProfileTap;

  const Header({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final coins = ref.watch(userCoinsProvider);
    final tickets = ref.watch(userTicketsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.backgroundWhite,
      child: Row(
        children: [
          // 프로필 버튼
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Row(
                children: [
                  // 주황색 원형 배경의 프로필 아이콘
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.coin, // 주황색 배경
                      shape: BoxShape.circle,
                    ),
                    child: userProfile.value?.profileImage != null
                        ? ClipOval(
                            child: Image.network(
                              userProfile.value!.profileImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: AppColors.textWhite,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.value?.nickname ?? '게스트',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Thinker (사색가)', // 칭호
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 코인 및 티켓
          Row(
            children: [
              _buildCoinTicketItem(
                icon: Icons.monetization_on,
                value: coins,
                color: AppColors.coin,
                bgColor: AppColors.coinBg,
              ),
              const SizedBox(width: 12),
              _buildCoinTicketItem(
                icon: Icons.confirmation_number,
                value: tickets,
                color: AppColors.ticket,
                bgColor: AppColors.backgroundWhite,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinTicketItem({
    required IconData icon,
    required int value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
