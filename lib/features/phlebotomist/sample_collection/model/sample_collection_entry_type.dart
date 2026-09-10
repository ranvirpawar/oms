// sample_collection_entry_types.dart
//
// Pulled out of the old combined controller, where they lived as top-level
// declarations. `sample_collection_models.dart` needs `TestIncompleteInfo`
// for `SampleBarcodeEntry.testIncompleteMap`, and previously got it by
// importing the *controller* file — a circular import (controller -> models,
// models -> controller) that only worked because Dart tolerates import
// cycles. Giving these two types their own file removes the cycle entirely.
//
// ACTION NEEDED: delete these two declarations from wherever they currently
// live (top of the old sample_collection_controller.dart) and have
// `sample_collection_models.dart` import this file instead.

import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';

/// One row of a sample-type's "incomplete" state: which reason was picked,
/// plus an optional free-text remark.


// // Re-export so callers of this file don't also need to import
// // sample_collection_models.dart just for this one type. If your project's
// // lint rules forbid re-exports, drop this line and import
// // sample_collection_models.dart directly wherever IncompleteReasonOption is
// // needed alongside TestIncompleteInfo.
// import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';
//
// export 'sample_collection_models.dart' show IncompleteReasonOption;