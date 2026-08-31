class ExistingPatientModel {
  final String patientId;
  final String title;
  final String firstName;
  final String middleName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String age;
  final String ageTitle;
  final String mobileNumber;
  final String email;
  final String address;
  final String aadhaarNumber;
  final String cityName;
  final String pincode;
  final String maritalStatus;

  ExistingPatientModel({
    required this.patientId,
    required this.title,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    required this.age,
    required this.ageTitle,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.aadhaarNumber,
    required this.cityName,
    required this.pincode,
    required this.maritalStatus,
  });

  factory ExistingPatientModel.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    /*if (json['DateOfBirth'] != null) {
      final millisStr = json['DateOfBirth'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      final millis = int.tryParse(millisStr);
      if (millis != null) dob = DateTime.fromMillisecondsSinceEpoch(millis);
    }*/
    if (json['DateOfBirth'] != null &&
        json['DateOfBirth'].toString().isNotEmpty) {
      dob = DateTime.tryParse(json['DateOfBirth'].toString());
    }


    return ExistingPatientModel(
      // patientId: json['PatientID'].toString() ?? '',
      patientId: json['PatientPermNumber']?.toString() ?? '',
      title: json['Title'] ?? '',
      firstName: json['FirstName'] ?? '',
      middleName: json['MiddleName'] ?? '',
      lastName: json['LastName'] ?? '',
      gender: json['Gender'] /*== 'M' ? 'Male' : 'Female'*/,
      dateOfBirth: dob,
      age: json['Age'].toString()?? ' ',
      ageTitle: json['AgeTitle'] ?? '',
      mobileNumber: json['MobileNumber'] ?? '',
      email: json['Email'] ?? '',
      address: json['Address'] ?? '',
      aadhaarNumber: json['AadhaarNumber'] ?? '',
      cityName: json['CityName'] ?? '',
      pincode: json['Pincode'].toString() ?? '',
      maritalStatus: json['MaritalStatus'] ?? '',
    );
  }
}
