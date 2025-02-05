import 'dart:io';
import 'dart:math';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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