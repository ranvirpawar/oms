class AppEnvironment {
  static bool _isBeta = false;

  // Call this once at app start
  static void setBeta() => _isBeta = true;
  static void setProduction() => _isBeta = false;

  static bool get isBeta => _isBeta;
  static bool get isProduction => !_isBeta;
}