import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:http/http.dart' show Response;
import 'package:overlay_support/overlay_support.dart'
    show showSimpleNotification;
import 'package:transcribe/common/http.dart' show MyHttpClient;

void showAddAppointmentBottomSheet(BuildContext context, Function setState) {
  final formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  String patientId = '';
  String appointmentTime = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the bottom sheet to resize for keyboard
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Add Patient to Appointments',
                style: GoogleFonts.lato(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              // Form
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: idController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Enter Patient ID',
                        hintText: 'e.g., 7',
                        prefixIcon: const Icon(Icons.person),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a patient ID';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        patientId = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // dart
                    TextFormField(
                      controller: timeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Appointment Time',
                        hintText: 'Select Time',
                        prefixIcon: const Icon(Icons.access_time),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          // Combine today's date with the selected time.
                          final now = DateTime.now();
                          final DateTime selectedDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            picked.hour,
                            picked.minute,
                          );
                          // Store ISO time string for backend.
                          appointmentTime = selectedDateTime.toIso8601String();
                          // Display friendly format in the text field.
                          timeController.text = picked.format(context);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an appointment time';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        debugPrint("Friendly time selected: $value");
                        // appointmentTime already stores the ISO string.
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter reason for appointment',
                  prefixIcon: const Icon(Icons.edit),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }

                  return null;
                },
                onSaved: (value) {
                  // No need to validate as it's already validated.
                },
              ),
              const SizedBox(height: 20.0),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        Navigator.of(context).pop();

                        debugPrint(
                          'Adding patient $patientId at $appointmentTime',
                        );
                        // Need to send time in TZ format for postgres to store
                        Response response = await MyHttpClient.post(
                          "/doctor/appointment-schedules",
                          {
                            "patientId": patientId,
                            "time": appointmentTime,
                            "reason": reasonController.text,
                          },
                        );

                        if (response.statusCode != 200) {
                          showSimpleNotification(
                            Text(
                              "Failed to add appointment | ${response.body}",
                            ),
                            background: Colors.red,
                            leading: Icon(Icons.error),
                          );
                        } else {
                          showSimpleNotification(
                            Text("Appointment added successfully"),
                            background: Colors.green,
                          );
                          setState(() {});
                        }
                      }
                    },
                    child: const Text('ADD'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
