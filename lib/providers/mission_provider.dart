import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mission_service.dart';
import '../models/mission.dart';

final missionServiceProvider = Provider<MissionService>((ref) {
  return MissionService();
});

final missionsProvider = FutureProvider<List<Mission>>((ref) async {
  final service = ref.read(missionServiceProvider);
  return await service.getAllMissions();
});

final userMissionProgressProvider = FutureProvider.family<Map<String, UserMissionProgress>, String>((ref, userId) async {
  final service = ref.read(missionServiceProvider);
  return await service.getUserMissionProgress(userId);
});
