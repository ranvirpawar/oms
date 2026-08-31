/*
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../phlebotomist/patient_registration/models/facility_list_model.dart';

class FacilityTypeMapper {
  static const Map<String, String> _facilityTypeMapping = {
    'HBT': 'HBT Clinics',
    'MH': 'Maternity Home',
    'SH': 'Speciality Hospital',
    'PH': 'Peripheral Hospital',
    'STD': 'STD Clinic',
    'DEADD': 'De-addiction Center',
    'UHC': 'UHC/UPHC',
    'DISP': 'Dispensary',
    'Polyclinic': 'Polyclinic',
    'Cooper': 'Cooper Hospital',
  };

  /// Maps facility type code to display name
  static String getDisplayName(String facilityType) {
    return _facilityTypeMapping[facilityType] ?? facilityType;
  }

  /// Gets all unique display names for dropdown
  static List<String> getDisplayNames(List<String> facilityTypes) {
    return facilityTypes
        .map((type) => getDisplayName(type))
        .toSet()
        .toList()
      ..sort();
  }

  /// Maps display name back to original code for API calls
  static String getOriginalCode(String displayName) {
    for (var entry in _facilityTypeMapping.entries) {
      if (entry.value == displayName) {
        return entry.key;
      }
    }
    return displayName; // Return as-is if no mapping found
  }
}

// Update your facilityTypesProvider to use the mapper
final facilityTypesProvider = Provider.family<List<String>, AsyncValue<List<FacilityModel>>>((ref, facilitiesAsync) {
  return facilitiesAsync.when(
    data: (facilities) {
      final types = facilities
          .map((f) => f.fType)
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList();

      // Convert to display names and sort
      return FacilityTypeMapper.getDisplayNames(types);
    },
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );
});

// Update your filteredFacilitiesProvider to handle the mapping
final filteredFacilitiesProvider = Provider.family<List<FacilityModel>, ({AsyncValue<List<FacilityModel>> facilities, String? selectedType})>((ref, params) {
  return params.facilities.when(
    data: (facilities) {
      if (params.selectedType == null || params.selectedType!.isEmpty) {
        return <FacilityModel>[];
      }

      // Convert display name back to original code for filtering
      final originalCode = FacilityTypeMapper.getOriginalCode(params.selectedType!);
      return facilities.where((f) => f.fType == originalCode).toList();
    },
    loading: () => <FacilityModel>[],
    error: (_, __) => <FacilityModel>[],
  );
});*/
