# UI retrieval and preservation

## Active system
`lib/theme/app_theme.dart`: Material 3/Inter.
`lib/theme/app_colors.dart`: blue/teal and semantic tokens.
`lib/theme/theme_provider.dart`: GetX theme preference.
Roots currently supply light theme; do not assume complete dark-mode support.
Local inline styles and shared tokens coexist. Preserve adjacent screen conventions rather than redesigning them.

## Reuse before adding
- `lib/utils/widgets/custom_appbar.dart`: title/search/actions.
- `lib/componenents/otp_boxes_input.dart`: OTP ownership, digit filtering, autofill, callbacks.
- `lib/utils/widgets/metrics_strip.dart`: summary metrics.
- `lib/features/phlebotomist/patient_queue/view/widgets/queue_action_button.dart`: action/busy styles.
- `lib/features/phlebotomist/patient_queue/view/widgets/queue_calendar_sheet.dart`: date-range selection (also dashboard).
- `lib/features/phlebotomist/patient_queue/view/widgets/rescheduled_slot.dart`: callback-driven form/OTP sheet.
- `lib/features/phlebotomist/sample_collection/view/widgets/incomplete_bottom_sheet.dart`: draft selection/reconciliation.
- `lib/features/phlebotomist/sample_collection/view/widgets/bag_context_card.dart`: shared active-bag context.
- `lib/utils/ui_designs/liquid_snackbar.dart`: feedback.
- `lib/services/snackbar_service.dart`: compatibility facade, not a second notification backend.

## State rendering references
`lib/features/phlebotomist/patient_queue/view/patient_queue_view.dart`:
explicit initial/loading/error/empty/loaded states; retry; refresh; scrollable empty state.
`lib/features/phlebotomist/sample_collection/view/order_confirmation_screen.dart`:
status gates -> loading/error -> bag/order content -> confirm action.
`lib/features/phlebotomist/sample_collection/view/sample_collection_screen.dart`:
sample entries, complications, notes, submission state.
Agent rule: inspect controller guards as well as disabled buttons; they are not always equivalent.

## Ownership
Bindings resolve GetView controllers; some older screens Get.put directly.
Text/scanner/animation handles require their existing lifecycle cleanup.
Incomplete sheet owns a draft, returns a complete map; dismissal should not imply confirmation.
Shared barcode tube rows are intentional (C04); do not split into unique barcode fields.
Preserve local haptics/animations unless relevant to the task.

## Scope
Android/iOS only (C20), portrait roots; do not infer responsive desktop support.
No universal pagination example exists; builder-based lists are not pagination.
No notification/background infrastructure (C19).
TAT strip is hidden; retained helpers are not permission to activate it (C13).
Examples with known import/lifecycle issues require source verification; see [KNOWN_GAPS](KNOWN_GAPS.md).
