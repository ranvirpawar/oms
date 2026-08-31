// providers/visit_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/provider/visit_providers.dart';

import '../model/visit_model.dart';
import '../services/visit_service.dart';

class VisitNotifier extends StateNotifier<AsyncValue<List<VisitData>>> {
  VisitNotifier(this._visitService) : super(const AsyncValue.loading());

  final VisitService _visitService;

  Future<void> fetchVisits({
    required DateTime date,
    required String userId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await _visitService.getFacilitySurvey(
        fromDate: date,
        toDate: date,
        userId: userId,
      );
      state = AsyncValue.data(response.output);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void selectVisit(VisitData? visit) {
    // This would typically be handled by selectedVisitProvider
  }
}

final visitNotifierProvider = StateNotifierProvider<VisitNotifier, AsyncValue<List<VisitData>>>((ref) {
  return VisitNotifier(ref.watch(visitServiceProvider));
});