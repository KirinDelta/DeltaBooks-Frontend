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
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        body: Center(
          child: _initError != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
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
                      onPressed: () async {
                        final Widget destination = widget.wishlistMode
                            ? const WishlistAddScreen()
                            : ManualEntryScreen(addMode: widget.addMode);
                        final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => destination));
                        if (result == true && mounted) {
                          if (!widget.wishlistMode && !widget.addMode) {
                            final libraryProvider =
                                Provider.of<LibraryProvider>(context,
                                    listen: false);
                            await libraryProvider.fetchLibraries();
                          } else {
                            Navigator.pop(context, true);
                          }
                        }
                      },
                      icon: const Icon(Icons.keyboard),
                      label: Text(l10n.addManually),
                    ),
                  ],
                )
              : CircularProgressIndicator(color: AppColors.goldLeaf),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller!,
              onDetect: _handleBarcode,
            ),
            Positioned(
              top: 16,
              left: 16,
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
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  heroTag: 'add_manual_fab',
                  onPressed: () async {
                    final Widget destination = widget.wishlistMode
                        ? const WishlistAddScreen()
                        : ManualEntryScreen(addMode: widget.addMode);
                    final result = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => destination));
                    if (result == true && mounted) {
                      if (!widget.wishlistMode && !widget.addMode) {
                        final libraryProvider = Provider.of<LibraryProvider>(
                            context,
                            listen: false);
                        await libraryProvider.fetchLibraries();
                      } else {
                        Navigator.pop(context, true);
                      }
                    }
                  },
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
