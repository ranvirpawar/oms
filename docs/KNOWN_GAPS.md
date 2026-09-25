# Known gaps, differences, and deferred decisions

## How to use
This is an observation register, not authorization to fix working behavior.
Implementation findings come from static source inspection; no passing build/test suite is asserted.
Product decisions C01-C21 are owned by [BUSINESS_RULES](BUSINESS_RULES.md).
Before a change, verify the cited source and act only within the requested scope.
Unknown means neither source nor product clarification establishes the answer.

## G01 — Flavor bootstrap difference
- Implementation: `lib/dev_main.dart` and `lib/beta_main.dart` register network/session infrastructure; `lib/main.dart` has a different bootstrap. `lib/network/app_urls.dart` includes an undeployed production URL.
- Product intent C01: dev is the working baseline; same code/features across flavors.
- Difference: intended feature parity does not establish equivalent startup wiring.
- Action: none now. Do not change development behavior to reconcile production bootstrap. Release-readiness requirements remain Unknown.

## G02 — Ignored migration dependency
- Implementation: dev/beta entry points reference migration; `.gitignore` excludes its directory; `test/migration/core/migration_core_test.dart` also depends on it.
- Product intent C02: keep migration untracked/out of scope; no BLoC-based feature development.
- Difference: local ignored source references create a potential clean-checkout portability dependency.
- Action: do not edit, track, activate, remove, or build features around migration. Report a concrete blocker if encountered. See [policy](MIGRATION_STATUS.md).

## G03 — Relative import observations
- Implementation: the audit found relative imports that resolve outside the intended lib path in bag-management code and `lib/utils/ui_designs/tap_menu.dart`.
- Source area: `lib/features/phlebotomist/bag_status_dashboard/controller/registrarion_bag_controller.dart`.
- Difference: static import observations are not a verified compiler result.
- Action: no unsolicited fix. Reverify the exact import/compiler diagnostic if it blocks a requested task.

## G04 — Capacity meaning versus calculation sites
- Implementation: bag selection/confirmation checks sample requirements; final tube totals also include extra/manual tube counts. See `lib/features/phlebotomist/sample_collection/controller/sample_collection_controller.dart` and `lib/features/phlebotomist/sample_collection/controller/bag_context_mixin.dart`.
- Product intent C03/C04: capacity and PatientCOunt mean tubes; SpaceVacant is available count; extra tubes/shared barcodes are intentional.
- Difference: different calculation sites must not be assumed to enforce the same final count. Backend acceptance behavior is not established by the client.
- Action: preserve naming and behavior. Do not invent new capacity enforcement or normalize extra tubes.

## G05 — Fully incomplete collection
- Implementation: entries may be resolved as fully unusable; payload inclusion uses nonempty barcode text. A barcode entry starts with a prefix. Sources: `lib/features/phlebotomist/sample_collection/model/barcode_formatter.dart`, `lib/features/phlebotomist/sample_collection/controller/sample_collection_controller.dart`.
- Product intent C05: requirements are limited; expansion is deferred.
- Difference: complete business treatment of a collection with no usable sample is not defined.
- Action: none now. Do not redesign validation/payload semantics; obtain requirements only when this behavior becomes the requested task.

## G06 — LIS status helpers and old fixtures
- Implementation: numeric OrderStatusID mapping and current card actions differ from legacy textual Collect expectations/helper concepts. Sources: `lib/features/phlebotomist/patient_queue/model/patient_queue_model.dart`, `lib/features/phlebotomist/patient_queue/view/widgets/patient_card.dart`, `test/features/phlebotomist/patient_queue/patient_queue_controller_test.dart`.
- Product intent C06: status 6 is the relevant LIS synchronization condition.
- Difference: older helpers/fixtures are not authoritative product semantics.
- Action: preserve status 6 behavior; do not redesign it or regress source to satisfy a stale fixture.

## G07 — DISHA recovery contract
- Implementation: collection interprets multiple response shapes, including a saved-but-sync-failed outcome; retry uses a backend key with a trailing space. Source: `lib/features/phlebotomist/sample_collection/service/sample_collection_service.dart`.
- Product intent C07: collection/synchronization are currently handled; no redesign.
- Unknown: backend idempotency guarantees, duplicate prevention and deeper recovery policy.
- Action: deferred. Preserve current response interpretation and request keys.

## G08 — Clinic acceptance and travel presentation
- Implementation: queue UI includes generic Accepted/START handling; actions reload backend state. Sources: `lib/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart`, `lib/features/phlebotomist/patient_queue/view/widgets/patient_card.dart`.
- Product intent C08: accepting a clinic order makes it Arrived on the backend; collection starts directly.
- Difference: comments/generic branches alone do not express that backend transition. A clinic order remaining Accepted would differ from the clarified contract.
- Action: no added clinic travel flow. Preserve refresh and test the backend Arrived response when changing this path.

## G09 — Concurrent routes
- Implementation: client checks loaded orders for active route/arrival/collection state; the loaded set is date-window bounded. Source: `lib/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart`.
- Product intent C09: app-level handling is current; server enforcement is a future optimization.
- Difference: client checks do not establish a server-wide concurrency guarantee.
- Action: preserve current behavior. Server enforcement Deferred.

