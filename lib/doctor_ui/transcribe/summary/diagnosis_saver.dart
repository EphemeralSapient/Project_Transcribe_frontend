import 'package:flutter/material.dart';
import 'package:transcribe/common/http.dart' show MyHttpClient;

class DiagnosisSaver {
  /// Saves the diagnosis data to the server
  static Future<bool> saveDiagnosis({
    required String patientId,
    required String appointmentId,
    required Map<String, dynamic> summarizedData,
    required Function(bool) setLoading,
    required BuildContext context,
  }) async {
    try {
      // Prepare the data for saving
      final Map<String, dynamic> diagnosisData = {
        'patient_id': patientId,
        'appointment_id': appointmentId,
        'diagnosis_data': summarizedData,
      };

      final response = await MyHttpClient.post(
        '/doctor/save-diagnosis',
        diagnosisData,
      );

      if (response.statusCode == 200) {
        setLoading(false);

        // Close the bottom sheet
        Navigator.pop(context);
        return true;
      } else {
        setLoading(false);
        return false;
      }
    } catch (e) {
      setLoading(false);
      return false;
    }
  }
}
