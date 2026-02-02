import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_question.dart';
import '../services/quiz_service.dart';

final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService();
});

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, Map<String, dynamic>>((ref, params) async {
  final quizService = ref.watch(quizServiceProvider);
  return await quizService.getQuestions(
    difficulty: params['difficulty'] as String?,
    category: params['category'] as String?,
    limit: params['limit'] as int? ?? 10,
  );
});

final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

final currentQuestionProvider = Provider<QuizQuestion?>((ref) {
  final questions = ref.watch(quizQuestionsProvider(<String, dynamic>{}));
  final index = ref.watch(currentQuestionIndexProvider);
  
  if (questions.value == null || questions.value!.isEmpty) return null;
  if (index >= questions.value!.length) return null;
  
  return questions.value![index];
});

final quizAnswersProvider = StateProvider<Map<int, String>>((ref) => {});

final quizResultsProvider = StateProvider<Map<int, bool>>((ref) => {});

final quizScoreProvider = Provider<int>((ref) {
  final results = ref.watch(quizResultsProvider);
  return results.values.where((isCorrect) => isCorrect).length;
});

