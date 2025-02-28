import 'package:flutter/material.dart';

import 'diagnosis_saver.dart';

class SummaryWidget extends StatefulWidget {
  final String patientId;
  final String appointmentId;
  final Map<String, dynamic> summarizedData;

  const SummaryWidget({
    super.key,
    required this.patientId,
    required this.appointmentId,
    required this.summarizedData,
  });

  @override
  _SummaryWidgetState createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget> {
  bool _isLoading = false;

  void _saveDiagnosis() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await DiagnosisSaver.saveDiagnosis(
      patientId: widget.patientId,
      appointmentId: widget.appointmentId,
      summarizedData: widget.summarizedData,
      setLoading: (value) {
        if (mounted) {
          setState(() {
            _isLoading = value;
          });
        }
      },
      context: context,
    );

    if (success && mounted) {
      // Show success notification
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Diagnosis saved successfully')));
    } else if (mounted) {
      // Show error notification
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save diagnosis')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Your widget UI here
      child:
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                onPressed: _saveDiagnosis,
                child: Text('Save Diagnosis'),
              ),
    );
  }
}
