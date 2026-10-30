import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../config/cloudinary_config.dart';

class CloudinaryService {
  const CloudinaryService();

  bool get isConfigured => CloudinaryConfig.isConfigured;

  Future<String?> uploadServiceImage(XFile file) => _upload(file, 'services');
  Future<String?> uploadShopImage(XFile file) => _upload(file, 'shops');
  Future<String?> uploadStaffImage(XFile file) => _upload(file, 'staff');
  Future<String?> uploadProfileImage(XFile file) => _upload(file, 'profiles');

  Future<String?> _upload(XFile file, String subfolder) async {
    if (!CloudinaryConfig.isConfigured) return null;

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final folder = CloudinaryConfig.folder.trim();
    if (folder.isNotEmpty) request.fields['folder'] = '$folder/$subfolder';

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Image upload failed.';
      try {
        final decoded = jsonDecode(body);
        final error = decoded['error'];
        if (error is Map && error['message'] != null) {
          message = error['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final url = decoded['secure_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }
    return url;
  }
}
