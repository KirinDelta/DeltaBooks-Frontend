import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// On web, cover images from third-party hosts (Google Books, Open Library)
/// are blocked by CORS when fetched via CanvasKit's XHR. Route them through
/// the backend proxy so the browser sees same-origin responses.
String? proxiedCoverUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (!kIsWeb) return url;
  return '${ApiService.baseUrl}/api/v1/image_proxy?url=${Uri.encodeComponent(url)}';
}
