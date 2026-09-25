# Team-lead tracking

## Use for
Supervisor summary, facility/bag list, urgency, status distribution, movement timeline/content drill-down.

## Canonical implementation
- `lib/features/team_lead/sample_live_tracking/view/live_tracking_view.dart`
- `lib/features/team_lead/sample_live_tracking/controller/live_tracking_controller.dart`
- `lib/features/team_lead/sample_live_tracking/services/live_tracking_service.dart`
- `lib/features/team_lead/sample_live_tracking/model/facility_model.dart`
- `lib/features/team_lead/sample_live_tracking/model/bag_model.dart`
- `lib/features/team_lead/sample_live_tracking/model/sample_flow_summary_flow.dart`
- `lib/features/team_lead/sample_live_tracking/model/get_bag_status_event_model.dart`

## Workflow (implementation)
Load user/date range -> parallel summary/facilities/bags -> local filtering/urgency/sorting.
GetSamplebagTrackingReport_inAppRBConnector types 1 summary, 3 facilities, 4 bags.
Drill-down GetBagDetails_Rb_trackingDahsboard types 1 timeline, 2 tube contents.
Facility card supplies facility code; bag-only drill-down supplies 0.
Drill-down uses fromDate as Visitdate; do not assume whole-range backend detail semantics.
Date change/pull refresh reloads API projections.

## Urgency
FacilityModel uses backend STD_TAT_TIME (default 3h), measured TAT or parsed TimeElapsed.
Warning at 70%; breach strictly above target; completed/late status derived separately.
This is not runner TatHelper policy.
C13 future runner timing does not authorize changes to team-lead calculations.
C14: preserve local IST behavior.

## Product scope
C19: notifications/background processing are not implemented.
'Live tracking' means current refreshable views here, not evidence of FCM, WebSockets or continuous backend GPS streaming.
Queue GPS START/END and in-screen map stream belong to [orders](orders-and-collection.md).

## Gaps / smallest change
Some failures become empty bags; elapsed-string parsing is limited. G18 records observations.
Do not invent backend metrics, enum permissions or polling schedules.
When changing, test affected projection parsing/filter/urgency/drill-down behavior using existing service seams.
