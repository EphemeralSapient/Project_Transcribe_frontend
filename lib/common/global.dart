// Used to store global variables only
library;

import 'package:shared_preferences/shared_preferences.dart';

// Important user data
String role = "doctor";
String token = "JWT Token";
String name = "Unknown User";

// Doctor related fields
String speciality = "General";
String yearsOfExperience = "0";

// General field
String phone = "0000000000";
String profilePic = "https://example.com";

Future<void> init() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  role = prefs.getString('role') ?? "doctor";
  token = prefs.getString('token') ?? "your_token_here";
  name = prefs.getString('name') ?? "Unknown User";

  speciality = prefs.getString('speciality') ?? "General";
  yearsOfExperience = prefs.getString('yearsOfExperience') ?? "0";

  phone = prefs.getString('phone') ?? "0000000000";
  profilePic = prefs.getString("profilePic") ?? "https://example.com";
}
