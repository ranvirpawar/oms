# Development baseline and configuration

## Product decisions
C01: dev is current working/development baseline; same code/features across flavors.
Do not treat production bootstrap gaps as a reason to change development implementation.
C20: Android/iOS only; web/Linux/macOS/Windows are not supported production targets.
C14: local IST behavior; do not normalize time zones.
C02: migration remains untracked/out of scope even where startup references it.

## Source map
- `lib/dev_main.dart`, `lib/beta_main.dart`, `lib/main.dart`: entry points.
- `lib/network/app_urls.dart`: environment URLs and endpoint definitions.
- `lib/services/app_envirionment_service.dart`: UI environment flags (spelling intentional).
- `android/app/build.gradle`: flavors, SDK, version/signing configuration.
- `android/app/src/main/AndroidManifest.xml`: capabilities, network configuration.
- `android/app/src/dev/AndroidManifest.xml`, `android/app/src/beta/AndroidManifest.xml`: overlays.
- `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`: iOS configuration.
- `pubspec.yaml`, `pubspec.lock`: package constraints/resolution.
- `.vscode/launch.json`: local launch examples, ignored by Git.

## Dev launch reference
`flutter run --flavor dev -t lib/dev_main.dart`
Derived from launch/Gradle configuration; not a verified build result from documentation creation.
Do not run operational API actions merely to validate documentation.

## Implementation observations
Dev/beta register AuthManager, SessionCoordinator, APIClient and expiry feedback.
Production omits the API/session spine and has a placeholder primary API base.
AppUrls mixes getters and lazily initialized static strings; avoid runtime environment switching assumptions.
Android has production/dev/beta flavors. Equivalent iOS flavor schemes are not established by this audit.
Version values differ across pubspec, Android flavors and iOS plist; do not choose a new authority without a task.

## Sensitive configuration
Release signing loads `android/keystore.properties`; document location only, never its contents.
Embedded fixture credentials/native map keys exist; never copy values into docs/tests/log examples.
Dev/beta permissive certificate callbacks and Android cleartext settings are existing observations.
Do not change security/build configuration as part of an unrelated feature.
Open questions/action policy: [KNOWN_GAPS](KNOWN_GAPS.md).
