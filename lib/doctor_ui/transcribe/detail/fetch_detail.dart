import 'dart:convert' show json;

import 'package:flutter/material.dart' show debugPrint;
import 'package:transcribe/common/http.dart' show MyHttpClient;

Future<Map<String, dynamic>> fetchPatientDetails(id) async {
  try {
    var response = await MyHttpClient.get('/patient/$id/details');
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch patient details');
    }
  } catch (e) {
    debugPrint('Error fetching patient details: $e');
    rethrow;
  }
}
