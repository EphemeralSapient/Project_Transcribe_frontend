import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:transcribe/doctor_ui/navigate_to_transcribe.dart'
    show navigateToTranscribeScreen;

Widget buildAppointmentCard(
  BuildContext context,
  Map<String, dynamic> appointment,
) {
  return Card(
    elevation: 5.0,
    margin: const EdgeInsets.only(bottom: 16.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Text(
          appointment['patientName'].substring(0, 1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        appointment['patientName'],
        style: GoogleFonts.lato(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${appointment['time']} • ${appointment['reason']}',
        style: GoogleFonts.lato(fontSize: 14.0),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
      onTap: () {
        navigateToTranscribeScreen(
          context,
          appointment['patientId'] ?? '',
          appointment['patientName'] ?? '',
          appointment["id"] ?? '',
        );
      },
    ),
  );
}
