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
  } catch (e) {
    print('⚠️ .env 파일을 찾을 수 없습니다. constants.dart의 기본값을 사용합니다.');
  }
  
  // Supabase 초기화
  await SupabaseService.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
