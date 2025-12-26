import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../widgets/common/bottom_navigation.dart';
import '../../widgets/home/weekly_ranking_banner.dart';
import '../../widgets/home/ranking_chart_widget.dart';
import '../../providers/matching_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/socket_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 상단 프로필 및 재화 정보 (경계선 없음)
          _buildTopBar(),
          // 메인 콘텐츠
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // 주황색 랭킹대전 배너
                const WeeklyRankingBanner(),
                const SizedBox(height: 8),
                // 랭킹 차트
                const RankingChartWidget(),
              ],
            ),
          ),
          // 하단 시작하기 버튼
          _buildStartButton(),
          // Bottom Navigation
          BottomNavigation(
            currentIndex: _currentNavIndex,
            onTap: (index) {
              setState(() => _currentNavIndex = index);
              switch (index) {
                case 0:
                  // 홈은 이미 현재 화면
                  break;
                case 1:
                  context.push('/mission');
                  break;
                case 2:
                  context.push('/challenge-quiz');
                  break;
                case 3:
                  context.push('/ranking');
                  break;
                case 4:
                  context.push('/shop');
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final userProfile = ref.watch(userProfileProvider);
    final coins = ref.watch(userCoinsProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
      ),
      color: AppColors.background,
      child: Row(
        children: [
          // 프로필 및 닉네임
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.push('/profile');
              },
              child: Row(
                children: [
                  // 프로필 이미지
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.coin,
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
                  // 닉네임
                  Expanded(
                    child: Text(
                      userProfile.value?.nickname ?? '게스트',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 골드 및 친구 버튼
          Row(
            children: [
              _buildCoinTicketItem(
                icon: Icons.monetization_on,
                value: coins,
                color: AppColors.coin,
                bgColor: AppColors.coinBg,
              ),
              const SizedBox(width: 12),
              // 친구 버튼
              GestureDetector(
                onTap: () {
                  // 친구 화면으로 이동 (향후 구현)
                  context.push('/friends');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: CustomPaint(
                    painter: FriendsIconPainter(),
                  ),
                ),
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

  Widget _buildStartButton() {
    final matchingStatus = ref.watch(matchingStatusProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ElevatedButton(
        onPressed: () {
          if (matchingStatus == 'idle') {
            // 매칭 시작
            _startMatching();
          } else if (matchingStatus == 'matching') {
            // 매칭 취소
            _cancelMatching();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: matchingStatus == 'matching'
              ? AppColors.difficultyExpert
              : AppColors.primary,
          foregroundColor: AppColors.textWhite,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          matchingStatus == 'matching' ? '매칭 대기 중...' : '시작하기',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _startMatching() {
    final currentUser = ref.read(currentUserProvider);
    final userProfile = ref.read(userProfileProvider);

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    ref.read(matchingStatusProvider.notifier).state = 'matching';

    final socketService = ref.read(socketServiceProvider);
    final rating = userProfile.value?.rating ?? 1000;

    // Socket 연결
    socketService.connect(currentUser.id);

    // 매칭 요청
    socketService.requestMatch(currentUser.id, rating);

    // 매칭 성공 리스너
    socketService.onMatchFound((opponent, matchId, questions) {
      ref.read(matchingStatusProvider.notifier).state = 'matched';
      ref.read(opponentProvider.notifier).state = opponent;
      ref.read(matchIdProvider.notifier).state = matchId;

      if (mounted) {
        context.push('/realtime-match-game', extra: {
          'opponent': opponent,
          'matchId': matchId,
          'questions': questions,
        });
      }
    });

    // 매칭 큐 상태 리스너
    socketService.onMatchQueued((queueSize) {
      // 큐 크기 표시 (선택사항)
    });

    // 매칭 에러 리스너
    socketService.removeListener('match-error');
    socketService.socket?.on('match-error', (data) {
      if (mounted) {
        ref.read(matchingStatusProvider.notifier).state = 'idle';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '매칭 중 오류가 발생했습니다')),
        );
      }
    });

    // 매칭 취소 확인 리스너
    socketService.removeListener('match-cancelled');
    socketService.socket?.on('match-cancelled', (_) {
      if (mounted) {
        ref.read(matchingStatusProvider.notifier).state = 'idle';
      }
    });
  }

  void _cancelMatching() {
    final socketService = ref.read(socketServiceProvider);
    
    // 매칭 취소 요청
    socketService.cancelMatch();
    
    // 상태를 idle로 변경
    ref.read(matchingStatusProvider.notifier).state = 'idle';
  }
}

// 친구 아이콘 CustomPainter
class FriendsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // SVG 경로를 Flutter Path로 변환
    // M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2
    final path1 = Path()
      ..moveTo(size.width * 0.67, size.height * 0.875) // M16 21
      ..lineTo(size.width * 0.67, size.height * 0.75) // v-2
      ..arcToPoint(
        Offset(size.width * 0.33, size.height * 0.75),
        radius: const Radius.circular(4),
        clockwise: false,
        largeArc: false,
      ) // a4 4 0 0 0-4-4
      ..lineTo(size.width * 0.25, size.height * 0.75) // H6
      ..arcToPoint(
        Offset(size.width * 0.08, size.height * 0.75),
        radius: const Radius.circular(4),
        clockwise: false,
        largeArc: false,
      ) // a4 4 0 0 0-4
      ..lineTo(size.width * 0.08, size.height * 0.875); // 4v2

    // M16 3.128a4 4 0 0 1 0 7.744
    final path2 = Path()
      ..moveTo(size.width * 0.67, size.height * 0.13) // M16 3.128
      ..arcToPoint(
        Offset(size.width * 0.67, size.height * 0.45),
        radius: const Radius.circular(4),
        clockwise: true,
        largeArc: false,
      ); // a4 4 0 0 1 0 7.744

    // M22 21v-2a4 4 0 0 0-3-3.87
    final path3 = Path()
      ..moveTo(size.width * 0.92, size.height * 0.875) // M22 21
      ..lineTo(size.width * 0.92, size.height * 0.75) // v-2
      ..arcToPoint(
        Offset(size.width * 0.75, size.height * 0.66),
        radius: const Radius.circular(4),
        clockwise: false,
        largeArc: false,
      ); // a4 4 0 0 0-3-3.87

    // circle cx="9" cy="7" r="4"
    final circlePath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.375, size.height * 0.29),
          radius: size.width * 0.167,
        ),
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
    canvas.drawPath(circlePath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
