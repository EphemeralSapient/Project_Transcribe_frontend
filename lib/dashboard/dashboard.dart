import 'package:flutter/material.dart';
import "package:transcribe/doctor_ui/main_ui.dart" show DoctorWidget;

enum AccountType { doctor, receptionist, pharmacist }

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    // TODO : Check the account type
    return DoctorWidget();
  }
}
