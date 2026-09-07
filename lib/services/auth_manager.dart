import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/model/login_response_model.dart';
import '../features/auth/model/profile_model.dart';
import '../features/auth/service/login_service.dart';
import 'device_info_service.dart';
import '../routes/route_manager.dart';

enum UserRole {
  phlebotomist('Phlebotomist'),
  runnerBoy('Runner Boy'),
  labTechnician('Lab Technician'),
  labAccession('Lab accession'),
  connector('Connector'),
  teamLead('Team Lead'),
  medicalOfficer('Medical Officer'),
  srMedicalOfficer('Sr Medical Officer'),
  chiefMedicalOfficer('Chief medical officer'),
  projectManager('Project Manager'),
  chiefMedicalSurgeon('Chief Medical Sergeon'),
  bmcAdmin('BMC-ADMIN'),
  executiveHealthOfficer('Executive health officer');

  const UserRole(this.displayName);

  final String displayName;

  static UserRole? fromString(String? role) {
    if (role == null || role.isEmpty) return null;

    for (UserRole userRole in UserRole.values) {
      if (userRole.displayName.toLowerCase() == role.toLowerCase() ||
          userRole.name.toLowerCase() == role.toLowerCase()) {
        return userRole;
      }
    }
    return null;
  }
}

class AuthManager extends GetxController {
  static const String _kUserDataKey = 'user_data';
  static const String _kTokenKey = 'auth_token';
  static const String _kLoginDateKey = 'login_date';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Observable states
  final Rx<Map<String, dynamic>?> _userData = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isLoggedIn = false.obs;
  final RxString _userMobileNumber = ''.obs;
  static const String _kUserRoleKey = 'user_role';
  final Rx<UserRole?> _userRole = Rx<UserRole?>(null);

  // CHANGED: token now lives here as the single source of truth (kept in
  // memory, backed by secure storage), instead of being read back out of
  // the _userData map. Nothing else below this line is new.
  String? _cachedToken;

  /// Constructor
  AuthManager() {
    initAuth();
  }

  /// Initialize authentication state
  Future<void> initAuth() async {
    _isLoading.value = true;
    try {
      // CHANGED: load the token into memory once, up front, so getToken()
      // never has to guess where it lives.
      _cachedToken = await _secureStorage.read(key: _kTokenKey);
      await _loadUserDataFromStorage();
      await _loadUserRoleFromStorage();
      _checkLoginStatus();
    } catch (e) {
      if (kDebugMode) {
        log('Error initializing auth: $e');
      }
      _isLoggedIn.value = false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load user data from storage
  Future<void> _loadUserDataFromStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString(_kUserDataKey);

      if (userDataString != null && userDataString.isNotEmpty) {
        _userData.value = json.decode(userDataString);

        if (kDebugMode) {
          log('User data loaded successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error loading user data: $e');
      }
      _userData.value = null;
    }
  }

  /// Check if the user is logged in
  void _checkLoginStatus() {
    final token = getToken();
    _isLoggedIn.value = (token != null && token.isNotEmpty);
  }

  /// Save user data to storage
  Future<void> saveUserDataToStorage(Map<String, dynamic> userData) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userDataString = json.encode(userData);
      await prefs.setString(_kUserDataKey, userDataString);

      if (kDebugMode) {
        log('😎😎User data saved successfully');
        for (var entry in userData.entries) {
          log('User data: ${entry.key} = ${entry.value}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error saving user data: $e');
      }
    }
  }

