import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();

    if (context.mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      '설정',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                ],
              ),
            ),
            // 설정 목록
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Account and General Settings
                    _buildSettingsSection(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.email,
                          title: '이메일',
                        ),
                        _buildDivider(),
                        _buildSettingItem(
                          context,
                          icon: Icons.person,
                          title: '사용자 이름',
                        ),
                        _buildDivider(),
                        _buildSettingItem(
                          context,
                          icon: Icons.link,
                          title: '걸음 수 데이터 소스',
                        ),
                        _buildDivider(),
                        _buildSettingItem(
                          context,
                          icon: Icons.language,
                          title: '언어',
                        ),
                        _buildDivider(),
                        _buildSettingItem(
                          context,
                          icon: Icons.shield,
                          title: '개인정보 보호',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Premium Status
                    _buildSettingsSection(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.diamond,
                          iconColor: AppColors.difficultyIntermediate,
                          title: '프리미엄 상태',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.coin,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '비활성',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Refer a Friend 배너
                    _buildReferFriendBanner(context),
                    const SizedBox(height: 16),
                    // App Customization
                    _buildSettingsSection(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.apps,
                          title: '앱 아이콘',
                        ),
                        _buildDivider(),
                        _buildSettingItem(
                          context,
                          icon: Icons.widgets,
                          title: '위젯',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 로그아웃 버튼
                    _buildSettingsSection(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.logout,
                          iconColor: AppColors.difficultyExpert,
                          title: '로그아웃',
                          onTap: () => _handleLogout(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderGray,
      indent: 60,
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        // 각 설정 항목 클릭 시 동작 (향후 구현)
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textSecondary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferFriendBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.coin,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '친구 추천',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 16,
                        color: AppColors.coin,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '50 /추천',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coin,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 캐릭터 아이콘
          const Text(
            '🎉',
            style: TextStyle(fontSize: 48),
          ),
        ],
      ),
    );
  }
}

