

import 'package:get/get.dart';

import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/controller/registrarion_bag_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/model/qr_bag_details.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/model/qr_bag_session.dart';

mixin HasBagContext on GetxController {
  /// Lazily resolves the shared bag controller. Reused if the phlebotomist
  /// already visited the bag dashboard; created here otherwise.
  BagRegistrationController get bagController =>
      Get.isRegistered<BagRegistrationController>()
          ? Get.find<BagRegistrationController>()
          : Get.put(BagRegistrationController());

  QRBagSession? get activeBag => bagController.activeBag;

  /// True only while at least one bag is open — enforced server-side too.
  bool get hasOpenBag => bagController.hasOpenBag;

  int get activeBagId => bagController.activeBagId;
  int get activeSessionId => bagController.activeSessionId;
  String get activeBagcode => bagController.activeBagcode;

  QRBagDetails? get activeBagDetails {
    final bag = activeBag;
    if (bag == null) return null;
    return bagController.bagDetailsMap[bag.bagId];
  }

  int get bagCapacity => activeBagDetails?.capacity ?? 0;
  int get bagUsed => activeBagDetails?.patientCount ?? 0;
  int get bagVacant => activeBagDetails?.spaceVacant ?? 0;

  /// 0..1 — drives the capacity bar on the active-bag card.
  double get bagFillRatio {
    final capacity = bagCapacity;
    if (capacity <= 0) return 0;
    return (bagUsed / capacity).clamp(0.0, 1.0);
  }

  bool get isBagFull => activeBagDetails != null && bagUsed >= bagCapacity;

  /// Number of sample types the current order needs.
  /// Default 0 so Order Confirmation (which has no sample entries) never
  /// triggers the capacity warning. SampleCollectionController overrides this.
  int get requiredSampleCount => 0;

  /// True when an open bag exists, its capacity is known, and it doesn't
  /// have enough vacant slots for every sample this order needs.
  bool get bagCapacityInsufficient =>
      hasOpenBag && bagCapacity > 0 && bagVacant < requiredSampleCount;
}