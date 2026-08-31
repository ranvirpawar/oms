// Doctor Reference Model
import 'package:flutter/cupertino.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import 'doctor_ref_model.dart';

class DoctorReference {
  final RxString selectedDoctorName = ''.obs;
  final TextEditingController mobileController = TextEditingController();
  final RxString selectedSpecialization = ''.obs;
  final RxString selectedDoctorId = ''.obs;

  DoctorReference({ReferenceDoctor? doctor}) {
    if (doctor != null) {
      selectedDoctorName.value = doctor.refDoctorName;
      selectedDoctorId.value = doctor.refDocCode.toString();


    }
  }

  void dispose() {
    mobileController.dispose();
  }
}
