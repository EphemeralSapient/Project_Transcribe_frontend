import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:transcribe/dashboard/options.dart'
    show showProfileOptionsBottomSheet;
import 'package:transcribe/doctor_ui/appointment/add_appointment.dart'
    show showAddAppointmentBottomSheet;
import 'package:transcribe/doctor_ui/appointment/main_tab.dart'
    show buildAppointmentsTab;
import 'package:transcribe/doctor_ui/patient_history/main_tab.dart'
    show buildPatientHistoryTab;

import '../common/global.dart' as global;

class CustomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double curveHeight = 50.0; // Adjust this value to control the curve depth
    Path path =
        Path()
          ..lineTo(0, size.height - curveHeight)
          ..quadraticBezierTo(
            size.width / 2,
            size.height + curveHeight,
            size.width,
            size.height - curveHeight,
          )
          ..lineTo(size.width, 0)
          ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DoctorWidget extends StatefulWidget {
  const DoctorWidget({super.key});

  @override
  _DoctorWidgetState createState() => _DoctorWidgetState();
}

class _DoctorWidgetState extends State<DoctorWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Show a bottom sheet for adding a patient by ID
  @override
  Widget build(BuildContext context) {
    debugPrint(global.profilePic);

    var tab =
        _currentIndex == 0
            ? buildAppointmentsTab(context, setState)
            : buildPatientHistoryTab(setState);
    return Scaffold(
      // FAB only visible on the Appointments tab
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton.extended(
                onPressed:
                    () => {showAddAppointmentBottomSheet(context, setState)},
                backgroundColor: Colors.lightBlue[300],
                label: const Text('Add Patient'),
                icon: const Icon(Icons.add),
              )
              : null,
      body: Stack(
        children: [
          // A curved AppBar background using the custom clipper
          ClipPath(
            clipper: CustomShapeClipper(),
            child: Container(
              height: 160.0, // Adjust the height as needed
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Doctor's Name & Profile
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left spacer if needed
                          const SizedBox(width: 48.0),
                          Column(
                            children: [
                              Text(
                                'Dr. ${global.name}',
                                style: GoogleFonts.lato(
                                  fontSize: 26.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                global.speciality,
                                style: GoogleFonts.lato(
                                  fontSize: 16.0,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),

                          // dart
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  offset: const Offset(0, 4),
                                  blurRadius: 4.0,
                                ),
                              ],
                            ),
                            child: Material(
                              elevation: 4.0,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: ClipOval(
                                child: InkWell(
                                  onTap:
                                      () => showProfileOptionsBottomSheet(
                                        context,
                                      ),
                                  child: Image.network(
                                    global.profilePic,
                                    width: 48.0,
                                    height: 48.0,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (
                                      BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 48.0,
                                        height: 48.0,
                                        alignment: Alignment.center,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (
                                      BuildContext context,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) {
                                      return Container(
                                        width: 48.0,
                                        height: 48.0,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content below the curved AppBar
          Container(margin: const EdgeInsets.only(top: 200.0), child: tab),
        ],
      ),
      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Patient History',
          ),
        ],
      ),
    );
  }
}
