import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transcribe/common/global.dart' as global;
import 'package:transcribe/common/http.dart' show MyHttpClient;
import 'package:transcribe/common/overlay.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Biometric variables
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false;
  bool _hasToken = false;

  // Loading indicator flag
  bool _isLoading = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAvailability();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check biometrics
  void _checkBiometricsAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      setState(() {
        _hasToken =
            token != null && token.isNotEmpty && token != "your_token_here";
        debugPrint("Token: $_hasToken");
      });

      bool canCheck = await auth.canCheckBiometrics;
      setState(() => _canCheckBiometrics = canCheck);
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
    } on Exception catch (_) {
      debugPrint("Biometric feature is not supported");
    }
  }

  // Handle login
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      var token = "JWT Token!";
      var role = "doctor";
      var name = 'Unknown User';
      var profilePic = 'https://example.com';

      // Converting given password to sha-256 hash hex string
      var bytes = utf8.encode(_passwordController.text);
      var digest = sha256.convert(bytes);
      var passwordHash = digest.toString();

      try {
        var response = await MyHttpClient.post("/auth/login", {
          'username': _userIdController.text,
          'password': passwordHash,
        });

        // Show full detailed response data
        debugPrint("Response: ${response.body}");
        debugPrint("Status code: ${response.statusCode}");
        debugPrint("Headers: ${response.headers}");

        // Dismiss loading indicator
        setState(() => _isLoading = false);

        // Possible errors from HTTP
        if (response.statusCode == 401) {
          _showError('Invalid credentials');
          return;
        }

        if (response.statusCode != 200) {
          _showError('Error connecting to server: ${response.statusCode}');
          return;
        }

        // Parse response data
        var data = jsonDecode(response.body);
        token = data['token'];
        role = data['role'];
        name = data['name'];
        profilePic = data['profilePic'];

        // We are done I guess
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Error connecting to server: $e');
        return;
      }

      await prefs.setString('token', token);
      await prefs.setString('role', role);
      await prefs.setString("name", name);
      await prefs.setString("profilePic", profilePic);
      global.token = token;
      global.name = name;
      global.role = role;
      global.profilePic = profilePic;

      void revert() {
        prefs.setString("token", "");
        prefs.setString("role", "");
        prefs.setString("name", "");
      }

      // Handle doctor information
      if (role == "doctor") {
        // Fetch the doctor information
        try {
          var response = await MyHttpClient.get("/doctor/info");

          if (response.statusCode != 200) {
            _showError("Failed to retrive doctor info: ${response.statusCode}");
            revert();
            return;
          }

          Map<String, dynamic> data = jsonDecode(response.body);

          debugPrint(
            "Doctor speciality is: ${data['specialty']} and experience is: ${data['experience']} and phone is: ${data['phone']}",
          );
          global.speciality = data['specialty'].toString();
          global.yearsOfExperience = data['experience'].toString();
          global.phone = data['phone'].toString();

          await prefs.setString("specialty", global.speciality);
          await prefs.setString("experience", global.yearsOfExperience);
          await prefs.setString("phone", global.phone);

          debugPrint("Doctor info: $data");
        } catch (e) {
          revert();
          debugPrint("Error fetching doctor info: $e");
        }
      }

      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  // Biometric auth
  Future<void> _authenticateWithBiometrics() async {
    try {
      setState(() => _isAuthenticating = true);
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      setState(() => _isAuthenticating = false);
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        var token = prefs.getString('token');

        if (token == "your_token_heree") {
          token = null;
        }

        if (token != null && token.isNotEmpty) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _showError('No valid token found! Please log in first.');
        }
      } else {
        _showError('Biometric authentication failed');
      }
    } on PlatformException catch (e) {
      setState(() => _isAuthenticating = false);
      _showError('Error during authentication: ${e.message}');
    }
  }

  void _showError(String message) {
    OverlayNotification.show(
      context: context,
      message: message,
      backgroundColor: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset('assets/background.png', fit: BoxFit.cover),
          ),
          // Overlay
          Container(color: Colors.black.withOpacity(0.5)),
          // Form
          FadeTransition(
            opacity: _animation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        // Warm greetings
                        _hasToken == true
                            ? "Sign in to proceed"
                            : 'Welcome back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 48.0),
                      TextFormField(
                        controller: _userIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          label: 'User ID',
                          icon: Icons.person,
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Please enter your user ID'
                                    : null,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          label: 'Password',
                          icon: Icons.lock,
                        ),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Please enter your password'
                                    : (value.length < 6)
                                    ? 'Password must be at least 6 characters'
                                    : null,
                      ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _canCheckBiometrics && _hasToken
                          ? Column(
                            children: [
                              const Text(
                                'Or login using biometric authentication',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8.0),

                              IconButton(
                                iconSize: 64.0,
                                icon: const Icon(
                                  Icons.fingerprint,
                                  color: Colors.white,
                                ),
                                onPressed:
                                    _isAuthenticating
                                        ? null
                                        : _authenticateWithBiometrics,
                              ),
                            ],
                          )
                          : Container(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: SpinKitCubeGrid(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      hintText: 'Enter your $label',
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide.none,
      ),
    );
  }
}
