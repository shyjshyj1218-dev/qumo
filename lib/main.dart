import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'app.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드 (선택사항)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env 파일 로드 성공');
  } catch (e) {
    debugPrint('⚠️ .env 파일을 찾을 수 없습니다. constants.dart의 기본값을 사용합니다.');
  }
  
  // Supabase 초기화
  final supabaseUrl = AppConstants.supabaseUrl;
  final supabaseAnonKey = AppConstants.supabaseAnonKey;
  
  debugPrint('🔵 Supabase 초기화 시도...');
  debugPrint('🔵 URL: $supabaseUrl');
  debugPrint('🔵 Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
  
  try {
    await SupabaseService.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('✅ Supabase 초기화 성공');
  } catch (e) {
    debugPrint('❌ Supabase 초기화 실패: $e');
    rethrow;
  }
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