## G10 — Recipient naming versus business meaning
- Implementation: getConnectorList, runnerBoyList, and Connector naming coexist with designation '3' and the phlebotomist-list endpoint. Sources: `lib/features/runner_boy/collected_sample_bags/service/collected_bags_service.dart`, `lib/features/runner_boy/collected_sample_bags/controller/collected_bags_controller.dart`, `lib/features/runner_boy/collected_sample_bags/model/connector_model.dart`.
- Product intent C11: designation is used to fetch the phlebotomist list; preserve implementation.
- Difference: local names must not be interpreted as a different recipient authorization contract.
- Action: no renaming or invented designation mapping/permission rules.

## G11 — Runner TAT remnants versus future clock
- Implementation: the active card's _TatStrip invocation and main-view _AttentionBanner/_FilterBar invocations are commented out; TAT helper/controller/filter/color code remains. QRBag.collectedAt prefers Createdon and falls back to Collecteddate/current time. Sources: `lib/features/runner_boy/collected_sample_bags/view/collected_bags_view.dart`, `lib/features/runner_boy/collected_sample_bags/controller/collected_bags_extension.dart`, `lib/features/runner_boy/collected_sample_bags/model/collected_bag_model.dart`.
- Product current C13: runner TAT is not shown in UI.
- Product future: use sample-collected time inside the bag, not pickup time; not a current priority.
- Difference: retained calculations must not be presented as the intended future sample-based clock. Residual colors/filter code do not authorize activating a TAT display.
- Unknown/Deferred: which sample timestamp to use when a bag contains multiple samples.
- Action: none now; do not activate or rebase TAT incidentally.

## G12 — Recollection source versus product completeness
- Implementation: views, controllers, endpoints and route references exist under `lib/features/phlebotomist/sample_recollection/`.
- Product intent C16: not yet developed; future/incomplete functionality; not current focus.
- Difference: source existence does not establish completed requirements or production readiness.
- Action: no expansion, cleanup or canonical new-feature use. See [recollection](modules/recollection.md).

## G13 — OTP/session decisions remain open
- Implementation: login proceeds to OTP; token-based and cached-user checks coexist; authentication initializes asynchronously. Login requests use the client's default auth behavior. Sources: `lib/features/auth/controller/login_controller.dart`, `lib/features/auth/service/login_service.dart`, `lib/services/auth_manager.dart`.
- Product intent C18: no final additional decision; preserve implementation.
- Unknown: authoritative OTP/lockout policy, session retention changes, password-change effects on saved credentials, server invalidation semantics.
- Action: record rather than invent requirements. Do not change these policies incidentally.

## G14 — Existing tests versus workflow coverage
- Implementation: limited helper/model/controller/widget tests exist; queue fixtures include older statuses and `test/widget_test.dart` is a counter template.
- Product C21: main workflows do not yet have product-confirmed test coverage; add appropriate unit/logic/workflow tests when working on modules.
- Difference: presence of test files is not evidence of end-to-end workflow coverage or a passing baseline.
- Action: testing is required as appropriate for future module changes. This documentation task adds no test/application code. See [TESTING](TESTING.md).

## G15 — State/lifecycle inconsistency
- Implementation: constructor-based AuthManager access, Get.find/Get.put patterns, asynchronous identity loading, cached bag details and differing request guards coexist. Sources: `lib/services/user_service.dart`, `lib/network/session_coordinator.dart`, `lib/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart`, `lib/features/phlebotomist/bag_status_dashboard/controller/registrarion_bag_controller.dart`.
- Unknown: race manifestation under a specific runtime sequence; static inspection does not prove a reproduced failure.
- Action: follow the module's canonical lifecycle. Reproduce and address only task-relevant behavior; no global state rewrite.

## G16 — Configuration and credential handling observations
- Implementation: development TLS override, request/response logging, persisted complete login JSON, and native integration configuration require care. Sources: `lib/dev_main.dart`, `lib/network/api_client.dart`, `lib/services/auth_manager.dart`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift`.
- Difference: token storage is not exclusively secure-storage-backed when login JSON also contains it.
- Unknown: final deployment hardening/credential-retention requirements.
- Action: do not copy credentials/tokens/configuration values into documentation or fixtures. Changes need a scoped task; do not alter working development behavior during unrelated work.

## G17 — Reschedule paths
- Implementation: queue action orchestration uses the assignment path while alternate/legacy service endpoint concepts coexist. Sources: `lib/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart`, `lib/features/phlebotomist/patient_queue/service/patient_queue_service.dart`.
- Unknown: whether unused alternatives remain supported backend contracts.
- Action: trace the active caller before modifying requests; do not switch endpoints or infer server behavior from constants alone.

## G18 — Fallback/error semantics
- Implementation: runner timestamps may fall back to current time; tracking services may return empty data on failure; runner handover can obtain location without transmitting it. Sources: `lib/features/runner_boy/collected_sample_bags/model/collected_bag_model.dart`, `lib/features/team_lead/sample_live_tracking/services/live_tracking_service.dart`, `lib/features/runner_boy/collected_sample_bags/view/handover_bag_view.dart`.
- Difference: empty UI is not always proof of an empty backend dataset; acquired GPS is not proof of server tracking.
- Action: preserve current contracts unless the requested change covers them. Do not claim background tracking/notifications (C19) or introduce timezone normalization (C14).
