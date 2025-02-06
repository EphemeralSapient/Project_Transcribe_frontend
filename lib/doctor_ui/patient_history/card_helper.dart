import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

List<Widget> buildSurgeriesList(Map<String, dynamic> patient) {
  final List surgeries = patient['surgeries'] ?? [];
  if (surgeries.isEmpty) return [];
  return surgeries.map<Widget>((surgery) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.healing, color: Colors.orange),
      title: Text(
        surgery['surgery_name'] ?? 'Surgery',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Date: ${surgery['surgery_date'] ?? '-'}\nNotes: ${surgery['notes'] ?? '-'}',
        style: GoogleFonts.lato(),
      ),
    );
  }).toList();
}

// Helper builder for Extras section
List<Widget> buildExtrasList(Map<String, dynamic> patient) {
  final List extras = patient['extras'] ?? [];
  if (extras.isEmpty) return [];
  return extras.map<Widget>((extra) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.insert_drive_file, color: Colors.brown),
      title: Text(
        extra['title'] ?? 'Extra',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(extra['notes'] ?? '-', style: GoogleFonts.lato()),
    );
  }).toList();
}

// Helper builder for transcription summary section
List<Widget> buildTranscriptionSummarySection(Map<String, dynamic> patient) {
  final Map<String, dynamic> summary = patient['transcription_summary'] ?? {};
  if (summary.isEmpty) return [];
  List<Widget> tiles = [];
  // Define keys you wish to show in order.
  final keys = [
    'diagnosis',
    'symptoms',
    'medications_prescribed',
    'tests_ordered',
    'follow_up_instructions',
    'allergies',
    'family_history',
    'lifestyle_recommendations',
  ];
  for (String key in keys) {
    if (summary[key] != null && summary[key].toString().trim().isNotEmpty) {
      tiles.add(
        ListTile(
          dense: true,
          title: Text(
            '${_prettifyKey(key)}:',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(summary[key].toString(), style: GoogleFonts.lato()),
        ),
      );
    }
  }
  return tiles;
}

// Helper to prettify summary keys (e.g., medications_prescribed --> Medications Prescribed)
String _prettifyKey(String key) {
  return key
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

/// Builds an expandable section tile.
Widget buildSectionTile({
  required String title,
  required IconData icon,
  required Color? iconColor,
  required List<Widget> children,
}) {
  return Theme(
    data: ThemeData.light().copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: GoogleFonts.lato(fontSize: 16.0, fontWeight: FontWeight.w600),
      ),
      children: children,
    ),
  );
}

/// ---------------- Helper Builders for Each Section ----------------

/// Vaccination list builder.
List<Widget> buildVaccinationList(Map<String, dynamic> patient) {
  final List vaccinations = patient['vaccinations'] ?? [];
  if (vaccinations.isEmpty) return [];
  return vaccinations.map<Widget>((vaccine) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
      title: Text(
        vaccine['vaccine_name'] ?? 'Unknown Vaccine',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${vaccine['date_administered'] ?? '-'} • ${vaccine['dose'] ?? ''}',
        style: GoogleFonts.lato(),
      ),
    );
  }).toList();
}

/// Hospital admissions list builder.
List<Widget> buildAdmissionList(Map<String, dynamic> patient) {
  final List admissions = patient['admissions'] ?? [];
  if (admissions.isEmpty) return [];
  return admissions.map<Widget>((admission) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.bed, color: Colors.redAccent),
      title: Text(
        admission['reason'] ?? 'Admission',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'From ${admission['admission_date'] ?? '-'} to ${admission['discharge_date'] ?? '-'}\nBed: ${admission['bed_number'] ?? '-'}',
        style: GoogleFonts.lato(),
      ),
    );
  }).toList();
}

/// Prescription (tablet prescribed) list builder.
List<Widget> buildPrescriptionList(Map<String, dynamic> patient) {
  final List prescriptions = patient['prescriptions'] ?? [];
  if (prescriptions.isEmpty) return [];
  return prescriptions.map<Widget>((prescription) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.medication, color: Colors.purple),
      title: Text(
        prescription['tabletName'] ?? 'Medication',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Dosage: ${prescription['dosage'] ?? '-'} | Duration: ${prescription['duration'] ?? '-'}',
        style: GoogleFonts.lato(),
      ),
    );
  }).toList();
}

/// Lab tests (e.g., blood tests) list builder.
List<Widget> buildLabTestList(Map<String, dynamic> patient) {
  final List labTests = patient['labTests'] ?? [];
  if (labTests.isEmpty) return [];
  return labTests.map<Widget>((labTest) {
    return ListTile(
      dense: false,
      leading: const Icon(Icons.biotech, color: Colors.teal),
      title: Text(
        labTest['testName'] ?? 'Lab Test',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Date: ${labTest['date'] ?? '-'}\nResult: ${labTest['result'] ?? 'Pending'}',
        style: GoogleFonts.lato(),
      ),
    );
  }).toList();
}
