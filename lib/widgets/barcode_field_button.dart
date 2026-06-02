import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class BarcodeFieldButton extends StatelessWidget {
  final TextEditingController controller;

  const BarcodeFieldButton({super.key, required this.controller});

  Future<void> _scan(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final scannerController = MobileScannerController();
    bool detected = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(
            children: [
              MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  if (detected) return;
                  if (capture.barcodes.isEmpty) return;
                  final value = capture.barcodes.first.rawValue;
                  if (value != null) {
                    detected = true;
                    controller.text = value;
                    Navigator.pop(sheetContext);
                  }
                },
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.pointCameraAtBarcode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    scannerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _scan(context),
      icon: const Icon(Icons.qr_code_scanner, size: 20),
      tooltip: AppLocalizations.of(context)!.scanBarcodeTip,
      color: AppColors.deepSeaBlue,
    );
  }
}
