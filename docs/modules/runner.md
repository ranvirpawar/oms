# Runner bag custody

## Use for
Destination/empty bag, whole-bag pickup, source/destination transfer, collected sessions, recipient list, handover, lab submission.

## Canonical source
- `lib/features/runner_boy/collect_empty_bag/controller/collect_destination_bag_controller.dart`
- `lib/features/runner_boy/collect_empty_bag/service/bag_service.dart`
- `lib/features/runner_boy/collect_empty_bag/view/collect_destination_bag.dart`
- `lib/features/runner_boy/collect_from_phlebotomist/controller/collect_bag_from_phlebo_controller.dart`
- `lib/features/runner_boy/collect_from_phlebotomist/service/collect_bag_service.dart`
- `lib/features/runner_boy/collect_from_phlebotomist/model/qr_bag_detail.dart`
- `lib/features/runner_boy/collect_from_phlebotomist/view/collect_bag_from_phlebo.dart`
- `lib/features/runner_boy/collected_sample_bags/controller/collected_bags_controller.dart`
- `lib/features/runner_boy/collected_sample_bags/service/collected_bags_service.dart`
- `lib/features/runner_boy/collected_sample_bags/model/collected_bag_model.dart`
- `lib/features/runner_boy/collected_sample_bags/model/connector_model.dart`
- `lib/features/runner_boy/collected_sample_bags/view/collected_bags_view.dart`
- `lib/features/runner_boy/collected_sample_bags/view/handover_bag_view.dart`
- `lib/features/runner_boy/collected_sample_bags/controller/collected_bags_extension.dart`

## Workflows (implementation)
- Empty: scan/manual -> shared assignment check -> InsertStartQRCodeBegEvent process 1.
- Whole pickup: GETQRBagCount type 1 -> closed bag required -> InsertQRBagSession_Event process 5.
- Transfer: source type 1 with tubes -> destination type 2, different/open -> InsertTransferSample_to_QRBag.
- Collected list: GetCollectedQRBagDetails -> select SessionIDs -> submit each selected session.
- SubmitQRBagToLabOrHandover type 1: lab, recipient defaults current user.
- Type 2: chosen recipient, payload key HanoverUserid.
- Sequential batch: progress/error per bag, partial success, then refreshed list.

## Product rules
C12: backend owns transfer rules. Preserve current client checks; do not invent/duplicate capacity/custody enforcement.
C11: current designation value fetches phlebotomist list; preserve implementation.
Source names say Connector/runnerBoyList and request designation '3'; these names are not authority to reinterpret recipient permissions.
See G10 for explicit source/product naming difference.
C10: phlebotomist direct lab path remains valid outside runner workflow.

## State and identity
Separate CollectBagState, TransferStep and SubmissionState from bag lifecycle.
selectedSessionIds is RxSet<int>; do not change selection to bag ID/code.
Transfer sends both source/destination session IDs and physical bag IDs.
QRBagCountDetail parses closed status from '1'; preserve endpoint-specific parsing.
Do not treat a local success UI as proof of backend transaction semantics.

## Runner TAT — Deferred (C13)
**Product current:** runner TAT is not shown in UI.
**Source:** _TatStrip invocation in active bag card and _AttentionBanner/_FilterBar in the main view are commented out. TatHelper/controller/filter/color code remains.
Retained helper evaluates 3 hours from QRBag.collectedAt, due-soon at 150 minutes, overdue at 180; empty bags have no TAT.
QRBag.collectedAt prefers Createdon, falling back to Collecteddate/current time.
**Product future:** base TAT on sample-collected time inside bag, not pickup time.
Not a current priority. Do not activate hidden display, change timestamps, or add new aggregation rules now.
Multiple samples' timestamp selection is Deferred/Unknown until implementation requirement.
Do not use runner helper as the business policy for [team tracking](tracking.md).
Residual UI/filter references versus product statement are recorded in G11.

## Change scope / tests
Reuse current services/scanner lifecycle and batch response handling.
Add tests for affected scan/transfer requests, server rejection, session selection and partial batch outcomes.
Do not write new TAT functionality or recipient authorization semantics incidentally.
See [KNOWN_GAPS](../KNOWN_GAPS.md) G10/G11/G15/G18.
