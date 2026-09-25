# Recollection — incomplete / future functionality

## Product status C16
Do not focus on recollection now. It is not yet developed/product-complete.
Existing routes, views, controllers and services are partial source, not a completed supported workflow.
Do not expand, redesign or finish it without an explicit requirement.

## Retrieval only
Keywords: recollection, rejected tests, Visitcode, replacement barcode, accept/deny.
- `lib/features/phlebotomist/sample_recollection/controller/sample_recollection_controller.dart`
- `lib/features/phlebotomist/sample_recollection/controller/recollection_tests_controller.dart`
- `lib/features/phlebotomist/sample_recollection/service/sample_recollection_service.dart`
- `lib/features/phlebotomist/sample_recollection/model/test_recollection_model.dart`
- `lib/features/phlebotomist/sample_recollection/model/rejected_tests_model.dart`
- `lib/features/phlebotomist/sample_recollection/view/sample_recollection_list_view.dart`
- `lib/features/phlebotomist/sample_recollection/view/recollection_test_selection_view.dart`

## Existing implementation (not product completion)
Facility/date list requests: pending 2, accepted 1, denied 3.
Groups by order ID; accepted grouping prefers replacement barcode.
Rejected tests fetched using Visitcode.
Accept/deny payload uses JSON-encoded MobileEntrySampleCollection, ServiceCode, NewOrderID and IsRecollectionBy.
Code has sugar-service restrictions (969/970/971) and differing select-all logic.
Do not generalize these constants to normal sample collection.

## Change boundary / unknowns
Preserve existing code if touching an explicitly requested narrow issue.
No bag-context linkage or complete operational lifecycle is established.
Requirements, clinical rationale, final selection rules and integration into custody are Deferred.
Do not ask C16 again; ask only for requirements necessary to a future explicit recollection task.
G12 in [KNOWN_GAPS](../KNOWN_GAPS.md) records audit-source versus product-completion distinction.
