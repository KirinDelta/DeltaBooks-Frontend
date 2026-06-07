import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import 'manual_entry_screen.dart';
import 'wishlist_add_screen.dart';

class ScannerMobile extends StatefulWidget {
  final bool wishlistMode;
  final bool addMode;

  const ScannerMobile({
    super.key,
    this.wishlistMode = false,
    this.addMode = false,
  });

  @override
  State<ScannerMobile> createState() => _ScannerMobileState();
}

class _ScannerMobileState extends State<ScannerMobile> {
  MobileScannerController? _controller;
  bool _isScanning = false;
  bool _isInitialized = false;
  bool _webStartRequested = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeScanner();
    }
  }

  // Mobile-only: autoStart: false + manual start() as required by CLAUDE.md.
  Future<void> _initializeScanner() async {
    setState(() {
      _isInitialized = false;
      _initError = null;
    });
    try {
      _controller?.dispose();
      _controller = MobileScannerController(autoStart: false);
      await _controller!.start();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _initError = e.toString();
        });
      }
    }
  }

  // Web-only: use autoStart: true so the MobileScanner widget calls attach()
  // before start() runs. Calling start() manually (before the widget mounts)
  // causes a 500 ms controllerNotAttached timeout — the permission dialog
  // is never shown. This matches how BarcodeFieldButton works.
  void _startWebCamera() {
    _controller?.dispose();
    _controller = MobileScannerController(autoStart: true);
    setState(() {
      _webStartRequested = true;
      _isInitialized = true;
      _initError = null;
    });
  }

  void _resetWebCamera() {
    _controller?.dispose();
    _controller = null;
    setState(() {
      _webStartRequested = false;
      _isInitialized = false;
      _initError = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isScanning || _controller == null) return;

    setState(() => _isScanning = true);
    if (capture.barcodes.isEmpty) {
      setState(() => _isScanning = false);
      return;
    }
    final barcode = capture.barcodes.first;

    if (barcode.rawValue != null && mounted) {
      final isbn = barcode.rawValue!;
      final Widget destination = widget.wishlistMode
          ? WishlistAddScreen(initialIsbn: isbn)
          : ManualEntryScreen(initialIsbn: isbn, addMode: widget.addMode);

      final result = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => destination));

      if (result == true && mounted) {
        if (!widget.wishlistMode && !widget.addMode) {
          final libraryProvider =
              Provider.of<LibraryProvider>(context, listen: false);
          await libraryProvider.fetchLibraries();
        } else {
          Navigator.pop(context, true);
          return;
        }
      }
    }

    setState(() => _isScanning = false);
  }

  Future<void> _navigateManual() async {
    final Widget destination = widget.wishlistMode
        ? const WishlistAddScreen()
        : ManualEntryScreen(addMode: widget.addMode);
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => destination));
    if (result == true && mounted) {
      if (!widget.wishlistMode && !widget.addMode) {
        final libraryProvider =
            Provider.of<LibraryProvider>(context, listen: false);
        await libraryProvider.fetchLibraries();
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Web: show enable-camera prompt before any start() call has been made.
    if (kIsWeb && !_webStartRequested) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.deepSeaBlue,
          foregroundColor: Colors.white,
          title: Text(l10n.scanBarcode),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 64, color: AppColors.goldLeaf),
                const SizedBox(height: 16),
                Text(
                  l10n.tapToEnableCamera,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startWebCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.enableCameraAccess),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldLeaf,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _navigateManual,
                  icon: const Icon(Icons.keyboard),
                  label: Text(l10n.addManually),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile loading or error state (never reached on web).
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.deepSeaBlue,
          foregroundColor: Colors.white,
          title: Text(l10n.scanBarcode),
        ),
        body: Center(
          child: _initError != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l10n.cameraPermissionDenied,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeScanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldLeaf,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.retry),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _navigateManual,
                      icon: const Icon(Icons.keyboard),
                      label: Text(l10n.addManually),
                    ),
                  ],
                )
              : CircularProgressIndicator(color: AppColors.goldLeaf),
        ),
      );
    }

    // Scanning state — full-screen camera with overlaid controls.
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller!,
              onDetect: _handleBarcode,
              // On web, MobileScanner's errorBuilder handles permission denial
              // so the user can retry without leaving the screen.
              errorBuilder: kIsWeb
                  ? (context, error) => Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                l10n.cameraPermissionDenied,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _resetWebCamera,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldLeaf,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(l10n.retry),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _navigateManual,
                                icon: const Icon(Icons.keyboard),
                                label: Text(l10n.addManually),
                              ),
                            ],
                          ),
                        ),
                      )
                  : null,
            ),
            // Back button top-left.
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Instruction card top-center.
            Positioned(
              top: 16,
              left: 72,
              right: 16,
              child: Card(
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.scanBarcode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Manual entry FAB bottom-center.
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  heroTag: 'add_manual_fab',
                  onPressed: _navigateManual,
                  icon: const Icon(Icons.keyboard),
                  label: Text(l10n.addManually),
                  backgroundColor: AppColors.goldLeaf,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
