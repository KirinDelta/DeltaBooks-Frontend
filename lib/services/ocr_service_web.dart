// This file is only compiled on web via the conditional export in ocr_service.dart.
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:image_picker/image_picker.dart';

// Calls window.Tesseract.recognize(image, lang) — loaded from CDN in index.html.
@JS('Tesseract.recognize')
external JSPromise<JSObject> _recognize(JSAny? image, JSString lang);

class OcrService {
  static Future<String?> extractText(XFile file, {bool allBlocks = false}) async {
    try {
      // file.path on Flutter web is a blob URL; Tesseract.js accepts it directly.
      final result = await _recognize(file.path.toJS, 'eng'.toJS).toDart;
      final data = result.getProperty<JSObject>('data'.toJS);
      final text = data.getProperty<JSString>('text'.toJS);
      final trimmed = text.toDart.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (e) {
      // ignore: avoid_print
      print('OcrService web error: $e');
      return null;
    }
  }
}
