import 'dart:convert';
import 'dart:io' show HttpOverrides;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:transcribe/common/global.dart' as global;
import 'package:transcribe/main.dart' show MyHttpOverrides;

// Conditional import: if running on the web, use get_client_web.dart; otherwise use get_client_io.dart.
import 'get_client_io.dart' if (dart.library.html) 'get_client_web.dart';

class MyHttpClient {
  // Uses the platform-specific getClient() function from the imported file.
  static http.Client getClientInstance() {
    // If non-web device then accept insecure connection
    if (!kIsWeb) {
      HttpOverrides.global = MyHttpOverrides();
    }
    return getClient();
  }

  static String baseURL() {
    return dotenv.env['BASE_URL'] ?? '';
  }

  static Future<http.Response> get(String path) async {
    final client = getClientInstance();
    final url = Uri.parse(baseURL() + path);
    final response = await client.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${global.token}",
      },
    );

    client.close();
    return response;
  }

  static Future<http.Response> delete(String path) async {
    final client = getClientInstance();
    final url = Uri.parse(baseURL() + path);
    final response = await client.delete(
      url,
      headers: {"Authorization": "Bearer ${global.token}"},
    );

    client.close();
    return response;
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = getClientInstance();
    final url = Uri.parse(baseURL() + path);
    final response = await client.post(
      url,
      body: jsonEncode(body),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${global.token}",
      },
    );
    client.close();
    return response;
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    debugPrint("Debug: ${jsonEncode(body)}");
    final client = getClientInstance();
    final url = Uri.parse(baseURL() + path);
    final response = await client.put(
      url,
      body: jsonEncode(body),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${global.token}",
      },
    );
    client.close();
    return response;
  }
}
