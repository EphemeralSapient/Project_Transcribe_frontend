class DiagnosisModel {
  final String patientId;
  final String appointmentId;
  final Map<String, dynamic> diagnosisData;

  DiagnosisModel({
    required this.patientId,
    required this.appointmentId,
    required this.diagnosisData,
  });

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'diagnosis_data': diagnosisData,
    };
  }

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      patientId: json['patient_id'],
      appointmentId: json['appointment_id'],
      diagnosisData: json['diagnosis_data'],
    );
  }
}
