# Product decisions and behavior-preservation rules

This is the canonical decision register from the product clarification of 2026-09-25.
All 21 answers are retained below. IDs are stable retrieval keys.
Implementation remains source-authoritative; these decisions establish clarified business meaning.
Do not re-question an answered decision without a new requirement or new material evidence.

## C01 — Release baseline
Use dev as the current working/development baseline.
The same code/features are currently used across flavors.
Do not treat production bootstrap gaps as a reason to change current development implementation.
Owner: [CONFIGURATION](CONFIGURATION.md). Implementation differences: G01.

## C02 — Migration architecture
Do not work on lib/migration. Keep migration code untracked/out of scope.
Do not design new features around migration architecture.
Document active architecture from the currently working implementation.
BLoC/migration does not need to be considered for current OMS development.
Owner: [MIGRATION_STATUS](MIGRATION_STATUS.md).

## C03 — Bag capacity
Capacity = total capacity of the bag to hold tubes.
PatientCOunt is an existing backend field/key; the backend provides the tube count.
SpaceVacant = currently available bag space/count.
Preserve existing backend naming and casing.
Owners: [DOMAIN_MODEL](DOMAIN_MODEL.md), [bags](modules/bags.md).

## C04 — Tube/barcode semantics
Shared barcodes across different tube types are intentional.
Extra tubes are intentional according to requirements.
Do not correct or normalize this behavior.
Agent rule: preserve shared barcode behavior; do not deduplicate barcodes across tube types unless explicitly requested.
Owner: [orders-and-collection](modules/orders-and-collection.md).

## C05 — Fully incomplete collection
Requirements are currently limited.
Do not spend time redesigning this behavior now.
Incorporate/expand it later when the requirement is defined.
Owner: [KNOWN_GAPS](KNOWN_GAPS.md), G05. Status: Deferred; no current implementation action.

## C06 — LIS status
For now, OrderStatusID 6 represents the relevant LIS synchronization condition.
Do not redesign this unless explicitly requested later.
Owner: [STATUS_MACHINES](STATUS_MACHINES.md). Legacy helper divergence: G06.

## C07 — DISHA failure / synchronization
Collection and synchronization are currently handled.
Do not spend implementation effort redesigning this now.
Deeper idempotency/recovery improvements may be documented as future/known gaps.
Owner: [orders-and-collection](modules/orders-and-collection.md), G07.
Status: preserve current behavior; deeper recovery Deferred.

## C08 — Clinic workflow
Clinic orders directly start collection.
When a clinic order is accepted, the backend changes its status to arrived.
Clinic workflow does not need the normal START/END travel flow.
Agent rule: consume the refreshed backend Arrived state; do not add clinic travel steps.
Owner: [orders-and-collection](modules/orders-and-collection.md), G08.

## C09 — Concurrent routes
Currently handled at application level.
Server-side enforcement may be considered a future optimization.
Do not change current behavior.
Owner: [orders-and-collection](modules/orders-and-collection.md), G09.

## C10 — Direct lab submission
Phlebotomist-assigned bags can directly be submitted to the lab.
Do not require an invented runner handover step for this path.
Owners: [bags](modules/bags.md), [lab-accession](modules/lab-accession.md).

## C11 — Handover designation
The designation value is currently used to fetch the phlebotomist list.
Preserve the existing implementation.
Do not reinterpret numeric designation values from controller/model names alone.
Owner: [runner](modules/runner.md). Naming difference: G10.

## C12 — Bag transfer
Bag transfer rules are handled server-side.
Do not duplicate or invent client-side enforcement.
Preserve current client checks; do not remove them as an incidental change.
Owner: [runner](modules/runner.md).

## C13 — Runner TAT
Runner TAT is not currently shown in the UI.
Intended future behavior: TAT should be based on sample-collected time inside the bag, not bag pickup time.
This is future development and not a current priority.
Document the distinction between retained code and intended future behavior.
Owner: [runner](modules/runner.md), G11. Status: Deferred; do not activate/rebase TAT now.

## C14 — Time zones
Use local IST behavior.
Do not introduce timezone normalization unless explicitly requested.
Owners: [API_CONVENTIONS](API_CONVENTIONS.md), [CONFIGURATION](CONFIGURATION.md).

## C15 — Fasting
Current fasting behavior/semantics are intentional.
Preserve the existing implementation.
Owner: [orders-and-collection](modules/orders-and-collection.md).
Do not turn advisory acknowledgment into an invented blocking rule.

## C16 — Recollection
Do not focus on recollection now.
It is not yet developed.
Document it as future/incomplete functionality where relevant.
Owner: [recollection](modules/recollection.md), G12.
Existing source is not evidence of product-complete functionality.

## C17 — Authorization
The backend authorization enum is configured in the app.
Login returns the authorization value.
The app renders features based on that value.
Do not invent additional permission semantics absent from implementation.
Owner: [AUTH_AND_ROLES](AUTH_AND_ROLES.md).

## C18 — OTP/session
No final additional product decision has been made yet.
Preserve current implementation.
Document unresolved questions instead of inventing rules.
Owner: [AUTH_AND_ROLES](AUTH_AND_ROLES.md), G13.

## C19 — Notifications/background work
Not implemented currently.
Do not assume infrastructure exists because of constants, widgets, or references.
Owners: [ARCHITECTURE](ARCHITECTURE.md), [tracking](modules/tracking.md).

## C20 — Platform support
Current target platforms are Android and iOS only.
Do not treat web/desktop scaffolding as supported production targets.
Owner: [CONFIGURATION](CONFIGURATION.md).

## C21 — Testing
Product reports no tests yet written for main OMS workflows.
Going forward, tests should be written when modifying/working on modules.
Include appropriate unit tests, logic tests, and workflow tests.
Follow existing project architecture/patterns; do not introduce a separate testing architecture.
Owner: [TESTING](TESTING.md).

## Additional confirmed implementation rules
Verify source before changes; these do not add product requirements.
- Queue collection mode filters Arrived orders; emergency priority sorts first.
- Barcode format: JAA + 7-9 digits; per-sample barcode availability is checked.
- Sample entries must be collected or fully unusable before submit.
- Opening/reopening a different bag closes the active bag first.
- Runner batch submission reports per-bag failures/partial success.
Canonical sources and edge cases: [orders](modules/orders-and-collection.md), [bags](modules/bags.md), [runner](modules/runner.md).
