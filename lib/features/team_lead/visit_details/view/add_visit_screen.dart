import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/custom_dropdown.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/visit_location_map.dart';
import 'package:lifenity_connect/utils/helper_functions/input_formatter.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import '../../../../componenents/c_textformfeild.dart';
import '../../../../componenents/cdateformpicker_field.dart';
import '../../../../constants/app_assets.dart';
import '../../../../utils/widgets/modern_dropdown.dart';
import '../model/facility_center_name_model.dart';
import '../provider/add_visit_notifier.dart';
import '../provider/add_visit_providers.dart';

class AddVisitScreen extends ConsumerWidget {
  const AddVisitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(userIdProvider);
    final districtNameAsync = ref.watch(districtNameProvider);
    final districtLgdCodeAsync = ref.watch(districtLgdCodeProvider);

    return userIdAsync.when(
      data: (userId) {
        if (userId.isEmpty) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Add Visit'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Unable to get user information'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(userIdProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final addVisitState = ref.watch(addVisitProvider(userId));
        final addVisitNotifier = ref.read(addVisitProvider(userId).notifier);

        // Watch facility types
        final facilityTypesAsync = ref.watch(facilityTypesProvider(userId));

        // Watch facility names only when type is selected
        final facilityNamesAsync = districtLgdCodeAsync.when(
          data: (distLgdCode) {
            if (addVisitState.selectedFacilityType == null ||
                distLgdCode.isEmpty) {
              return const AsyncValue<List<FacilityCenterName>>.data(
                  <FacilityCenterName>[]);
            }
            return ref.watch(facilityNamesProvider((
              distLgdCode: distLgdCode,
              centerTypeId: addVisitState.selectedFacilityType!.centerTypeId,
            )));
          },
          loading: () => const AsyncValue<List<FacilityCenterName>>.loading(),
          error: (error, stack) =>
              AsyncValue<List<FacilityCenterName>>.error(error, stack),
        );

        return Scaffold(
          appBar: const CustomAppBar(title: 'Add Visit'),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: CFormDateField(
                          label: 'Date',
                          value: DateFormat('dd-MM-yyyy')
                              .format(addVisitState.selectedDate),
                          onTap: () async {

                          },
                          iconPath: AppAssets.calendarIcon,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CFormDateField(
                          iconPath: AppAssets.calendarClockIcon,
                          label: 'Time',
                          isReadOnly: true,
                          onTap: () async {

                          },
                          value: addVisitState.selectedTime.format(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // District (non-editable)
                  districtNameAsync.when(
                    data: (districtName) => CFormTextField(
                      label: 'District',
                      iconPath: AppAssets.location,
                      isRequired: true,
                      initialValue: districtName,
                      isReadOnly: true,
                    ),
                    loading: () => const CFormTextField(
                      label: 'District',
                      iconPath: AppAssets.mapPinIcon,
                      isRequired: true,
                      initialValue: 'Loading...',
                    ),
                    error: (_, __) => const CFormTextField(
                      label: 'District',
                      iconPath: AppAssets.mapPinIcon,
                      isRequired: true,
                      initialValue: 'Error loading district',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Facility Type Dropdown
                  facilityTypesAsync.when(
                    data: (facilityTypes) {
                      return ModernDropdown(
                        isRequired: true,
                        iconPath: AppAssets.facility,
                        label: 'Facility Type',
                        value: addVisitState
                                .selectedFacilityType?.centerTypeName ??
                            '',
                        items: facilityTypes
                            .map((type) => type.centerTypeName)
                            .toList(),
                        onChanged: (value) {
                          if (value != null && value.isNotEmpty) {
                            final selectedType = facilityTypes.firstWhere(
                              (type) => type.centerTypeName == value,
                            );
                            addVisitNotifier.updateFacilityType(selectedType);
                          } else {
                            addVisitNotifier.updateFacilityType(null);
                          }
                        },
                      );
                    },
                    loading: () => ModernDropdown(
                      isRequired: true,
                      iconPath: AppAssets.facility,
                      label: 'Facility Type',
                      value: '',
                      items: const [],
                      onChanged: (value)=>'',

                    ),
                    error: (error, _) => ModernDropdown(
                      isRequired: true,
                      iconPath: AppAssets.facility,
                      label: 'Facility Type',
                      value: '',
                      items: const [],
                      onChanged: (value)=>'',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Facility Name Dropdown
                  facilityNamesAsync.when(
                    data: (facilityNames) {
                      final isEnabled =
                          addVisitState.selectedFacilityType != null &&
                              facilityNames.isNotEmpty;

                      return CustomDropdown(
                        key: ValueKey(
                            '${addVisitState.selectedFacilityType?.centerTypeId ?? 0}_${addVisitState.selectedFacility?.centerId ?? 0}'),
                        label: 'Facility Name',
                        value:
                            addVisitState.selectedFacility?.centerLabName ?? '',
                        items: facilityNames
                            .map((facility) => facility.centerLabName)
                            .toList(),
                        onChanged: isEnabled
                            ? (value) {
                                if (value != null && value.isNotEmpty) {
                                  final selectedFacility =
                                      facilityNames.firstWhere(
                                    (facility) =>
                                        facility.centerLabName == value,
                                  );
                                  addVisitNotifier
                                      .updateSelectedFacility(selectedFacility);
                                } else {
                                  addVisitNotifier.updateSelectedFacility(null);
                                }
                              }
                            : null,
                        iconPath: AppAssets.facility,
                        isRequired: true,
                        isReadOnly: !isEnabled,
                        placeholder: addVisitState.selectedFacilityType == null
                            ? 'Select Facility Type First'
                            : facilityNames.isEmpty
                                ? 'No facilities available'
                                : 'Select Facility',
                      );
                    },
                    loading: () => CustomDropdown(
                      label: 'Facility Name',
                      value: '',
                      items: const [],
                      onChanged: null,
                      iconPath: AppAssets.facility,
                      isRequired: true,
                      isReadOnly: true,
                      placeholder: addVisitState.selectedFacilityType == null
                          ? 'Select Facility Type First'
                          : 'Loading facilities...',
                    ),
                    error: (error, _) => const CustomDropdown(
                      label: 'Facility Name',
                      value: '',
                      items: [],
                      onChanged: null,
                      iconPath: AppAssets.facility,
                      isRequired: true,
                      isReadOnly: true,
                      placeholder: 'Error loading facilities',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Doctor Name Fields
                  Text(
                    'Doctor Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  CFormTextField(
                    label: 'First Name',
                    iconPath: AppAssets.userIcon,
                    isRequired: true,
                    inputFormatters: [SingleWordFormatter()],
                    controller: ref.watch(drFirstNameControllerProvider),
                    onChanged: (value) =>
                        addVisitNotifier.updateDrFirstName(value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CFormTextField(
                          controller: ref.watch(drLastNameControllerProvider),
                          label: 'Last Name',
                          iconPath: AppAssets.userIcon,
                          isRequired: false,
                          inputFormatters: [SingleWordFormatter()],
                          onChanged: (value) =>
                              addVisitNotifier.updateDrLastName(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CFormTextField(
                          controller: ref.watch(drMidNameControllerProvider),
                          label: 'Middle Name',
                          iconPath: AppAssets.userIcon,
                          inputFormatters: [SingleWordFormatter()],
                          isRequired: false,
                          onChanged: (value) =>
                              addVisitNotifier.updateDrMidName(value),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mobile Number
                  CFormTextField(
                    controller: ref.watch(mobileControllerProvider),
                    label: 'Mobile Number',
                    iconPath: AppAssets.mobileIcon,
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: InputFormatters.digits,
                    onChanged: (value) =>
                        addVisitNotifier.updateMobileNo(value),
                  ),

                  const SizedBox(height: 16),

                  // Remark
                  CFormTextField(
                    controller: ref.watch(remarkControllerProvider),
                    label: 'Remark',
                    iconPath: AppAssets.fileNoteIcon,
                    maxLines: 1,
                    maxLength: 100,
                    // allow alphanumeric and space
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                    ],
                    onChanged: (value) => addVisitNotifier.updateRemark(value),
                  ),

                  const SizedBox(height: 16),

                  // Photo Section
                  Text(
                    'Photo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: addVisitState.selectedPhoto == null
                        ? () => _pickImage(ImageSource.camera, addVisitNotifier)
                        : null,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: addVisitState.selectedPhoto != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    key: ValueKey(
                                        addVisitState.selectedPhoto?.path),
                                    addVisitState.selectedPhoto!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => addVisitNotifier.removePhoto(),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to capture photo',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error Display
                  if (addVisitState.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              addVisitState.error!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (addVisitState.selectedFacility?.latitude != null && addVisitState.latitude != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: VisitLocationMapWidget(
                        userLat: double.parse(addVisitState.latitude!),
                        userLng: double.parse(addVisitState.longitude!),
                        facilityLat: addVisitState.selectedFacility!.latitude!,
                        facilityLng: addVisitState.selectedFacility!.longitude!,
                        distanceInMeters: addVisitState.distanceInMeters,
                        isWithinRadius: addVisitState.isWithinRadius,
                        isRefreshing: addVisitState.isFetchingLocation,
                        distance: addVisitState.distance?? ' ',

                        onRefreshLocation: () =>
                            ref.read(addVisitProvider(userId).notifier).refreshLocation(),
                      ),
                    ),
                  if (addVisitState.error != null) const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: addVisitState.isSubmitting
                          ? null
                          : () => addVisitNotifier.submitVisit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: addVisitState.isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Submitting...'),
                              ],
                            )
                          : const Text(
                              'Submit Visit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        appBar: CustomAppBar(title: 'Add Visit'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: const CustomAppBar(title: 'Add Visit'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userIdProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, AddVisitNotifier notifier) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        notifier.updatePhoto(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
}
