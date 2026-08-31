class InvoiceStatus {
  final int invoiceId;
  final String facilityName;
  final String fType;
  final String invoiceNumber;
  final String invoiceDate;
  final String processDescription;
  final int rn;

  InvoiceStatus({
    required this.invoiceId,
    required this.facilityName,
    required this.fType,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.processDescription,
    required this.rn,
  });

  factory InvoiceStatus.fromJson(Map<String, dynamic> json) {
    return InvoiceStatus(
      invoiceId: json['Invoice_ID'] ?? 0,
      facilityName: json['FacilityName'] ?? '',
      fType: json['FType'] ?? '',
      invoiceNumber: json['InvoiceNumber'] ?? '',
      invoiceDate: json['InvoiceDate'] ?? '',
      processDescription: json['ProcessDescription'] ?? '',
      rn: json['Rn'] ?? 0,
    );
  }
}

class InvoiceStage {
  final int processId;
  final String processDescription;

  InvoiceStage({
    required this.processId,
    required this.processDescription,
  });

  factory InvoiceStage.fromJson(Map<String, dynamic> json) {
    return InvoiceStage(
      processId: json['Processid'] ?? 0,
      processDescription: json['ProcessDescription'] ?? '',
    );
  }
}
