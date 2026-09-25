# Domain and identifier rules

## Product meaning
- C03: Capacity is total tube capacity; backend `PatientCOunt` supplies tube count; SpaceVacant is available bag space/count.
- C04: barcodes shared across different tube types and extra tubes are intentional.
- C14: preserve local IST behavior.
Agent rule: do not rename backend keys to improve domain naming.

## Identity domains (do not interchange)
- Login response userId: login OTP verification identity.
- EmpCode: operational user identity used by many feature calls.
- Profile designation ID: numeric input for dashboard/other contracts.
- SampleCollectionOrderID: numeric internal collection order; queue id is its string form.
- OrderID: string order identifier used in collection URL paths/payloads.
- OMSOrderID: additional display identifier.
- PatientID: patient identity.
- OrderAssignDetailID: assignment identity used in tracking.
- BagID: physical bag; Bagcode: scanned/displayed code; SessionID: operational bag session.
- Visitcode and ServiceCode: recollection-specific identifiers, not assumed equivalent to normal collection IDs.

## Canonical models
- `lib/features/auth/model/login_response_model.dart`: LoginResponseModel/UserModel.
- `lib/features/auth/model/profile_model.dart`: richer profile/designation.
- `lib/features/phlebotomist/patient_queue/model/patient_queue_model.dart`: AssignedPatient, OrderTest, AvailableSlot, RescheduleReason.
- `lib/features/phlebotomist/sample_collection/model/sample_collection_models.dart`: requirements, tests/tube types, submission payload/result.
- `lib/features/phlebotomist/sample_collection/model/barcode_formatter.dart`: mutable SampleBarcodeEntry (despite filename).
- `lib/features/phlebotomist/sample_collection/model/pre_collection_checklist.dart`: checklist and answer types.
- `lib/features/phlebotomist/bag_status_dashboard/model/qr_bag_session.dart`: bag session/open flag.
- `lib/features/phlebotomist/bag_status_dashboard/model/qr_bag_details.dart`: capacity projection.
- `lib/features/phlebotomist/bag_status_dashboard/model/active_bag_model.dart`: bag contents.
- `lib/features/runner_boy/collected_sample_bags/model/collected_bag_model.dart`: runner QRBag projection.
- `lib/features/lab_technician/accept_handover_bag/model/bag_model_new.dart`: lab scan/details.
- `lib/features/lab_technician/accept_handover_bag/model/bag_details_extended_model.dart`: facility/patient details.

## Relationships
Order -> sample requirements -> tests -> tube types.
SampleBarcodeEntry owns one barcode and deduplicated tube-type rows plus manual extra rows.
Collection payload -> OrderID + user + bag ID + session ID + tube count + details/complications/incomplete tests.
PatientOrder.fromResponse joins registrationDetails/testDetails/barcodeDetails by SampleCollectionOrderID.
Runner selection is keyed by session ID, not physical bag ID.
Handover and accession are endpoint-specific projections/actions; no shared accession-number aggregate is established.

## Limits
Do not interpret requirement count as physical tube count; see G04 in [KNOWN_GAPS](KNOWN_GAPS.md).
Status domains are separate: [STATUS_MACHINES](STATUS_MACHINES.md).
Fully incomplete behavior remains limited/deferred (C05), not a new domain redesign task.
