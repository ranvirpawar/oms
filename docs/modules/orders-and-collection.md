# Orders and sample collection

## Use for
Queue, patient/order cards, clinic/home, accept/reject, route/arrival, reschedule, OTP, fasting checklist, barcode, tubes, partial collection, DISHA/LIS retry.

## Canonical source map
All paths repository-relative.
- `lib/features/phlebotomist/patient_queue/view/patient_queue_view.dart`
- `lib/features/phlebotomist/patient_queue/view/widgets/patient_card.dart`
- `lib/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart`
- `lib/features/phlebotomist/patient_queue/service/patient_queue_service.dart`
- `lib/features/phlebotomist/patient_queue/service/location_tracking_service.dart`
- `lib/features/phlebotomist/patient_queue/model/patient_queue_model.dart`
- `lib/features/phlebotomist/patient_queue/view/widgets/rescheduled_slot.dart`
- `lib/features/phlebotomist/sample_collection/binding/sample_collection_binding.dart`
- `lib/features/phlebotomist/sample_collection/controller/order_confirmation_controller.dart`
- `lib/features/phlebotomist/sample_collection/controller/sample_collection_controller.dart`
- `lib/features/phlebotomist/sample_collection/controller/bag_context_mixin.dart`
- `lib/features/phlebotomist/sample_collection/service/sample_collection_service.dart`
- `lib/features/phlebotomist/sample_collection/model/sample_collection_models.dart`
- `lib/features/phlebotomist/sample_collection/model/barcode_formatter.dart`
- `lib/features/phlebotomist/sample_collection/model/barcode_validator.dart`
- `lib/features/phlebotomist/sample_collection/model/pre_collection_checklist.dart`
- `lib/features/phlebotomist/sample_collection/view/order_confirmation_screen.dart`
- `lib/features/phlebotomist/sample_collection/view/sample_collection_screen.dart`
- `lib/features/phlebotomist/sample_collection/view/widgets/incomplete_bottom_sheet.dart`
- `lib/features/phlebotomist/sample_collection/view/widgets/sample_collection_success_page.dart`

## Workflow
Queue -> accept/reject -> refreshed backend order.
- **Product C08:** clinic acceptance makes backend status Arrived; clinic directly starts collection, no normal START/END travel.
- Home: accepted -> GPS START -> en route -> GPS END -> arrived.
- Collection: arrived -> requirements + shared bag -> patient OTP if needed -> backend checklist -> sample entries -> submit -> result/LIS retry.
No UI-local forced clinic status transition is required by this documentation.

## Queue rules (implementation)
Date window sent to server; visit/status/clinic/emergency/search filters applied locally.
Today, Mon-Sun week, future from tomorrow through next-month boundary, past 30 days, custom range.
Collection mode narrows to Arrived. Phlebotomist defaults home; other roles clinic.
Search: name/address/test. Emergency priority sorts first, then lifecycle/priority/slot.
processingIds guard per-order actions.
C09: concurrent-route control is app-level and intentionally retained; currently examines loaded window only.

## Collection invariants
- Requires shared open bag; use HasBagContext, not duplicated local bag state.
- Confirm UI checks full/insufficient bag capacity. Final validator differs: see G04.
- C03: PatientCOunt means tubes. Preserve backend key.
- C04: one sample barcode shared across tube-type rows and extra tubes is intentional.
- JAA + 7-9 digits; format/local duplicate checks -> debounced availability API; stale field responses ignored.
- Up to 3 manual extra tubes per sample entry; preserve existing tubeCount calculation.
- Incomplete sheet drafts per-test reasons/remarks; confirmation replaces the whole map; empty map clears flags.
- Each entry must be collected or fully unusable. Any incomplete tests -> PARTIALLY_COLLECTED payload.
- C05: fully incomplete requirements limited; do not redesign. G05 records payload observations.
- C06: order status 6 is relevant LIS condition. Do not revive legacy textual status parsing.

## OTP and checklist
Patient OTP is separate from login OTP; preserve exact `isOtpVerified == 'Yes'` gate.
Checklist fetch uses POST despite GET comments.
Existing nonempty answers for every checklist item skip repeat UI.
Fasting rows share meal time; existing min/max comparison and advisory acknowledgment are intentional (C15).
Do not reinterpret fastingDurationIN or introduce stronger clinical validation without requirement.
C14: local IST/date behavior. C18: additional OTP/session requirements Unknown.

## API ownership
PatientQueueService: orders/details; UpdateSampleOrderStatus (assignment 2/3/4); slots/reasons/reschedule OTP.
LocationTrackingService: START/END payload includes assignment ID, collection-order ID and GPS.
SampleCollectionService: requirements, barcode availability, collection OTP, checklist, collection submit, DISHA retry.
Payload carries OrderID, user, current BagID/SessionID, tube count, collected timestamp, complications, incomplete tests.
Preserve spelling/casing; see [API conventions](../API_CONVENTIONS.md).

## Save vs sync
Collection persistence and DISHA synchronization are distinct result dimensions.
Saved-but-LIS-failed is a soft result; retry uses dedicated backend endpoint, not original collection resubmission.
C07: current handling is considered handled; deeper idempotency/recovery Deferred.
Never invent backend transaction guarantees.

## Reschedule
Callback sheet offers today + 6 days, backend slots, mandatory reason, Other remark, conditional patient OTP.
Queue and active collection use assignment update; separate collection-service reschedule method remains.
Preserve task-local path; G17 records alternate contract.

## Cross-module / change scope
[Auth](../AUTH_AND_ROLES.md) provides EmpCode; [bags](bags.md) owns current session;
[statuses](../STATUS_MACHINES.md) defines distinct status domains.
Agent rule: inspect view + controller + service + model for affected action; preserve unrelated gates.
Add task-scoped unit/logic/workflow tests per [TESTING](../TESTING.md).
Known gaps G04-G09/G17 are not permission for broad fixes.
