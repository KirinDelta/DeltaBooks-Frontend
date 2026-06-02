import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const _cloudName = 'dzbz7gwus';
  static const _uploadPreset = 'DeltaBooks';

  static Future<String?> uploadImage(XFile file) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      // Use readAsBytes() instead of fromPath() — on Flutter web, XFile.path
      // is a blob URL, not a filesystem path, so fromPath() throws.
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }
      // ignore: avoid_print
      print('Cloudinary upload failed – status ${streamed.statusCode}: $body');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
