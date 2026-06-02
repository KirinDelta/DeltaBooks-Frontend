import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../services/ocr_service.dart';
import '../theme/app_colors.dart';

class OcrFieldButton extends StatefulWidget {
  final TextEditingController controller;

  /// Replace field value with digits only (e.g. page count).
  final bool numericOnly;

  /// Replace field value with digits + one decimal point (e.g. price).
  final bool decimalAllowed;

  /// Append with newline instead of space (for multiline fields).
  final bool multiLine;

  const OcrFieldButton({
    super.key,
    required this.controller,
    this.numericOnly = false,
    this.decimalAllowed = false,
    this.multiLine = false,
  });

  @override
  State<OcrFieldButton> createState() => _OcrFieldButtonState();
}

class _OcrFieldButtonState extends State<OcrFieldButton> {
  bool _processing = false;

  Future<void> _scan() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (file == null) return;

    setState(() => _processing = true);
    final raw = await OcrService.extractText(file);
    if (!mounted) return;
    setState(() => _processing = false);

    if (raw == null || raw.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noTextDetected)));
      return;
    }

    String processed = raw;
    if (widget.numericOnly) {
      processed = raw.replaceAll(RegExp(r'[^0-9]'), '');
    } else if (widget.decimalAllowed) {
      processed = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      final parts = processed.split('.');
      if (parts.length > 2) {
        processed = '${parts.first}.${parts.skip(1).join('')}';
      }
    }

    if (processed.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noTextDetected)));
      return;
    }

    final current = widget.controller.text;
    if (widget.numericOnly || widget.decimalAllowed || current.isEmpty) {
      widget.controller.text = processed;
    } else {
      final sep = widget.multiLine ? '\n' : ' ';
      widget.controller.text = current + sep + processed;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      onPressed: _scan,
      icon: const Icon(Icons.camera_alt_outlined, size: 20),
      tooltip: AppLocalizations.of(context)!.scanFieldTooltip,
      color: AppColors.deepSeaBlue,
    );
  }
}
