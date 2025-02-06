import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart' show SpinKitPulsingGrid;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:transcribe/doctor_ui/patient_history/card.dart'
    show buildPatientHistoryCard;
import 'package:transcribe/doctor_ui/patient_history/fetch_data.dart'
    show fetchPatientHistory;

Widget buildPatientHistoryTab(Function setState) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: fetchPatientHistory(),
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
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  size: 80.0,
                  color: Colors.blueAccent.withOpacity(0.6),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'No Patient History Found',
                  style: GoogleFonts.lato(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
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
        );
      } else {
        final histories = snapshot.data!;
        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final patient = histories[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                delay: const Duration(milliseconds: 100),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: buildPatientHistoryCard(patient),
                  ),
                ),
              );
            },
          ),
        );
      }
    },
  );
}
