import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';


import 'package:intl/intl.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/network/app_urls.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../../../utils/helper_functions/helper_methods.dart';
import '../models/beneficiary_consent_model.dart';
import '../models/center_name_model.dart';
import '../models/district_list_model.dart';
import '../models/doctor_ref_model.dart';
import '../models/existing_patient_model.dart';
import '../models/facility_list_model.dart';
import '../models/id_proof_models.dart';
import '../models/marital_status_model.dart';
import '../models/registered_patient_model.dart';
import '../models/state_list.dart';
import '../models/tests_model.dart';



class PatientRegistrationService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<List<CenterModel>> getLabNames(String userId) async {
    try {
      final response = await apiClient.post(
        AppUrls.getCenterList,
        data: {'UserID': userId},
      );
      final data = response.body;
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => CenterModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load centers: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FacilityModel>> getFacilityList(String userId) async {
    try {
      final response = await apiClient.post(
        AppUrls.getFacilityList,
        data: {'UserID': userId},
      );
      final data = response.body;
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => FacilityModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load facilities: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<IdentityProofModel>> getIdentityProofList() async {
    try {
      final response = await apiClient.post(AppUrls.getIdentityProof, data: {});
      final data = response.body;
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => IdentityProofModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load identity proofs: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MaritalStatusModel>> getMaritalStatusList() async {
    try {
      final response = await apiClient.post(AppUrls.getMaritalStatus, data: {});
      final data = response.body;
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => MaritalStatusModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load marital status: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DistrictModel>> fetchDistrictList() async {
    try {
      final response = await apiClient.post(AppUrls.getDistrictList, data: {});
      final data = response.body;
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => DistrictModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load districts: ${data['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  Future<List<StateModel>> getStateList() async {
    try {
      final response = await apiClient.post(AppUrls.getStateList, data: {});
      final data = response.body;
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => StateModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load states: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkOpdNumberExists(
      String opdNumber, String facilityCode) async {
    try {
      final response = await apiClient.post(
        AppUrls.checkOpdNumberExists,
        data: {
          'Opdnumber': opdNumber,
          'Facilitycode': facilityCode,
        },
      );
      final data = response.body;
      if (data['status'] == 'Success') {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReferenceDoctor>> fetchReferenceDoctors(
      {required String facilityCode}) async {
    try {
      final now = DateTime.now();
      // Use ISO-8601 format that C# System.DateTime accepts
      final visitDate = DateTime(now.year, now.month, now.day)
          .toUtc()
          .toIso8601String();
      final response = await apiClient.post(
        AppUrls.getDoctorReferenceList,
        data: {
          'VisitDate': visitDate,
          'FacilityCode': facilityCode,
        },
      );
      final data = response.body;
      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output.map((e) => ReferenceDoctor.fromJson(e)).toList();
      } else {
        Get.snackbar(
            'Error', data['message'] ?? 'Failed to load reference doctors');
        return [];
      }
    } catch (e) {
      // Get.snackbar('Error', 'Something went wrong: $e');
      return [];
    }
  }

  Future<List<ExistingPatientModel>> searchExistingPatients({
    required int type,
    required String searchValue,
  }) async {
    try {
      final response = await apiClient.post(
        AppUrls.searchExistingPatient,
        data: {
          'type': type.toString(),
          'Searchvalue': searchValue,
        },
      );
      final data = response.body;
      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output.map((e) => ExistingPatientModel.fromJson(e)).toList();
      } else {
        kPrint("Search failed: ${data['message'] ?? 'No message'}");
        return [];
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  Future<Map<String, dynamic>> getHMISPatientTests(String patientId) async {
    try {
      final result = await apiClient.post(
        AppUrls.getHMISPatientTests,
        data: {'Mobilenumber': patientId},
      );
      if (result.data is Map<String, dynamic>) {
        return result.data as Map<String, dynamic>;
      }
      return result.body;
    } catch (e) {
      throw Exception('Error fetching HMIS patient tests: $e');
    }
  }

  Future<Map<String, dynamic>> sendOtp(
      String mobileNumber, String createdBy) async {
    try {
      final response = await apiClient.post(
        AppUrls.sendOTP,
        data: {'MOBNO': mobileNumber, 'CreatedBy': createdBy},
      );
      kPrint('🤷‍♂️ $response');
      return response.body;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<Map<String, dynamic>> validateMobileNumber(String mobileNumber) async {
    try {
      final result = await apiClient.post(
        AppUrls.validateMobile,
        data: {'mobNo': mobileNumber},
      );
      kPrint('Request URL: ${AppUrls.validateMobile}');
      kPrint('${result.statusCode}');
      kPrint('${result.data}');
      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      throw Exception('Failed to validate mobile: $e');
    }
  }

  String? _fixNumericField(dynamic value) {
    if (value == null || value.toString().isEmpty || value == 'null') {
      return '0';
    }
    return value.toString();
  }

  Future<Map<String, dynamic>> savePatientDetails(
      Map<String, dynamic> patientArray) async {
    try {
      kPrint('-----------------Insider SavePatientDetails-----------------');

      final firstPatient = patientArray['patientArray']?.isNotEmpty == true
          ? patientArray['patientArray'][0]
          : {};

      if (firstPatient.isEmpty) {
        throw Exception('No patient data found');
      }

      final enhancedPatientData = {
        'ORDERNO': '0',
        'title': firstPatient['title']?.toString() ?? '0',
        'lastName': firstPatient['lastName']?.toString() ?? '',
        'centerId': firstPatient['centerId']?.toString() ?? '0',
        'address': firstPatient['address']?.toString() ?? '',
        'facilityId': firstPatient['facilityId']?.toString() ?? '0',
        'gender': firstPatient['gender']?.toString() ?? '',
        'adharNumber': firstPatient['adharNumber']?.toString() ?? '',
        'stateId': '27',
        'postalCode': firstPatient['postalCode']?.toString() ?? '',
        'mobile': firstPatient['mobile']?.toString() ?? '',
        'cityId': _fixNumericField(firstPatient['cityId']) ?? '0',
        'countryId': '1',
        'firstName': firstPatient['firstName']?.toString() ?? '',
        'districtId': _fixNumericField(firstPatient['districtId']) ?? '0',
        'talukaId': _fixNumericField(firstPatient['talukaId']) ?? '0',
        'dob': _formatDob(firstPatient['dob']?.toString() ?? ''),
        'age': firstPatient['age']?.toString() ?? '0',
        'middleName': firstPatient['middleName']?.toString() ?? '',
        'tokenId': firstPatient['tokenId']?.toString() ?? '',
        'PatRegNo': firstPatient['PatRegNo']?.toString() ?? '',
        'IdProofId': _fixNumericField(firstPatient['IdProofId']),
        'AgeTitle': firstPatient['AgeTitle'],
        'ABHANumber': firstPatient['ABHANumber']?.toString() ?? '',
        'ABHAAddress': '',
        'ISOTPVerify': firstPatient['ISOTPVerify']?.toString() ?? '0',
        'BloodGroup': 'NA',
        'CategoryCast': _fixNumericField(firstPatient['CategoryCast']) ?? '0',
        'MaritalStatus':
        _fixNumericField(firstPatient['MaritalStatus']) ?? '0',
        'patCrno': firstPatient['patCrno']?.toString() ?? '',
        'Orderdate': DateFormat('yyyy/MM/dd').format(DateTime.now()),
      };

      final cleanData = <String, dynamic>{};
      for (var key in enhancedPatientData.keys) {
        if (enhancedPatientData[key] != null) {
          cleanData[key] = enhancedPatientData[key];
        }
      }

      kPrint('🎯 EXACT NATIVE PAYLOAD:');
      kPrint(jsonEncode(cleanData));

      // Still form-style wrapper used by this endpoint: inpt=<json>
      final result = await apiClient.post(
        AppUrls.savePatientDetails,
        data:  jsonEncode(cleanData),
        // data: {'inpt': jsonEncode(cleanData)},

      );

      kPrint('Status: ${result.statusCode}');
      kPrint('Response: ${result.data}');

      final resData = result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;

      if (resData['status']?.toString().toLowerCase() == 'success') {
        final patientPermid = resData['patientPermid'];
        return {
          'success': true,
          'data': resData,
          'patientPermid': patientPermid?.toString(),
        };
      } else {
        throw Exception(
            'Server Error: ${resData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      kPrint('❌ ERROR: $e');
      rethrow;
    }
  }

  String _formatDob(String dob) {
    if (dob.isEmpty) return '';
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year/$month/$day';
      }
      return dob;
    } catch (e) {
      kPrint('⚠️ DOB format error: $e');
      return dob;
    }
  }

  Future<Map<String, dynamic>> submitLabData(
      Map<String, dynamic> labData) async {
    try {
      final jsonString = jsonEncode(labData);
      // final data = {'inpt': jsonString};
      final data = labData;
      // final data = {/*'inpt':*/ labData};

      printLongString(jsonString);

      kPrint('==================');
      kPrint(AppUrls.saveForm);

      final result = await apiClient.post(
        AppUrls.saveForm,
        data: data,
      );

      kPrint('Status Code: ${result.statusCode}');
      kPrint('Response: ${result.data}');

      if (result.statusCode == 200) {
        try {
          final resData = result.body;

          if (resData['status'] == 'Success') {
            kPrint('✅ Lab data submitted successfully!');

            return {
              'success': true,
              'data': resData,
            };
          } else if (resData['status'] == 'Fail') {
            kPrint(
              'Submission failed: ${resData['message']}',
            );

            throw Exception(
              resData['message'] ?? 'Submission failed',
            );
          } else {
            kPrint(
              '⚠️ Unexpected response status: ${resData['status']}',
            );

            throw Exception(
              'Unexpected response status: ${resData['status']}',
            );
          }
        } catch (e) {
          // Keep EXACT old behavior:
          // Any exception while processing a 200 response
          // is treated as successful request.
          kPrint(
            '✅ Request successful but response is not JSON: ${result.body}',
          );

          return {
            'success': true,
            'message': 'Data submitted successfully',
          };
        }
      } else {
        kPrint('HTTP Error: ${result.statusCode}');

        throw Exception(
          'Server error: ${result.statusCode}',
        );
      }
    } catch (e) {
      kPrint('Request failed: $e');
      rethrow;
    }
  }

  Future<void> submitOrderInput(Map<String, dynamic> input) async {
    try {
      final jsonString = jsonEncode(input);
      final info = await PackageInfo.fromPlatform();
      final version = info.version;

      printLongString(
          'Submitting Order Input:\n${jsonEncode({
            "P1": input,
            "ispatVerified": 1,
            "MobVersion": version,
          })}');
      kPrint('==================');
      kPrint(AppUrls.orderInputUrl);

      final result = await apiClient.post(
        AppUrls.orderInputUrl,
        data: {
          'P1': input,
          'ispatVerified': '1',
          'MobVersion': version,
        },

      );

      kPrint('📬 Order Input Status: ${result.statusCode}');
      kPrint('📬 Order Input Response: ${result.data}');

      final resData = result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;

      if (resData['status'] != 'Success') {
        throw Exception(
            'Order input failed: ${resData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      kPrint('❌ Order Input Submission Error: $e');
      rethrow;
    }
  }

  void printLongString(String text) {
    kPrint('🤷‍♂️');
    final pattern = RegExp('.{1,1000}');
    pattern.allMatches(text).forEach((match) => kPrint(match.group(0) ?? ''));
  }

  Future<bool> insertDoctor({
    required String firstName,
    required String middleName,
    required String lastName,
    required String empCode,
    required String facilityCode,
  }) async {
    try {
      final formData = {
        'FName': firstName,
        'MName': middleName,
        'LName': lastName,
        'Speciality': 'NA',
        'Salutation': 'NA',
        'Title': 'Dr.',
        'CreationUID': empCode.toString(),
        'FacilityCode': facilityCode.toString(),
      };

      kPrint('📡 Submitting Doctor Data:\n$formData');

      final result = await apiClient.post(
        AppUrls.insertDoctor,
        data: formData,
      );

      kPrint('📬 Insert Doctor Status: ${result.statusCode}');
      kPrint('📬 Insert Doctor Response: ${result.data}');

      final resData = result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
      final status = resData['status']?.toString().toLowerCase();

      if (status == 'success') {
        kPrint('✅ Doctor inserted successfully.');
        return true;
      } else {
        kPrint('⚠️ Doctor insertion failed: ${resData['message']}');
        return false;
      }
    } catch (e) {
      kPrint('❌ Insert Doctor Error: $e');
      rethrow;
    }
  }

  Future<List<TestModel>> fetchTestsByCategory(int categoryCode) async {
    try {
      final response = await apiClient.post(
        AppUrls.getTestNames,
        data: {'MOBCATCODE': categoryCode.toString()},
      );
      final data = response.body;
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) {
          final test = TestModel.fromJson(json);
          test.testCategoryCode = categoryCode;
          return test;
        }).toList();
      } else {
        throw Exception('Failed to load tests: ${data['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching tests for category $categoryCode: $e');
    }
  }

  Future<RegisteredPatientResponse?> fetchRegisteredPatients({
    required String facilityId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final body = {
        'userid': facilityId,
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      };
      kPrint('Request Body: $body');
      kPrint('Request URL: ${AppUrls.getRegisteredPatientList}');

      final result = await apiClient.post(
        AppUrls.getRegisteredPatientList,
        data: body,
      );

      kPrint(
          'Response Status Code: ${result.statusCode}, Response Body: ${result.data}');

      final decoded = result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
      return RegisteredPatientResponse.fromJson(decoded);
    } catch (e, stackTrace) {
      kPrint('Error fetching patients: $e');
      kPrint('Stack Trace: $stackTrace');
      return null;
    }
  }

  Future<bool> updatePatientOpdReceipt({
    required String orderId,
    required String opdNumber,
    required String basicReceipt,
    required String advanceReceipt,
    required String patientType,
    required String mobile,
    required String importStat,
  }) async {
    try {
      final body = {
        'Orderid': orderId,
        'opd_number': opdNumber,
        'BasicReceipt': basicReceipt,
        'AdvanceReceipt': advanceReceipt,
        'patienttype': patientType,
        'Mobile': mobile,
        'importstat': importStat,
      };
      kPrint('Update Patient Request Body: $body');
      kPrint('Request URL: ${AppUrls.updatePatientDetails}');

      final result = await apiClient.post(
        AppUrls.updatePatientDetails,
        data: body,
      );

      kPrint(
          'Response Status Code: ${result.statusCode}, Response Body: ${result.data}');

      final decoded = result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
      return decoded['status'] == 'Success';
    } catch (e) {
      kPrint('Update error: $e');
      return false;
    }
  }

  Future<BeneficiaryConsentResponse> getBeneficiaryConsentDetails({
    required String mobileNo,
    required String beneficiaryName,
  }) async {
    try {
      final body = {
        'MobileNo': mobileNo,
        'BeneficiaryName': beneficiaryName,
      };
      kPrint('Request url: ${AppUrls.getBeneficiaryConsentDetails}');
      kPrint('Request Body: $body');

      final result = await apiClient.post(
        AppUrls.getBeneficiaryConsentDetails,
        data: body,
      );

      kPrint('Consent check response: ${result.data}');

      final json = result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
      return BeneficiaryConsentResponse.fromJson(json);
    } catch (e) {
      kPrint('Error checking beneficiary consent: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendDpdpConsentOtp({
    required String mobile,
    required String otp,
    required String createdBy,
    required String msgId,
    required String beneficiaryName,
  }) async {
    try {
      final body = {
        'MOBNO': mobile,
        'OTP': otp,
        'CreatedBy': createdBy,
        'MsgID': msgId,
        'BeneficiaryName': beneficiaryName,
      };
      kPrint('Request url: ${AppUrls.sendRegistrationOtpWithDpdpConsent}');
      kPrint('Request Body: $body');

      final result = await apiClient.post(
        AppUrls.sendRegistrationOtpWithDpdpConsent,
        data: body,
      );

      kPrint('Send DPDP consent OTP response: ${result.data}');

      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      kPrint('Error sending DPDP consent OTP: $e');
      rethrow;
    }
  }

  /// Photo upload — uses FormData (isFormData: true)
  Future<bool> uploadConsentPhoto({
    required String mobileNo,
    required String beneficiaryName,
    required File photoFile,
    required String createdBy,
  }) async {
    try {
      final String safeName = beneficiaryName
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')   // remove spaces & special chars
          .replaceAll(RegExp(r'_+'), '_');            // collapse multiple underscores

      final String extension = photoFile.path.split('.').last.toLowerCase();
      final String fileName = '${safeName}_${mobileNo}_dpdpconsent.$extension';
      final formData = FormData.fromMap({
        'MobileNo': mobileNo,
        'BeneficiaryName': beneficiaryName,
        'IsCellularPhone': '1',
        'CreatedBy': createdBy,
        'Photo': await MultipartFile.fromFile(photoFile.path, filename: fileName),
      });

      kPrint('========== CONSENT PHOTO UPLOAD ==========');
      kPrint('URL: ${AppUrls.addConsentPhoto}');
      kPrint('MobileNo: $mobileNo');
      kPrint('BeneficiaryName: $beneficiaryName');
      kPrint('IsCellularPhone: 1');
      kPrint('CreatedBy: $createdBy');
      kPrint('Photo Path: ${photoFile.path}');
      kPrint('==========================================');

      final result = await apiClient.post(
        AppUrls.addConsentPhoto,
        data: formData,
        isFormData: true,
      );

      kPrint('Upload consent photo response: ${result.data}');

      final data = result.data;
      if (data is Map && data['status'] == 'Success') return true;
      return true;
    } catch (e) {
      kPrint('Error uploading consent photo: $e');
      return false;
    }
  }

  Future<bool> checkDuplicateBarcode(String barcode) async {
    try {
      final response = await apiClient.post(
        AppUrls.checkBarcode,
        data: {'ORDERNO': barcode},
      );

      final data = response.body; // same as other methods in this service

      if (data['status'] == 'Success' && data['output'] == 0) {
        return true; // Barcode does not exist → valid
      } else {
        return false;
      }
    } catch (e) {
      // Keep same behaviour – return false on any error
      return false;
    }
  }
}

/*class PatientRegistrationService {
  APIClient apiClient = Get.put(APIClient());
  Dio dio = Dio();



  Future<List<CenterModel>> getLabNames(String userId) async {
    try {
      final url = AppUrls.getCenterList;
      final queryParams = {
        'UserID': userId,
      };

      final response = await apiClient.post(url, data: queryParams);
      // debugPrint
      final data = response.body;
      // final data = response['data'];
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => CenterModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load centers: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FacilityModel>> getFacilityList(String userId) async {
    try {
      final url = AppUrls.getFacilityList;
      final queryParams = {
        'UserID': userId,
      };

      final response = await apiClient.post(url, data: queryParams);
      final data = response.body;       // final data = response['data'];

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => FacilityModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load facilities: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<IdentityProofModel>> getIdentityProofList() async {
    try {
      final url = AppUrls.getIdentityProof;
      final response = await apiClient.post(url);
      final data = response.body; // final data = response['data'];

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => IdentityProofModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load identity proofs: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // marital status list
  Future<List<MaritalStatusModel>> getMaritalStatusList() async {
    try {
      final url = AppUrls.getMaritalStatus;
      final response = await apiClient.post(url);
      final data = response.body; // final data = response['data'];

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => MaritalStatusModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load marital status: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // get district list
  Future<List<DistrictModel>> fetchDistrictList() async {
    try {
      final url = AppUrls.getDistrictList;
      final response = await apiClient.post(url); // Replace with actual URL

      final data = response.body; // final data = response['data'];
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => DistrictModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load districts: ${data['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  Future<List<StateModel>> getStateList() async {
    try {
      final url = AppUrls.getStateList;

      final response = await apiClient.post(url);
      final data = response.body; // final data = response['data'];

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => StateModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load states: ${data['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // check opd number exists
  Future<bool> checkOpdNumberExists(
      String opdNumber, String facilityCode) async {
    try {
      final url = AppUrls.checkOpdNumberExists;
      final queryParams = {
        'Opdnumber': opdNumber,
        'Facilitycode': facilityCode,
      };

      final response = await apiClient.post(url, data: queryParams);
      final data = response.body; // final data = response['data'];

      if (data['status'] == 'Success') {
        return false;
        //return false if exists
      } else {
        return true;
      }
    } catch (e) {
      rethrow;
    }
  }

  // fetch doctor reference list
  Future<List<ReferenceDoctor>> fetchReferenceDoctors(
      {required String facilityCode}) async {
    try {
      final response = await apiClient.post(
        AppUrls.getDoctorReferenceList,
        data: {
          'VisitDate': DateTime(
                  DateTime.now().year, DateTime.now().month, DateTime.now().day)
              .toString(),
          'FacilityCode': facilityCode,
        },
      );

      final data = response.body; // final data = response['data'];
      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output.map((e) => ReferenceDoctor.fromJson(e)).toList();
      } else {
        Get.snackbar(
            'Error', data['message'] ?? 'Failed to load reference doctors');
        return [];
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
      return [];
    }
  }

  Future<List<ExistingPatientModel>> searchExistingPatients({
    required int type,
    required String searchValue,
  }) async {
    try {
      final url = AppUrls.searchExistingPatient;
      final queryParams = {
        'type': type.toString(),
        'Searchvalue': searchValue,
      };
      final response = await apiClient.post(
        url,
        data: queryParams,
      );

      final data = response.body; // final data = response['data'];
      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output.map((e) => ExistingPatientModel.fromJson(e)).toList();
      } else {
        debugPrint("Search failed: ${data['message'] ?? 'No message'}");
        return [];
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }
  Future<Map<String, dynamic>> getHMISPatientTests(String patientId) async {
    try {
      final response = await dio.post(
        AppUrls.getHMISPatientTests,
        data: {
          'Mobilenumber': patientId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ensure the response is a Map<String, dynamic>
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          // In case the API returns JSON as a string
          try {
            return jsonDecode(response.data as String) as Map<String, dynamic>;
          } catch (_) {
            throw Exception('Invalid response format: expected JSON object');
          }
        }
      } else {
        throw Exception('Failed to fetch HMIS patient tests: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String message = 'Error fetching HMIS patient tests';
      if (e.response != null) {
        message += ' (${e.response?.statusCode}): ${e.response?.data}';
      } else {
        message += ': ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// TESTS SECTION
*//*  Future<List<TestModel>> fetchAllTests() async {
    try {
      List<TestModel> allTests = [];

      // Fetch tests for all three categories (MOBCATCODE: 1, 2, 3)
      for (int categoryCode = 1; categoryCode <= 3; categoryCode++) {
        final categoryTests = await fetchTestsByCategory(categoryCode);
        allTests.addAll(categoryTests);
      }

      return allTests;
    } catch (e) {
      throw Exception('Error fetching all tests: $e');
    }
  }*//*

*//*  /// Fetch tests by specific category
  Future<List<TestModel>> fetchTestsByCategory(int mobCatCode) async {
    try {
      final url = '${AppUrls.getTestNames}?MOBCATCODE=$mobCatCode';
      final response = await apiClient.post(url);
      final data = response['data'];

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => TestModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tests: ${data['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching tests for category $mobCatCode: $e');
    }
  }*//*

  // send mobile verification otp
  Future<Map<String, dynamic>> sendOtp(
      String mobileNumber, String createdBy) async {
    try {
      final url = AppUrls.sendOTP;
      final params = {'MOBNO': mobileNumber, 'CreatedBy': createdBy};

      final response = await apiClient.post(url, data: params);
      // debug debugPrint

      debugPrint('🤷‍♂️🤷‍♂ $response️');
      // return response['data'];
      return response.body;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<Map<String, dynamic>> validateMobileNumber(
    String mobileNumber,
  ) async {
    try {
      final url = AppUrls.validateMobile;
      final params = {'mobNo': mobileNumber};

      final uri = Uri.parse(url).replace(data: params);
      debugPrint('Request URL: $uri');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body;
      } else {
        throw Exception('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }
  String? _fixNumericField(dynamic value) {
    if (value == null || value.toString().isEmpty || value == 'null') {
      return '0';
    }
    return value.toString();
  }
  // fill the patient Data in the api
  Future<Map<String, dynamic>> savePatientDetails(
      Map<String, dynamic> patientArray) async {
    try {
      debugPrint('-----------------Insider SavePatientDetails-----------------');

      final firstPatient = patientArray['patientArray']?.isNotEmpty == true
          ? patientArray['patientArray'][0]
          : {};

      if (firstPatient.isEmpty) {
        throw Exception('No patient data found');
      }

      // ✅ EXACT NATIVE STRUCTURE - ONLY these fields!
      final enhancedPatientData = {
        // ✅ REQUIRED - Match Native EXACTLY
        'ORDERNO': '0',
        'title': firstPatient['title']?.toString() ?? '0',
        'lastName': firstPatient['lastName']?.toString() ?? '',
        'centerId': firstPatient['centerId']?.toString() ?? '0',
        'address': firstPatient['address']?.toString() ?? '',
        'facilityId': firstPatient['facilityId']?.toString() ?? '0',
        'gender': firstPatient['gender']?.toString() ?? '',
        'adharNumber': firstPatient['adharNumber']?.toString() ?? '',
        'stateId': '27',                    // ✅ Native hardcoded
        'postalCode': firstPatient['postalCode']?.toString() ?? '',
        'mobile': firstPatient['mobile']?.toString() ?? '',
        'cityId': _fixNumericField(firstPatient['cityId']) ?? '0',
        'countryId': '1',                   // ✅ Native hardcoded
        'firstName': firstPatient['firstName']?.toString() ?? '',
        'districtId': _fixNumericField(firstPatient['districtId']) ?? '0',
        'talukaId': _fixNumericField(firstPatient['talukaId']) ?? '0',
        'dob': _formatDob(firstPatient['dob']?.toString() ?? ''),
        'age': firstPatient['age']?.toString() ?? '0',
        'middleName': firstPatient['middleName']?.toString() ?? '',
        'token_id': firstPatient['token_id']?.toString() ?? '',
        'PatRegNo': firstPatient['PatRegNo']?.toString() ?? '',
        'IdProofId': _fixNumericField(firstPatient['IdProofId']) ,                   // ✅ FIX: Use "2" (like your previous log)
        'AgeTitle': firstPatient['AgeTitle'],
        'ABHANumber': firstPatient['ABHANumber']?.toString() ?? '',
        'ABHAAddress': '',                  // ✅ Empty for now
        'ISOTPVerify': firstPatient['ISOTPVerify']?.toString() ?? '0',
        'BloodGroup': 'NA',
        'CategoryCast': _fixNumericField(firstPatient['CategoryCast']) ?? '0',
        'MaritalStatus': _fixNumericField(firstPatient['MaritalStatus']) ?? '0',
        'patCrno': firstPatient['patCrno']?.toString() ?? '',
        'Orderdate': DateFormat('yyyy/MM/dd').format(DateTime.now()),

        // ✅ REMOVE ALL EXTRA FIELDS: filter2, PatientType, FemaleCategoryId, etc.
      };

      // ✅ CRITICAL: Remove any extra fields that might sneak in
      final cleanData = <String, dynamic>{};
      for (var key in enhancedPatientData.keys) {
        if (enhancedPatientData[key] != null) {
          cleanData[key] = enhancedPatientData[key];
        }
      }

      final jsonString = jsonEncode(cleanData);
      final formData = 'inpt=$jsonString';

      debugPrint('🎯 EXACT NATIVE PAYLOAD:');
      debugPrint(jsonString);

      final response = await http.post(
        Uri.parse(AppUrls.savePatientDetails),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData,
      );

      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        debugPrint("Status from server: ${resData['status']}");

        if (resData['status']?.toString().toLowerCase() == 'success') {
          final patientPermid = resData['patientPermid'];
          return {
            'success': true,
            'data': resData,
            'patientPermid': patientPermid?.toString()
          };
        } else {
          throw Exception('Server Error: ${resData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ ERROR: $e');
      rethrow;
    }
  }
  String _formatDob(String dob) {
    if (dob.isEmpty) return '';

    try {
      // ✅ Parse DD/MM/YYYY → YYYY/MM/DD
      final parts = dob.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year/$month/$day';  // 1989/08/18
      }
      return dob; // Return original if format doesn't match
    } catch (e) {
      debugPrint('⚠️ DOB format error: $e');
      return dob;
    }
  }
  Future<Map<String, dynamic>> submitLabData(
      Map<String, dynamic> labData) async {
    try {
      final jsonString = jsonEncode(labData);
      final formData = 'inpt=$jsonString';

      // Usage
      printLongString(formData.toString());

      debugPrint('==================');
      debugPrint(AppUrls.saveForm);

      final response = await http.post(
        Uri.parse(AppUrls.saveForm),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final resData = jsonDecode(response.body);

          if (resData['status'] == 'Success') {
            debugPrint('✅ Lab data submitted successfully!');
            // Return success response for handling in UI
            return {'success': true, 'data': resData};
          } else if (resData['status'] == 'Fail') {
            // Handle failure cases like "Details Already Exists!"
            debugPrint(" Submission failed: ${resData['message']}");
            throw Exception(resData['message'] ?? 'Submission failed');
          } else {
            // Handle unexpected status values
            debugPrint("⚠️ Unexpected response status: ${resData['status']}");
            throw Exception('Unexpected response status: ${resData['status']}');
          }
        } catch (e) {
          // If JSON parsing fails, treat as success if status code is 200
          debugPrint(
              '✅ Request successful but response is not JSON: ${response.body}');
          return {'success': true, 'message': 'Data submitted successfully'};
        }
      } else {
        // Handle HTTP error status codes
        debugPrint(' HTTP Error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(' Request failed: $e');
      rethrow; // Re-throw to be handled by calling function
    }
  }

  Future<void> submitOrderInput(Map<String, dynamic> input) async {
    try {
      final jsonString = jsonEncode(input);
      final info = await PackageInfo.fromPlatform();
      final version = info.version;
      final formData = 'P1=$jsonString&ispatVerified=1&MobVersion=$version';
      printLongString('Submitting Order Input:\n$formData');
      debugPrint('==================');
      debugPrint(AppUrls.orderInputUrl);


      final response = await http.post(
        Uri.parse(AppUrls.orderInputUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      );

      debugPrint('📬 Order Input Status: ${response.statusCode}');
      debugPrint('📬 Order Input Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to submit order input: ${response.statusCode}');
      }

      final resData = jsonDecode(response.body);
      if (resData['status'] != 'Success') {
        throw Exception(
            'Order input failed: ${resData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ Order Input Submission Error: $e');
      rethrow;
    }
  }

  void printLongString(String text) {
    debugPrint('🤷‍♂️');
    final pattern = RegExp('.{1,1000}'); // 1000 is the chunk size
    pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
  }

  Future<bool> insertDoctor({
    required String firstName,
    required String middleName,
    required String lastName,
    required String empCode,
    required String facilityCode,
  }) async {
    try {
      final formData = {
        'FName': firstName,
        'MName': middleName,
        'LName': lastName,
        'Speciality': 'NA',
        'Salutation': 'NA',
        'Title': 'Dr.',
        'CreationUID': empCode.toString(),
        'FacilityCode': facilityCode.toString(),
      };

      debugPrint('📡 Submitting Doctor Data:\n$formData');

      final response = await http.post(
        Uri.parse(AppUrls.insertDoctor),
        // Make sure this points to the correct URL
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      );

      debugPrint('📬 Insert Doctor Status: ${response.statusCode}');
      debugPrint('📬 Insert Doctor Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to insert doctor: ${response.statusCode}');
      }

      final resData = jsonDecode(response.body);
      final status = resData['status']?.toString().toLowerCase();

      if (status == 'success') {
        debugPrint('✅ Doctor inserted successfully.');
        return true;
      } else {
        debugPrint('⚠️ Doctor insertion failed: ${resData['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Insert Doctor Error: $e');
      rethrow;
    }
  }

  // fetch test lists
  Future<List<TestModel>> fetchTestsByCategory(int categoryCode) async {
    try {
      final url = AppUrls.getTestNames;
      final queryParams = {
        'MOBCATCODE': categoryCode.toString(),
      };
      final response = await apiClient.post(url, data: queryParams);

      final data = response.body; // final data = response['data'];
      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) {
          final test = TestModel.fromJson(json);
          test.testCategoryCode = categoryCode; // Set the mobCatCode here
          return test;
        }).toList();
      } else {
        throw Exception('Failed to load tests: ${data['message']}');
      }
      *//*if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList.map((json) => TestModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tests: ${data['message']}');
      }*//*
    } catch (e) {
      throw Exception('Error fetching tests for category $categoryCode: $e');
    }
  }

  // registered patient List
  Future<RegisteredPatientResponse?> fetchRegisteredPatients({
    required String facilityId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final body = {
        'userid': facilityId,
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      };
      CustomDebugFunction.log('Request Body: $body');
      final uri = Uri.parse(AppUrls.getRegisteredPatientList);
      CustomDebugFunction.log('Request Body: $body' +''+'Request URL: $uri');
      final response = await http.post(
        uri,
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      final decodedResponse = jsonDecode(response.body);
      CustomDebugFunction.log(
          'Response Status Code: ${response.statusCode}, Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return RegisteredPatientResponse.fromJson(decodedResponse);
      }
      return null;
    } catch (e,  stackTrace) {
      CustomDebugFunction.log('Error fetching patients: $e');
      debugPrint('Stack Trace: $stackTrace');
      debugPrint('Error fetching patients: $e');
      return null;
    }
  }

  Future<bool> updatePatientOpdReceipt({
    required String orderId,
    required String opdNumber,
    required String basicReceipt,
    required String advanceReceipt,
    required String patientType,
    required String mobile,
    required String importStat,
  }) async {
    try {
      final body = {
        'Orderid': orderId,
        'opd_number': opdNumber,
        'BasicReceipt': basicReceipt,
        'AdvanceReceipt': advanceReceipt,
        'patienttype': patientType,
        'Mobile': mobile,
        'importstat': importStat,
      };
      debugPrint('Update Patient Request Body: ${body.toString()}');
      debugPrint('Request URL: ${AppUrls.updatePatientDetails}');

      final uri = Uri.parse(AppUrls.updatePatientDetails);
      final response = await http.post(uri, body: body, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });
      debugPrint(
          'Response Status Code: ${response.statusCode}, Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['status'] == 'Success';
      }
      return false;
    } catch (e) {
      debugPrint('Update error: $e');
      return false;
    }
  }

  Future<BeneficiaryConsentResponse> getBeneficiaryConsentDetails({
    required String mobileNo,
    required String beneficiaryName,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.getBeneficiaryConsentDetails);
      final body = {
        'MobileNo': mobileNo,
        'BeneficiaryName': beneficiaryName,
      };
      CustomDebugFunction.log('Request url: $uri');
      CustomDebugFunction.log('Request Body: $body');
      final response = await http.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      CustomDebugFunction.log('Consent check response: ${response.body}');
      final json =  jsonDecode(response.body) as Map<String, dynamic>;
      return BeneficiaryConsentResponse.fromJson(json);
    } catch (e) {
      CustomDebugFunction.log('Error checking beneficiary consent: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendDpdpConsentOtp({
    required String mobile,
    required String otp,
    required String createdBy,
    required String msgId,
    required String beneficiaryName,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.sendRegistrationOtpWithDpdpConsent);
      final body = {
        'MOBNO': mobile,
        'OTP': otp,
        'CreatedBy': createdBy,
        'MsgID': msgId,
        'BeneficiaryName': beneficiaryName,
      };
      CustomDebugFunction.log('Request url: $uri');
      CustomDebugFunction.log('Request Body: $body');

      final response = await http.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      CustomDebugFunction.log('Send DPDP consent OTP response: ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      CustomDebugFunction.log('Error sending DPDP consent OTP: $e');
      rethrow;
    }
  }

  Future<bool> uploadConsentPhoto({
    required String mobileNo,
    required String beneficiaryName,
    required File photoFile,
    required String createdBy,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.addConsentPhoto);


      final request = http.MultipartRequest('POST', uri)
        ..fields['MobileNo'] = mobileNo
        ..fields['BeneficiaryName'] = beneficiaryName
        ..fields['IsCellularPhone'] = '1'

        ..fields['CreatedBy'] = createdBy
        ..files.add(await http.MultipartFile.fromPath('fileName', photoFile.path));

      CustomDebugFunction.log('========== CONSENT PHOTO UPLOAD ==========');
      CustomDebugFunction.log('URL: $uri');
      CustomDebugFunction.log('Fields: ${request.fields}');
      CustomDebugFunction.log('MobileNo: $mobileNo');
      CustomDebugFunction.log('BeneficiaryName: $beneficiaryName');
      CustomDebugFunction.log('IsCellularPhone: 1');
      CustomDebugFunction.log('CreatedBy: $createdBy');
      CustomDebugFunction.log('Photo Path: ${photoFile.path}');
      CustomDebugFunction.log(
        'Photo Filename: ${request.files.first.filename}',
      );
      CustomDebugFunction.log(
        'Photo Field Name: ${request.files.first.field}',
      );
      CustomDebugFunction.log(
        'Photo Length: ${request.files.first.length}',
      );
      CustomDebugFunction.log('==========================================');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      CustomDebugFunction.log('Upload consent photo response: ${response.body}');
      if (response.statusCode != 200) return false;

      try {
        final data = jsonDecode(response.body);
        return data['status'] == 'Success';
      } catch (_) {
        return true; // handler may return plain text on success
      }
    } catch (e) {
      CustomDebugFunction.log('Error uploading consent photo: $e');
      return false;
    }
  }
}*/
