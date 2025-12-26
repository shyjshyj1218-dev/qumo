import 'package:dio/dio.dart';
import '../utils/constants.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // 인터셉터 추가 (인증 토큰 등)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 토큰 추가 로직
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  // 인증 관련
  Future<Response> register(String email, String password) async {
    return await _dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> login(String email, String password) async {
    return await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> logout() async {
    return await _dio.post('/api/auth/logout');
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/api/auth/me');
  }

  // 퀴즈 관련
  Future<Response> getQuestions({
    String? difficulty,
    String? category,
    int? limit,
  }) async {
    return await _dio.get('/api/quiz/questions', queryParameters: {
      if (difficulty != null) 'difficulty': difficulty,
      if (category != null) 'category': category,
      if (limit != null) 'limit': limit,
    });
  }

  Future<Response> getQuestionById(String id) async {
    return await _dio.get('/api/quiz/questions/$id');
  }

  Future<Response> saveQuizResult(Map<String, dynamic> result) async {
    return await _dio.post('/api/quiz/results', data: result);
  }

  // 사용자 관련
  Future<Response> getUser(String id) async {
    return await _dio.get('/api/users/$id');
  }

  Future<Response> updateUser(String id, Map<String, dynamic> data) async {
    return await _dio.put('/api/users/$id', data: data);
  }

  Future<Response> getUserRating(String id) async {
    return await _dio.get('/api/users/$id/rating');
  }

  Future<Response> updateUserRating(String id, int rating) async {
    return await _dio.put('/api/users/$id/rating', data: {'rating': rating});
  }

  // 미션 관련
  Future<Response> getMissions() async {
    return await _dio.get('/api/missions');
  }

  Future<Response> getMission(String id) async {
    return await _dio.get('/api/missions/$id');
  }

  Future<Response> completeMission(String id) async {
    return await _dio.post('/api/missions/$id/complete');
  }

  // 랭킹 관련
  Future<Response> getRankings({int? limit, int? offset}) async {
    return await _dio.get('/api/rankings', queryParameters: {
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    });
  }

  Future<Response> getUserRank(String userId) async {
    return await _dio.get('/api/rankings/user/$userId');
  }

  // 상점 관련
  Future<Response> getShopItems() async {
    return await _dio.get('/api/shop/items');
  }

  Future<Response> purchaseItem(String itemId, {int? coins, int? tickets}) async {
    return await _dio.post('/api/shop/purchase', data: {
      'item_id': itemId,
      if (coins != null) 'coins': coins,
      if (tickets != null) 'tickets': tickets,
    });
  }
}

