import 'package:flutter/material.dart';

import 'scanner_screen_mobile.dart'
    if (dart.library.html) 'scanner_screen_web.dart';

class ScannerScreen extends StatelessWidget {
  final bool wishlistMode;

  const ScannerScreen({super.key, this.wishlistMode = false});

  @override
  Widget build(BuildContext context) {
    return ScannerMobile(wishlistMode: wishlistMode);
  }
}
