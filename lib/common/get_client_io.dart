import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' show IOClient;

http.Client getClient() {
  final HttpClient httpClient =
      HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
  return IOClient(httpClient);
}
