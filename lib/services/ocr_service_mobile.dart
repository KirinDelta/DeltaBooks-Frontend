import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  /// Returns the text from the most visually prominent block in the image
  /// (i.e. the largest text by bounding-box area). Passing [allBlocks] returns
  /// all blocks joined by newlines — useful for multi-line description fields.
  static Future<String?> extractText(XFile file, {bool allBlocks = false}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final result = await recognizer.processImage(inputImage);

      if (result.blocks.isEmpty) return null;

      if (allBlocks) {
        final text = result.blocks.map((b) => b.text.trim()).join('\n').trim();
        return text.isEmpty ? null : text;
      }

      // Sort blocks by bounding-box area descending so the biggest text
      // (title, author) comes first. Fall back to raw area = 0 for blocks
      // without a bounding box so they sink to the bottom.
      final sorted = result.blocks.toList()
        ..sort((a, b) {
          final aArea = (a.boundingBox.width) * (a.boundingBox.height);
          final bArea = (b.boundingBox.width) * (b.boundingBox.height);
          return bArea.compareTo(aArea);
        });

      final text = sorted.first.text.trim();
      return text.isEmpty ? null : text;
    } finally {
      recognizer.close();
    }
  }
}
