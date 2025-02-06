import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart' show SpinKitPulsingGrid;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:overlay_support/overlay_support.dart'
    show showSimpleNotification;
import 'package:transcribe/common/http.dart' show MyHttpClient;
import 'package:transcribe/doctor_ui/appointment/card.dart'
    show buildAppointmentCard;
import 'package:transcribe/doctor_ui/appointment/fetch_data.dart'
    show fetchAppointments;

Widget buildAppointmentsTab(BuildContext context, Function setState) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future:
        fetchAppointments(), // Ensure this returns your appointments list asynchronously
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: SpinKitPulsingGrid(color: Colors.blueAccent, size: 50.0),
        );
      } else if (snapshot.hasError) {
        debugPrint(snapshot.stackTrace.toString());
        return Center(
          child: AnimationConfiguration.synchronized(
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64.0,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Oops! Something went wrong.',
                        style: GoogleFonts.lato(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.lato(
                          fontSize: 16.0,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          textStyle: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return AnimationConfiguration.synchronized(
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 80.0,
                        color: Colors.blueAccent.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'No Appointments Found',
                        style: GoogleFonts.lato(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Tap refresh or add a patient.',
                        style: GoogleFonts.lato(
                          fontSize: 16.0,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          textStyle: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        final appointments = snapshot.data!;
        return Container(
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.1, 0.9, 1.0],
              colors: [
                Theme.of(
                  context,
                ).scaffoldBackgroundColor, // Fully opaque at top
                Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.0), // Fade out
                Theme.of(context).scaffoldBackgroundColor.withOpacity(
                  0.0,
                ), // Transparent center
                Theme.of(
                  context,
                ).scaffoldBackgroundColor, // Fully opaque at bottom
              ],
            ),
          ),
          child: AnimationLimiter(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const SizedBox(height: 50),
                for (int index = 0; index < appointments.length; index++)
                  Dismissible(
                    key: ValueKey(appointments[index]['patientId']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Icon(Icons.delete, color: Colors.black),
                          SizedBox(width: 8.0),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 16.0),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('Confirm Deletion'),
                                  content: Text(
                                    'Are you sure you want to remove the appointment for ${appointments[index]['patientName']}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(ctx).pop(false),
                                      child: const Text('CANCEL'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        var response = await MyHttpClient.delete(
                                          "/doctor/appointment-schedules/${appointments[index]['id']}",
                                        );
                                        if (response.statusCode != 200) {
                                          showSimpleNotification(
                                            Text(
                                              "Failed to delete appointment | ${response.body}",
                                            ),
                                            background: Colors.red,
                                            leading: const Icon(Icons.error),
                                          );
                                        } else {
                                          showSimpleNotification(
                                            const Text(
                                              "Appointment deleted successfully",
                                            ),
                                            background: Colors.green,
                                          );
                                          Navigator.of(ctx).pop(true);
                                          setState(() {});
                                        }
                                      },
                                      child: const Text('DELETE'),
                                    ),
                                  ],
                                ),
                          ) ??
                          false;
                    },
                    onDismissed: (direction) {
                      setState(() => appointments.removeAt(index));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Appointment deleted for ${appointments[index]['patientName']}.',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: AnimationConfiguration.staggeredList(
                      position: index,
                      delay: const Duration(milliseconds: 100),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: buildAppointmentCard(
                            context,
                            appointments[index],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    },
  );
}
