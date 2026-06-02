// mobile_scanner v5+ supports web natively (loads ZXing automatically).
// Re-export ScannerMobile from the mobile implementation so that
// scanner_screen.dart's conditional import resolves to the same widget
// on all platforms.
export 'scanner_screen_mobile.dart' show ScannerMobile;
