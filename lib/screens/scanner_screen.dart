import 'package:flutter/material.dart';

import 'scanner_screen_mobile.dart'
    if (dart.library.html) 'scanner_screen_web.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScannerMobile();
  }
}
