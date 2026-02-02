import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../providers/matching_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  int _waitingTime = 0;
  int _queueSize = 0;

  @override
  void initState() {
    super.initState();
    _startMatching();
  }

  void _startMatching() {
    final currentUser = ref.read(currentUserProvider);
    final userProfile = ref.read(userProfileProvider);
    
    if (currentUser == null) return;

    final socketService = ref.read(socketServiceProvider);
    final rating = userProfile.value?.rating ?? 1000;

    socketService.connect(currentUser.id, onConnected: (userId) {
      socketService.requestMatch(userId, rating);
    });

    socketService.onMatchFound((data) {
      debugPrint('🎉 매칭 성공: $data');
      ref.read(matchingStatusProvider.notifier).state = 'matched';
      
      // TODO: 나중에 문제 화면으로 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('매칭 성공! (문제 화면은 다음 단계에서 구현)')),
        );
      }
    });

    socketService.onMatchQueued(() {
      setState(() {
        _queueSize = 1; // 큐에 대기 중
      });
    });

    // 타이머 시작
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _waitingTime++;
        });
        _startTimer();
      }
    });
  }

  void _cancelMatching() {
    final socketService = ref.read(socketServiceProvider);
    socketService.disconnect();

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('매칭 중'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              '상대방을 찾는 중...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '대기 시간: ${_formatTime(_waitingTime)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (_queueSize > 0) ...[
              const SizedBox(height: 8),
              Text(
                '대기 인원: $_queueSize명',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _cancelMatching,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.difficultyExpert,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

