import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';

class VideoAnalysisService {
  final String _replicateToken;
  final String _modelId;
  
  VideoAnalysisService() :
    _replicateToken = dotenv.env['REPLICATE_API_KEY'] ?? 
      (throw Exception('REPLICATE_API_KEY not found in environment')),
    _modelId = dotenv.env['REPLICATE_IMAGE_DESCRIPTION_MODEL'] ?? 
      (throw Exception('REPLICATE_IMAGE_DESCRIPTION_MODEL not found in environment'));

  String _getFrameUrl(String videoUrl, Duration position) {
    // Check if it's a Cloudinary URL
    if (!videoUrl.contains('cloudinary.com')) {
      throw Exception('Video URL must be from Cloudinary');
    }

    // Extract the version and public ID from the URL
    final uri = Uri.parse(videoUrl);
    final pathSegments = uri.pathSegments;
    
    // Find the version (should be in format v1234567)
    final version = pathSegments.firstWhere(
      (segment) => segment.startsWith('v') && segment.substring(1).contains(RegExp(r'^\d+$')),
      orElse: () => 'v1',
    );
    
    // Get the filename without extension
    final filename = pathSegments.last.split('.').first;
    
    // Calculate the frame position in seconds
    final seconds = position.inMilliseconds / 1000;
    
    // Create the transformation URL for a frame
    // w_1280,h_720: Set dimensions
    // c_fill: Ensure the frame fills the dimensions
    // so_{seconds}: Seek to specific timestamp
    // f_jpg: Convert to JPG
    final baseUrl = videoUrl.split('/video/upload/').first;
    return '$baseUrl/video/upload/w_1280,h_720,c_fill,so_${seconds.toStringAsFixed(2)},f_jpg/$version/$filename.jpg';
  }

  Future<List<String>> analyzeVideoFrame(String videoUrl) async {
    try {
      print('🎬 Starting video frame analysis...');
      
      // Initialize video player to get duration
      final videoController = VideoPlayerController.network(videoUrl);
      await videoController.initialize();
      
      // Get video duration and calculate middle frame position
      final duration = videoController.value.duration;
      final middlePosition = duration ~/ 2;
      
      // Get the frame URL from Cloudinary
      final frameUrl = _getFrameUrl(videoUrl, Duration(seconds: middlePosition.inSeconds));
      print('🖼️ Extracted frame URL: $frameUrl');
      
      // Clean up video controller
      await videoController.dispose();
      
      // Make API call to Replicate with the frame URL
      final response = await http.post(
        Uri.parse('https://api.replicate.com/v1/predictions'),
        headers: {
          'Authorization': 'Token $_replicateToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'version': _modelId,
          'input': {
            'input_image': frameUrl,
            'use_sam_hq': true,
            'show_visualization': false,
          },
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to start prediction: ${response.body}');
      }

      final predictionData = json.decode(response.body);
      final String predictionId = predictionData['id'];
      print('🚀 Started prediction: $predictionId');

      // Poll for results
      while (true) {
        final statusResponse = await http.get(
          Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
          headers: {
            'Authorization': 'Token $_replicateToken',
          },
        );

        if (statusResponse.statusCode != 200) {
          throw Exception('Failed to get prediction status');
        }

        final statusData = json.decode(statusResponse.body);
        if (statusData['status'] == 'succeeded') {
          print('✨ Analysis complete!');
          final tags = statusData['output']['tags'] as String;
          final tagList = tags.split(',').map((tag) => tag.trim()).toList();
          
          // Log results with emojis
          print('\n🔍 Found objects in video:');
          for (final tag in tagList) {
            print('  🎯 $tag');
          }
          print('\n');
          
          return tagList;
        } else if (statusData['status'] == 'failed') {
          throw Exception('Prediction failed: ${statusData['error']}');
        }

        // Wait before polling again
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('❌ Error analyzing video frame: $e');
      rethrow;
    }
  }
} 