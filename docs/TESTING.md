# Module testing expectations

## Product requirement C21
Product reports no tests yet written for main OMS workflows.
Existing limited tests do not establish workflow coverage.
Going forward, write appropriate unit, logic and workflow tests when modifying/working on modules.
Follow current Flutter/GetX/service patterns; do not introduce a separate architecture just for tests.
Agent rule: test the requested behavior and preservation-sensitive edges, not an unsolicited redesign.

## Existing references
- `test/features/phlebotomist/patient_queue/patient_queue_service_test.dart`: custom Dio HttpClientAdapter, canned envelopes through APIClient.
- `test/features/phlebotomist/patient_queue/patient_queue_controller_test.dart`: fake/recording services, GetX setup.
- `test/features/phlebotomist/patient_queue/patient_card_test.dart`: action callbacks.
- `test/features/auth/login_binding_test.dart`: binding resolution/widget setup.
- `test/componenents/otp_boxes_input_test.dart`: digits/autofill/ownership callbacks.
- `test/dashboard_summary_model_test.dart`: role-specific parsing, empty outcomes.
- `test/utils/helper_methods_test.dart`: pure helper behavior.

## Fixtures and isolation
Use synthetic non-sensitive IDs/data. Do not copy embedded credentials or operational patient data.
Reset GetX between tests; set up API/session prerequisites and preference mocks where needed.
Stub networking; no real OMS/LIS mutations.
Prefer existing constructor service seams or Dio adapter pattern.
Preserve field casing and distinguish IDs in fixtures.

## Known baseline limitations
- Older queue fixtures expect textual Collect, while active model uses numeric OrderStatusID.
- Use status 6 for relevant LIS condition (C06); do not regress implementation to satisfy stale tests.
- `test/widget_test.dart` is a counter template, not a valid OMS workflow specification.
- `test/migration/core/migration_core_test.dart` depends on excluded migration source. Do not modify migration to repair unrelated runs.
- No passing suite/build is asserted by these docs.

## Task-scoped coverage examples
- Queue: empty/error/refresh, action guard, numeric statuses, clinic accept -> mocked backend Arrived.
- Collection: shared barcodes, extra tube counts, incomplete reconciliation, payload, saved-vs-sync-failed outcomes.
- Bags: session identity, close/open request sequence, contents joins.
- Runner: server transfer rejection, selected sessions, mixed batch outcomes.
- Lab: scan -> detail requests -> process 8 -> reset/failure.
- Auth: binding/session-terminal behavior and intentional credential retention.
These are test targets when the associated module changes, not authorization to implement deferred functionality.
Do not activate runner TAT or expand recollection to write tests.

## Commands
Targeted example: `flutter test test/componenents/otp_boxes_input_test.dart`.
Broader checks as task-appropriate: `flutter analyze`, `flutter test`.
Report actual results; distinguish pre-existing failures. Commands were not executed during documentation creation.
