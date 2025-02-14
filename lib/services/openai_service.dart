import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'langsmith_service.dart';

class OpenAIService {
  static final String _baseUrl = dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  static final String _model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4';
  final LangSmithService _langSmith = LangSmithService();

  OpenAIService() {
    _initializeLangSmith();
  }

  Future<void> _initializeLangSmith() async {
    await _langSmith.initialize();
  }

  Future<String> generateLyrics({
    required String prompt,
    required int maxLength,
  }) async {
    return _langSmith.traceAsync<String>(
      name: 'Generate Lyrics',
      runType: 'llm',
      inputs: {
        'prompt': prompt,
        'max_length': maxLength,
        'model': _model,
      },
      operation: () async {
        try {
          print('🎭 Crafting lyrical inspiration...');
          
          final response = await http.post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content': '''You are a skilled hip-hop songwriter who creates clean, formatted lyrics without any meta information or section labels.
Return only the actual lyrics text. The lyrics must be under $maxLength characters.
IMPORTANT: Use ONLY standard ASCII characters (a-z, A-Z, 0-9, and basic punctuation like .,!?). 
DO NOT use any special characters, smart quotes, em dashes, or any Unicode characters.
DO NOT include any formatting, verse numbers, or section labels.
Write in a natural, flowing style that could be performed.
Keep it simple and clean - this will be processed by text-to-speech so avoid any fancy typography.''',
                },
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
              'max_tokens': 150,  // Limiting response length
              'temperature': 0.7,  // Balancing creativity and coherence
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            var lyrics = data['choices'][0]['message']['content'].trim();
            
            // Sanitize the lyrics to ensure only ASCII characters
            lyrics = _sanitizeText(lyrics);
            
            // Ensure lyrics are under maxLength by removing whole words
            while (lyrics.length > maxLength) {
              final lastSpaceIndex = lyrics.lastIndexOf(' ');
              if (lastSpaceIndex == -1) {
                lyrics = lyrics.substring(0, maxLength);
              } else {
                lyrics = lyrics.substring(0, lastSpaceIndex);
              }
            }
            
            print('\n🎵 Generated Lyrics 🎵');
            print('📝 Length: ${lyrics.length} characters');
            print('🎤 Lyrics:\n$lyrics');
            
            return lyrics;
          } else {
            throw Exception('Failed to generate lyrics: ${response.body}');
          }
        } catch (e) {
          print('❌ Error generating lyrics: $e');
          rethrow;
        }
      },
    );
  }

  String _sanitizeText(String text) {
    // First, normalize all apostrophes and quotes to simple ASCII versions
    text = text
      .replaceAll("\u2018", "'")  // Left single quote
      .replaceAll("\u2019", "'")  // Right single quote
      .replaceAll("\u201C", "\"")  // Left double quote
      .replaceAll("\u201D", "\"")  // Right double quote
      .replaceAll("`", "'")
      .replaceAll("\u00B4", "'")  // Acute accent
      .replaceAll("\u2032", "'")  // Prime
      .replaceAll("\u00E2", "'")  // a circumflex
      .replaceAll("\u20AC\u2122", "'")  // Euro sign + TM
      .replaceAll("\u20AC\u201C", "\"")  // Euro sign + left double quote
      .replaceAll("\u20AC", "'");  // Euro sign
    
    // Replace em/en dashes with regular hyphens
    text = text
      .replaceAll("\u2014", "-")  // Em dash
      .replaceAll("\u2013", "-")  // En dash
      .replaceAll("\u2010", "-")  // Hyphen
      .replaceAll("\u2011", "-")  // Non-breaking hyphen
      .replaceAll("\u2012", "-")  // Figure dash
      .replaceAll("\u2015", "-")  // Horizontal bar
      .replaceAll("\u2212", "-"); // Minus sign
    
    // Replace ellipsis with three periods
    text = text.replaceAll("\u2026", "...");
    
    // Remove any remaining non-ASCII characters
    text = text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
    
    // Clean up any double spaces and trim
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }
} 