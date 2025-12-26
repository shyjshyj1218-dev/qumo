class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String answer;
  final String? category;
  final String difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    this.category,
    required this.difficulty,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizQuestion.fromSupabase(Map<String, dynamic> data) {
    // id는 bigserial이므로 정수로 올 수 있음
    final id = data['id']?.toString() ?? '';
    
    // options는 jsonb이므로 List<dynamic> 또는 List<String>으로 올 수 있음
    List<String> optionsList = [];
    if (data['options'] != null) {
      if (data['options'] is List) {
        optionsList = (data['options'] as List)
            .map((e) => e.toString())
            .toList();
      } else {
        // 만약 JSON 문자열로 온다면 파싱 필요
        optionsList = [data['options'].toString()];
      }
    }
    
    return QuizQuestion(
      id: id,
      question: data['question'] ?? '',
      options: optionsList,
      answer: data['answer'] ?? '',
      category: data['category'],
      difficulty: data['difficulty'] ?? 'beginner',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id.isNotEmpty ? int.tryParse(id) : null,
      'question': question,
      'options': options, // Supabase가 자동으로 jsonb로 변환
      'answer': answer,
      'category': category,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
