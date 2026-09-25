# Bag sessions, capacity, contents and history

## Use for
Manage bags, scan/open/close/reopen, active bag, capacity, collected orders, history/available bags, phlebotomist direct lab submission.

## Canonical source
- `lib/features/phlebotomist/bag_status_dashboard/controller/registrarion_bag_controller.dart`
- `lib/features/phlebotomist/bag_status_dashboard/controller/patient_list_controller.dart`
- `lib/features/phlebotomist/bag_status_dashboard/service/bag_registration_service.dart`
- `lib/features/phlebotomist/bag_status_dashboard/model/qr_bag_session.dart`
- `lib/features/phlebotomist/bag_status_dashboard/model/qr_bag_details.dart`
- `lib/features/phlebotomist/bag_status_dashboard/model/active_bag_model.dart`
- `lib/features/phlebotomist/bag_status_dashboard/view/bag_registration_dashboard.dart`
- `lib/features/phlebotomist/bag_status_dashboard/view/scan_bag_page.dart`
- `lib/features/phlebotomist/bag_status_dashboard/view/widget/bag_detail_view.dart`
- `lib/features/phlebotomist/bag_status/controller/bag_status_controller.dart`
- `lib/features/phlebotomist/bag_status/service/bag_status_service.dart`
- `lib/features/phlebotomist/bag_status/model/bag_status_model.dart`
- `lib/features/phlebotomist/sample_collection/controller/bag_context_mixin.dart`
- `lib/constants/bag_process_ids.dart`

## Product invariants
C03: capacity holds tubes; PatientCOunt is backend tube count; SpaceVacant is available space/count.
Preserve all backend names/casing.
C10: phlebotomist-assigned bags may be submitted directly to lab. Do not add a mandatory runner step.
Physical bag ID/code and session ID are distinct; never replace session identity with barcode alone.

## Implementation workflow
Load user -> GetUserwiseQRBagSession -> open-session detail requests.
activeBag is first open session; BagCloseStatus 0 means open.
Open scanned code -> assignment check -> close active session if present -> start process 2 -> store new session/details.
Close -> process 3 -> update local status/remove details cache.
Reopen -> close different active bag -> process 2 -> reload details.
Assignment check reads output row Status/Message; preserve response handling.

## State and API
BagRegistrationController owns allSessions and bagDetailsMap keyed by bag ID.
ensureSessionsLoaded coordinates initial loading and fresh open-bag details.
GetActiveQRBagSessions supports contents selection; GetRegistrationDetails_QRBag returns joined projections.
PatientOrder.fromResponse joins registration/test/barcode collections by SampleCollectionOrderID.
BagDetailView uses sessionId/bagId/bagcode arguments and a tagged PatientListController.
Direct lab submit uses process 100 through PatientListController.
History groups nonavailable transactions by Bagcode newest-first; exact CurrentStage 'Available assign' is separated.

## Cross-module rules
Collection must use shared HasBagContext and refresh bag state after successful submit.
Runner pickup/transfer is in [runner](runner.md); lab acceptance in [lab-accession](lab-accession.md).
Do not confuse direct process 100 with runner submission type 1.

## Change scope / gaps
Preserve close-then-open behavior; separate requests do not prove atomic backend transactions.
Capacity unit is answered, not Unknown; implementation counting mismatch remains G04.
Details cache/session lifecycle and incorrect imports are observations G03/G15.
Do not refactor compatibility getters or normalize IDs as unrelated cleanup.
Add scoped tests for request sequencing, identity, capacity-related requested behavior and content joins.
