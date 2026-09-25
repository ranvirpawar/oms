# Keep status domains separate

## Order status — implementation
Source: `lib/features/phlebotomist/patient_queue/model/patient_queue_model.dart`.
OrderStatusID: 1 Not Assigned; 2 Assigned; 3 Accepted; 4 On The Way; 5 Arrived;
6 Sample Collected; 7 Picked Up; 8 Accepted In Lab; 9 Processing; 10 Report Available;
11 Rescheduled; 12 Sample Rejected; 13 Received At LIS.
Parsing uses numeric OrderStatusID; unknown/missing IDs currently fall back to Assigned.
Downstream statuses are recognized; this does not imply this client implements processing/report creation.

## Product interpretation
- C06: status 6 is the relevant LIS synchronization condition for now. Preserve it.
- C08: accepting clinic orders makes the backend return Arrived (5); clinic directly enters collection.
- Home travel uses START/END tracking and refreshed backend states.
- Assignment rejection is not sample rejection.
- Do not redesign status parsing or add states without a requirement.

## Assignment status — separate contract
`lib/features/phlebotomist/patient_queue/service/patient_queue_service.dart`:
AssignStatusID 2 Accepted; 3 Rejected; 4 Rescheduled.
Do not substitute OrderStatusID values in this payload.

## Collection
`lib/features/phlebotomist/sample_collection/model/sample_collection_models.dart`:
- Sample entry: pending / collected / incomplete.
- Payload OrderStatusCode: COLLECTED / PARTIALLY_COLLECTED.
- Submission outcome: success / partialLisFailure.
Partial collection concerns incomplete tests; partialLisFailure concerns synchronization after saving.
C05/C07: preserve limited incomplete behavior and current sync handling.

## Bag event master
`lib/constants/bag_process_ids.dart`:
1 empty bag collected; 2 opened; 3 closed; 4 samples transferred;
5 whole bag collected; 6 handover; 7 submitted to lab; 8 accepted by lab;
100 direct phlebotomist lab submission.
`QRBagSession.bagCloseStatus == 0` means open.
Transfer and runner handover use dedicated endpoints; do not force every action through a numeric-event API.
C10: direct phlebotomist lab submission is intentional.

## Recollection (incomplete/future)
Existing endpoint types: pending 2, accepted 1, denied 3.
Do not confuse these with assignment/order/bag codes. See [recollection](modules/recollection.md).

## UI states
QueueLoadState, CollectBagState, TransferStep, SubmissionState and LoginStep track interaction progress.
They are not backend lifecycle enums.
Runner TAT code is retained/deferred; team-lead urgency is separate. See [runner](modules/runner.md) and [tracking](modules/tracking.md).

## Known divergence
isLisSyncFailed recognizes sampleCollected; needsDishaSync and older code/tests reference collect.
C06 controls business meaning. Do not opportunistically harmonize helpers; G06 in [KNOWN_GAPS](KNOWN_GAPS.md).
