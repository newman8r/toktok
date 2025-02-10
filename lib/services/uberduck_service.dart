import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
    required String prompt,
    String model = 'melody-1',  // Default to melody-1 model
    bool? shouldQuantize,
    bool? includeTimepoints,
  }) async {
    print('🎵 Attempting to generate song with prompt: $prompt');
    print('🔑 Using API Key: ${_apiKey?.substring(0, 5)}... and Secret: ${_apiSecret?.substring(0, 5)}...');

    if (_apiKey == null || _apiSecret == null) {
      print('❌ API credentials missing!');
      throw Exception('Uberduck API credentials not found in environment variables');
    }

    final requestBody = {
      'prompt': prompt,
      'model': model,
      if (shouldQuantize != null) 'should_quantize': shouldQuantize,
      if (includeTimepoints != null) 'include_timepoints': includeTimepoints,
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