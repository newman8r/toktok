import 'dart:io';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart' as crypto;
import '../models/gem_model.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

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
    // Check if it's a Cloudinary URL
    if (videoUrl.contains('cloudinary.com')) {
      // Convert video URL to thumbnail URL
      // Example: https://res.cloudinary.com/demo/video/upload/v1234/sample.mp4
      // becomes: https://res.cloudinary.com/demo/video/upload/w_400,h_400,c_fill,g_auto/v1234/sample.jpg
      return videoUrl.replaceAll(
        RegExp(r'\/upload\/'),
        '/upload/w_400,h_400,c_fill,g_auto/'
      ).replaceAll(RegExp(r'\.[^.]+$'), '.jpg');
    } else {
      // For non-Cloudinary URLs (like Replicate), we'll use the video URL directly
      // The GemCard will handle generating a local thumbnail using video_thumbnail
      return videoUrl;
    }
  }

  // New method to get cached thumbnail path
  Future<String> _getCachedPath(String videoUrl) async {
    final docDir = await getApplicationDocumentsDirectory();
    final thumbDir = Directory('${docDir.path}/thumbnails');
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    // Create a unique but consistent filename for this video URL
    final filename = crypto.sha1.convert(utf8.encode(videoUrl)).toString();
    return '${thumbDir.path}/$filename.jpg';
  }

  // New method to generate local thumbnail from video URL with caching
  Future<String?> generateLocalThumbnail(String videoUrl) async {
    try {
      // Check cache first
      final cachedPath = await _getCachedPath(videoUrl);
      final cachedFile = File(cachedPath);
      
      // If cached version exists, return it
      if (await cachedFile.exists()) {
        print('✨ Using cached thumbnail for: $videoUrl');
        return cachedPath;
      }

      print('🎬 Generating new thumbnail for: $videoUrl');
      // Generate new thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: cachedPath,  // Save directly to cache location
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );
      
      return thumbnailPath;
    } catch (e) {
      print('❌ Error generating thumbnail: $e');
      return null;
    }
  }

  Future<bool> deleteVideo(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Parameters to sign (in alphabetical order)
      final paramsToSign = {
        'public_id': publicId,
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
          'timestamp': timestamp.toString(),
          'api_key': _apiKey,
          'signature': signature,
          'type': 'upload',
        },
      );

      if (response.statusCode == 200) {
        print('✨ Video deleted successfully');
        return true;
      } else {
        print('Failed to delete video: ${response.body}');
        throw Exception('Failed to delete video from Cloudinary');
      }
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      rethrow;
    }
  }

  Future<String?> combineVideos(List<String> videoUrls) async {
    try {
      print('🎬 Starting video combination...');
      print('📋 Videos to combine: ${videoUrls.length}');

      if (videoUrls.isEmpty) return null;
      if (videoUrls.length == 1) return videoUrls.first;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final combinedPublicId = 'combined_${_generatePublicId()}';

      // Extract video IDs from URLs
      final videoIds = videoUrls.map((url) {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        print('🔍 URL being processed: $url');
        print('🔍 Path segments: $pathSegments');
        
        // Get the version (should be in format v1234567)
        // Find the segment that starts with 'v' followed by numbers
        final version = pathSegments.firstWhere(
          (segment) => segment.startsWith('v') && segment.substring(1).contains(RegExp(r'^\d+$')),
          orElse: () => 'v1',
        );
        final id = pathSegments.last.split('.').first;
        print('🔍 Version: $version');
        print('🔍 Extracted ID: $id');
        return {'version': version, 'id': id};
      }).toList();

      print('📝 Video IDs: $videoIds');

      // Create transformation string for video concatenation
      final baseVideo = videoIds.first;
      final overlayVideos = videoIds.skip(1).map((video) {
        // For each overlay video, we need to:
        // 1. Reference just the video ID (without version)
        // 2. Add splice flag
        // 3. Add layer_apply flag
        return [
          {
            'l_video': video['id'],  // Just use the ID without version
            'flags': 'splice'
          },
          {
            'flags': 'layer_apply'
          }
        ];
      }).expand((x) => x).toList();

      // Convert transformations to string format
      final transformation = overlayVideos.map((t) {
        if (t.containsKey('l_video')) {
          return 'l_video:${t['l_video']},fl_${t['flags']}';
        } else {
          return 'fl_${t['flags']}';
        }
      }).join('/');

      print('🔄 Transformation string: $transformation');

      // Parameters to sign (in alphabetical order)
      final paramsToSign = {
        'public_id': combinedPublicId,
        'timestamp': timestamp.toString(),
        'type': 'upload',
      };

      // Only include transformation if it's not empty
      if (transformation.isNotEmpty) {
        paramsToSign['transformation'] = transformation;
      }

      print('📝 Parameters to sign:');
      paramsToSign.forEach((key, value) {
        print('   $key: $value');
      });

      // Create the string to sign by joining parameters with their values
      final sortedParams = paramsToSign.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      
      final stringToSign = sortedParams
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      print('🔑 String to sign (before adding API secret): $stringToSign');
      
      // For debugging, show the complete string with a masked API secret
      final maskedApiSecret = _apiSecret.replaceAll(RegExp(r'.'), '*');
      print('🔑 Complete string to sign (with masked secret): $stringToSign$maskedApiSecret');

      // Generate SHA-1 signature
      final bytes = utf8.encode(stringToSign + _apiSecret);
      final signature = crypto.sha1.convert(bytes).toString();

      print('✍️ Generated signature: $signature');

      // Create multipart request
      final url = Uri.parse('$_baseUrl/video/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields.addAll({
          'api_key': _apiKey,
          'file': videoUrls.first,  // Use the complete URL of the first video
          'public_id': combinedPublicId,
          'resource_type': 'video',
          'signature': signature,
          'timestamp': timestamp.toString(),
          'type': 'upload',
        });

      // Only add transformation if it's not empty
      if (transformation.isNotEmpty) {
        request.fields['transformation'] = transformation;
      }

      print('🚀 Request fields:');
      request.fields.forEach((key, value) {
        if (key == 'api_key') {
          print('   $key: ${value.substring(0, 4)}...${value.substring(value.length - 4)}');
        } else {
          print('   $key: $value');
        }
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ Failed to combine videos: ${response.body}');
        return null;
      }

      final responseData = json.decode(response.body);
      final secureUrl = responseData['secure_url'] as String?;

      if (secureUrl == null) {
        print('❌ Failed to get secure URL from response');
        return null;
      }

      print('✅ Successfully combined videos: $secureUrl');
      return secureUrl;
    } catch (e) {
      print('❌ Error combining videos: $e');
      return null;
    }
  }

  Future<String> addAudioToVideo({
    required String videoUrl,
    required String audioUrl,
    required Duration audioDuration,
  }) async {
    try {
      print('Starting audio overlay operation...');
      print('Video URL: $videoUrl');
      print('Audio URL: $audioUrl');
      print('Audio duration: $audioDuration');

      // First, download the audio file to a temporary location
      print('Downloading audio file...');
      final audioDownloadResponse = await http.get(Uri.parse(audioUrl));
      final tempDir = await Directory.systemTemp.createTemp('audio_overlay');
      final tempFile = File('${tempDir.path}/temp_audio.mp3');
      await tempFile.writeAsBytes(audioDownloadResponse.bodyBytes);
      print('Audio file downloaded to: ${tempFile.path}');

      // Upload the audio file to Cloudinary
      print('Uploading audio to Cloudinary...');
      final audioPublicId = 'audio_${_generatePublicId()}';
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Parameters to sign for audio upload (excluding resource_type)
      final audioUploadParams = {
        'public_id': audioPublicId,
        'timestamp': timestamp.toString(),
        'type': 'upload',
      };
      
      final audioSignature = _generateSignature(audioUploadParams);
      final audioUploadUrl = Uri.parse('$_baseUrl/video/upload');
      final audioRequest = http.MultipartRequest('POST', audioUploadUrl)
        ..fields.addAll({
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': audioSignature,
          'public_id': audioPublicId,
          'resource_type': 'video',  // Include in request but not in signature
          'type': 'upload',
        })
        ..files.add(await http.MultipartFile.fromPath('file', tempFile.path));

      print('🚀 Sending audio upload request to Cloudinary...');
      final audioStreamedResponse = await audioRequest.send();
      final audioResponse = await http.Response.fromStream(audioStreamedResponse);

      print('📥 Audio upload response status: ${audioResponse.statusCode}');
      print('📥 Audio upload response body: ${audioResponse.body}');

      if (audioResponse.statusCode != 200) {
        throw Exception('Failed to upload audio to Cloudinary: ${audioResponse.statusCode} - ${audioResponse.body}');
      }

      Map<String, dynamic> audioResponseData;
      try {
        audioResponseData = json.decode(audioResponse.body);
      } catch (e) {
        print('❌ Failed to parse audio upload response: $e');
        throw Exception('Invalid response from Cloudinary during audio upload');
      }

      final audioCloudinaryUrl = audioResponseData['secure_url'] as String?;
      if (audioCloudinaryUrl == null) {
        throw Exception('Failed to get audio URL from response');
      }

      print('✅ Audio uploaded successfully: $audioCloudinaryUrl');

      // Create the eager transformation array using the Cloudinary audio public ID
      final eagerTransformation = 'vc_auto/du_${audioDuration.inSeconds}/l_video:$audioPublicId,fl_layer_apply';

      // Parameters to sign (in alphabetical order, excluding file, cloud_name, resource_type, and api_key)
      final paramsToSign = {
        'eager': eagerTransformation,
        'public_id': 'combined_${_generatePublicId()}',
        'timestamp': timestamp.toString(),
        'type': 'upload',
      };

      print('📝 Parameters to sign:');
      paramsToSign.forEach((key, value) => print('   $key: $value'));

      final signature = _generateSignature(paramsToSign);

      // Create multipart request for video upload
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/video/upload'))
        ..fields.addAll({
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
          'public_id': paramsToSign['public_id']!,
          'resource_type': 'video',
          'type': 'upload',
          'eager': eagerTransformation,
          'file': videoUrl,
        });

      print('🎥 Sending video upload request to Cloudinary...');
      print('🔑 Request fields:');
      request.fields.forEach((key, value) => print('   $key: $value'));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Video upload response status: ${response.statusCode}');
      print('📥 Video upload response body: ${response.body}');

      // Clean up temporary files
      await tempFile.delete();
      await tempDir.delete();

      if (response.statusCode != 200) {
        throw Exception('Failed to create new video: ${response.statusCode} - ${response.body}');
      }

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('❌ Failed to parse video upload response: $e');
        throw Exception('Invalid response from Cloudinary during video upload');
      }

      final secureUrl = responseData['eager']?[0]?['secure_url'] as String?;
      if (secureUrl == null) {
        throw Exception('Failed to get secure URL from response');
      }

      print('✅ Successfully created new video with audio: $secureUrl');
      return secureUrl;
    } catch (e) {
      print('❌ Error in addAudioToVideo: $e');
      rethrow;
    }
  }
} 