import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';

class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구글 로그인 실패: ${e.toString()}'),
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
        title: const Text('구글 로그인'),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _handleGoogleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.google,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('구글 로그인'),
                ),
        ),
      ),
    );
  }
}

