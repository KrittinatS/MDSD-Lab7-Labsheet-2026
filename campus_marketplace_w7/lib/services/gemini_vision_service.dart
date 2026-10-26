import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';
import 'gemini_service.dart';

class GeminiVisionService {
  static const _prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';

  Future<ListingDraft> analyzeProductImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final uri = GeminiService.generateContentUri;
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'category': {
              'type': 'STRING',
              'enum': [
                'หนังสือเรียน',
                'อุปกรณ์อิเล็กทรอนิกส์',
                'ของแต่งหอพัก',
                'เสื้อผ้า',
                'อื่นๆ',
              ],
            },
            'description': {'type': 'STRING'},
          },
          'required': ['title', 'category', 'description'],
        },
      },
    });

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API error (${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Gemini API response format is invalid.');
      }

      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception(
          'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
        );
      }

      final candidate = candidates.first;
      if (candidate is! Map<String, dynamic>) {
        throw Exception('Gemini API response format is invalid.');
      }
      if (candidate['finishReason'] == 'SAFETY') {
        throw Exception(
          'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
        );
      }

      final content = candidate['content'];
      final parts = content is Map<String, dynamic> ? content['parts'] : null;
      if (parts is! List || parts.isEmpty) {
        throw Exception('Gemini API response does not contain text content.');
      }

      final text = parts.first is Map<String, dynamic>
          ? (parts.first as Map<String, dynamic>)['text']
          : null;
      if (text is! String || text.trim().isEmpty) {
        throw Exception('Gemini API returned an empty response.');
      }

      final listingJson = jsonDecode(text);
      if (listingJson is! Map<String, dynamic>) {
        throw Exception('Gemini API returned invalid listing JSON.');
      }

      return ListingDraft.fromJson(listingJson);
    } on TimeoutException {
      throw Exception('Gemini API timeout after 60 seconds.');
    }
  }
}
