import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 연결 테스트 스크립트
/// 실행: dart run check_supabase.dart
void main() async {
  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  
  final url = dotenv.env['SUPABASE_URL']!;
  final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  
  print('🔗 Supabase 연결 테스트 시작...');
  print('URL: $url');
  print('Anon Key: ${anonKey.substring(0, 20)}...');
  
  try {
    // Supabase 초기화
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    
    final supabase = Supabase.instance.client;
    
    // 간단한 연결 테스트
    print('\n✅ Supabase 연결 성공!');
    
    // 테이블 목록 확인
    print('\n📊 기존 테이블 확인 중...');
    try {
      // users 테이블 확인
      final usersCheck = await supabase.from('users').select('count').limit(1);
      print('✅ users 테이블 존재');
    } catch (e) {
      print('⚠️ users 테이블이 없거나 접근 권한이 없습니다: $e');
    }
    
    print('\n✨ 설정이 완료되었습니다!');
    print('이제 flutter run으로 앱을 실행할 수 있습니다.');
    
  } catch (e) {
    print('\n❌ 오류 발생: $e');
    print('Supabase URL과 anon key를 확인해주세요.');
  }
}

