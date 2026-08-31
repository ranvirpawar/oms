import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/models/center_name_model.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/models/district_list_model.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/models/facility_list_model.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/models/marital_status_model.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';
import 'package:uuid/uuid.dart';

import '../models/doctor_reference.dart';
import '../models/existing_patient_model.dart';
import '../models/id_proof_models.dart';
import '../models/state_list.dart';
import '../service/patient_registration_service.dart';

import '../view/test_selection_view.dart';
import '../view/widget/existing_patient_bottomsheet.dart';
import 'package:lifenity_connect/utils/helper_functions/debug_print.dart';

class PatientRegistrationController extends GetxController {
  // Section Management
  final RxInt selectedSection = 0.obs;
  final List<String> sections = [
    'Lab Info',
    'Patient Info',
    'Residence Info',
    /*   'Medical Info'*/
  ];

  // Form Keys for validation
  final GlobalKey<FormState> labFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> patientFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> residenceFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> medicalFormKey = GlobalKey<FormState>();

  // Lab Info Section
  final Rx<CenterModel?> selectedLabName = Rx<CenterModel?>(
    null,
  ); // Changed from RxString
  final Rx<FacilityModel?> selectedFacilityName = Rx<FacilityModel?>(
    null,
  ); // Changed from RxString
  final RxString selectedProcessLab = ''.obs;
  final RxString selectedSampleType = 'Regular Patient'.obs;
  final RxString selectedPatientType = 'OPD'.obs;
  final TextEditingController opdNoController = TextEditingController();
  final RxString labInfoError = ''.obs;

  // bag id
  final RxString bagId = ''.obs;

  // Patient Info Section
  final RxBool isNewPatient = true.obs;
  final RxString selectedPrefix = ''.obs;
  final RxString patientId = ''.obs;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final RxString selectedGender = ''.obs;
  final Rx<DateTime?> selectedDateOfBirth = Rx<DateTime?>(null);
  final TextEditingController ageController = TextEditingController();
  final RxString selectedMaritalStatus = ''.obs;
  final RxString selectedSearchPatientType = 'Mobile'.obs;
  final RxString selectedIdType = ''.obs;
  final TextEditingController idProofNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final RxString patientInfoError = ''.obs;
  final RxString ageValidation = ''.obs;

  // Existing Patient Search

  final TextEditingController searchIdNumberController =
      TextEditingController();
  final RxBool isSearchingPatient = false.obs;
  final RxString searchError = ''.obs;
  final selectedSystemType = 'NHM'.obs; //
  final selectedSearchIdType = 'mobile'.obs; // Default to mobile

  // Residence Info Section
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final RxString selectedCountry = ''.obs;
  final RxString selectedState = ''.obs;
  final RxString selectedCity = ''.obs;
  final RxString residenceInfoError = ''.obs;
  final RxString selectedANCList = ''.obs;

  // Medical Info Section
  final RxList<DoctorReference> doctorReferences = <DoctorReference>[].obs;
  final RxString medicalInfoError = ''.obs;

  final RxList<CenterModel> labNames = <CenterModel>[].obs;
  final RxList<FacilityModel> facilityNames = <FacilityModel>[].obs;
  final RxList<IdentityProofModel> idProofTypes = <IdentityProofModel>[].obs;
  final RxList<DistrictModel> cities = <DistrictModel>[].obs;
  final RxList<StateModel> states = <StateModel>[].obs;
  final RxList<MaritalStatusModel> maritalStatuses = <MaritalStatusModel>[].obs;
  final RxList<DoctorReference> doctorNames = <DoctorReference>[].obs;
  final RxString selectedWard = ''.obs;
  final RxList<String> wards = <String>[].obs;
  final List<String> searchPatientUsing = ['Mobile', 'OPD', 'Patient Id'];
  final List<String> sampleTypes = ['Regular Patient', 'Glucose Patient'];

  final List<String> patientTypes = ['OPD', 'IPD', 'Camp', 'Emergency'];

  final List<String> prefixes = [
    'Mr.',
    'Master',
    'Mrs.',
    'Ms.',
    'Sis',
    'Smt.',
    'Baby',
    'B/O',
  ];

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> ancList = [
    'Not Pregnant',
    'Ante Natal Care (ANC Status)',
    'Post Natal Care (PNC Status)',
  ];

  final List<String> countries = ['India'];

  final List<String> specializations = [
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'Psychiatry',
  ];

  final Map<String, Map<String, dynamic>> existingPatientsData = {};

  // Service for API calls
  final PatientRegistrationService _service = Get.put(
    PatientRegistrationService(),
  );

  final RxString opdError = ''.obs;
  final AuthManager authManager = Get.put(AuthManager());
  final RxBool isOtpSent = false.obs;
  final RxString otpError = ''.obs;
  final RxString mobileNumberError = ''.obs;
  var otpLength = 0.obs;

  final TextEditingController otpController = TextEditingController();
  final RxString receivedOtp = ''.obs;
  final RxBool isVerified = false.obs;
  final RxBool isOPDVerifying = false.obs;
  final RxBool isOpdVerified = false.obs;
  final RxBool isMobileVerifying = false.obs;
  final RxBool isMobileVerified = false.obs;

  // Add these new variables to your controller
  final RxString selectedAgeTitle = 'Days'.obs; // Default to Days for Baby
  final List<String> ageTitleOptions = ['Days', 'Years'];

  // Add this new reactive variable to handle age title for other prefixes
  final RxString otherPrefixAgeTitle = 'YEAR'.obs;

