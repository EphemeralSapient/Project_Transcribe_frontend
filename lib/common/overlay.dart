// File: overlay.dart
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class OverlayNotification {
  /// Displays an overlay notification using overlay_support's [showSimpleNotification].
  static Future<void> show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    double top = 50.0,
    Color backgroundColor = Colors.black,
    double opacity = 0.7,
  }) async {
    showSimpleNotification(
      Text(message, style: const TextStyle(color: Colors.white)),
      background: backgroundColor.withOpacity(opacity),
      autoDismiss: true,
      slideDismissDirection: DismissDirection.up,
      duration: duration,
      position: NotificationPosition.top,
    );
  }
}
