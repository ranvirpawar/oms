import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/migration/core/auth/auth_state.dart';
import 'package:lifenity_connect/migration/core/failure/failure.dart';
import 'package:lifenity_connect/network/app_error.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

void main() {
  group('Failure.fromAppError', () {
    test('maps each transport error to the right FailureKind', () {
      const cases = <(AppError, FailureKind)>[
        (NoInternetError(), FailureKind.network),
        (TimeoutError('timed out'), FailureKind.timeout),
        (TlsError('tls'), FailureKind.security),
        (ForbiddenError('no'), FailureKind.forbidden),
        (NotFoundError('404'), FailureKind.notFound),
        (ConflictError('conflict'), FailureKind.conflict),
        (ServerError('500'), FailureKind.server),
        (ResponseParsingError('bad json'), FailureKind.parse),
        (RequestCancelledError(), FailureKind.cancellation),
        (UnknownError('boom'), FailureKind.unknown),
      ];

      for (final (error, kind) in cases) {
        final failure = Failure.fromAppError(error);
        expect(failure.kind, kind, reason: 'for ${error.runtimeType}');
        expect(failure.isSessionTerminal, isFalse,
            reason: '${error.runtimeType} must not be session-terminal');
      }
    });

    test('marks UnauthorizedError as session-terminal', () {
      final failure =
          Failure.fromAppError(const UnauthorizedError('expired'));
      expect(failure.kind, FailureKind.unauthorized);
      expect(failure.isSessionTerminal, isTrue);
      expect(failure.statusCode, 401);
    });

    test('marks SessionExpiredError as session-terminal', () {
      final failure = Failure.fromAppError(const SessionExpiredError());
      expect(failure.kind, FailureKind.sessionExpired);
      expect(failure.isSessionTerminal, isTrue);
    });

    test('preserves field errors and retry-after', () {
      final validation = Failure.fromAppError(const ValidationError(
        'invalid',
        {'email': ['bad']},
      ));
      expect(validation.kind, FailureKind.validation);
      expect(validation.fieldErrors['email'], ['bad']);

      final limited = Failure.fromAppError(const RateLimitedError(
        'slow down',
        retryAfter: Duration(seconds: 5),
      ));
      expect(limited.kind, FailureKind.rateLimited);
      expect(limited.retryAfter, const Duration(seconds: 5));
    });
  });

  group('AuthState', () {
    test('equality compares status, role, and userData', () {
      const a = AuthState.authenticated(
        role: UserRole.phlebotomist,
        userData: {'name': 'x'},
      );
      const b = AuthState.authenticated(
        role: UserRole.phlebotomist,
        userData: {'name': 'x'},
      );
      const c = AuthState.authenticated(role: UserRole.paramedic);
      expect(a, b);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });

    test('status helpers reflect the lifecycle', () {
      expect(const AuthState.unknown().isUnknown, isTrue);
      expect(const AuthState.unknown().isAuthenticated, isFalse);
      expect(
        const AuthState.authenticated().isAuthenticated,
        isTrue,
      );
      expect(
        const AuthState.unauthenticated().isAuthenticated,
        isFalse,
      );
    });
  });
}
