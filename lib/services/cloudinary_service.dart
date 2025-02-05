import 'dart:io';
import 'dart:math';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

class CloudinaryService {
  late final Cloudinary _cloudinary;
  final _random = Random.secure();
  
  CloudinaryService() {
    _cloudinary = Cloudinary.signedConfig(
      apiKey: dotenv.env['CLOUDINARY_API_KEY']!,
      apiSecret: dotenv.env['CLOUDINARY_API_SECRET']!,
      cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME']!,
    );
  }

  String _generatePublicId() {
    // Generate a random 16 character string
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<String?> uploadVideo(File videoFile) async {
    try {
      final publicId = _generatePublicId();
      
      final response = await _cloudinary.upload(
        file: videoFile.path,
        fileBytes: await videoFile.readAsBytes(),
        resourceType: CloudinaryResourceType.video,
        folder: 'toktok_videos',
        publicId: publicId,
        progressCallback: (count, total) {
          final progress = (count / total) * 100;
          print('Upload progress: ${progress.toStringAsFixed(2)}%');
        },
      );

      if (response.isSuccessful) {
        print('Upload successful: ${response.secureUrl}');
        return response.secureUrl;
      } else {
        print('Upload failed: ${response.error}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserVideos() async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
      final apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
      final apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(timestamp, apiSecret);
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/resources/video/upload'
        '?prefix=toktok_videos'
        '&max_results=100'
        '&type=upload'
        '&timestamp=$timestamp'
        '&api_key=$apiKey'
        '&signature=$signature'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final resources = data['resources'] as List;
        print('✨ Found ${resources.length} videos');
        
        return resources.map((resource) => {
          'publicId': resource['public_id'] as String,
          'secureUrl': resource['secure_url'] as String,
          'createdAt': DateTime.parse(resource['created_at'] as String),
          'bytes': resource['bytes'] as int,
        }).toList();
      } else {
        print('❌ Failed to fetch videos: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching videos from Cloudinary: $e');
      return [];
    }
  }

  String _generateSignature(int timestamp, String apiSecret) {
    final params = 'prefix=toktok_videos&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(params);
    final digest = crypto.sha1.convert(bytes);
    return digest.toString();
  }

  String getThumbnailUrl(String videoUrl) {
    // Convert video URL to thumbnail URL
    // Example: https://res.cloudinary.com/demo/video/upload/v1234/sample.mp4
    // becomes: https://res.cloudinary.com/demo/video/upload/c_thumb,w_400,g_face/v1234/sample.jpg
    return videoUrl.replaceAll(
      RegExp(r'\/upload\/'),
      '/upload/c_thumb,w_400,g_face/'
    ).replaceAll(RegExp(r'\.[^.]+$'), '.jpg');
  }

  Future<bool> deleteVideo(String publicId) async {
    try {
      final response = await _cloudinary.destroy(
        publicId,
        resourceType: CloudinaryResourceType.video,
      );
      if (response.isSuccessful) {
        print('Video deleted successfully');
        return true;
      } else {
        print('Failed to delete video: ${response.error}');
        return false;
      }
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }
} 