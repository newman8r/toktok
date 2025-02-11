import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ReplicateService {
  static final String _baseUrl = dotenv.env['REPLICATE_BASE_URL'] ?? 'https://api.replicate.com/v1/predictions';
  static final String _apiKey = dotenv.env['REPLICATE_API_KEY'] ?? '';
  static final String _modelVersion = dotenv.env['REPLICATE_MODEL'] ?? '6c9132aee14409cd6568d030453f1ba50f5f3412b844fe67f78a9eb62d55664f';

  /// Available parameters for the Hunyuan video model:
  /// - prompt: The text description of the video to generate
  /// - negative_prompt: What not to include in the video
  /// - num_frames: Number of frames to generate (affects video length)
  /// - width: Video width (default: 1024)
  /// - height: Video height (default: 576)
  /// - num_inference_steps: Number of denoising steps (default: 50)
  /// - guidance_scale: How closely to follow the prompt (default: 9)
  /// - seed: Random seed for reproducibility
  Future<Map<String, dynamic>> generateVideo({
    required String prompt,
    String? negativePrompt,
    int numFrames = 240,  // Changed to 240 frames for 10 seconds at 24fps
    int width = 1024,
    int height = 576,
    int numInferenceSteps = 50,
    double guidanceScale = 9.0,
    int? seed,
  }) async {
    try {
      print('🎬 Starting video generation...');
      print('📝 Prompt: $prompt');
      
      if (_apiKey.isEmpty) {
        throw Exception('Replicate API key not found in environment variables');
      }

      // Prepare the input parameters
      final input = {
        'prompt': prompt,
        'num_frames': numFrames,
        'width': width,
        'height': height,
        'num_inference_steps': numInferenceSteps,
        'guidance_scale': guidanceScale,
      };

      // Add optional parameters if provided
      if (negativePrompt != null) {
        input['negative_prompt'] = negativePrompt;
      }
      if (seed != null) {
        input['seed'] = seed;
      }

      print('🔧 Configuration:');
      input.forEach((key, value) => print('   $key: $value'));

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': _modelVersion,
          'input': input,
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 202) {
        final data = jsonDecode(response.body);
        
        // Always poll for completion since video generation takes time
        return await _pollForCompletion(data['id']);
      } else {
        throw Exception('Failed to start video generation: ${response.body}');
      }
    } catch (e) {
      print('❌ Error generating video: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _pollForCompletion(String predictionId) async {
    print('🔄 Starting to poll for completion...');
    
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/$predictionId'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status'];

          print('📊 Current status: $status');

          switch (status) {
            case 'succeeded':
              print('✅ Video generation completed successfully!');
              return data;
            case 'failed':
              print('❌ Generation failed: ${data['error']}');
              throw Exception('Video generation failed: ${data['error']}');
            case 'canceled':
              throw Exception('Video generation was canceled');
            default:
              // For 'starting' or 'processing' status
              print('⏳ Still processing... waiting 5 seconds');
              await Future.delayed(const Duration(seconds: 5));
          }
        } else {
          throw Exception('Failed to check prediction status: ${response.body}');
        }
      } catch (e) {
        print('❌ Error during polling: $e');
        rethrow;
      }
    }
  }

  /// Get the status of an existing prediction
  Future<Map<String, dynamic>> checkStatus(String predictionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$predictionId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check status: ${response.body}');
      }
    } catch (e) {
      print('❌ Error checking status: $e');
      rethrow;
    }
  }

  /// Cancel an in-progress prediction
  Future<void> cancelPrediction(String predictionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$predictionId/cancel'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel prediction: ${response.body}');
      }
    } catch (e) {
      print('❌ Error canceling prediction: $e');
      rethrow;
    }
  }
} 