  Future<void> setUserMobileNumberToStorage(String mobileNumber) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobileNumber', mobileNumber);
      _userMobileNumber.value = mobileNumber; // store in observable
      if (kDebugMode) {
        log('Mobile number saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error saving mobile number: $e');
      }
    }
  }

  Future<void> saveLoginResponseModel(LoginResponseModel model) async {
    try {
      final Map<String, dynamic> data = model.toJson();
      await saveUserDataToStorage(data);

      if (data.containsKey('token') && data['token'] != null && data['token'].toString().isNotEmpty) {
        await _saveToken(data['token']);
      } else if (kDebugMode) {
        // If you see this, LoginResponseModel.toJson() is dropping/renaming
        // the token field — that's why later requests go out unauthenticated.
        log('⚠️ saveLoginResponseModel: no usable "token" key in ${data.keys}');
      }
      await _saveLoginDate();
      _userData.value = data;
      _isLoggedIn.value = true;

      if (kDebugMode) {
        log('LoginResponseModel saved');
      }
    } catch (e) {
      log('Error saving LoginResponseModel: $e');
    }
  }

  Future<String?> getUserMobileNumber() async {
    if (_userMobileNumber.value.isNotEmpty) {
      return _userMobileNumber.value;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');

    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      _userMobileNumber.value = mobileNumber; // update in-memory
      return mobileNumber;
    }

    return null;
  }

  /// Get user mobile number from storage

  // get user data from the storage
  static Future<Map<String, dynamic>?> getUserDataFromStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('userData');

    if (userData != null) {
      return jsonDecode(userData) as Map<String, dynamic>;
    }

    return null;
  }

  /// Save token to secure storage
  Future<void> _saveToken(String token) async {
    try {
      await _secureStorage.write(key: _kTokenKey, value: token);
      // CHANGED: keep the in-memory cache in sync the moment we persist it.
      _cachedToken = token;
      if (kDebugMode) {
        log('Token saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error saving token: $e');
      }
    }
  }

  /// Clear user data from storage
  Future<void> clearUserDataFromStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserDataKey);
      await _secureStorage.delete(key: _kTokenKey);
      // CHANGED: clear the cache alongside secure storage.
      _cachedToken = null;

      if (kDebugMode) {
        log('User data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error clearing user data: $e');
      }
    }
  }

  /// Login user with provided data and token
  Future<bool> loginUser(
      {required Map<String, dynamic> userData, required String token}) async {
    try {
      _isLoading.value = true;

      // Store the user data
      _userData.value = userData;
      await saveUserDataToStorage(userData);

      // Store the token
      await _saveToken(token);
      await _saveLoginDate();
      _isLoggedIn.value = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        log('Login error: $e');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> processLoginResponse(Map<String, dynamic> response) async {
    try {
      // Customize this based on your API structure
      final bool success = response['success'] ?? false;

      if (success && response.containsKey('data')) {
        // Extract token from response - adjust path based on your API
        final token = response['data']['token'];
        if (token == null || token.isEmpty) {
          return false;
        }

        // Login the user with the data and token
        return await loginUser(
          userData: response['data'],
          token: token,
        );
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        log('Error processing login response: $e');
      }
      return false;
    }
  }

  // save device into to the local storage
  Future<void> saveDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoService().getDeviceInfo();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('deviceInfo', json.encode(deviceInfo));
      if (kDebugMode) {
        log('Device info saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error saving device info: $e');
      }
    }
  }

  // get device info from the local storage
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? deviceInfoString = prefs.getString('deviceInfo');

      if (deviceInfoString != null && deviceInfoString.isNotEmpty) {
        return json.decode(deviceInfoString);
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error loading device info: $e');
      }
    }
    return null;
  }

  /// [clearCredentials] = true only on manual logout (user tapped "Sign out")
  /// [clearCredentials] = false on session-expiry auto-logout
  Future<void> logoutUser({bool clearCredentials = false}) async {
    try {
      _isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final profile = await getUserProfileFromStorage();

      if (profile?.empCode != null) {
        try {
          final LoginService loginService = Get.put(LoginService());
          await loginService.logOutUser(profile!.empCode.toString());
        } catch (apiError) {
          if (kDebugMode) log('Logout API failed: $apiError');
        }
      }

      await prefs.remove(_kUserDataKey);
      await prefs.remove(_kLoginDateKey);
      await _secureStorage.delete(key: _kTokenKey);
      // CHANGED: clear the cache alongside secure storage.
      _cachedToken = null;
      await clearUserProfileFromStorage();
      await prefs.remove('workerDetails');
      await _clearUserRole();

      // Only wipe credentials on intentional sign-out
      if (clearCredentials) {
        await clearSavedCredentials();
      }

      _userData.value = null;
      _isLoggedIn.value = false;
      RouteManager.redirectToLogin();
    } catch (e) {
      if (kDebugMode) log('Logout error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      // 1) Check if user data exists (in-memory or storage)
      final userData = await getUserData();
      final hasUserData = userData != null && userData.isNotEmpty;

      // // 2) Check if mobile number exists (in-memory or storage)
      // final mobileNumber = await getUserMobileNumber();
      // final hasMobileNumber = mobileNumber != null && mobileNumber.isNotEmpty;

      // 3) User is considered logged in if both user data and mobile number exist
      final loggedIn = hasUserData;

      // 4) Update Rx variable for UI/listeners
      _isLoggedIn.value = loggedIn;

      if (kDebugMode) {
        print(
            'isUserLoggedIn🚩: hasUserData=$hasUserData,  loggedIn=$loggedIn');
      }

      return loggedIn;
    } catch (e) {
      if (kDebugMode) {
        log('Error checking login status: $e');
      }
      return false;
    }
  }

  /// Get user token from memory or storage
  // CHANGED: now returns the cached token (loaded from secure storage in
  // initAuth / kept fresh by _saveToken) instead of reading
  // _userData.value['token']. This was the root cause of `Token:` printing
  // empty — the two locations could disagree. Signature is unchanged
  // (still sync, still String?), so no call site needs to change.
  String? getToken() {
    try {
      return _cachedToken;
    } catch (e, stackTrace) {
      log('Error getting token: $e $stackTrace');
      return null;
    }
  }

  /// Get current user data from shared preferences
  /// Get current user data (in‐memory if available, otherwise from SharedPreferences)
  Future<Map<String, dynamic>?> getUserData() async {
    // 1) if already in memory, return it
    if (_userData.value != null) {
      return _userData.value;
    }

    // 2) otherwise load from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kUserDataKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> data =
        json.decode(jsonString) as Map<String, dynamic>;

        // update in-memory copy
        _userData.value = data;

        if (kDebugMode) {
          log('getUserData: loaded from storage');
        }
        return data;
      }
    } catch (e) {
      if (kDebugMode) {
        log('getUserData error: $e');
      }
    }
    // nothing found
    return null;
  }

  /// Get a specific user property
  dynamic getUserProperty(String property) {
    if (_userData.value != null && _userData.value!.containsKey(property)) {
      return _userData.value![property];
    }
    return null;
  }

  /// Check if loading
  bool isLoading() {
    return _isLoading.value;
  }

  /// Update user data
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    if (_userData.value != null) {
      // Merge new data with existing data
      _userData.value = {..._userData.value!, ...newData};
      await saveUserDataToStorage(_userData.value!);
    }
  }

  static const String _kUserProfileKey = 'user_profile';

  /// Save user profile to storage
  Future<void> saveUserProfileToStorage(ProfileData profile) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String profileJson = json.encode(profile.toJson());
      await prefs.setString(_kUserProfileKey, profileJson);

      if (kDebugMode) {
        log('✅ User profile saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error saving user profile: $e');
      }
    }
  }

  /// Get user profile from storage
  Future<ProfileData?> getUserProfileFromStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? profileJson = prefs.getString(_kUserProfileKey);

      if (profileJson != null && profileJson.isNotEmpty) {
        final Map<String, dynamic> profileMap = json.decode(profileJson);
        return ProfileData.fromJson(profileMap);
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error getting user profile: $e');
      }
    }
    return null;
  }

  /// Clear user profile from storage
  Future<void> clearUserProfileFromStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserProfileKey);
      if (kDebugMode) {
        log('🗑 User profile cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error clearing user profile: $e');
      }
    }
  }

  Future<void> setUserRole(String? designation) async {
    try {
      final role = UserRole.fromString(designation);

      if (role != null) {
        _userRole.value = role;

        // Save to SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserRoleKey, role.name);

        if (kDebugMode) {
          log('✅ User role set successfully: ${role.displayName}');
        }
      } else {
        if (kDebugMode) {
          log('⚠️ Invalid role designation: $designation');
        }
        _userRole.value = null;
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error setting user role: $e');
      }
    }
  }

  /// Get current user role
  UserRole? getUserRole() {
    return _userRole.value;
  }

  /// Get user role as string
  String? getUserRoleString() {
    return _userRole.value?.displayName;
  }

  /// Get user role name (enum name)
  String? getUserRoleName() {
    return _userRole.value?.name;
  }

  /// Check if user has specific role
  bool hasRole(UserRole role) {
    return _userRole.value == role;
  }

  /// Check if user is Phlebotomist
  bool isPhlebotomist() {
    return _userRole.value == UserRole.phlebotomist;
  }

  /// Check if user is Runner Boy
  bool isRunnerBoy() {
    return _userRole.value == UserRole.runnerBoy;
  }

  /// Check if user is Lab Technician
  bool isLabTechnician() {
    return _userRole.value == UserRole.labTechnician;
  }

  /// Check if user is Team Lead
  bool isTeamLead() {
    return _userRole.value == UserRole.teamLead;
  }

  /// Load user role from storage (call this in initAuth)
  Future<void> _loadUserRoleFromStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? roleString = prefs.getString(_kUserRoleKey);

      if (roleString != null && roleString.isNotEmpty) {
        // Try to find the role by enum name
        for (UserRole role in UserRole.values) {
          if (role.name == roleString) {
            _userRole.value = role;
            if (kDebugMode) {
              log('User role loaded: ${role.displayName}');
            }
            break;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error loading user role: $e');
      }
    }
  }

  /// Clear user role from storage
  Future<void> _clearUserRole() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserRoleKey);
      _userRole.value = null;

      if (kDebugMode) {
        log('User role cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error clearing user role: $e');
      }
    }
  }




  /// Save today's date when user logs in
  Future<void> _saveLoginDate() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_kLoginDateKey, today);
    if(kDebugMode){
      log('Date saved successfully: $today');
    }

  }

  /// Returns true if the session has expired (date changed since login)
  Future<bool> isSessionExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_kLoginDateKey);
      if (savedDate == null) return false; // no date = fresh install, not expired

      final today = DateTime.now().toIso8601String().substring(0, 10);
      return savedDate != today;
    } catch (e) {
      if (kDebugMode) log('Error checking session expiry: $e');
      return false;
    }
  }

  static const String _kSavedUsernameKey = 'saved_username';
  static const String _kSavedPasswordKey = 'saved_password';

  /// Call this on every successful login — persists credentials forever
  Future<void> saveCredentials(String username, String password) async {
    try {
      // Use secure storage so password isn't in plain SharedPreferences
      await _secureStorage.write(key: _kSavedUsernameKey, value: username);
      await _secureStorage.write(key: _kSavedPasswordKey, value: password);
      if (kDebugMode) log('Credentials saved for next-day auto-fill');
    } catch (e) {
      if (kDebugMode) log('Error saving credentials: $e');
    }
  }

  /// Returns saved credentials, or null if none exist
  Future<({String username, String password})?> getSavedCredentials() async {
    try {
      final username = await _secureStorage.read(key: _kSavedUsernameKey);
      final password = await _secureStorage.read(key: _kSavedPasswordKey);
      if (username != null && password != null &&
          username.isNotEmpty && password.isNotEmpty) {
        return (username: username, password: password);
      }
    } catch (e) {
      if (kDebugMode) log('Error reading credentials: $e');
    }
    return null;
  }

  /// Only call on manual logout / account switch — NOT on session expiry logout
  Future<void> clearSavedCredentials() async {
    if(kDebugMode){
      log('Clearing saved credentials');
    }
    await _secureStorage.delete(key: _kSavedUsernameKey);
    await _secureStorage.delete(key: _kSavedPasswordKey);
  }
}
