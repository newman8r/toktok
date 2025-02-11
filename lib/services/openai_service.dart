import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static final String _baseUrl = dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  static final String _model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4';

  Future<String> generateLyrics({
    required String musicStyle,
    required String weatherMood,
    required String timeContext,
    required String locationVibe,
    required String temperature,
    required String weatherDescription,
  }) async {
    try {
      print('🎭 Crafting lyrical inspiration...');
      
      final prompt = '''
Create song lyrics (maximum 400 characters) in the style of $musicStyle music.
Context:
- Weather: $weatherDescription ($temperature°C, mood: $weatherMood)
- Time: $timeContext
- Location vibe: $locationVibe

Important formatting rules:
1. Do NOT include any section labels (like 'Verse', 'Chorus', 'Bridge', etc.)
2. Do NOT include any formatting or metadata
3. Just write the lyrics as continuous text
4. Use commas or line breaks naturally within the text
5. Keep it under 400 characters total

The lyrics should reflect the current context and mood. If it's rap/hip-hop, include rhyming. Keep it concise and emotionally resonant.
The lyrics need to be highly professional and catchy, never corny or awkward. We need to be able to look at existing popular songs and use the same style.
You should always include the provided context in the lyrics. If the context has the name of a city or place you should strongly consider using it - such as the name of the city or location, nearby landmarks, the time of day, etc.
Be inspired by:
Tupac Shakur
The Notorious B.I.G.
Kendrick Lamar
Jay-Z
Eminem
Missy Elliott
OutKast
Nas
Drake
Lauryn Hill
Michael Jackson
Madonna
Beyoncé
Prince
The Beatles
Queen
Pink Floyd
Daft Punk
Aphex Twin
Kanye West
and other artists at the top of their game.
''';

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
              'content': 'You are a skilled songwriter who creates clean, formatted lyrics without any meta information or section labels. Return only the actual lyrics text.',
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
        final lyrics = data['choices'][0]['message']['content'].trim();
        
        print('\n🎵 Generated Lyrics 🎵');
        print('📝 Style: $musicStyle');
        print('✨ Context: $timeContext, $weatherMood, $locationVibe');
        print('🎤 Lyrics:\n$lyrics');
        
        return lyrics;
      } else {
        throw Exception('Failed to generate lyrics: ${response.body}');
      }
    } catch (e) {
      print('❌ Error generating lyrics: $e');
      rethrow;
    }
  }
} 