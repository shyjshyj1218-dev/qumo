import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final authService = ref.watch(authServiceProvider);
  try {
    return await authService.getUserProfile(currentUser.id);
  } catch (e) {
    return null;
  }
});

final userCoinsProvider = Provider<int>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.value?.coins ?? 0;
});

final userTicketsProvider = Provider<int>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.value?.tickets ?? 0;
});

final userRatingProvider = Provider<int>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.value?.rating ?? 1000;
});

