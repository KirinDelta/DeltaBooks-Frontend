import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import 'manual_entry_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanning = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      _controller = MobileScannerController();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing scanner: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
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
      // Navigate to ManualEntryScreen with scanned ISBN
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManualEntryScreen(
            initialIsbn: barcode.rawValue!,
          ),
        ),
      );
      
      // Refresh libraries if book was added
      if (result == true && mounted) {
        final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
        await libraryProvider.fetchLibraries();
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
          child: CircularProgressIndicator(
            color: AppColors.goldLeaf,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: _controller!,
              onDetect: _handleBarcode,
            ),
            // Top instruction card
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
            // Bottom FAB for "Add Manually"
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  heroTag: 'add_manual_fab',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManualEntryScreen(),
                      ),
                    );
                    
                    // Refresh libraries if book was added
                    if (result == true && mounted) {
                      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
                      await libraryProvider.fetchLibraries();
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
