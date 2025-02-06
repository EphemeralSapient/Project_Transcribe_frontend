import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import '../common/global.dart' as global show token;

void logout(BuildContext context) {
  Navigator.pop(context);
  // Clear user data as needed before logging out.
  global.token = "";
  SharedPreferences.getInstance().then((prefs) {
    prefs.remove('token');
  });
  Navigator.pushReplacementNamed(context, '/login');
}
