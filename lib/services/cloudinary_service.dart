import 'dart:io';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart' as crypto;
import '../models/gem_model.dart';

class CloudinaryService {
  final _random = Random.secure();
  
  late final String _cloudName;
  late final String _apiKey;
  late final String _apiSecret;
  late final String _baseUrl;
  
  CloudinaryService() {
    _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
    _apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
    _apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;
    _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName';
  }

  String _generatePublicId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<String?> uploadVideo(
    File videoFile, {
    String? publicId,
    int? timestamp,
    Map<String, String>? paramsToSign,
  }) async {
    try {
      final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final pid = publicId ?? _generatePublicId();

      // Create signature
      final params = paramsToSign ?? {
        'public_id': pid,
        'timestamp': ts.toString(),
      };

      final signature = _generateSignature(params);

      // Create multipart request
      final url = Uri.parse('$_baseUrl/video/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['timestamp'] = ts.toString()
        ..fields['api_key'] = _apiKey
        ..fields['signature'] = signature
        ..fields['public_id'] = pid;
      
      // Add any additional fields from paramsToSign
      params.forEach((key, value) {
        if (key != 'public_id' && key != 'timestamp') {
          request.fields[key] = value;
        }
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          videoFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Upload successful: ${data['secure_url']}');
        return data['secure_url'];
      } else {
        print('Upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  String _generateSignature(Map<String, String> params) {
    // Sort parameters alphabetically
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Create string to sign
    final stringToSign = sortedParams
        .map((e) => '${e.key}=${e.value}')
        .join('&') + _apiSecret;

    // Generate SHA-1 signature
    final bytes = utf8.encode(stringToSign);
    return crypto.sha1.convert(bytes).toString();
  }

  Future<String> cropVideo({
    required String videoUrl,
    required ui.Rect cropRect,
    required ui.Size originalSize,
  }) async {
    try {
      print('Starting video crop operation...');
      print('Original video URL: $videoUrl');
      print('Crop rect: $cropRect');
      print('Original size: $originalSize');

      // Convert crop rect to absolute pixels and ensure valid dimensions
      final int x = cropRect.left.round().clamp(0, originalSize.width.toInt());
      final int y = cropRect.top.round().clamp(0, originalSize.height.toInt());
      final int width = cropRect.width.round().clamp(100, 4999);
      final int height = cropRect.height.round().clamp(100, 4999);

      print('Crop dimensions (x: $x, y: $y, width: $width, height: $height)');

      // Validate dimensions
      if (width <= 0 || height <= 0) {
        throw Exception('Invalid crop dimensions: width and height must be positive');
      }

      if (x + width > originalSize.width || y + height > originalSize.height) {
        throw Exception('Crop rectangle exceeds video dimensions');
      }

      // Extract public ID from original URL
      final Uri uri = Uri.parse(videoUrl);
      final String path = uri.path;
      final String originalPublicId = path.split('/').last.split('.').first;
      
      // Create a new public ID for the cropped version
      final String croppedPublicId = '${originalPublicId}_cropped_${_generatePublicId().substring(0, 8)}';
      print('New public ID: $croppedPublicId');

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create the eager transformation array
      final eagerTransformation = 'c_crop,x_$x,y_$y,w_$width,h_$height';

      // Parameters to sign (in alphabetical order)
      final paramsToSign = {
        'eager': eagerTransformation,
        'file': videoUrl,
        'public_id': croppedPublicId,
        'resource_type': 'video',
        'timestamp': timestamp.toString(),
        'type': 'upload',
      };

      final signature = _generateSignature(paramsToSign);

      print('Generated signature with params:');
      paramsToSign.forEach((key, value) {
        print('  $key: $value');
      });
      print('Signature: $signature');

      // Create multipart request
      final url = Uri.parse('$_baseUrl/video/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['timestamp'] = timestamp.toString()
        ..fields['api_key'] = _apiKey
        ..fields['signature'] = signature
        ..fields['public_id'] = croppedPublicId
        ..fields['resource_type'] = 'video'
        ..fields['type'] = 'upload'
        ..fields['eager'] = eagerTransformation
        ..fields['file'] = videoUrl;

      print('Sending request to create new video...');
      print('Request URL: $url');
      print('Request fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('Failed to create new video: ${response.body}');
        throw Exception('Failed to create new video: ${response.body}');
      }

      final responseData = json.decode(response.body);
      final secureUrl = responseData['eager']?[0]?['secure_url'] as String?;

      if (secureUrl == null) {
        throw Exception('Failed to get secure URL from response');
      }

      print('Successfully created new video: $secureUrl');
      return secureUrl;
    } catch (e) {
      print('Error in cropVideo: $e');
      rethrow;
    }
  }

  Future<ui.Size> getVideoDimensions(String videoUrl) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/video/details/$videoUrl'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ui.Size(
          data['width'].toDouble(),
          data['height'].toDouble(),
        );
      }
      throw Exception('Failed to get video dimensions');
    } catch (e) {
      print('Error getting video dimensions: $e');
      rethrow;
    }
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
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Parameters to sign
      final paramsToSign = {
        'public_id': publicId,
        'resource_type': 'video',
        'timestamp': timestamp.toString(),
        'type': 'upload',
      };

      final signature = _generateSignature(paramsToSign);

      // Create request
      final url = Uri.parse('$_baseUrl/video/destroy');
      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'resource_type': 'video',
          'type': 'upload',
          'timestamp': timestamp.toString(),
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        print('Video deleted successfully');
        return true;
      } else {
        print('Failed to delete video: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }
} 