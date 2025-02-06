import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' show IOClient;
import 'package:transcribe/common/global.dart' as global;

class MyHttpClient {
  static http.Client getClient() {
    final HttpClient httpClient =
        HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }

  static baseURL() {
    return dotenv.env['BASE_URL'];
  }

  static Future<http.Response> get(String path) async {
    final client = getClient();
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
    final client = getClient();
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
    final client = getClient();
    final url = Uri.parse(baseURL() + path);
    // debugPrint(body.toString());
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
    debugPrint("Debugging the damn field : ${jsonEncode(body)}} ");
    final client = getClient();
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
