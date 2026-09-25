# API contracts and change rules

## Canonical transport
- `lib/network/api_client.dart`: Dio APIClient, ApiResult, getTyped, HTTP methods.
- `lib/network/app_error.dart`: typed transport failures.
- `lib/network/retry_policy.dart`: retry eligibility/backoff.
- `lib/network/session_coordinator.dart`: terminal 401 coordination.
- `lib/network/app_urls.dart`: endpoint/environment definitions.
Agent rule: use the existing client/service path; do not introduce another networking layer.

## Implementation
- Connect 20s; receive/send 30s; HTTP 200-299 accepted.
- Bearer token from SessionCoordinator -> AuthManager cached token.
- No refresh-token implementation; 401 triggers coordinated logout.
- Default retry policy allows up to 3 attempts for eligible methods/failures.
- POST is excluded by isMethodRetryable. Comments about opt-in do not override executable logic.
- Cancellation is supported by transport but not consistently used in features.
- Most services use untyped ApiResult and hand-written parsing.
- JSON is default; form/multipart support is not evidence of an active upload feature.
- No standard pagination/offline mutation queue is established.

## Envelope references
- Queue service: output list or single object; selected no-record failures become empty.
- Collection service: requirements output object; DISHA outcome evaluated separately from top-level status.
- Bag service/controller: opening output object; session listing output list.
- Bag content model: joins three top-level lists.
- Location service: nested A_testStatus/trackingResult acknowledgment.
Canonical files:
`lib/features/phlebotomist/patient_queue/service/patient_queue_service.dart`
`lib/features/phlebotomist/sample_collection/service/sample_collection_service.dart`
`lib/features/phlebotomist/bag_status_dashboard/service/bag_registration_service.dart`
`lib/features/phlebotomist/bag_status_dashboard/model/active_bag_model.dart`
`lib/features/phlebotomist/patient_queue/service/location_tracking_service.dart`

## Contract invariants
- Preserve endpoint-specific casing/spelling, including PatientCOunt, BagID/Bagid/bagId, HanoverUserid, RescheduleReasoneID.
- DISHA retry currently contains an `orderId ` key with trailing space. Do not normalize it incidentally.
- Some legacy payload fields contain JSON-encoded arrays inside JSON objects (recollection).
- Distinguish EmpCode, login userId, string OrderID, numeric SampleCollectionOrderID, BagID, SessionID.
- Use queryParameters where the relevant existing implementation does; do not rewrite unrelated URL construction.
- C14: retain local IST date/time behavior and endpoint-specific formats. No speculative UTC conversion.
- Preserve error identity when call sites need AppError.isSessionTerminal. Do not stack generic feedback over session-expiry feedback.
- Existing service-side feedback is a boundary inconsistency, not authorization to refactor it.

## Backend ownership
C12: transfer rules are server-owned; preserve current client guards without inventing more.
C17: do not infer permissions beyond returned authorization and existing rendering.
C07: deeper DISHA idempotency/recovery is Deferred.
C18: additional OTP/session rules remain Unknown.

## Date/filter behavior
Queue fetches bounded date ranges; visit/status/clinic/search filtering is local.
Bag and tracking lists are locally filtered/sorted after API fetches.
Do not invent pagination tokens or server-side sorting parameters.

## Configuration and observability
See [CONFIGURATION](CONFIGURATION.md) for dev baseline and flavor differences.
Debug logs can include response/user data. Never copy credentials, tokens, or patient fixtures into documentation.
Relevant observations: [KNOWN_GAPS](KNOWN_GAPS.md).
