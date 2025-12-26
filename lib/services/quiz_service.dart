import '../models/quiz_question.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class QuizService {
  final supabase = SupabaseService.client;

  Future<List<QuizQuestion>> getQuestions({
    String? difficulty,
    String? category,
    int limit = 10,
  }) async {
    var query = supabase
        .from(AppConstants.quizQuestionsCollection)
        .select();

    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.limit(limit);

    return (response as List)
        .map((data) => QuizQuestion.fromSupabase(data as Map<String, dynamic>))
        .toList();
  }

  Future<QuizQuestion?> getQuestionById(String questionId) async {
    // bigserial ID는 정수이므로 int로 변환 시도
    final id = int.tryParse(questionId) ?? questionId;
    final response = await supabase
        .from(AppConstants.quizQuestionsCollection)
        .select()
        .eq('id', id)
        .single();

    if (response == null) {
      return null;
    }

    return QuizQuestion.fromSupabase(response as Map<String, dynamic>);
  }

  Future<void> saveQuizResult({
    required String userId,
    required String difficulty,
    required int correctCount,
    required int totalCount,
    required int timeSpent,
  }) async {
    await supabase.from('quiz_results').insert({
      'user_id': userId,
      'difficulty': difficulty,
      'correct_count': correctCount,
      'total_count': totalCount,
      'time_spent': timeSpent,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
