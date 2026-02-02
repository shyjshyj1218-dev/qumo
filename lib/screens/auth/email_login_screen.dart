import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await authService.signInWithEmail(email, password);
      } else {
        final response = await authService.signUpWithEmail(email, password);
        // 회원가입 후 닉네임 설정 화면으로 이동
        if (mounted && response.user != null) {
          context.push('/nickname-setup', extra: response.user!.id);
        }
        return;
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _isLogin ? '로그인 실패' : '회원가입 실패';
        if (e is AuthException) {
          // 사용자 친화적인 에러 메시지로 변환
          if (e.message.contains('Invalid login credentials') || 
              e.message.contains('invalid_credentials')) {
            errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다';
          } else if (e.message.contains('Email not confirmed')) {
            errorMessage = '이메일 인증이 필요합니다';
          } else if (e.message.contains('User already registered')) {
            errorMessage = '이미 등록된 이메일입니다';
          } else {
            errorMessage = e.message;
          }
          debugPrint('❌ Supabase Auth 에러: ${e.message}');
          debugPrint('❌ 에러 상태 코드: ${e.statusCode}');
        } else {
          debugPrint('❌ ${_isLogin ? "로그인" : "회원가입"} 에러: $e');
          errorMessage = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.difficultyExpert,
            duration: const Duration(seconds: 5),
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
        title: Text(_isLogin ? '이메일 로그인' : '회원가입'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: '이메일을 입력하세요',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    hintText: '비밀번호를 입력하세요',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? '로그인' : '회원가입'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _isLogin = !_isLogin);
                  },
                  child: Text(
                    _isLogin
                        ? '계정이 없으신가요? 회원가입'
                        : '이미 계정이 있으신가요? 로그인',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
