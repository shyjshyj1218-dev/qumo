import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_user.dart';
import '../services/matching_service.dart';
import '../services/socket_service.dart';

final matchingServiceProvider = Provider<MatchingService>((ref) {
  return MatchingService();
});

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

final matchingStatusProvider = StateProvider<String>((ref) => 'idle'); // idle, matching, matched

final opponentProvider = StateProvider<MatchUser?>((ref) => null);

final matchIdProvider = StateProvider<String?>((ref) => null);

final playerProgressProvider = StateProvider<int>((ref) => 0);

final opponentProgressProvider = StateProvider<int>((ref) => 0);

final playerCorrectCountProvider = StateProvider<int>((ref) => 0);

final opponentCorrectCountProvider = StateProvider<int>((ref) => 0);

final matchResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

