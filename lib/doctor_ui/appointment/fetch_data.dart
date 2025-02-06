import 'dart:convert' show jsonDecode;

import 'package:http/http.dart' show Response;
import 'package:timeago/timeago.dart' as timeago show format;
import 'package:transcribe/common/http.dart' show MyHttpClient;

Future<List<Map<String, dynamic>>> fetchAppointments() async {
  Response response = await MyHttpClient.get("/doctor/appointment-schedules");
  // debugPrint(response.body);
  // Return sample appointments (or fetched data)
  var schedules = jsonDecode(response.body) as Map<String, dynamic>;
  List<Map<String, String>> ret = List.empty(growable: true);

  for (Map<String, dynamic> schedule in schedules['schedules']) {
    DateTime dt = DateTime.parse(schedule["time"]);

    String friendlyTime = timeago.format(dt, allowFromNow: true);
    ret.add({
      'patientId': schedule['patientid'].toString(),
      'time': friendlyTime,
      'patientName': schedule['patientname'] ?? "Unknown",
      'reason': schedule['reason'] ?? "No reason specified",
      'id': schedule['id'].toString(),
      'status': schedule['status'] ?? "scheduled?",
    });
  }

  return ret;
}
