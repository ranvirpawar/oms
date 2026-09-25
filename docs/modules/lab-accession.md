# Laboratory bag acceptance

## Use for
Scan submitted bag, session lookup, facility/patient detail, acceptance/reset.

## Canonical implementation
- `lib/features/lab_technician/accept_handover_bag/view/accept_bag_in_lab_view.dart`
- `lib/features/lab_technician/accept_handover_bag/controller/accept_bag_in_lab_controller.dart`
- `lib/features/lab_technician/accept_handover_bag/service/lab_accession_api_service.dart`
- `lib/features/lab_technician/accept_handover_bag/model/bag_model_new.dart`
- `lib/features/lab_technician/accept_handover_bag/model/bag_details_extended_model.dart`
Reachability comes from `lib/routes/route_manager.dart`, not the new/old filename suffix.

## Workflow (implementation)
Scan/manual Bagcode -> GETScanQRBag -> SessionID.
Parallel Proc_GetQRBagDetails_ForLabTeam:
type 1 main details; type 2 facility summary; type 4 patients.
Local facility filter narrows displayed patients.
Accept -> InsertQRBagSession_Event process 8 -> feedback -> scanner reset.
Failed scan/details/accept retains or resets state according to controller; inspect exact branch before edits.
Service currently sends facilitycode '0' for detail requests; do not substitute a guessed lab identity.

## Product / invariants
C10: phlebotomist-assigned bags may arrive via direct lab submission (process 100), not only runner custody.
C17: features are rendered from returned authorization; do not add invented lab permissions.
Bag session ID is acceptance identity.
This module does not establish sample processing, rejection adjudication, report authoring or accession-number lifecycle.

## Cross-module
[bags](bags.md): direct submission; [runner](runner.md): type 1 submission/type 2 handover.
[STATUS_MACHINES](../STATUS_MACHINES.md): event 8 is not OrderStatusID 8 by interchangeable contract.
Do not reactivate old transaction-based handover/acceptance code.

## Scope / testing
Add relevant scan -> detail -> accept workflow tests and failure/reset tests when modifying.
C19: no background notification delivery is implied by acceptance.
Legacy source and lifecycle observations: [KNOWN_GAPS](../KNOWN_GAPS.md).
