import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';
import 'league_service.dart';

class AuthService {
  final GoTrueClient _auth = SupabaseService.auth;
  final SupabaseClient _supabase = SupabaseService.client;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    // 웹: 현재 실행 중인 origin으로 리다이렉트 (예: http://localhost:<port>/)
    // 모바일: 딥링크 사용
    final redirect = kIsWeb
        ? Uri.base
            .replace(path: '/', fragment: '') // 해시라우터 대비 fragment 제거
            .toString()
        : 'io.supabase.flutterquickstart://login-callback/';

    return await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirect,
    );
  }

  Future<AuthResponse> signInWithNaver() async {
    // Naver는 커스텀 OAuth provider로 구현 필요
    // 또는 커스텀 토큰 사용
    throw UnimplementedError('Naver Sign-In not implemented yet');
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> createUserProfile(String userId, String email, String nickname) async {
    final userData = {
      'id': userId,
      'email': email,
      'nickname': nickname,
      'coins': 0,
      'tickets': 0,
      'rating': 1000,
      'current_league_tier': 'bronze', // 기본값: 브론즈
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from(AppConstants.usersCollection)
        .insert(userData);

    // 리그 초기화
    final leagueService = LeagueService();
    await leagueService.initializeUserLeague(userId);
  }

  Future<UserModel> getUserProfile(String userId) async {
    final response = await _supabase
        .from(AppConstants.usersCollection)
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromSupabase(response);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _supabase
        .from(AppConstants.usersCollection)
        .update(updates)
        .eq('id', userId);
  }

  Future<void> updateNickname(String userId, String nickname) async {
    await updateUserProfile(userId, {'nickname': nickname});
  }
}
