# Active architecture and ownership

## Implementation
- Dev root: `lib/dev_main.dart`; normal route helpers: `lib/routes/route_manager.dart`.
- GetX view/Obx -> GetxController -> feature service -> `lib/network/api_client.dart` -> backend.
- Feature services combine request construction, response interpretation, and model parsing. No uniform repository/use-case layer exists.
- Controllers own business orchestration, reactive collections, form/scanner handles, navigation, and feedback.
- Some services also show feedback. Do not silently move responsibilities during unrelated work.
- Riverpod ProviderScope wrappers do not establish a feature-provider architecture.
- BLoC/migration is excluded by C02; see [migration policy](MIGRATION_STATUS.md).

## Startup and DI
Dev initializes environment, orientation/theme, AuthManager, SessionCoordinator, APIClient, and session-expiry feedback.
Startup also contains an existing migration hook: leave it alone.
- `lib/features/auth/binding/login_binding.dart`: login service/controller factories.
- `lib/features/phlebotomist/patient_queue/binding/patient_queue_binding.dart`: service injection and collection-mode parsing.
- `lib/features/phlebotomist/sample_collection/binding/sample_collection_binding.dart`: typed patient/order inputs.
Other screens register controllers with Get.put; services often resolve APIClient with Get.find.
Agent rule: preserve the local feature's lifecycle/registration contract; do not add a competing DI system.

## Cross-module state
- `lib/services/auth_manager.dart`: persisted session + cached token/identity/role.
- `lib/services/user_service.dart`: user/profile access.
- `lib/features/phlebotomist/sample_collection/controller/bag_context_mixin.dart`: resolves shared BagRegistrationController.
- Bag controller owns sessions and bag-ID detail cache. Collection refreshes it after success.
- `lib/features/dashboard/dashboard_controller/dashboard_controller.dart`: route-pop observer refreshes metrics.
- Queue refreshes server order data after actions; filters are derived locally.
- Reschedule and incomplete-selection sheets retain local draft state until confirmation.

## Navigation contracts
Get.to/off/offAll with widget constructors; no central declarative/named-route guard architecture.
RouteManager handles main destinations; feature controllers/views also navigate directly.
Typed collection bindings are the reference for new inputs within this pattern.
Bag detail uses map arguments sessionId/bagId/bagcode and a tagged PatientListController.
Profile requires loggedInUser despite a nullable routing surface.
Do not infer backend authorization from a visible tile or route.

## Representative traces
- Queue view -> PatientQueueController -> PatientQueueService -> AssignedPatient -> Rx load/list state -> Obx.
- SampleCollectionScreen -> SampleCollectionController -> SampleCollectionPayload -> SampleCollectionService -> submission result -> success/retry UI.
- AcceptBagInLabView -> AcceptBagInLabController -> LabAccessionService -> scan/details models -> Rx state.
Exact file paths are in the corresponding [module pages](INDEX.md).

## Change boundary
Agent rule: use existing GetX/service patterns and make the smallest task-scoped change.
Known bootstrap, lifecycle, and error inconsistencies are [observations](KNOWN_GAPS.md), not a refactor backlog authorization.
