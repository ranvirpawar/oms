import 'dart:async';

import '../services/auth_manager.dart';


class SessionCoordinator {
  SessionCoordinator(this._authManager);

  final AuthManager _authManager;

  final _events = StreamController<SessionEvent>.broadcast();
  Stream<SessionEvent> get events => _events.stream;

  bool _sessionExpiredEmitted = false;
  bool _loggingOut = false;

  /// Bumped on every logout/login — repositories can stamp a request
  /// with this value at start time and discard the result if it no
  /// longer matches by the time the response arrives (guards against a
  /// slow response updating UI after the user already logged out).
  int _generation = 0;
  int get currentGeneration => _generation;

  /// APIClient calls this to build the Authorization header.
  /// AuthManager.getToken() is already synchronous (cached in memory)
  /// — wrapped in Future only so it satisfies the same async signature
  /// APIClient expects.
  Future<String?> currentAccessToken() async => _authManager.getToken();

  /// APIClient calls this exactly once per request when it gets a 401.
  /// Returns false ALWAYS — there is no refreshed token to retry with in
  /// this app, so every 401 is terminal. What this method guarantees is
  /// that the terminal action (logout + one "session expired" event)
  /// happens exactly once no matter how many requests hit 401 at the
  /// same moment.
  Future<bool> handleUnauthorized({String? requestId}) async {
    if (_loggingOut) return false; // a teardown is already happening — don't pile on

    if (!_sessionExpiredEmitted) {
      _sessionExpiredEmitted = true;
      _loggingOut = true;
      _events.add(const SessionExpired());
      try {
        // clearCredentials: false — this is an auto-logout from an
        // expired session, not the user tapping "Sign out". Matches the
        // distinction already documented on AuthManager.logoutUser().
        await _authManager.logoutUser(clearCredentials: false);
      } finally {
        _generation++;
        _loggingOut = false;
      }
    }

    return false; // never retry — no refresh path exists
  }

  /// Call this once, right after a successful login (alongside your
  /// existing `saveLoginResponseModel` / `loginUser` call) so the next
  /// session gets its own fresh "session expired" guard instead of
  /// inheriting the previous session's already-fired flag.
  void notifyLoginSuccess() {
    _sessionExpiredEmitted = false;
    _generation++;
    _events.add(const LoggedIn());
  }
}

sealed class SessionEvent {
  const SessionEvent();
}

class SessionExpired extends SessionEvent {
  const SessionExpired();
}

class LoggedIn extends SessionEvent {
  const LoggedIn();
}