import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
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
  final TextEditingController _isbnController = TextEditingController();
  bool _showManualInput = false;

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
    _isbnController.dispose();
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
        final l10n = AppLocalizations.of(context)!;
        if (book != null) {
          final add = await showDialog<bool>(
            context: context,
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return AlertDialog(
                title: Text(book.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.author}: ${book.author}'),
                    Text('${l10n.isbn}: ${book.isbn}'),
                    Text('${l10n.pages}: ${book.totalPages}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.addToLibrary),
                  ),
                ],
              );
            },
          );
          
          if (add == true) {
            final success = await bookProvider.addBookToLibrary(book.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? l10n.bookAdded : l10n.addError),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.bookNotFound)),
            );
          }
        }
      }
    }
    
    setState(() => _isScanning = false);
  }

  Future<void> _handleManualIsbn() async {
    final l10n = AppLocalizations.of(context)!;
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterIsbnError)),
      );
      return;
    }

    if (_isScanning) return;
    
    setState(() => _isScanning = true);
    
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final book = await bookProvider.findBookByIsbn(isbn);
    
    if (mounted) {
      if (book != null) {
        final add = await showDialog<bool>(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(book.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.author}: ${book.author}'),
                  Text('${l10n.isbn}: ${book.isbn}'),
                  Text('${l10n.pages}: ${book.totalPages}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.addToLibrary),
                ),
              ],
            );
          },
        );
        
        if (add == true) {
          final success = await bookProvider.addBookToLibrary(book.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? l10n.bookAdded : l10n.addError),
              ),
            );
            _isbnController.clear();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookNotFound)),
        );
      }
    }
    
    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
          if (!_showManualInput)
            MobileScanner(
              controller: _controller!,
              onDetect: _handleBarcode,
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 100,
                  color: Colors.white54,
                ),
              ),
            ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showManualInput 
                          ? l10n.enterIsbnManually
                          : l10n.scanBarcode,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (_showManualInput) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _isbnController,
                        decoration: InputDecoration(
                          labelText: l10n.isbn,
                          hintText: l10n.enterIsbn,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isScanning,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isScanning ? null : _handleManualIsbn,
                            icon: const Icon(Icons.search),
                            label: Text(l10n.search),
                          ),
                          TextButton(
                            onPressed: _isScanning
                                ? null
                                : () {
                                    setState(() {
                                      _showManualInput = false;
                                      _isbnController.clear();
                                    });
                                  },
                            child: Text(l10n.cancel),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _showManualInput = !_showManualInput;
                    if (!_showManualInput) {
                      _isbnController.clear();
                    }
                  });
                },
                icon: Icon(_showManualInput ? Icons.qr_code_scanner : Icons.keyboard),
                label: Text(_showManualInput ? l10n.scan : l10n.enterIsbnManually),
                backgroundColor: const Color(0xFF1A365D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
