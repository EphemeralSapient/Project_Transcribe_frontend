import 'package:http/http.dart' as http;

http.Client getClient() {
  // Web can use the default http.Client
  return http.Client();
}
