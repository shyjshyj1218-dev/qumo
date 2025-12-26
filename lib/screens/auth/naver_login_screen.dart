import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';

class NaverLoginScreen extends ConsumerStatefulWidget {
  const NaverLoginScreen({super.key});

  @override
  ConsumerState<NaverLoginScreen> createState() => _NaverLoginScreenState();
}

class _NaverLoginScreenState extends ConsumerState<NaverLoginScreen> {
  bool _isLoading = false;

  Future<void> _handleNaverLogin() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithNaver();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('네이버 로그인 실패: ${e.toString()}'),
            backgroundColor: AppColors.difficultyExpert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('네이버 로그인'),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _handleNaverLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.naver,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('네이버 로그인'),
                ),
        ),
      ),
    );
  }
}

