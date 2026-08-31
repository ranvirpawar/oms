import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lifenity_connect/features/auth/model/profile_model.dart';
import 'package:lifenity_connect/services/user_service.dart';

import '../model/visit_model.dart';
import '../services/visit_service.dart';

// Service Provider
final visitServiceProvider = Provider<VisitService>((ref) {
  return VisitService();
});

// Selected Date Provider
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// User ID Provider (you can modify this based on your auth system)
final userIdProvider = FutureProvider<String>((ref) async {
  final UserService userService = UserService();
  final ProfileData? userProfile =  await userService.getUserProfile();
  return userProfile?.empCode.toString()?? ' ';
});

// Visit Data Provider
final visitDataProvider = FutureProvider<VisitResponse>((ref) async {
  final visitService = ref.watch(visitServiceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final userIdAsync = ref.watch(userIdProvider);

  // Handle AsyncValue<String>
  return await userIdAsync.when(
    data: (userId) async {
      return await visitService.getFacilitySurvey(
        fromDate: selectedDate,
        toDate: selectedDate,
        userId: userId,
      );
    },
    loading: () async {
      // You can either throw, return empty, or handle loading state
      throw Exception('User ID still loading');
    },
    error: (e, _) async {
      throw Exception('Failed to get user ID: $e');
    },
  );
});


// Selected Visit Provider for detail view
final selectedVisitProvider = StateProvider<VisitData?>((ref) {
  return null;
});