  @override
  void onInit() {
    super.onInit();

    getUserdata();

    //  listener for date of birth to calculate age
    selectedDateOfBirth.listen((date) {
      if (date != null) {
        calculateAge(date);
      }
    });

    // get bag id from arguments
    final args = Get.arguments;
    if (args != null) {
      bagId.value = args['bagId'];
      CustomDebugFunction.log('👺 patient registration bagId: $bagId');
    }

    // Add listener for prefix changes to clear DOB and age
    selectedPrefix.listen((prefix) {
      selectedDateOfBirth.value = null;
      ageController.clear();
      ageValidation.value = '';

      // Reset age titles based on prefix
      if (prefix == 'Baby') {
        selectedAgeTitle.value = 'Days';
      } else if (prefix != 'B/O') {
        otherPrefixAgeTitle.value = 'YEAR'; // Reset other prefixes to Years
      }
    });

    firstNameController.addListener(_onConsentTriggerFieldsChanged);
    lastNameController.addListener(_onConsentTriggerFieldsChanged);
    mobileNumberController.addListener(_onConsentTriggerFieldsChanged);
  }

  final RxString empId = ''.obs;

  Timer? _debounceTimer;

  @override
  void onClose() {
    // Dispose all controllers
    opdNoController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    idProofNumberController.dispose();
    emailController.dispose();
    searchIdNumberController.dispose();
    addressController.dispose();
    pincodeController.dispose();

    _consentCheckDebounce?.cancel();
    _consentResendTimer?.cancel();
    _consentPollTimer?.cancel();
    super.onClose();
  }

  void getUserdata() {
    authManager
        .getUserData()
        .then((data) {
          CustomDebugFunction.log('📅user data from auth');
          if (data != null) {
            data.forEach((key, value) {
              CustomDebugFunction.log('$key: $value');
            });
            // Store empId if available
            final user = data['user'];
            if (user != null && user.containsKey('EmpCode')) {
              empId.value = user['EmpCode'].toString();
              fetchDropdownData();
              CustomDebugFunction.log('✅ empId set: ${empId.value}');
            } else {
              CustomDebugFunction.log('❌ EmpCode not found in user data');
            }
          } else {
            CustomDebugFunction.log('No user data found');
          }
        })
        .catchError((err) {
          CustomDebugFunction.log('Error loading user data: $err');
        });
  }

  // fetch data
  void fetchDropdownData() async {
    try {
      final userId = empId.value;

      final centers = await _service.getLabNames(userId);
      labNames.assignAll(centers);
      if (labNames.isNotEmpty) {
        selectedLabName.value = labNames.first;
      }
      if (selectedProcessLab.value.isEmpty) {
        selectedProcessLab.value = labNames.first.centerName;
      }
      final facilities = await _service.getFacilityList(userId);
      facilityNames.assignAll(facilities);
      wards.assignAll(
        facilities
            .map((f) => f.ward)
            .where((ward) => ward.isNotEmpty)
            .toSet()
            .toList(),
      );
      selectedWard.value = wards.first;
      if (selectedWard.value != '') {
        selectedFacilityName.value = facilityNames.firstWhere(
          (facility) => facility.ward == selectedWard.value,
          orElse: () => facilityNames.first,
        );
        CustomDebugFunction.log(
          'Selected Facility ${selectedFacilityName.value?.facilityId} ',
        );
      }
      final idTypesList = await _service.getIdentityProofList();
      idProofTypes.assignAll(idTypesList);

      /*  // district
      final districts = await _service.fetchDistrictList();
      cities.assignAll(districts);
      //states
      final statesList = await _service.getStateList();
      states.assignAll(statesList);*/

      // marital status
      final maritalStatusList = await _service.getMaritalStatusList();
      maritalStatuses.assignAll(maritalStatusList);
    } catch (e) {
      CustomDebugFunction.log('Error loading dropdown data: $e');
    }
  }

