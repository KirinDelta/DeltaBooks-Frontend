import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import 'manual_entry_screen.dart';

// mobile_scanner is not supported on web — only import on native platforms
import 'scanner_screen_mobile.dart'
    if (dart.library.html) 'scanner_screen_web.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ScannerWebStub();
    }
    return const ScannerMobile();
  }
}
