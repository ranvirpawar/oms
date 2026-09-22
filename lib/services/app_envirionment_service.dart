import 'package:lifenity_connect/network/app_urls.dart';

class AppEnvironment {
  /// Defaults to live (production) so `main.dart` needs no explicit call.
  static Environment _environment = Environment.live;


  static void setDev() => _environment = Environment.dev;
  static void setBeta() => _environment = Environment.beta;
  static void setProduction() => _environment = Environment.live;

  static bool get isDev => _environment == Environment.dev;
  static bool get isBeta => _environment == Environment.beta;
  static bool get isProduction => _environment == Environment.live;
}
