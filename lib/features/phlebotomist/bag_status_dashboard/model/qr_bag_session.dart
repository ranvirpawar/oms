

// Session model from GetUserwiseQRBagSession
class QRBagSession {
  final int sessionID;
  final int bagId;
  final String bagcode;
  final int bagCloseStatus;

  QRBagSession({
    required this.sessionID,
    required this.bagId,
    required this.bagcode,
    required this.bagCloseStatus,
  });

  factory QRBagSession.fromJson(Map<String, dynamic> json) {
    return QRBagSession(
      sessionID:      json['SessionID']      as int,
      bagId:          json['BagID']          as int,  // ← capital D, not 'BagId' or 'bagId'
      bagcode:        json['Bagcode']        as String,
      bagCloseStatus: json['BagCloseStatus'] as int,
    );
  }

  bool get isOpen => bagCloseStatus == 0;
}

