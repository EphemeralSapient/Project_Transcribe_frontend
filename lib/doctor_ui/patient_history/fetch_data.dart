import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:transcribe/common/http.dart' show MyHttpClient;

Future<List<Map<String, dynamic>>> fetchPatientHistory() async {
  debugPrint("Ok");
  var response = await MyHttpClient.get("/doctor/appointment-history");
  var decoded = jsonDecode(response.body) as Map<String, dynamic>;
  debugPrint("response : ${response.body}");
  List<Map<String, dynamic>> histories = [];
  for (Map<String, dynamic> record in decoded['history']) {
    histories.add(record);
  }
  return histories;
}
