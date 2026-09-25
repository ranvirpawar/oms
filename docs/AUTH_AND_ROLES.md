# Authentication, identity, authorization

## Use for
Login, four-digit OTP, session expiry, logout, profile, password recovery/change, role-specific dashboard visibility.

## Canonical implementation
- `lib/features/auth/controller/login_controller.dart`, `lib/features/auth/service/login_service.dart`, `lib/features/auth/binding/login_binding.dart`.
- `lib/features/auth/controller/splash_screen_controller.dart`.
- `lib/services/auth_manager.dart`, `lib/services/user_service.dart`.
- `lib/network/session_coordinator.dart`.
- `lib/features/dashboard/dashboard_controller/dashboard_controller.dart`.
- `lib/utils/widgets/app_drawer.dart`.

## Workflow (implementation)
Credentials -> Login -> OTP step -> VerifyLoginOtp -> save credentials/login response ->
notify session coordinator -> set role -> fetch/store profile -> dashboard.
Login OTP uses response userId; operational features generally use EmpCode.
requiresOtp exists in the model; current successful login handling proceeds to OTP.
Login resend cooldown is 30 seconds; collection OTP uses a separate 60-second timer.
Do not transfer rules between login, collection, recovery, and reschedule OTP flows.

## Session/persistence
- Secure storage: cached token backing and saved username/password.
- Preferences: complete user JSON, profile, role, login date, device info, mobile number.
- Login JSON also contains token: do not claim secure storage is its sole persisted location.
- Splash compares saved date to current device date.
- Automatic expiry/logout preserves credentials; explicit drawer sign-out clears them.
- 401 is terminal; no refresh implementation.
- Constructor auth initialization is asynchronous; do not assume it has completed simply because Get.put returned.
- Profile routing expects nonnull loggedInUser; inspect ProfileBinding before modifying navigation.

## Product rules
C17: backend authorization enum is configured in the app; login returns the authorization value; app renders features from it.
Implementation represents this through returned designation, UserRole parsing and dashboard switching.
Do not invent a separate ACL, additional permission hierarchy, or server guarantee.
C18: no final additional OTP/session product decision; preserve implementation. Rate limits, authoritative lockouts and future retention policy are Unknown.
C14: local IST behavior; no timezone normalization.
C02: use current GetX login, not migration login.

## Current feature rendering
- Phlebotomist / Paramedic / Nurse: orders, collection, bags, recollection references.
- Runner Boy: empty bags, pickup, handover, history.
- Lab Technician / Lab accession: acceptance/history.
- Team Lead: tracking.
Other enum values do not prove dedicated modules; inspect the fallback branch.
Visibility is not proof of server-side enforcement.
C16: recollection visibility/source does not make it product-complete.

## Password/profile
`lib/features/auth/controller/forgot_password_controller.dart`: mobile -> OTP/reset.
`lib/features/auth/controller/change_password_controller.dart`: old/new/confirmation validation.
`lib/features/auth/controller/profile_controller.dart`: cached profile presentation.
No administrative role/user management workflow is established here.

## Change scope and tests
Preserve successful-login order, binding resolution, credential-clearing distinction and session-terminal handling.
Add relevant service/controller/widget tests using [TESTING](TESTING.md).
Known issues (saved credentials after password change, auth checks, logging, default authenticated login requests): G13/G16 in [KNOWN_GAPS](KNOWN_GAPS.md); no unsolicited fixes.
