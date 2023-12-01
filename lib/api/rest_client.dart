import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class RestClient {
  static const String baseUrl = 'sacredvest.backendless.app';
  static const Map<String, String> _requestHeaders = {
    'Content-Type': 'application/json',
  };

  RestClient();

  Future<String> doGet(String endpoint,
      [Map<String, dynamic>? queryParameters]) async {
    final response = await http.get(
      Uri.https(
        baseUrl,
        endpoint,
        queryParameters,
      ),
      headers: _requestHeaders,
    );

    return _returnResultOrError(response);
  }

  Future<String> _returnResultOrError(http.Response response) {
    final body = convert.utf8.decode(response.bodyBytes);
    if (response.statusCode >= 400) {
      String message;
      try {
        message = convert.jsonDecode(body)["message"];
      } on Exception {
        message = body;
      }

      return Future.error("${response.statusCode}: $message");
    }

    return Future.value(body);
  }
}
