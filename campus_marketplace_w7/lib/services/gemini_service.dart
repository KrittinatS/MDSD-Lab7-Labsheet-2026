import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  static const _model = 'gemini-3.5-flash-lite';
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static Uri get generateContentUri {
    if (_apiKey.trim().isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is not set. Run with '
        '--dart-define=GEMINI_API_KEY=YOUR_API_KEY.',
      );
    }

    return Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_model:generateContent?key=$_apiKey',
    );
  }

  Future<String> generateText(String prompt) async {
    final uri = generateContentUri;

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API error (${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final candidates = decoded['candidates'];

      if (candidates == null || candidates is! List || candidates.isEmpty) {
        throw Exception('Gemini API response does not contain any candidates.');
      }

      final firstCandidate = candidates.first;
      if (firstCandidate is! Map<String, dynamic>) {
        throw Exception('Gemini API response format is invalid.');
      }

      final content = firstCandidate['content'];
      final parts = content != null ? content['parts'] : null;

      if (parts == null || parts is! List || parts.isEmpty) {
        throw Exception('Gemini API response does not contain text content.');
      }

      final text = parts.first['text'];
      if (text == null || text is! String || text.trim().isEmpty) {
        throw Exception('Gemini API returned an empty response.');
      }

      return text.trim();
    } on TimeoutException {
      throw Exception('Gemini API timeout after 20 seconds.');
    }
  }
}
