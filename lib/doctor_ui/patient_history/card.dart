import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:timeago/timeago.dart' as timeago show format;
import 'package:transcribe/doctor_ui/patient_history/card_helper.dart';

Widget buildPatientHistoryCard(Map<String, dynamic> patient) {
  final transcription = patient['transcription_summary'] ?? {};
  final patientName =
      patient['patient_name'] ?? "Patient #${patient['patient_id']}";
  final lastVisitDT = patient['appointment_time'] ?? '-';
  DateTime dt = DateTime.parse(lastVisitDT);
  String lastVisit = timeago.format(dt, allowFromNow: true);
  final diagnosis = transcription['diagnosis'] ?? 'N/A';

  // Decomposed it into function for readability
  final sections = buildPatientSections(patient);

  return Card(
    elevation: 6.0,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 28.0,
                child: Text(
                  patientName[0].toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigoAccent,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: GoogleFonts.lato(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Last Visit: $lastVisit\nDiagnosis: $diagnosis',
                      style: GoogleFonts.lato(
                        fontSize: 14.0,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 28.0,
              ),
            ],
          ),
        ),
        // Append all available sections
        ...sections,
      ],
    ),
  );
}

// dart
List<Widget> buildPatientSections(Map<String, dynamic> patient) {
  List<Widget> sections = [];

  final vaccinations = buildVaccinationList(patient);
  if (vaccinations.isNotEmpty) {
    sections.add(
      buildSectionTile(
        title: 'Vaccinations',
        icon: Icons.vaccines,
        iconColor: Colors.green[600],
        children: vaccinations,
      ),
    );
  }

  final admissions = buildAdmissionList(patient);
  if (admissions.isNotEmpty) {
    sections.add(
      buildSectionTile(
        title: 'Hospital Admissions',
        icon: Icons.local_hospital,
        iconColor: Colors.red,
        children: admissions,
      ),
    );
  }

  final prescriptions = buildPrescriptionList(patient);
  if (prescriptions.isNotEmpty) {
    sections.add(
      buildSectionTile(
        title: 'Prescriptions',
        icon: Icons.medication,
        iconColor: Colors.purple,
        children: prescriptions,
      ),
    );
  }

  final labTests = buildLabTestList(patient);
  if (labTests.isNotEmpty) {
    sections.add(
      buildSectionTile(
        title: 'Lab Tests',
        icon: Icons.biotech,
        iconColor: Colors.teal,
        children: labTests,
      ),
    );
  }

  final surgeries = buildSurgeriesList(patient);
  if (surgeries.isNotEmpty) {
    sections.add(
      buildSectionTile(
        title: 'Surgeries',
        icon: Icons.healing,
        iconColor: Colors.orange,
        children: surgeries,
      ),
    );
  }

  final extras = buildExtrasList(patient);
  if (extras.isNotEmpty) {
    sections.add(
      buildSectionTile(
        title: 'Extras',
        icon: Icons.insert_drive_file,
        iconColor: Colors.brown,
        children: extras,
      ),
    );
  }

  final summary = buildTranscriptionSummarySection(patient);
  if (summary.isNotEmpty) {
    sections.add(
      buildSectionTile(
        title: 'Summary Details',
        icon: Icons.description,
        iconColor: Colors.indigo,
        children: summary,
      ),
    );
  }

  if (sections.isEmpty) {
    sections.add(
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No additional details available.',
          style: GoogleFonts.lato(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  return sections;
}
