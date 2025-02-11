import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class UberduckService {
  static final String _baseUrl = 'https://api.uberduck.ai';
  static String? get _apiKey => dotenv.env['UBERDUCK_API_KEY'];
  static String? get _apiSecret => dotenv.env['UBERDUCK_API_SECRET'];

  // Basic auth header using API key and secret
  static String get _authHeader => 'Basic ${base64Encode(
    utf8.encode('${_apiKey}:${_apiSecret}')
  )}';

  // Generate a song using the Uberduck API
  static Future<Map<String, dynamic>> generateSong({
    required String lyrics,
    required String style_preset,
    String? voicemodel_uuid,
  }) async {
    print('🎵 Attempting to generate song with lyrics: ${lyrics.substring(0, math.min(50, lyrics.length))}...');
    print('🎸 Style preset: $style_preset');
    if (voicemodel_uuid != null) {
      print('🎤 Voice model UUID: $voicemodel_uuid');
    }

    if (_apiKey == null || _apiSecret == null) {
      print('❌ API credentials missing!');
      throw Exception('Uberduck API credentials not found in environment variables');
    }

    final requestBody = {
      'lyrics': lyrics,
      'style_preset': style_preset,
      if (voicemodel_uuid != null) 'voicemodel_uuid': voicemodel_uuid,
    };

    print('📤 Sending request to $_baseUrl/generate-song');
    print('📦 Request body: $requestBody');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-song'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Successfully generated song. Response data: $responseData');
        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        print('❌ Failed to generate song. Error body: $errorBody');
        throw Exception(errorBody['detail'] ?? 'Failed to generate song');
      }
    } catch (e) {
      print('❌ Exception during song generation: $e');
      rethrow;
    }
  }

  // Check the status of a generation
  static Future<Map<String, dynamic>> checkStatus(String uuid) async {
    print('🔍 Checking status for UUID: $uuid');

    if (_apiKey == null || _apiSecret == null) {
      print('❌ API credentials missing during status check!');
      throw Exception('Uberduck API credentials not found in environment variables');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status/$uuid'),
        headers: {
          'Authorization': _authHeader,
        },
      );

      print('📥 Status check response code: ${response.statusCode}');
      print('📥 Status check response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Successfully retrieved status. Response data: $responseData');
        return responseData;
      } else {
        print('❌ Failed to check status. Response: ${response.body}');
        throw Exception('Failed to check status: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception during status check: $e');
      rethrow;
    }
  }
} 