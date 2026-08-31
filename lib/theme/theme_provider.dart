
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends GetxController {
  static ThemeProvider get to => Get.find<ThemeProvider>();

  // Theme mode observable
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;

  // Theme data getters
  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  // Current theme based on theme mode
  ThemeData get currentTheme =>
      _themeMode.value == ThemeMode.light ? lightTheme :
      _themeMode.value == ThemeMode.dark ? darkTheme :
      Get.isPlatformDarkMode ? darkTheme : lightTheme;

  // Is dark mode active
  bool get isDarkMode =>
      _themeMode.value == ThemeMode.dark ||
          (_themeMode.value == ThemeMode.system && Get.isPlatformDarkMode);

  // Storage key
  static const String _themeModeKey = 'theme_mode';

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  // Load theme mode from local storage
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);

    if (savedThemeMode != null) {
      switch (savedThemeMode) {
        case 'light':
          _themeMode.value = ThemeMode.light;
          break;
        case 'dark':
          _themeMode.value = ThemeMode.dark;
          break;
        default:
          _themeMode.value = ThemeMode.system;
      }
    }
  }

  // Save theme mode to local storage
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;

    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'system';
    }

    await prefs.setString(_themeModeKey, themeModeString);
  }

  // Change theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    _saveThemeMode(mode);
  }

  // Toggle between light and dark mode
  void toggleThemeMode() {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }
}