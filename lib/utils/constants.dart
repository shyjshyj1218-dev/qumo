import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase - 환경 변수에서 로드하거나 기본값 사용
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';
  
  // API - 환경 변수에서 로드하거나 기본값 사용
  static String get baseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'https://your-api-url.com';
  static String get socketUrl => 
      dotenv.env['SOCKET_URL'] ?? 'http://192.168.219.105:3001';

  // Supabase 테이블/컬렉션 이름
  static const String usersCollection = 'users';
  static const String quizQuestionsCollection = 'quiz_questions';
  static const String quizRoomsCollection = 'quiz_rooms';
  static const String matchesCollection = 'matches';
  static const String missionsCollection = 'missions';
  static const String rankingsCollection = 'rankings';
  static const String shopItemsCollection = 'shop_items';

  // Difficulty Levels
  static const String difficultyBeginner = 'beginner';
  static const String difficultyIntermediate = 'intermediate';
  static const String difficultyAdvanced = 'advanced';
  static const String difficultyExpert = 'expert';

  // Match Status
  static const String matchStatusWaiting = 'waiting';
  static const String matchStatusInProgress = 'in_progress';
  static const String matchStatusFinished = 'finished';

  // Game Results
  static const String resultWin = 'win';
  static const String resultLose = 'lose';
  static const String resultDraw = 'draw';

  // Quiz Room Status
  static const String roomStatusWaiting = 'waiting';
  static const String roomStatusInProgress = 'in_progress';
  static const String roomStatusFinished = 'finished';

  // Time Limits
  static const int matchGameTimeLimit = 300; // 5 minutes in seconds
  static const int questionTimeLimit = 30; // 30 seconds per question
}
