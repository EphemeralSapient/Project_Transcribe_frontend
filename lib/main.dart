// main.dart

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/global.dart';
import 'dashboard/dashboard.dart';
import 'login.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); // Base URL and such.
  await init(); // Load user data and token
  HttpOverrides.global = MyHttpOverrides();
  runApp(OverlaySupport.global(child: MyApp())); // Notification style
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    var client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Use GoogleFonts for the app
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthenticationWrapper(),
      routes: {
        '/login': (context) => const Login(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkTokenAndAuthenticate();
  }

  Future<void> _checkTokenAndAuthenticate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _hasToken =
          token != null && token.isNotEmpty && token != "your_token_here";
    });

    if (_hasToken) {
      // Token exists, proceed to biometric auth only if not on web
      if (kIsWeb) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _authenticateWithBiometrics();
      }
    } else {
      // No token: direct to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication is not supported on web'),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    try {
      setState(() => _isAuthenticating = true);
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      setState(() => _isAuthenticating = false);
      if (authenticated) {
        if (_hasToken) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid token found! Please log in.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric Authentication Failed!')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on PlatformException catch (e) {
      debugPrint('Error during authentication: $e');
      setState(() => _isAuthenticating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticating
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : const Scaffold(body: Center(child: Text('')));
  }
}
