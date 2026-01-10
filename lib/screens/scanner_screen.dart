import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

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
    
    if (barcode.rawValue != null) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final book = await bookProvider.findBookByIsbn(barcode.rawValue!);
      
      if (mounted) {
        if (book != null) {
          final add = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(book.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Autor: ${book.author}'),
                  Text('ISBN: ${book.isbn}'),
                  Text('Pagini: ${book.totalPages}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Anulează'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Adaugă la raft'),
                ),
              ],
            ),
          );
          
          if (add == true) {
            final success = await bookProvider.addBookToShelf(book.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Carte adăugată!' : 'Eroare la adăugare'),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Carte negăsită')),
            );
          }
        }
      }
    }
    
    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _handleBarcode,
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  'Scanează codul de bare al cărții',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
