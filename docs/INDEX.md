# Task -> module -> canonical source

Read [root guidance](../AGENTS.md) first. Source paths below and in documents are repository-relative unless linked otherwise.

## Task routing
- Login, OTP, session, role visibility, profile: [AUTH_AND_ROLES](AUTH_AND_ROLES.md).
- Queue, accept/reject, clinic/home visits, GPS, reschedule, collection, partial collection, LIS retry: [orders-and-collection](modules/orders-and-collection.md).
- Open/close/reopen bag, capacity, contents, history, direct lab submit: [bags](modules/bags.md).
- Empty bag, whole pickup, sample transfer, recipient handover, batch submit: [runner](modules/runner.md).
- Lab scan, facility/patient detail, acceptance: [lab-accession](modules/lab-accession.md).
- Supervisory summary, facility/bag tracking, urgency: [tracking](modules/tracking.md).
- Recollection references: [recollection](modules/recollection.md) (incomplete; not current development focus).
- ID/model meaning: [DOMAIN_MODEL](DOMAIN_MODEL.md).
- Status/process codes: [STATUS_MACHINES](STATUS_MACHINES.md).
- Transport/envelopes/errors: [API_CONVENTIONS](API_CONVENTIONS.md).
- DI/state/lifecycle: [ARCHITECTURE](ARCHITECTURE.md).
- Widgets/forms/scanners: [UI_PATTERNS](UI_PATTERNS.md).
- Flavor/build/platform: [CONFIGURATION](CONFIGURATION.md).
- Tests: [TESTING](TESTING.md).
- Odd behavior or contradiction: [KNOWN_GAPS](KNOWN_GAPS.md).
- Migration references: [MIGRATION_STATUS](MIGRATION_STATUS.md), exclusion policy only.

## Decision lookup
The complete answers are owned by [BUSINESS_RULES](BUSINESS_RULES.md).
- C01 dev baseline; C02 migration exclusion; C03 tube capacity; C04 shared barcodes/extra tubes.
- C05 incomplete collection deferred; C06 status 6 LIS condition; C07 synchronization preservation.
- C08 clinic acceptance -> backend Arrived; C09 app-level concurrent routes; C10 direct phlebotomist lab submission.
- C11 designation/list contract; C12 server-owned transfer validation; C13 runner TAT deferred.
- C14 local IST; C15 fasting intentional; C16 recollection incomplete.
- C17 login authorization/feature rendering; C18 OTP/session unresolved; C19 no background/notifications.
- C20 Android/iOS; C21 future module tests.

## Retrieval discipline
Read the selected module's canonical controller, service, model, and relevant view before changing behavior.
Follow cross-module links only when the task crosses that boundary.
Do not infer active functionality from dependencies, old comments, endpoint constants, or scaffold directories.
