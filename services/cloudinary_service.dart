import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // For content type detection
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  /// Your unsigned upload preset name
  static const unsignedUploadPreset = 'story_app_unsigned';

  /// Max file size: 10MB
  static const maxFileSize = 10 * 1024 * 1024;

  /// Upload an image or audio file to Cloudinary
  Future<String> uploadFile({
    required File file,
    required String folder,
    required String resourceType,
  }) async {
    try {
      //  Validate file first
      _validateFile(file, resourceType);

      //  Load credentials from .env
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'demo';

      // Note: For audio, use 'video' as resourceType in Cloudinary API
      final endpointResource = resourceType == 'audio' ? 'video' : resourceType;

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$endpointResource/upload',
      );

      //  Create multipart request
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = unsignedUploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      //  Execute upload
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        //  Parse JSON for secure_url
        final jsonResponse = json.decode(responseBody);
        final secureUrl = jsonResponse['secure_url'] as String?;

        if (secureUrl != null) {
          return secureUrl;
        } else {
          throw Exception(
            'Upload succeeded but no URL returned. Full response: $responseBody',
          );
        }
      } else {
        throw Exception('''
Upload failed!
Status: ${response.statusCode}
Body: $responseBody
''');
      }
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Validate file before uploading
  void _validateFile(File file, String resourceType) {
    if (!file.existsSync()) {
      throw Exception('File does not exist: ${file.path}');
    }

    final fileSize = file.lengthSync();
    if (fileSize > maxFileSize) {
      throw Exception('File size ${fileSize ~/ 1024}KB exceeds 10MB limit.');
    }

    final mimeType = lookupMimeType(file.path);

    if (resourceType == 'image') {
      if (mimeType == null || !mimeType.startsWith('image/')) {
        throw Exception(
          'Invalid image file. Detected type: $mimeType, path: ${file.path}',
        );
      }
    } else if (resourceType == 'audio') {
      if (mimeType == null || !mimeType.startsWith('audio/')) {
        throw Exception(
          'Invalid audio file. Detected type: $mimeType, path: ${file.path}',
        );
      }
    } else {
      throw Exception('Unsupported resourceType: $resourceType');
    }
  }
}
