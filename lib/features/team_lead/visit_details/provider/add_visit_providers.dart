
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../services/user_service.dart';
import '../../../auth/model/profile_model.dart';
import '../model/facility_center_name_model.dart';
import '../model/facility_center_type_model.dart';
import '../services/visit_service.dart';
import 'add_visit_notifier.dart';
import 'add_visit_state.dart';



final userServiceProvider = Provider<UserService>((ref) => UserService());

final userIdProvider = FutureProvider<String>((ref) async {
  final userService = ref.read(userServiceProvider);
  final ProfileData? userProfile = await userService.getUserProfile();
  return userProfile?.empCode.toString() ?? '';
});

final userProfileProvider = FutureProvider<ProfileData?>((ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.getUserProfile();
});

final districtNameProvider = FutureProvider<String>((ref) async {
  final userService = ref.read(userServiceProvider);
  final ProfileData? userProfile = await userService.getUserProfile();
  return userProfile?.distName ?? '';
});

final visitServiceProvider = Provider<VisitService>((ref) => VisitService());

final districtLgdCodeProvider = FutureProvider<String>((ref) async {
  final userService = ref.read(userServiceProvider);
  final ProfileData? userProfile = await userService.getUserProfile();
  return userProfile?.distLgdCode.toString() ?? '';
});


// NEW: Provider for facility types
final facilityTypesProvider = FutureProvider.family<List<FacilityCenterType>, String>((ref, userId) async {
  if (userId.isEmpty) {
    return <FacilityCenterType>[];
  }
  final visitService = ref.read(visitServiceProvider);
  return await visitService.getFacilityTypeList(userId);
});

// NEW: Provider for facility names based on selected type
final facilityNamesProvider = FutureProvider.family<List<FacilityCenterName>, ({
String distLgdCode,
int centerTypeId
})>((ref, params) async {
  if ( params.distLgdCode.isEmpty || params.centerTypeId == 0) {
    return <FacilityCenterName>[];
  }

  final visitService = ref.read(visitServiceProvider);
  return await visitService.getFacilityList( params.distLgdCode, params.centerTypeId);
});

final addVisitProvider =
StateNotifierProvider.autoDispose.family<AddVisitNotifier, AddVisitState, String>(
      (ref, userId) {
    final visitService = ref.read(visitServiceProvider);
    return AddVisitNotifier(visitService, userId);
  },
);

final drFirstNameControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final drMidNameControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final drLastNameControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final mobileControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final remarkControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});


