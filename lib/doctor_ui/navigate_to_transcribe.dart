// dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:transcribe/doctor_ui/transcribe.dart' show TranscribeScreen;

void navigateToTranscribeScreen(
  BuildContext context,
  String patientId,
  String patientName,
  String appointmentId,
) {
  Navigator.push(
    context,
    kIsWeb
        ? MaterialPageRoute(
          builder:
              (context) => TranscribeScreen(
                patientId: patientId,
                patientName: patientName,
                appointmentId: appointmentId,
              ),
        )
        : PageRouteBuilder(
          pageBuilder:
              (c, a1, a2) => TranscribeScreen(
                patientId: patientId,
                patientName: patientName,
                appointmentId: appointmentId,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween(
                    begin: 1.5,
                    end: 1.0,
                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 650),
        ),
  );
}
