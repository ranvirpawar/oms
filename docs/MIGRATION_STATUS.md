# Migration exclusion policy

## Product decision C02
Do not work on `lib/migration`.
Keep migration code untracked and out of scope.
Do not design new features around migration architecture.
BLoC/migration does not need to be considered for current OMS development.
Document/use the current working GetX implementation.

## Existing references (context only)
`lib/dev_main.dart` and `lib/beta_main.dart` import a migration injector.
`.gitignore` excludes /lib/migration/.
A migration test exists at `test/migration/core/migration_core_test.dart`.
Normal `lib/routes/route_manager.dart` login routing uses GetX LoginScreenView/LoginBinding.
The previous audit found a local login BLoC/GetIt bridge, not an active replacement of normal routing.

## Agent rule
Do not scan, edit, track, activate, remove, or use migration as a canonical feature template for ordinary OMS work.
Do not fix ignored-source portability by adding migration to Git.
If a requested task is blocked by these references, report the concrete blocker; do not expand scope.
Explicit future user authorization is required to change this exclusion.
G02 in [KNOWN_GAPS](KNOWN_GAPS.md) preserves the existing source/deployment observation.
