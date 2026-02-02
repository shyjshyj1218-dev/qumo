import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/league_service.dart';
import '../models/league.dart';

final leagueServiceProvider = Provider<LeagueService>((ref) {
  return LeagueService();
});

// 사용자의 현재 리그
final currentLeagueProvider = FutureProvider.family<LeagueModel?, String>((ref, userId) async {
  final service = ref.read(leagueServiceProvider);
  try {
    return await service.getOrCreateCurrentLeague(userId);
  } catch (e) {
    return null;
  }
});

// 사용자의 리그 랭킹
final userLeagueRankingsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final service = ref.read(leagueServiceProvider);
  try {
    return await service.getUserLeagueRankings(userId);
  } catch (e) {
    return [];
  }
});

// 리그 랭킹 (리그 ID로)
final leagueRankingsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, leagueId) async {
  final service = ref.read(leagueServiceProvider);
  try {
    return await service.getLeagueRankings(leagueId);
  } catch (e) {
    return [];
  }
});