  void onOpdNumberChanged(String value) {
    opdError.value = '';
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      checkOpdNumberExists(value);
    });
  }

  // check if OPD number exists
  Future<void> checkOpdNumberExists(String opdNumber) async {
    try {
      isOPDVerifying.value = true;

      final facilityCode = selectedFacilityName.value;
      if (facilityCode == null) {
        opdError.value = 'Please select a facility first';
        SnackBarService.to.showMessage(
          message: 'Please select a facility first',
        );
        return;
      }
      final isExist = await _service.checkOpdNumberExists(
        opdNumber,
        facilityCode.facilityId.toString(),
      );
      if (isExist) {
        opdError.value = 'OPD number already exists';

        isOpdVerified.value = false;
        opdNoController.clear();
        SnackBarService.to.showMessage(
          message: 'OPD number already exists',
          position: SnackPosition.TOP,
        );
      } else {
        isOpdVerified.value = true;
        opdError.value = '';
        labInfoError.value = '';
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to check OPD number');
      return;
    } finally {
      isOPDVerifying.value = false;
    }
  }

  // Section Management
  void selectSection(int index) {
    selectedSection.value = index;
  }

  // Age calculation based on date of birth
  void calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final ageInDays = now.difference(birthDate).inDays;

    if (selectedPrefix.value == 'B/O') {
      // B/O always in days
      ageController.text = ageInDays.toString();
    } else if (selectedPrefix.value == 'Baby') {
      // Baby calculation - dynamically set age title based on actual age
      if (ageInDays < 365) {
        selectedAgeTitle.value = 'Days';
        ageController.text = ageInDays.toString();
      } else {
        selectedAgeTitle.value = 'Years';
        int ageInYears = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          ageInYears--;
        }
        ageController.text = ageInYears.toString();
      }
    } else {
      // Other prefixes - dynamic like Baby
      if (ageInDays < 365) {
        otherPrefixAgeTitle.value = 'Days'; // Auto-set to Days
        ageController.text = ageInDays.toString();
      } else {
        otherPrefixAgeTitle.value = 'Years'; // Auto-set to Years
        int ageInYears = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          ageInYears--;
        }
        ageController.text = ageInYears.toString();
      }
    }
  }

  // Patient type toggle
  void togglePatientType(bool isNew) {
    isNewPatient.value = isNew;
    if (isNew) {
      clearPatientFields();
      searchError.value = '';
    }
  }

  // Search existing patient
  // Method to change system type (HMIS/NHM)
  void changeSystemType(String systemType) {
    selectedSystemType.value = systemType;
    // Clear search field when switching systems
    searchIdNumberController.clear();
    searchError.value = '';
    CustomDebugFunction.log('System type changed to: $systemType');
  }

  // Method to change search type (mobile/opd/patient_id)
  void changeSearchType(String searchType) {
    selectedSearchIdType.value = searchType;
    selectedSearchPatientType.value = searchType;
    // Clear search field when switching search types
    searchIdNumberController.clear();
    searchError.value = '';
    CustomDebugFunction.log('Search type changed to: $searchType');
  }

  // Updated searchExistingPatient method
  Future<void> searchExistingPatient() async {
    if (selectedSearchIdType.value.isEmpty) {
      searchError.value = 'Please select search type';
      return;
    }

    final searchValue = searchIdNumberController.text.trim();
    if (searchValue.isEmpty) {
      searchError.value = 'Please enter ${_getSearchTypeLabel()} number';
      return;
    }

    searchError.value = '';
    isSearchingPatient.value = true;

    try {
      final typeStr = selectedSearchIdType.value.trim().toLowerCase();
      final systemType = selectedSystemType.value;

      int type;

      if (systemType == 'NHM') {
        // NHM types
        type = typeStr == 'mobile'
            ? 1
            : typeStr == 'opd'
            ? 2
            : 3;
      } else {
        // HMIS types
        type = typeStr == 'mobile'
            ? 5
            : typeStr == 'opd'
            ? 4
            : 6;
      }

      CustomDebugFunction.log(
        '🕵️ System: $systemType, Search Type: $typeStr, API Type: $type',
      );

      final patients = await _service.searchExistingPatients(
        type: type,
        searchValue: searchValue,
      );

      if (patients.isEmpty) {
        searchError.value = 'No matching patients found';
      } else if (patients.length == 1) {
        _fillPatientData(patients.first);
      } else {
        PatientSelectionSheet.show(patients, _fillPatientData);
      }
    } catch (e, stackTrace) {
      CustomDebugFunction.log(e.toString());
      CustomDebugFunction.log(stackTrace.toString());
      searchError.value = 'No matching patients found';
    }

    isSearchingPatient.value = false;
  }

  String _getSearchTypeLabel() {
    switch (selectedSearchIdType.value) {
      case 'mobile':
        return 'mobile';
      case 'opd':
        return 'OPD';
      case 'patient_id':
        return 'Patient ID';
      default:
        return 'ID';
    }
  }

  // Prefill patient data
  void prefillPatientData(Map<String, dynamic> data) {
    selectedPrefix.value = data['prefix'] ?? '';
    firstNameController.text = data['firstName'] ?? '';
    middleNameController.text = data['middleName'] ?? '';
    lastNameController.text = data['lastName'] ?? '';
    selectedGender.value = data['gender'] ?? '';
    selectedDateOfBirth.value = data['dateOfBirth'];
    selectedMaritalStatus.value = data['maritalStatus'] ?? '';
    emailController.text = data['email'] ?? '';
    addressController.text = data['address'] ?? '';
    pincodeController.text = data['pincode'] ?? '';
    selectedCountry.value = data['country'] ?? '';
    selectedState.value = data['state'] ?? '';
    selectedCity.value = data['city'] ?? '';
    mobileNumberController.text = data['MobileNumber'] ?? '';
  }

  // Clear patient fields
  void clearPatientFields() {
    selectedPrefix.value = '';
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    selectedGender.value = '';
    selectedDateOfBirth.value = null;
    ageController.clear();
    selectedMaritalStatus.value = '';
    selectedIdType.value = '';
    idProofNumberController.clear();
    emailController.clear();
    addressController.clear();
    pincodeController.clear();
    selectedCountry.value = '';
    selectedState.value = '';
    selectedCity.value = '';
    searchIdNumberController.clear();
    selectedSearchIdType.value = '';
    mobileNumberController.clear();
  }

  // Doctor reference management
  void addDoctorReference() {
    doctorReferences.add(DoctorReference());
  }

  void removeDoctorReference(int index) {
    if (doctorReferences.length > index) {
      doctorReferences[index].dispose();
      doctorReferences.removeAt(index);
    }
  }

  String getAgeTitle() {
    if (selectedPrefix.value == 'B/O') {
      return 'Days';
    } else if (selectedPrefix.value == 'Baby') {
      return selectedAgeTitle.value;
    } else {
      // For other prefixes, use dynamic title based on DOB or default to Years
      return otherPrefixAgeTitle.value;
    }
  }

  /*String getAgeTitle() {
    if (selectedPrefix.value == "Baby") {
      return "Days";
    } else if (selectedPrefix.value == "B/O") {
      return "Days";
    }
    return "Year";
  }*/
  // Validation methods
  bool validateLabInfo() {
    labInfoError.value = '';

    if (selectedLabName.value == null) {
      labInfoError.value = 'Please select lab name';
      return false;
    }
    if (selectedFacilityName.value == null) {
      labInfoError.value = 'Please select facility name';
      return false;
    }
    if (selectedProcessLab.value.isEmpty) {
      labInfoError.value = 'Please select process lab';
      return false;
    }
    if (selectedSampleType.value.isEmpty) {
      labInfoError.value = 'Please select sample type';
      return false;
    }
    if (selectedPatientType.value.isEmpty) {
      labInfoError.value = 'Please select patient type';
      return false;
    }
    if (opdError.value.isNotEmpty) {
      labInfoError.value = opdError.value;
      return false;
    }
    if (opdNoController.text.isEmpty) {
      labInfoError.value = 'Please enter OPD number';
      return false;
    }
    if (!isOpdVerified.value) {
      labInfoError.value = 'Please enter Valid OPD number';
      return false;
    }
    if (isOPDVerifying.value) {
      labInfoError.value = 'Please wait till we validate OPD number';
      return false;
    }

    return true;
  }

  bool validatePatientInfo() {
    patientInfoError.value = '';

    if (!isNewPatient.value) {
      if (selectedSearchIdType.value.isEmpty ||
          searchIdNumberController.text.isEmpty) {
        patientInfoError.value = 'Please search for existing patient first';
        return false;
      }
    }

    if (selectedPrefix.value.isEmpty) {
      patientInfoError.value = 'Please select prefix';
      return false;
    }
    if (firstNameController.text.isEmpty) {
      patientInfoError.value = 'Please enter first name';
      return false;
    }
    if (lastNameController.text.isEmpty) {
      patientInfoError.value = 'Please enter last name';
      return false;
    }

    if (selectedGender.value == 'Female' && selectedANCList.value.isEmpty) {
      patientInfoError.value = 'Please select ANC status for female patients';

      return false;
    }
    if (selectedGender.value.isEmpty) {
      patientInfoError.value = 'Please select gender';
      return false;
    }
    /*if (selectedDateOfBirth.value == null) {
      patientInfoError.value = 'Please select date of birth';
      return false;
    }*/
    // age validator

    if (selectedMaritalStatus.value.isEmpty) {
      patientInfoError.value = 'Please select marital status';
      return false;
    }
    if (idProofNumberController.text.isNotEmpty) {
      if (selectedIdType.value == 'Aadhaar Card') {
        if (idProofNumberController.text.length != 12) {
          patientInfoError.value = 'Please enter valid Number';
          return false;
        }
      }
    }

    // validate age
    // validate age
    // Replace the existing age validation section with:
    if (ageController.text.isEmpty) {
      /* patientInfoError.value = "Please enter age";*/
      ageValidation.value = 'Please enter age';
      return false;
    }
    if (ageController.text.isNotEmpty) {
      final int? age = int.tryParse(ageController.text.trim());

      if (age == null) {
        /* patientInfoError.value = 'Please enter a valid age';*/
        ageValidation.value = 'Please enter a valid age';
        return false;
      }

      if (age < 0) {
        /*    patientInfoError.value = 'Age cannot be negative';*/
        ageValidation.value = 'Age cannot be negative';
        return false;
      }

      final String ageTitle = getAgeTitle();

      // Validation based on prefix and age title
      if (selectedPrefix.value == 'B/O') {
        // B/O is always in days and max 365 days
        if (age > 365) {
          /*   patientInfoError.value =
              'Age must be less than or equal to 365 days for B/O';*/
          ageValidation.value =
              'Age must be less than or equal to 365 days for B/O';
          return false;
        }
      } else if (selectedPrefix.value == 'Baby') {
        if (selectedAgeTitle.value == 'Days') {
          if (age > 365) {
            /*  patientInfoError.value =
                'Age must be less than or equal to 365 days';*/
            ageValidation.value = 'Age must be less than or equal to 365 days';
            return false;
          }
        } else if (selectedAgeTitle.value == 'Years') {
          if (age > 10) {
            /*    patientInfoError.value =
                'Baby age must be less than or equal to 10 years';*/
            ageValidation.value =
                'Baby age must be less than or equal to 10 years';
            return false;
          }
        }
      } else {
        // Other prefixes are always in years

        // Other prefixes - validation based on current age title
        if (otherPrefixAgeTitle.value == 'Days') {
          if (age > 365) {
            /* patientInfoError.value =
                'Age must be less than or equal to 365 days';*/
            ageValidation.value = 'Age must be less than or equal to 365 days';
            return false;
          }
        } else {
          if (age > 110) {
            /*  patientInfoError.value =
                'Age must be less than or equal to 110 years';*/
            ageValidation.value = 'Age must be less than or equal to 110 years';
            return false;
          }
        }
      }

      // Compute age in years for ANC validation (only for non-Baby/B/O prefixes or Baby in years)
      double ageInYears = 0.0;
      if (selectedPrefix.value == 'Baby') {
        if (selectedAgeTitle.value == 'Days') {
          ageInYears = age / 365.0;
        } else {
          ageInYears = age.toDouble();
        }
      } else if (selectedPrefix.value == 'B/O') {
        ageInYears = age / 365.0;
      } else {
        // Other prefixes
        if (otherPrefixAgeTitle.value == 'Days') {
          ageInYears = age / 365.0;
        } else {
          ageInYears = age.toDouble();
        }
      }
      // ANC Age Range Validation (Only if selected and applicable)
      if (selectedGender.value == 'Female') {
        final anc = selectedANCList.value.trim();

        if (anc == 'Ante Natal Care (ANC Status)') {
          if (ageInYears < 18 || ageInYears > 50) {
            /*      patientInfoError.value =
                'Ante Natal Care can only be selected for age between 18 and 50 years';*/
            ageValidation.value =
                'Ante Natal Care can only be selected for age between 18 and 50 years';
            return false;
          }
        } else if (anc == 'Post Natal Care (PNC Status)') {
          // if (ageInYears <= 50) {
          //   /*patientInfoError.value =
          //       'Post Natal Care can only be selected for age above 50 years';*/
          //   ageValidation.value =
          //       'Post Natal Care can only be selected for age above 50 years';
          //   return false;
          // }
          //

          if (ageInYears < 18 || ageInYears > 50) {
            /*patientInfoError.value =
                'Post Natal Care can only be selected for age above 50 years';*/
            ageValidation.value =
                'Post Natal Care can only be selected for age between 18 and 50 years';
            return false;
          }
        }
      }

      ageValidation.value = '';
    }

    if (mobileNumberController.text.isEmpty) {
      patientInfoError.value = 'Please enter mobile number';
      mobileNumberError.value = 'Please enter mobile number';
      return false;
    }
    if (mobileNumberError.value.isNotEmpty) {
      patientInfoError.value = mobileNumberError.value;
      return false;
    }
    if (isNewPatient.value && !isMobileVerified.value) {
      mobileNumberError.value = 'Please verify mobile number';
      return false;
    }

    if (mobileNumberController.text.isNotEmpty) {
      final mobile = mobileNumberController.text.trim();
      if (mobile.isEmpty) {
        /* patientInfoError.value = 'Please enter mobile number';*/
        mobileNumberError.value = 'Please enter mobile number';
        return false;
      }
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
        /*       patientInfoError.value = 'Please enter valid 10-digit mobile number';*/
        mobileNumberError.value = 'Please enter valid 10-digit mobile number';
        return false;
      }

      // ✅ Clear previous mobile validation errors if validation succeeds
      mobileNumberError.value = '';
    }
    if (!validateConsent()) {
      patientInfoError.value = consentError.value;
      return false;
    }

    return true;
  }

  // Add this method to handle age conversion when dropdown changes
  void onAgeTitleChanged(String newTitle) {
    if (selectedPrefix.value == 'Baby' && ageController.text.isNotEmpty) {
      final currentAge = int.tryParse(ageController.text) ?? 0;

      if (selectedAgeTitle.value == 'Days' && newTitle == 'Years') {
        // Convert days to years
        final ageInYears = (currentAge / 365).floor();
        ageController.text = ageInYears.toString();
      } else if (selectedAgeTitle.value == 'Years' && newTitle == 'Days') {
        // Convert years to days (approximate)
        final ageInDays = currentAge * 365;
        ageController.text = ageInDays.toString();
      }
    }
    selectedAgeTitle.value = newTitle;
  }

  bool validateResidenceInfo() {
    residenceInfoError.value = '';

    if (addressController.text.isEmpty) {
      residenceInfoError.value = 'Please enter address';
      return false;
    }
    if (pincodeController.text.isEmpty) {
      residenceInfoError.value = 'Please enter pincode';
      return false;
    }
    /* if (selectedCountry.value.isEmpty) {
      residenceInfoError.value = 'Please select country';
      return false;
    }*/
    /* if (selectedState.value.isEmpty) {
      residenceInfoError.value = 'Please select state';
      return false;
    }*/
    /* if (selectedCity.value.isEmpty) {
      residenceInfoError.value = 'Please select city';
      return false;
    }*/

    return true;
  }

  bool validateMedicalInfo() {
    medicalInfoError.value = '';

    for (int i = 0; i < doctorReferences.length; i++) {
      final ref = doctorReferences[i];
      if (ref.selectedDoctorName.value.isEmpty) {
        medicalInfoError.value =
            'Please select doctor name for reference ${i + 1}';
        return false;
      }
      if (ref.mobileController.text.isEmpty) {
        medicalInfoError.value =
            'Please enter mobile number for reference ${i + 1}';
        return false;
      }
      if (ref.selectedSpecialization.value.isEmpty) {
        medicalInfoError.value =
            'Please select specialization for reference ${i + 1}';
        return false;
      }
    }

    return true;
  }

  // Submit form
  Future<void> submitForm() async {
    bool isValid = true;

    // Validate all sections
    if (!validateLabInfo()) isValid = false;
    if (!validatePatientInfo()) isValid = false;
    if (!validateResidenceInfo()) isValid = false;

    if (!isValid) {
      SnackBarService.to.showMessage(message: 'Please add required fields');
      return;
    }
    final patientArray = createPatientArray();
    // CustomDebugFunction.log
    if (kDebugMode) {
      CustomDebugFunction.log(patientArray.toString());
    }
    if (selectedSystemType.value == 'HMIS') {
      final hmisPatientId = selectedSearchIdType.value == 'mobile'
          ? 'm-${searchIdNumberController.text.trim()}'
          : selectedSearchIdType.value == 'opd'
          ? 'o-${searchIdNumberController.text.trim()}'
          : 'p-${searchIdNumberController.text.trim()}';
      CustomDebugFunction.log('hmisPatientId: $patientId');
      final arguments = {
        'patientArray': patientArray,
        'isHMISPatient': true,
        'patientId': hmisPatientId,
      };
      CustomDebugFunction.log('arguments for hmis patient 💕💕: $arguments');

      Get.to(
        () => TestSelectionView(bagId: bagId.value),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
        arguments: arguments,
      );
    } else {
      CustomDebugFunction.log(' 💕Regular Patient Route💕');
      Get.to(
        () => TestSelectionView(bagId: bagId.value),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
        arguments: {'patientArray': patientArray, 'isHMISPatient': false},
      );
    }
  }

  String generateUniquePatientId() {
    const uuid = Uuid();
    return uuid.v4().replaceAll('-', '').substring(0, 12); // 12 digit unique ID
  }

  // Method to create patient array for API integration
  Map<String, dynamic> createPatientArray() {
    final int prefixIndex = selectedPrefix.value.isNotEmpty
        ? prefixes.indexOf(selectedPrefix.value) +
              1 // Add 1 for 1-based indexing
        : 0;
    return {
      'patientArray': [
        {
          'title': prefixIndex.toString(),
          'lastName': lastNameController.text.trim(),
          'centerId': selectedLabName.value?.centerId.toString() ?? '',
          'address': addressController.text.trim(),
          'facilityId': selectedFacilityName.value?.facilityId.toString() ?? '',
          'gender': selectedGender.value.isNotEmpty
              ? selectedGender.value.substring(0, 1).toUpperCase()
              : '',
          'adharNumber': selectedIdType.value == 'Aadhaar Card'
              ? idProofNumberController.text.trim()
              : '',
          /*'patientId':19991*/
          'patientId': patientId.value.isEmpty
              ? generateUniquePatientId()
              : patientId.value,
          'stateId': selectedState.value.isNotEmpty
              ? states
                    .firstWhere(
                      (state) => state.stateName == selectedState.value,
                      orElse: () => StateModel(stateId: 0, stateName: ''),
                    )
                    .stateId
                    .toString()
              : '27',
          'postalCode': pincodeController.text.trim(),
          'mobile': mobileNumberController.text.trim(),
          'cityId': selectedCity.value.isNotEmpty
              ? cities
                    .firstWhere(
                      (city) => city.districtName == selectedCity.value,
                      orElse: () => DistrictModel(
                        distrcitId: 0,
                        districtName: '',
                        districtCode: 0,
                        stateId: 0,
                        distLgdCode: 0,
                        divisionId: 0,
                        distName: '',
                      ),
                    )
                    .distLgdCode
                    .toString()
              : '',
          'countryId': selectedCountry.value.isNotEmpty ? '1' : '1',
          // Assuming India is ID 1
          'firstName': firstNameController.text.trim(),
          'districtId': '',
          'talukaId': '',
          // Not collected in form
          'dob': selectedDateOfBirth.value != null
              ? DateFormat('dd/MM/yyyy').format(selectedDateOfBirth.value!)
              : '',
          'age': ageController.text.trim(),
          'middleName': middleNameController.text.trim(),
          'filter2': selectedFacilityName.value != null
              ? "${selectedFacilityName.value!.facilityId} ${DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())}"
              : '',
          'camp_id': selectedPatientType.value == 'Camp' ? '1' : '',
          'tokenId': opdNoController.text.trim(),

          'TimeOfBirth': '',
          'BirthWeight': '',
          'GestationalWeek': '',
          'PatientType': selectedPatientType.value,
          'PatRegNo': generateUniquePatRegNo(),
          'IdProofId': selectedIdType.value.isNotEmpty
              ? idProofTypes
                    .firstWhere(
                      (idProof) => idProof.idTypeName == selectedIdType.value,
                      orElse: () => IdentityProofModel(
                        idTypeCode: 0,
                        idTypeName: '',
                        idTypeDesc: '',
                        activeFlag: '',
                        creationUID: 0,
                        creationDateTime: '',
                      ),
                    )
                    .idTypeCode
                    .toString()
              : '',
          'FemaleCategoryId': ancCategoryMap[selectedANCList.value] ?? '0',
          'AgeTitle': getAgeTitle(),
          'ABHANumber': '',
          'ABHAAddress': '',
          'ISOTPVerify': '1',
          /*"ISOTPVerify": isVerified.value ? "1" : "0"*/
          'CategoryCast': '0',
          'MaritalStatus': selectedMaritalStatus.value.isNotEmpty
              ? maritalStatuses
                    .firstWhere(
                      (status) =>
                          status.maritalStatus == selectedMaritalStatus.value,
                      orElse: () => MaritalStatusModel(
                        maritalStatusId: 0,
                        maritalStatus: '',
                      ),
                    )
                    .maritalStatusId
                    .toString()
              : '',
          'FamilyID': '0',
          'FamilyMemName': '',
          'patCrno': '',
        },
      ],
    };
  }

  String generateUniquePatRegNo() {
    final facilityCode = selectedFacilityName.value?.facilityId
        .toString()
        .padLeft(3, '0');
    final now = DateTime.now();

    // Format: YYYYMMDD
    final dateStr = DateFormat('yyyyMMdd').format(now);

    // Format: HHMMSS
    final timeStr = DateFormat('HHmmss').format(now);

    // Generate random 2-digit suffix to avoid collisions
    final random = Random().nextInt(99).toString().padLeft(2, '0');

    return '$facilityCode$dateStr$timeStr$random';
  }

  final Map<String, String> ancCategoryMap = {
    'Not Pregnant': '1',
    'Ante Natal Care (ANC Status)': '2',
    'Post Natal Care (PNC Status)': '3',
  };

  // Reset form
  void resetForm() {
    selectedSection.value = 0;
    isMobileVerified.value = false;
    isOpdVerified.value = false;

    // Reset lab info
    selectedLabName.value = null;
    selectedFacilityName.value = null;
    // selectedFacilityName.value = '';
    selectedProcessLab.value = '';
    selectedSampleType.value = 'Regular Patient';
    selectedPatientType.value = '';
    selectedWard.value = '';
    opdNoController.clear();
    mobileNumberController.clear();

    // Reset patient info
    isNewPatient.value = true;
    clearPatientFields();

    // Reset medical info
    for (var ref in doctorReferences) {
      ref.dispose();
    }
    doctorReferences.clear();
    _resetConsentState();
    _lastCheckedConsentKey = '';

    // Clear all errors
    labInfoError.value = '';
    patientInfoError.value = '';
    residenceInfoError.value = '';
    medicalInfoError.value = '';
    searchError.value = '';
  }

  void _fillPatientData(ExistingPatientModel patient) {
    selectedPrefix.value = patient.title;
    patientId.value = patient.patientId;
    firstNameController.text = patient.firstName;
    middleNameController.text = patient.middleName;
    lastNameController.text = patient.lastName;
    selectedGender.value = patient.gender;
    selectedDateOfBirth.value = patient.dateOfBirth;
    ageController.text = patient.age.toString();
    emailController.text = patient.email;
    addressController.text = patient.address;
    pincodeController.text = patient.pincode;
    selectedCity.value = patient.cityName;
    selectedMaritalStatus.value = patient.maritalStatus;
    mobileNumberController.text = patient.mobileNumber;
    // Run DPDP consent check for this existing patient
    triggerConsentCheckForSelectedPatient();
  }

  Future<void> validateMobileNumber() async {
    try {
      final mobileNumber = mobileNumberController.text;
      if (mobileNumber.length != 10) {
        /*mobileNumberError.value = 'Please enter a valid 10-digit mobile number';*/
        return;
      }
      isMobileVerifying.value = true;
      final response = await _service.validateMobileNumber(mobileNumber);

      CustomDebugFunction.log('controller response : ${response.toString()}');
      /* "output": [
    {
    "MobExistCount": 93,
    "ISOTPPopoOpen": 0
    }
    ]*/
      if (response['status'] == 'Success') {
        if (response['output'][0]['MobExistCount'] > 6) {
          mobileNumberError.value =
              'Mobile number already registered for 6 members';
          isMobileVerified.value = false;
        } else {
          isMobileVerified.value = true;
          mobileNumberError.value = '';
        }
      } else {
        mobileNumberError.value = response['message'] ?? 'Failed to send OTP';
      }
    } catch (e) {
      mobileNumberError.value = 'Error sending OTP';
    } finally {
      isMobileVerifying.value = false;
      isOtpSent.value = false;
    }
  }

  Future<void> sendOtpVerification() async {
    try {
      final mobileNumber = mobileNumberController.text;
      if (mobileNumber.length != 10) {
        mobileNumberError.value = 'Please enter a valid 10-digit mobile number';
        return;
      }

      final response = await _service.sendOtp(mobileNumber, '310');
      if (response['status'] == 'Success') {
        isOtpSent.value = true;
        mobileNumberError.value = '';
        receivedOtp.value = response['message'] ?? '';
        _showOtpBottomSheet();
      } else {
        mobileNumberError.value = response['message'] ?? 'Failed to send OTP';
      }
    } catch (e) {
      mobileNumberError.value = 'Error sending OTP: $e';
    } finally {
      isOtpSent.value = false;
    }
  }

  void verifyOtp(String enteredOtp) {
    if (enteredOtp == receivedOtp.value) {
      isOtpSent.value = false;
      isVerified.value = true;
      otpError.value = '';
      Get.back();
      Get.snackbar(
        'Success',
        'Mobile number verified successfully',
        snackPosition: SnackPosition.TOP,
      );
    } else {
      otpError.value = 'Invalid OTP';
    }
  }

  void _showOtpBottomSheet() {
    Get.bottomSheet(
      isDismissible: false,
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.4),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Verify OTP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // close button
                  IconButton(
                    onPressed: () {
                      Get.back;
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: const OutlineInputBorder(),
                  errorText: otpError.value.isNotEmpty ? otpError.value : null,
                ),
                onChanged: (value) {
                  otpLength.value = value.length;
                  if (value.length == 4) {
                    verifyOtp(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: otpLength.value == 4
                    ? () => verifyOtp(otpController.text)
                    : null,
                child: const Text('Verify'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Get.back();
                  sendOtpVerification();
                },
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  ///
  // ================= DPDP Consent =================
  final RxBool showConsentSection = false.obs;
  final RxBool isCheckingConsent = false.obs;
  final RxBool isConsentVerified = false.obs;
  final RxString consentMethod = ''.obs; // 'existing' | 'link' | 'paper'
  final RxString consentStatusMessage = ''.obs;
  final RxString consentError = ''.obs;

  // Link-based digital consent (user verifies on their own phone)
  final RxBool isSendingConsentLink = false.obs;
  final RxBool isConsentLinkSent = false.obs;
  final RxString consentLinkError = ''.obs;
  final RxInt consentResendSeconds = 0.obs;
  final RxBool isPollingConsent = false.obs; // background re-check indicator
  Timer? _consentResendTimer;
  Timer? _consentPollTimer;

  // Paper consent
  final Rx<File?> consentPhotoFile = Rx<File?>(null);
  final RxBool isUploadingConsentPhoto = false.obs;

  Timer? _consentCheckDebounce;
  String _lastCheckedConsentKey = '';

  String _beneficiaryName() {
    return [
      firstNameController.text.trim(),
      middleNameController.text.trim(),
      lastNameController.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');
  }

  void _onConsentTriggerFieldsChanged() {
    final mobile = mobileNumberController.text.trim();
    final name = _beneficiaryName();

    showConsentSection.value = mobile.length == 10 && name.isNotEmpty;

    _consentCheckDebounce?.cancel();
    _consentCheckDebounce = Timer(const Duration(milliseconds: 700), () {
      _maybeCheckConsent();
    });
  }

  void _maybeCheckConsent() {
    final mobile = mobileNumberController.text.trim();
    final name = _beneficiaryName();
    if (mobile.length != 10 || name.isEmpty) return;

    final key = '$name|$mobile';
    if (key == _lastCheckedConsentKey) return;
    _lastCheckedConsentKey = key;

    _resetConsentState(keepVisible: true);
    checkDpdpConsent(mobile, name);
  }

  /// Call this explicitly right after an existing patient is selected,
  /// so the same consent flow runs for them too (not just fresh typing).
  void triggerConsentCheckForSelectedPatient() {
    _lastCheckedConsentKey = ''; // force re-check even if key matches leftovers
    _onConsentTriggerFieldsChanged();
    _maybeCheckConsent();
  }

  void _resetConsentState({bool keepVisible = false}) {
    isConsentVerified.value = false;
    consentMethod.value = '';
    consentStatusMessage.value = '';
    consentError.value = '';
    isConsentLinkSent.value = false;
    consentLinkError.value = '';
    consentPhotoFile.value = null;
    _consentResendTimer?.cancel();
    consentResendSeconds.value = 0;
    _consentPollTimer?.cancel();
    isPollingConsent.value = false;
    if (!keepVisible) showConsentSection.value = false;
  }

  Future<void> checkDpdpConsent(
      String mobile,
      String name, {
        bool silent = false,
      }) async {
    try {
      if (!silent) {
        isCheckingConsent.value = true;
      }

      consentError.value = '';

      final response = await _service.getBeneficiaryConsentDetails(
        mobileNo: mobile,
        beneficiaryName: name,
      );

      // Consent exists
      if (response.hasConsent) {
        isConsentVerified.value = true;

        consentMethod.value = consentMethod.value.isEmpty
            ? 'existing'
            : consentMethod.value;

        consentStatusMessage.value = consentMethod.value == 'link'
            ? 'Patient confirmed consent on their phone'
            : 'Consent already on record for this patient';

        _consentPollTimer?.cancel();
        isPollingConsent.value = false;
      } else {
        // No consent OR consent withdrawn
        isConsentVerified.value = false;

        if (response.isConsentWithdrawn) {
          consentStatusMessage.value =
          'Consent has been withdrawn for this patient, please send a consent link again';

        } else {
          consentStatusMessage.value =
          'DPDP consent required before proceeding';
        }
      }
    } catch (e) {
      CustomDebugFunction.log(
        'Error checking DPDP consent: $e',
      );

      if (!silent) {
        consentError.value =
        'Unable to verify consent status. Please try again.';
      }

      isConsentVerified.value = false;
    } finally {
      if (!silent) {
        isCheckingConsent.value = false;
      }
    }
  }

  // ---- Path A: link-based digital consent ----

  Future<void> sendConsentLink() async {
    final mobile = mobileNumberController.text.trim();
    final name = _beneficiaryName();

    if (mobile.length != 10) {
      consentLinkError.value = 'Enter a valid 10-digit mobile number first';
      return;
    }

    try {
      isSendingConsentLink.value = true;
      consentLinkError.value = '';

      final generatedOtp = _generateSixDigitOtp();
      final msgId = _generateMsgId();

      final response = await _service.sendDpdpConsentOtp(
        mobile: mobile,
        otp: generatedOtp,
        createdBy: empId.value,
        msgId: msgId,
        beneficiaryName: name,
      );

      if (response['status'] == 'Success') {
        isConsentLinkSent.value = true;
        consentMethod.value = 'link';
        _startConsentResendTimer();
        _startConsentPolling(mobile, name);
        SnackBarService.to.showMessage(
          message: 'Verification link sent to $mobile',
          position: SnackPosition.TOP,
        );
      } else {
        consentLinkError.value =
            response['message'] ?? 'Failed to send verification link';
      }
    } catch (e) {
      CustomDebugFunction.log('Error sending DPDP consent link: $e');
      consentLinkError.value =
          'Failed to send verification link. Please try again.';
    } finally {
      isSendingConsentLink.value = false;
    }
  }

  String _generateSixDigitOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _generateMsgId() {
    final now = DateTime.now();
    return 'MSG${DateFormat('yyyyMMddHHmmss').format(now)}'
        '${Random().nextInt(999).toString().padLeft(3, '0')}';
  }

  void _startConsentResendTimer() {
    _consentResendTimer?.cancel();
    consentResendSeconds.value = 30;
    _consentResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (consentResendSeconds.value <= 1) {
        timer.cancel();
        consentResendSeconds.value = 0;
      } else {
        consentResendSeconds.value--;
      }
    });
  }

  void resendConsentLink() {
    if (consentResendSeconds.value > 0) return;
    sendConsentLink();
  }

  /// Silently re-checks GetBeneficiaryConsentDetails in the background
  /// so the UI flips to "verified" the moment the patient confirms on
  /// their own phone, without the phlebotomist having to do anything.
  void _startConsentPolling(String mobile, String name) {
    _consentPollTimer?.cancel();
    isPollingConsent.value = true;
    _consentPollTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (isConsentVerified.value) {
        timer.cancel();
        isPollingConsent.value = false;
        return;
      }
      checkDpdpConsent(mobile, name, silent: true);
    });
  }

  /// Manual "Check status" button — in case the patient confirmed
  /// but the phlebotomist doesn't want to wait for the next poll tick.
  Future<void> checkConsentStatusNow() async {
    final mobile = mobileNumberController.text.trim();
    final name = _beneficiaryName();
    if (mobile.length != 10 || name.isEmpty) return;
    await checkDpdpConsent(mobile, name);
  }

  // ---- Path B: Paper consent (unchanged) ----

  Future<void> pickConsentPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (pickedFile == null) return;

      consentPhotoFile.value = File(pickedFile.path);
      await uploadConsentPhoto();
    } catch (e) {
      CustomDebugFunction.log('Error picking consent photo: $e');
      SnackBarService.to.showMessage(
        message: 'Unable to capture consent photo',
      );
    }
  }

  Future<void> uploadConsentPhoto() async {
    final file = consentPhotoFile.value;
    if (file == null) return;

    final mobile = mobileNumberController.text.trim();
    final name = _beneficiaryName();

    try {
      isUploadingConsentPhoto.value = true;
      consentError.value = '';

      final success = await _service.uploadConsentPhoto(
        mobileNo: mobile,
        beneficiaryName: name,
        photoFile: file,
        createdBy: empId.value,
      );

      if (success) {
        isConsentVerified.value = true;
        consentMethod.value = 'paper';
        consentStatusMessage.value = 'Paper consent captured and uploaded';
        _consentPollTimer?.cancel();
        isPollingConsent.value = false;
        SnackBarService.to.showMessage(
          message: 'Consent photo uploaded successfully',
        );
      } else {
        consentPhotoFile.value = null;
        consentError.value = 'Failed to upload consent photo. Please retry.';
      }
    } catch (e) {
      CustomDebugFunction.log('Error uploading consent photo: $e');
      consentPhotoFile.value = null;
      consentError.value = 'Failed to upload consent photo. Please retry.';
    } finally {
      isUploadingConsentPhoto.value = false;
    }
  }

  // ---- Gate ----

  bool validateConsent() {
    consentError.value = '';
    if (isCheckingConsent.value) {
      consentError.value = 'Please wait, verifying consent status...';
      return false;
    }
    if (!isConsentVerified.value) {
      consentError.value =
          'DPDP consent is mandatory. Send a verification link or capture paper consent.';
      return false;
    }
    return true;
  }

}
