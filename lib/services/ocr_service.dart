// ML Kit (iOS/macOS) on native, Tesseract.js on web.
export 'ocr_service_mobile.dart'
    if (dart.library.html) 'ocr_service_web.dart';
