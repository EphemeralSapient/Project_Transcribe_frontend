//  import 'package:flutter/material.dart';

// void showFullDetailsBottomSheet(BuildContext context, Function setState) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Fetch dynamic patient details
//       Map<String, dynamic> fetcheddetailsUnfiltered = await fetchPatientDetails(
//         widget.patientId,
//       );

//       Map<String, String> fetchedDetails = {};

//       // Filter out null values and convert to string and proper key name for detailicon thing
//       if (fetcheddetailsUnfiltered.containsKey("age")) {
//         fetchedDetails["Age"] = fetcheddetailsUnfiltered["age"].toString();
//       } else {
//         fetchedDetails["Age"] = "Nil";
//       }

//       if (fetcheddetailsUnfiltered.containsKey("first_name") &&
//           fetcheddetailsUnfiltered.containsKey("last_name")) {
//         fetchedDetails["Name"] =
//             fetcheddetailsUnfiltered["first_name"] +
//             " ${fetcheddetailsUnfiltered["last_name"]}";
//       } else {
//         fetchedDetails["Name"] = "Nil";
//       }

//       if (fetcheddetailsUnfiltered.containsKey("gender")) {
//         fetchedDetails["Gender"] = fetcheddetailsUnfiltered["gender"];
//       } else {
//         fetchedDetails["Gender"] = "Nil";
//       }

//       if (fetcheddetailsUnfiltered.containsKey("blood_type")) {
//         fetchedDetails["Blood Type"] = fetcheddetailsUnfiltered["blood_type"];
//       } else {
//         fetchedDetails["Blood Type"] = "Nil";
//       }

//       if (fetcheddetailsUnfiltered.containsKey("contact_phone")) {
//         fetchedDetails["Contact"] = fetcheddetailsUnfiltered["contact_phone"];
//       } else {
//         fetchedDetails["Contact"] = "Nil";
//       }

//       if (fetcheddetailsUnfiltered.containsKey("address")) {
//         fetchedDetails["Address"] = fetcheddetailsUnfiltered["address"];
//       } else {
//         fetchedDetails["Address"] = "Nil";
//       }

//       setState(() {
//         _isLoading = false;
//         patientDetails = fetchedDetails;
//       });

//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.white.withOpacity(0.9),
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
//         ),
//         builder: (context) {
//           return Padding(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//             ),
//             child: DraggableScrollableSheet(
//               expand: false,
//               maxChildSize: 0.8,
//               minChildSize: 0.3,
//               initialChildSize: 0.5,
//               builder: (context, scrollController) {
//                 return ListView(
//                   controller: scrollController,
//                   padding: const EdgeInsets.all(16.0),
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 50,
//                         height: 5,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(12.0),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16.0),
//                     Text(
//                       'Full Details',
//                       style: GoogleFonts.lato(
//                         fontSize: 24.0,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16.0),
//                     ...patientDetails.entries.map((entry) {
//                       return _buildEditableListTile(
//                         title: entry.key,
//                         value: entry.value,
//                         opType: "details",
//                         icon: _getDetailsIcon(entry.key),
//                         onValueChanged: (newValue) {
//                           setState(() {
//                             patientDetails[entry.key] = newValue;
//                           });
//                         },
//                       );
//                     }),
//                   ],
//                 );
//               },
//             ),
//           );
//         },
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       showSimpleNotification(
//         Text(
//           'Error fetching patient details: $e',
//           style: const TextStyle(color: Colors.white),
//         ),
//         leading: const Icon(Icons.error_outline, color: Colors.white),
//         background: Colors.redAccent,
//       );
//     }
//   }
