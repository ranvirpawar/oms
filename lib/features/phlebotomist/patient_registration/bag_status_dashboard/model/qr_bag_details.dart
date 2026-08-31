// Bag details model from Proc_GetQRBagDetails
class QRBagDetails {
  final String qrCode;
  final int capacity;
  final int patientCount;
  final int spaceVacant;

  QRBagDetails({
    required this.qrCode,
    required this.capacity,
    required this.patientCount,
    required this.spaceVacant,
  });

  factory QRBagDetails.fromJson(Map<String, dynamic> json) => QRBagDetails(
    qrCode: json['QRCode'] ?? '',
    capacity: json['Capacity'] ?? 0,
    patientCount: json['PatientCOunt'] ?? 0,
    spaceVacant: json['SpaceVacant'] ?? 0,
  );
}