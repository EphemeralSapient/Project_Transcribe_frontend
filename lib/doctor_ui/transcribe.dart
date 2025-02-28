// TODO : Decompose this file into smaller files on transcribe folder

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audio_waveforms/audio_waveforms.dart'
    show AudioWaveforms, RecorderController, WaveStyle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart'
    show showSimpleNotification;
import 'package:timeago/timeago.dart' as timeago;
import 'package:transcribe/common/global.dart' as global;
import 'package:transcribe/common/http.dart';

class TranscribeScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String appointmentId;

  const TranscribeScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.appointmentId,
  });

  @override
  _TranscribeScreenState createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen>
    with SingleTickerProviderStateMixin {
  bool isRecording = false;
  late AnimationController _animationController;
  late RecorderController _recorderController;

  bool _isLoading = false;
  String _loadingMessage = 'Processing...';

  /// Holds the summarized data from the server (transcript + summary).
  Map<String, dynamic>? _summarizedData;

  /// Sample data for patient history
  Map<String, dynamic> patientHistory = {
    'Last Visit': '2023-01-15',
    'Diagnosis': 'Hypertension',
    'Medications': 'Atenolol, Lisinopril',
    'Allergies': 'Penicillin',
  };

  /// Sample data for full patient details
  Map<String, dynamic> patientDetails = {
    'Age': '45',
    'Gender': 'Male',
    'Blood Type': 'O+',
    'Contact': '+1 555 123 4567',
    'Address': '123 Main St, Springfield',
  };

  /// **Hospital records**: a generalized template containing
  /// various categories (Vaccinations, Admissions, Surgeries, etc.)
  Map<String, dynamic> hospitalRecords = {
    'Vaccinations': [
      {'name': 'COVID-19', 'date': '2021-08-20', 'dose': '2nd dose'},
      {'name': 'Influenza', 'date': '2023-01-05', 'dose': '1st dose'},
    ],
    'Admissions': [
      {
        'admissionDate': '2022-01-05',
        'dischargeDate': '2022-01-10',
        'reason': 'Surgery',
        'bedNumber': 'B12',
      },
    ],
    'Surgeries': [
      {
        'surgeryName': 'Appendectomy',
        'surgeryDate': '2019-05-10',
        'notes': 'No complications',
      },
      {
        'surgeryName': 'Knee Arthroscopy',
        'surgeryDate': '2021-02-22',
        'notes': 'Physical therapy recommended',
      },
    ],
    // Add the new Extra category
    'Extra': [
      {'title': 'Blood Test', 'notes': 'Fasting required, results pending'},
    ],
  };

  @override
  void initState() {
    super.initState();
    // Create an animation controller for the “pulsating” effect while recording
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);

    // Initialize the audio recorder controller
    if (!kIsWeb) {
      _recorderController = RecorderController();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (!kIsWeb) _recorderController.dispose();
    super.dispose();
  }

  /// Start or stop the recording using the [RecorderController].
  void _startOrStopRecording() async {
    if (!isRecording) {
      // Start recording
      await _recorderController.record();
      setState(() {
        isRecording = true;
      });
      showSimpleNotification(
        const Text(
          'Recording started...',
          style: TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.mic, color: Colors.white),
        background: Colors.green,
      );
    } else {
      // Stop recording
      final path = await _recorderController.stop();
      setState(() {
        isRecording = false;
        _isLoading = true; // Start loading overlay
        _loadingMessage = 'Transcribing...';
      });
      showSimpleNotification(
        const Text('Recording stopped.', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.stop, color: Colors.white),
        background: Colors.red,
      );
      if (path != null) {
        // Send the recorded audio file to the server for transcription
        await _sendAudioFileToServer(File(path));
      } else {
        setState(() {
          _isLoading = false; // Stop loading overlay
        });
        showSimpleNotification(
          const Text(
            'Recording failed.',
            style: TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.error, color: Colors.white),
          background: Colors.redAccent,
        );
      }
    }
  }

  /// Sends the recorded audio file to the server (upload + summarize).
  Future<void> _sendAudioFileToServer(File audioFile) async {
    debugPrint("Sending audio file to server...");
    try {
      String uploadUrl = '${MyHttpClient.baseURL()}/upload';
      var client = MyHttpClient.getClientInstance();

      // 1) Upload the audio file
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );
      request.headers.addAll({
        "Authorization": "Bearer ${global.token}",
        "Content-Type": "application/json",
      });

      var response = await client.send(request);

      debugPrint("Upload Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);
        debugPrint('Upload response data: $data');

        // Extract the transcript from the response
        var transcript = data['transcript'];

        // Update UI to indicate we’re moving to summarizing
        setState(() {
          _isLoading = true;
          _loadingMessage = 'Summarizing...';
        });
        showSimpleNotification(
          const Text(
            'Transcription complete. Summarizing...',
            style: TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.text_snippet, color: Colors.white),
          background: Colors.blue,
        );

        // 2) Summarize the transcript
        var summarizeResponse = await MyHttpClient.post("/doctor/summarize", {
          'transcript': transcript,
        });

        if (summarizeResponse.statusCode == 200) {
          var summarizeResponseData = summarizeResponse.body;
          var summaryJson = json.decode(summarizeResponseData);

          // Check if the response indicates any model error
          if (summaryJson['summary'] == "No response from model" ||
              summaryJson['summary'] ==
                  "No medical consultation found in the transcript") {
            setState(() {
              _isLoading = false;
            });
            showSimpleNotification(
              Text(
                summaryJson['summary'],
                style: const TextStyle(color: Colors.white),
              ),
              leading: const Icon(Icons.info_outline, color: Colors.white),
              background: Colors.orangeAccent,
            );
            return;
          }

          debugPrint('Summarize response data: $summaryJson');
          String summaryField = summaryJson['summary'];

          // Remove code block markers (```json ... ```) if present
          String jsonString = summaryField.trim();
          if (jsonString.startsWith('```json')) {
            jsonString = jsonString.substring('```json'.length);
          } else if (jsonString.startsWith('```')) {
            jsonString = jsonString.substring('```'.length);
          }
          if (jsonString.endsWith('```')) {
            jsonString = jsonString.substring(0, jsonString.length - 3);
          }

          jsonString = jsonString.trim(); // Clean up whitespace

          Map<String, dynamic> summarizedData;
          try {
            summarizedData = json.decode(jsonString);
          } catch (e) {
            debugPrint('Error parsing JSON in summary field: $e');
            setState(() {
              _isLoading = false;
            });
            showSimpleNotification(
              const Text(
                'Error parsing summarized data',
                style: TextStyle(color: Colors.white),
              ),
              leading: const Icon(Icons.error_outline, color: Colors.white),
              background: Colors.redAccent,
            );
            return;
          }

          setState(() {
            _summarizedData = summarizedData;
            _isLoading = false;
          });

          debugPrint('Parsed summarized data: $_summarizedData');
          // Show the summarized data in a bottom sheet
          _showSummarizedDataBottomSheet();
        } else {
          // Summarize error
          setState(() {
            _isLoading = false;
          });
          var errorText =
              'Failed to summarize transcript. Status: ${summarizeResponse.statusCode} | Body: ${summarizeResponse.body}';
          debugPrint(errorText);

          showSimpleNotification(
            Text(errorText, style: const TextStyle(color: Colors.white)),
            leading: const Icon(Icons.error_outline, color: Colors.white),
            background: Colors.redAccent,
          );
        }
      } else {
        // Upload error
        setState(() {
          _isLoading = false;
        });
        showSimpleNotification(
          Text(
            'Failed to upload audio. Status: ${response.statusCode}',
            style: const TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
          background: Colors.redAccent,
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _isLoading = false;
      });
      showSimpleNotification(
        Text('Error: $e', style: const TextStyle(color: Colors.white)),
        leading: const Icon(Icons.error_outline, color: Colors.white),
        background: Colors.redAccent,
      );
    }
  }

  /// Bottom sheet to show the summarized data (diagnosis, summary, etc.) in an editable form.
  void _showSummarizedDataBottomSheet() {
    if (_summarizedData == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.8,
            minChildSize: 0.3,
            initialChildSize: 0.5,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Small top drag handle
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          'Summarized Diagnosis',
                          style: GoogleFonts.lato(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        // Editable fields from summarized data
                        _buildEditableListTile(
                          title: 'Summary',
                          value: _summarizedData!['summary'] ?? '',
                          icon: Icons.description,
                          opType: "summary",
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['summary'] = newValue;
                            });
                          },
                        ),
                        _buildEditableListTile(
                          title: 'Diagnosis',
                          value:
                              _summarizedData!['diagnosis']?.toString() ?? '',
                          icon: Icons.local_hospital,
                          opType: "summary",
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['diagnosis'] = newValue;
                            });
                          },
                        ),
                        _buildEditableListTile(
                          title: 'Symptoms',
                          value: _summarizedData!['symptoms']?.toString() ?? '',
                          icon: Icons.healing,
                          opType: "summary",
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['symptoms'] = newValue;
                            });
                          },
                        ),
                        _buildMedicationListTile(
                          title: 'Medications Prescribed',
                          medications:
                              _summarizedData!['medications_prescribed'] is List
                                  ? List<Map<String, dynamic>>.from(
                                    _summarizedData!['medications_prescribed'],
                                  )
                                  : [], // Convert to proper list of maps
                          icon: Icons.medication,
                          onEditComplete: (newMedications) {
                            setState(() {
                              _summarizedData!['medications_prescribed'] =
                                  newMedications;
                            });
                          },
                        ),
                        _buildEditableListTile(
                          title: 'Tests Ordered',
                          value:
                              _summarizedData!['tests_ordered']?.toString() ??
                              '',
                          icon: Icons.science,
                          opType: "summary",
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['tests_ordered'] = newValue;
                            });
                          },
                        ),
                        _buildEditableListTile(
                          title: 'Follow-up Instructions',
                          value:
                              _summarizedData!['follow_up_instructions']
                                  ?.toString() ??
                              '',
                          opType: "summary",
                          icon: Icons.assignment_turned_in,
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['follow_up_instructions'] =
                                  newValue;
                            });
                          },
                        ),
                        _buildEditableListTile(
                          title: 'Allergies',
                          value:
                              _summarizedData!['allergies']?.toString() ?? '',
                          icon: Icons.warning,
                          opType: "summary",
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['allergies'] = newValue;
                            });
                          },
                        ),
                        _buildEditableListTile(
                          title: 'Family History',
                          value:
                              _summarizedData!['family_history']?.toString() ??
                              '',
                          icon: Icons.family_restroom,
                          opType: "summary",
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['family_history'] = newValue;
                            });
                          },
                        ),
                        _buildEditableListTile(
                          title: 'Lifestyle Recommendations',
                          value:
                              _summarizedData!['lifestyle_recommendations']
                                  ?.toString() ??
                              '',
                          opType: "summary",
                          icon: Icons.thumb_up,
                          onValueChanged: (newValue) {
                            setState(() {
                              _summarizedData!['lifestyle_recommendations'] =
                                  newValue;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Add a persistent save button at the bottom
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _saveSummarizedData(),
                            icon: const Icon(Icons.save),
                            label: Text(
                              'Save Diagnosis',
                              style: GoogleFonts.lato(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Save the summarized data to the server
  Future<void> _saveSummarizedData() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Saving diagnosis...';
    });

    try {
      // Prepare the data for saving
      final Map<String, dynamic> diagnosisData = {
        'patient_id': widget.patientId,
        'appointment_id': widget.appointmentId,
        'diagnosis_data': _summarizedData,
      };

      final response = await MyHttpClient.post(
        '/doctor/save-diagnosis',
        diagnosisData,
      );

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });

        // Close the bottom sheet first
        Navigator.pop(context);

        // Show success notification
        showSimpleNotification(
          const Text(
            'Diagnosis saved successfully!',
            style: TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.check_circle, color: Colors.white),
          background: Colors.green,
        );
      } else {
        throw Exception('Failed to save diagnosis: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      showSimpleNotification(
        Text(
          'Error saving diagnosis: $e',
          style: const TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.error_outline, color: Colors.white),
        background: Colors.redAccent,
      );
    }
  }

  /// Bottom Sheet for editing a patient's general "History"
  Future<Map<String, dynamic>> fetchPatientHistory(id) async {
    try {
      debugPrint("!!! $id");
      var response = await MyHttpClient.get('/patient/$id/history');
      debugPrint("response? : ${response.body}");
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        Map<String, String> finalzied = {};

        // Transform the data to desired form with icon and proper key value
        // For _getDetailIcon to work also replace empty or null value with Nil
        if (data == null) {
          throw Exception("No data found");
        }
        data = data as Map<String, dynamic>;

        if (data.containsKey("last_visit")) {
          var dt = data["last_visit"];
          finalzied["Last Visit"] = timeago.format(DateTime.parse(dt));
        } else {
          finalzied["Last Visit"] = "Nil";
        }

        if (data.containsKey("diagnosis")) {
          finalzied["Diagnosis"] = data["diagnosis"];
        } else {
          finalzied["Diagnosis"] = "Nil";
        }

        if (data.containsKey("medications")) {
          finalzied["Medications"] = data["medications"];
        } else {
          finalzied["Medications"] = "Nil";
        }

        if (data.containsKey("allergies")) {
          finalzied["Allergies"] = data["allergies"];
        } else {
          finalzied["Allergies"] = "Nil";
        }

        if (data.containsKey("family_history")) {
          finalzied["Family History"] = data["family_history"];
        } else {
          finalzied["Family History"] = "Nil";
        }

        if (data.containsKey("lifestyle_recommendations")) {
          finalzied["Lifestyle Recommendations"] =
              data["lifestyle_recommendations"];
        } else {
          finalzied["Lifestyle Recommendations"] = "Nil";
        }

        return finalzied;
      } else {
        throw Exception('Failed to fetch patient history');
      }
    } catch (e) {
      debugPrint('Error fetching patient history: $e');
      rethrow;
    }
  }

  void _showPatientHistoryBottomSheet() async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissing the dialog by tapping outside
      builder:
          (context) => Scaffold(
            backgroundColor: Colors.transparent,
            body: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinKitWave(color: Colors.white, size: 48.0),
                      const SizedBox(height: 16.0),
                      Text(
                        _loadingMessage,
                        style: GoogleFonts.lato(
                          fontSize: 18.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    try {
      // Fetch details asynchronously
      Map<String, dynamic> patientHistory = await fetchPatientHistory(
        widget.patientId,
      );

      // Close the loading indicator
      Navigator.of(context).pop();

      // Then show the bottom sheet with the fetched data
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              expand: false,
              maxChildSize: 0.8,
              minChildSize: 0.3,
              initialChildSize: 0.5,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Patient History',
                      style: GoogleFonts.lato(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    ...patientHistory.entries.map((entry) {
                      return _buildEditableListTile(
                        title: entry.key,
                        value: entry.value.toString(),
                        opType: "history",
                        icon: _getHistoryIcon(entry.key),
                        onValueChanged: (newValue) {
                          setState(() {
                            patientHistory[entry.key] = newValue;
                          });
                        },
                      );
                    }),
                  ],
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      // Handle any errors here
      Navigator.of(context).pop(); // Close the loading indicator
      // Show an error message or handle the error appropriately
      showSimpleNotification(
        Text(
          'Error fetching details: $e',
          style: const TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.error_outline, color: Colors.white),
        background: Colors.redAccent,
      );
    }
  }

  // Future<void> __showPatientHistoryBottomSheet() async {
  //   debugPrint("Appointment id : ${widget.appointmentId}");
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white.withOpacity(0.9),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(context).viewInsets.bottom,
  //         ),
  //         child: DraggableScrollableSheet(
  //           expand: false,
  //           maxChildSize: 0.8,
  //           minChildSize: 0.3,
  //           initialChildSize: 0.5,
  //           builder: (context, scrollController) {
  //             return ListView(
  //               controller: scrollController,
  //               padding: const EdgeInsets.all(16.0),
  //               children: [
  //                 // Drag handle
  //                 Center(
  //                   child: Container(
  //                     width: 50,
  //                     height: 5,
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey[300],
  //                       borderRadius: BorderRadius.circular(12.0),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16.0),
  //                 Text(
  //                   'Patient History',
  //                   style: GoogleFonts.lato(
  //                     fontSize: 24.0,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //                 const SizedBox(height: 16.0),
  //                 // Build a list tile for each entry in the patientHistory map
  //                 ...patientHistory.entries.map((entry) {
  //                   return _buildEditableListTile(
  //                     title: entry.key,
  //                     value: entry.value,
  //                     opType: "history",
  //                     icon: _getHistoryIcon(entry.key),
  //                     onValueChanged: (newValue) {
  //                       setState(() {
  //                         patientHistory[entry.key] = newValue;
  //                       });
  //                     },
  //                   );
  //                 }),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

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

  void _showFullDetailsBottomSheet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch dynamic patient details
      Map<String, dynamic> fetcheddetailsUnfiltered = await fetchPatientDetails(
        widget.patientId,
      );

      Map<String, String> fetchedDetails = {};

      // Filter out null values and convert to string and proper key name for detailicon thing
      if (fetcheddetailsUnfiltered.containsKey("age")) {
        fetchedDetails["Age"] = fetcheddetailsUnfiltered["age"].toString();
      } else {
        fetchedDetails["Age"] = "Nil";
      }

      if (fetcheddetailsUnfiltered.containsKey("first_name") &&
          fetcheddetailsUnfiltered.containsKey("last_name")) {
        fetchedDetails["Name"] =
            fetcheddetailsUnfiltered["first_name"] +
            " ${fetcheddetailsUnfiltered["last_name"]}";
      } else {
        fetchedDetails["Name"] = "Nil";
      }

      if (fetcheddetailsUnfiltered.containsKey("gender")) {
        fetchedDetails["Gender"] = fetcheddetailsUnfiltered["gender"];
      } else {
        fetchedDetails["Gender"] = "Nil";
      }

      if (fetcheddetailsUnfiltered.containsKey("blood_type")) {
        fetchedDetails["Blood Type"] = fetcheddetailsUnfiltered["blood_type"];
      } else {
        fetchedDetails["Blood Type"] = "Nil";
      }

      if (fetcheddetailsUnfiltered.containsKey("contact_phone")) {
        fetchedDetails["Contact"] = fetcheddetailsUnfiltered["contact_phone"];
      } else {
        fetchedDetails["Contact"] = "Nil";
      }

      if (fetcheddetailsUnfiltered.containsKey("address")) {
        fetchedDetails["Address"] = fetcheddetailsUnfiltered["address"];
      } else {
        fetchedDetails["Address"] = "Nil";
      }

      setState(() {
        _isLoading = false;
        patientDetails = fetchedDetails;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              expand: false,
              maxChildSize: 0.8,
              minChildSize: 0.3,
              initialChildSize: 0.5,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Full Details',
                      style: GoogleFonts.lato(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    ...patientDetails.entries.map((entry) {
                      return _buildEditableListTile(
                        title: entry.key,
                        value: entry.value,
                        opType: "details",
                        icon: _getDetailsIcon(entry.key),
                        onValueChanged: (newValue) {
                          setState(() {
                            patientDetails[entry.key] = newValue;
                          });
                        },
                      );
                    }),
                  ],
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showSimpleNotification(
        Text(
          'Error fetching patient details: $e',
          style: const TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.error_outline, color: Colors.white),
        background: Colors.redAccent,
      );
    }
  }

  /// Displays a bottom sheet with polished ExpansionTiles for hospital records.
  /// Also includes a button to add new records in each category.
  void _showHospitalRecordsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            initialChildSize: 0.6,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                children: [
                  // Top drag handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Title
                  Text(
                    'Hospital Records',
                    style: GoogleFonts.lato(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),

                  // Build a card-wrapped ExpansionTile for each category
                  ...hospitalRecords.entries.map((entry) {
                    final categoryName = entry.key;
                    final categoryData = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Theme(
                        // Removes the default ExpansionTile divider color
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Icon(
                            _getHospitalRecordIcon(categoryName),
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            categoryName,
                            style: GoogleFonts.lato(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          // Pass categoryName and data into our builder
                          children: _buildRecordListWithAddButton(
                            categoryName,
                            categoryData,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Builds a list of record tiles for a category,
  /// plus a button to add new records in that category.
  List<Widget> _buildRecordListWithAddButton(
    String categoryName,
    dynamic categoryData,
  ) {
    final widgets = <Widget>[];

    // 1) If the category data is not a list, just display a fallback tile
    if (categoryData is! List) {
      return [
        ListTile(
          title: Text(
            'Unknown format',
            style: GoogleFonts.lato(fontSize: 16.0),
          ),
          subtitle: Text(
            categoryData.toString(),
            style: GoogleFonts.lato(fontSize: 14.0),
          ),
        ),
      ];
    }

    // 2) If the list is empty, show a "no data" message
    if (categoryData.isEmpty) {
      widgets.add(
        ListTile(
          title: Text(
            'No data available for this category.',
            style: GoogleFonts.lato(fontSize: 16.0),
          ),
        ),
      );
    } else {
      // 3) Otherwise map each record to a ListTile
      for (var record in categoryData) {
        widgets.add(_buildRecordListTile(categoryName, record));
      }
    }

    // 4) At the end, add a small "Add New Record" button
    widgets.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          onPressed: () => _showAddRecordDialog(categoryName),
          icon: const Icon(Icons.add),
          label: Text(
            'Add New Record',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white70,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );

    return widgets;
  }

  /// Shows a dialog with text fields for the user to add a new record
  /// to the specified [categoryName]. We define which fields to collect
  /// based on the category.
  void _showAddRecordDialog(String categoryName) {
    // 1) Determine which fields to ask for
    List<String> fields;
    switch (categoryName.toLowerCase()) {
      case 'vaccinations':
        fields = ['name', 'date', 'dose'];
        break;
      case 'admissions':
        fields = ['admissionDate', 'dischargeDate', 'reason', 'bedNumber'];
        break;
      case 'surgeries':
        fields = ['surgeryName', 'surgeryDate', 'notes'];
        break;
      case 'extra': // <--- NEW
        fields = ['title', 'notes'];
        break;
      default:
        // Fallback for unknown categories
        fields = ['field1', 'field2'];
        break;
    }
    // 2) Create a TextEditingController for each field
    final controllers = <String, TextEditingController>{};
    for (var f in fields) {
      controllers[f] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              // const Icon(Icons.add_box, color: Colors.blueAccent),
              const SizedBox(width: 8.0),
              Text(
                "Add $categoryName Record",
                style: GoogleFonts.lato(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: controllers[field],
                        decoration: InputDecoration(
                          hintStyle: GoogleFonts.lato(color: Colors.grey[400]),

                          labelText: field,
                          prefixIcon: Icon(
                            _getIconForField(field),
                            color: Colors.blueAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                // 3) Build the new record map from user input
                final newRecord = <String, dynamic>{};
                for (var f in fields) {
                  newRecord[f] = controllers[f]!.text.trim();
                }

                // 4) Add it to the chosen category
                setState(() {
                  (hospitalRecords[categoryName] as List).add(newRecord);
                });

                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  /// Returns an icon that matches the given field name.
  /// Customize as needed for your field labels.
  IconData _getIconForField(String field) {
    switch (field.toLowerCase()) {
      case 'name':
      case 'surgeryname':
        return Icons.medical_information; // or Icons.person, etc.
      case 'date':
      case 'admissiondate':
      case 'dischargedate':
      case 'surgerydate':
        return Icons.calendar_today;
      case 'dose':
        return Icons.vaccines;
      case 'reason':
        return Icons.help;
      case 'bednumber':
        return Icons.bed;
      case 'notes':
        return Icons.description;
      default:
        return Icons.edit_note;
    }
  }

  /// Builds a *single record* tile with a concise display.
  Widget _buildRecordListTile(
    String categoryName,
    Map<String, dynamic> record,
  ) {
    String titleText = 'Record';
    String subtitleText = '';

    // Customize the display based on category
    switch (categoryName.toLowerCase()) {
      case 'extra':
        final entryTitle = record['title'] ?? 'Untitled';
        final entryNotes = record['notes'] ?? 'No notes';
        titleText = entryTitle;
        subtitleText = 'Notes: $entryNotes';
        break;

      case 'vaccinations':
        // Example: "COVID-19 (2nd dose)"
        final vaccineName = record['name'] ?? 'Unknown Vaccine';
        final dose = record['dose'] ?? 'N/A';
        final date = record['date'] ?? 'No Date';
        titleText = '$vaccineName ($dose)';
        subtitleText = 'Date: $date';
        break;

      case 'admissions':
        // Example: "Surgery - 2022-01-05" + "Bed #: B12"
        final reason = record['reason'] ?? 'No Reason';
        final admissionDate = record['admissionDate'] ?? 'N/A';
        final dischargeDate = record['dischargeDate'] ?? 'N/A';
        final bedNumber = record['bedNumber'] ?? 'N/A';
        titleText = '$reason - $admissionDate';
        subtitleText = 'Discharged: $dischargeDate • Bed #: $bedNumber';
        break;

      case 'surgeries':
        // Example: "Appendectomy (2019-05-10)" + "Notes: No complications"
        final surgeryName = record['surgeryName'] ?? 'No Name';
        final surgeryDate = record['surgeryDate'] ?? 'No Date';
        final notes = record['notes'] ?? 'No Notes';
        titleText = '$surgeryName ($surgeryDate)';
        subtitleText = 'Notes: $notes';
        break;

      default:
        // Fallback for unknown categories:
        // show one-line summary of all key-values
        titleText = record.keys.map((k) => record[k]).join(' • ');
        subtitleText = record.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(' | ');
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Text(
          titleText,
          style: GoogleFonts.lato(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitleText,
          style: GoogleFonts.lato(fontSize: 14.0, color: Colors.grey[700]),
        ),
        trailing: const Icon(Icons.edit, color: Colors.grey),
        onTap: () {
          _showEditHospitalRecordDialog(categoryName, record);
        },
      ),
    );
  }

  /// Dialog to edit each field in a given record
  void _showEditHospitalRecordDialog(
    String categoryName,
    Map<String, dynamic> record,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $categoryName"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: record.length,
              itemBuilder: (context, index) {
                final key = record.keys.elementAt(index);
                final value = record[key].toString();
                return ListTile(
                  title: Text(key),
                  subtitle: Text(value),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    // Close this AlertDialog, open an edit dialog for the field
                    Navigator.of(context).pop();
                    _showEditDialog('$categoryName ($key)', value, "records", (
                      newValue,
                    ) {
                      setState(() {
                        record[key] = newValue;
                      });
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  /// Generic text field dialog for editing a single value
  // dart
  void _showEditDialog(
    String title,
    String currentValue,
    String opType,
    ValueChanged<String> onValueChanged,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blueAccent),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  "Edit $title",
                  style: GoogleFonts.lato(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.lato(fontSize: 18.0),
                decoration: InputDecoration(
                  hintText: 'Enter new $title',
                  hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                textStyle: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                debugPrint("/patient/${widget.patientId}/$opType");
                http.Response update = await MyHttpClient.put(
                  "/patient/${widget.patientId}/$opType",
                  {title: controller.text},
                );

                if (update.statusCode != 200) {
                  debugPrint("Error updating $title: ${update.body}");
                  showSimpleNotification(
                    Text(
                      'Error updating $title: ${update.body}',
                      style: GoogleFonts.lato(color: Colors.white),
                    ),
                    leading: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                    ),
                    background: Colors.redAccent,
                  );
                } else {
                  onValueChanged(controller.text);
                  showSimpleNotification(
                    Text(
                      '$title updated successfully!',
                      style: GoogleFonts.lato(color: Colors.white),
                    ),
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    background: Colors.greenAccent,
                  );
                }

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  /// Reusable ListTile builder for single-line edits (patient history, etc.)
  Widget _buildEditableListTile({
    required String title,
    required String value,
    required String opType,
    required IconData icon,
    required ValueChanged<String> onValueChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: GoogleFonts.lato(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value, style: GoogleFonts.lato(fontSize: 16.0)),
      trailing:
          title != "Last Visit"
              ? const Icon(Icons.edit, color: Colors.grey)
              : null,
      onTap: () {
        if (title == "Last Visit") {
          return;
        }
        // Show a text field dialog for editing also send the patient id
        _showEditDialog(title, value, opType, onValueChanged);
      },
    );
  }

  /// Generic text field dialog for editing a single value

  /// Returns an icon for the patient history fields
  IconData _getHistoryIcon(String key) {
    switch (key) {
      case 'Last Visit':
        return Icons.calendar_today;
      case 'Diagnosis':
        return Icons.local_hospital;
      case 'Medications':
        return Icons.medication;
      case 'Allergies':
        return Icons.warning;
      case 'Family History':
        return Icons.family_restroom;
      case 'Lifestyle Recommendations':
        return Icons.thumb_up;
      default:
        return Icons.info;
    }
  }

  /// Returns an icon for the full details fields
  IconData _getDetailsIcon(String key) {
    switch (key) {
      case 'Age':
        return Icons.cake;
      case 'Gender':
        return Icons.person;
      case 'Blood Type':
        return Icons.bloodtype;
      case 'Contact':
        return Icons.phone;
      case 'Address':
        return Icons.home;
      default:
        return Icons.info;
    }
  }

  /// Returns an icon for the hospital record categories
  IconData _getHospitalRecordIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'vaccinations':
        return Icons.vaccines;
      case 'admissions':
        return Icons.local_hospital;
      case 'surgeries':
        return Icons.healing;
      case 'extra': // <<-- Optionally add
        return Icons.sticky_note_2; // or any icon you like

      default:
        return Icons.info_outline;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Transcribe Mode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          Padding(
            padding: const EdgeInsets.all(
              16.0,
            ).copyWith(top: kToolbarHeight + 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildPatientInfoCard(),
                const SizedBox(height: 16.0),
                _buildRecordButtonsRow(),
                const SizedBox(height: 32.0),
                Expanded(child: _buildWaveformOrInstruction()),
                const SizedBox(height: 32.0),
                if (!kIsWeb) _buildRecordingButton(),
                const SizedBox(height: 16.0),
                if (!kIsWeb)
                  Text(
                    isRecording ? 'Recording...' : 'Start Transcribe Mode',
                    style: GoogleFonts.lato(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child:
                _isLoading ? _buildLoadingOverlay() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 1) Background Gradient
  Widget _buildBackgroundGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  /// 2) Patient Info Card
  Widget _buildPatientInfoCard() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          radius: 25,
          child: Text(
            widget.patientName.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          widget.patientName,
          style: GoogleFonts.lato(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Patient ID: ${widget.patientId}',
          style: GoogleFonts.lato(fontSize: 16.0),
        ),
      ),
    );
  }

  /// 3) Row of Buttons (Patient History, Full Details, Hospital Records)
  Widget _buildRecordButtonsRow() {
    return Wrap(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      runSpacing: 15,
      spacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: _showPatientHistoryBottomSheet,
          icon: const Icon(Icons.history),
          label: Text(
            'Patient History',
            style: GoogleFonts.lato(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: _buildButtonStyle(),
        ),
        ElevatedButton.icon(
          onPressed: _showFullDetailsBottomSheet,
          icon: const Icon(Icons.person),
          label: Text(
            'Personal Details',
            style: GoogleFonts.lato(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: _buildButtonStyle(),
        ),
        ElevatedButton.icon(
          onPressed: _showHospitalRecordsBottomSheet,
          icon: const Icon(Icons.local_hospital),
          label: Text(
            'Hospital Records',
            style: GoogleFonts.lato(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: _buildButtonStyle(),
        ),
      ],
    );
  }

  /// Button style used in the above row
  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white70,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    );
  }

  /// 4) Either show the AudioWaveforms or an instruction Text

  Widget _buildWaveformOrInstruction() {
    if (kIsWeb) {
      return Center(
        child: Text(
          'Audio recording & waveform visualization are not supported on web.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 18.0, color: Colors.white),
        ),
      );
    } else {
      if (isRecording) {
        return AudioWaveforms(
          recorderController: _recorderController,
          size: const Size(double.infinity, 200.0),
          waveStyle: const WaveStyle(
            waveColor: Colors.white,
            extendWaveform: true,
            showMiddleLine: false,
            scaleFactor: 120,
          ),
        );
      } else {
        return Center(
          child: Text(
            'Tap the button below to start transcribing the conversation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 18.0, color: Colors.white),
          ),
        );
      }
    }
  }

  /// 5) Circular Record / Stop button with a pulsating animation
  Widget _buildRecordingButton() {
    return GestureDetector(
      onTap: _startOrStopRecording,
      child: Transform.scale(
        scale: isRecording ? _animationController.value : 1.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? Colors.redAccent : Colors.greenAccent[700],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8.0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24.0),
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            size: 48.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 6) Loading Overlay when sending/processing data
  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitWave(color: Colors.white, size: 48.0),
              const SizedBox(height: 16.0),
              Text(
                _loadingMessage,
                style: GoogleFonts.lato(fontSize: 18.0, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationListTile({
    required String title,
    required List<Map<String, dynamic>> medications,
    required IconData icon,
    required Function(List<Map<String, dynamic>>) onEditComplete,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: GoogleFonts.lato(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${medications.length} medication${medications.length != 1 ? 's' : ''} prescribed',
          style: GoogleFonts.lato(fontSize: 14.0),
        ),
        children: [
          ...medications.map((med) {
            // Extract medication data
            final name = med['medication'] ?? 'Unknown';
            final dosage = med['dosage'] ?? 'Unspecified';
            final frequency = med['frequency'] ?? 'Unspecified';
            final duration = med['duration'] ?? 'Unspecified';

            // Warning check
            final warningProb =
                double.tryParse(
                  med['wrong_medication_probability']?.toString() ?? '0',
                ) ??
                0;
            final warningReason = med['wrong_medication_reason'] ?? '';
            final hasWarning = warningProb > 0.5;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: hasWarning ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
                  if (hasWarning)
                    Tooltip(
                      message: warningReason,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dosage: $dosage',
                    style: GoogleFonts.lato(fontSize: 14.0),
                  ),
                  Text(
                    'Frequency: $frequency',
                    style: GoogleFonts.lato(fontSize: 14.0),
                  ),
                  Text(
                    'Duration: $duration',
                    style: GoogleFonts.lato(fontSize: 14.0),
                  ),
                  if (hasWarning)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(top: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        warningReason,
                        style: GoogleFonts.lato(
                          fontSize: 12.0,
                          color: Colors.deepOrange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed:
                    () => _showMedicationEditDialog(med, (updatedMed) {
                      setState(() {
                        // Find and replace the medication in the list
                        final index = medications.indexOf(med);
                        if (index >= 0) {
                          medications[index] = updatedMed;
                          onEditComplete(medications);
                        }
                      });
                    }),
              ),
            );
          }),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text('Add Medication', style: GoogleFonts.lato()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  () => _showMedicationEditDialog({}, (newMed) {
                    setState(() {
                      medications.add(newMed);
                      onEditComplete(medications);
                    });
                  }),
            ),
          ),
        ],
      ),
    );
  }

  // Add medication edit dialog
  void _showMedicationEditDialog(
    Map<String, dynamic> medication,
    Function(Map<String, dynamic>) onSave,
  ) {
    // Create controllers for each field
    final nameController = TextEditingController(
      text: medication['medication']?.toString() ?? '',
    );

    // Default values for dropdowns
    String selectedDosage = medication['dosage']?.toString() ?? 'Select dosage';
    String selectedFrequency =
        medication['frequency']?.toString() ?? 'Select frequency';
    String selectedDuration =
        medication['duration']?.toString() ?? 'Select duration';

    // Preserve warning data if it exists
    final wrongProb = medication['wrong_medication_probability'] ?? 0;
    final wrongReason = medication['wrong_medication_reason'] ?? '';
    final alternativeSuggestion =
        medication['alternative_suggestion']?.toString();

    // Common dosage options
    final dosageOptions = [
      'Select dosage',
      '5mg',
      '10mg',
      '20mg',
      '25mg',
      '50mg',
      '75mg',
      '100mg',
      '200mg',
      '250mg',
      '500mg',
      '1g',
      'Other',
    ];

    // Common frequency options
    final frequencyOptions = [
      'Select frequency',
      'Once daily',
      'Twice daily',
      'Three times daily',
      'Four times daily',
      'Every 4 hours',
      'Every 6 hours',
      'Every 8 hours',
      'Every 12 hours',
      'As needed',
      'Other',
    ];

    // Common duration options
    final durationOptions = [
      'Select duration',
      '3 days',
      '5 days',
      '7 days',
      '10 days',
      '14 days',
      '1 month',
      '3 months',
      '6 months',
      'Ongoing',
      'Other',
    ];

    // For custom entry with "Other" option
    final customDosageController = TextEditingController();
    final customFrequencyController = TextEditingController();
    final customDurationController = TextEditingController();

    // Check if the current values exist in our options
    if (!dosageOptions.contains(selectedDosage) &&
        selectedDosage != 'Select dosage') {
      customDosageController.text = selectedDosage;
      selectedDosage = 'Other';
    }

    if (!frequencyOptions.contains(selectedFrequency) &&
        selectedFrequency != 'Select frequency') {
      customFrequencyController.text = selectedFrequency;
      selectedFrequency = 'Other';
    }

    if (!durationOptions.contains(selectedDuration) &&
        selectedDuration != 'Select duration') {
      customDurationController.text = selectedDuration;
      selectedDuration = 'Other';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return AlertDialog(
              title: const Text('Edit Medication'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication name field
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    // Alternative suggestion if available
                    if (alternativeSuggestion != null &&
                        alternativeSuggestion.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: InkWell(
                          onTap: () {
                            setStateLocal(() {
                              nameController.text = alternativeSuggestion;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Suggested: $alternativeSuggestion',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.touch_app,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Dosage dropdown
                    const Text(
                      'Dosage:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: double.infinity,
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: selectedDosage,
                            isExpanded: true,
                            items:
                                dosageOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setStateLocal(() {
                                selectedDosage = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // Custom dosage field if "Other" is selected
                    if (selectedDosage == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: customDosageController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Dosage',
                            border: OutlineInputBorder(),
                            hintText: 'Enter custom dosage',
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Frequency dropdown
                    const Text(
                      'Frequency:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: double.infinity,
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: selectedFrequency,
                            isExpanded: true,
                            items:
                                frequencyOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setStateLocal(() {
                                selectedFrequency = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // Custom frequency field if "Other" is selected
                    if (selectedFrequency == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: customFrequencyController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Frequency',
                            border: OutlineInputBorder(),
                            hintText: 'Enter custom frequency',
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Duration dropdown
                    const Text(
                      'Duration:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: double.infinity,
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: selectedDuration,
                            isExpanded: true,
                            items:
                                durationOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setStateLocal(() {
                                selectedDuration = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // Custom duration field if "Other" is selected
                    if (selectedDuration == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: customDurationController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Duration',
                            border: OutlineInputBorder(),
                            hintText: 'Enter custom duration',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Determine the final values (either from dropdown or custom)
                    final finalDosage =
                        selectedDosage == 'Other'
                            ? customDosageController.text
                            : (selectedDosage == 'Select dosage'
                                ? ''
                                : selectedDosage);

                    final finalFrequency =
                        selectedFrequency == 'Other'
                            ? customFrequencyController.text
                            : (selectedFrequency == 'Select frequency'
                                ? ''
                                : selectedFrequency);

                    final finalDuration =
                        selectedDuration == 'Other'
                            ? customDurationController.text
                            : (selectedDuration == 'Select duration'
                                ? ''
                                : selectedDuration);

                    final updatedMedication = {
                      'medication': nameController.text,
                      'dosage': finalDosage,
                      'frequency': finalFrequency,
                      'duration': finalDuration,
                      // Preserve the warning flags
                      'wrong_medication_probability': wrongProb,
                      'wrong_medication_reason': wrongReason,
                      'alternative_suggestion': alternativeSuggestion,
                    };

                    onSave(updatedMedication);
                    Navigator.pop(context);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
