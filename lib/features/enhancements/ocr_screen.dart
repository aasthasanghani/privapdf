import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pick_service.dart';
import 'ocr_service.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  bool _busy = false;
  String? _text;

  Future<void> _fromImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    final paths = [for (final f in files) if (f.path != null) f.path!];
    if (paths.isEmpty) return;
    await _run(() => OcrService.recognizeFiles(paths));
  }

  Future<void> _fromPdf() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    await _run(() async {
      final rendered = await PdfRenderService.render(picked.first, dpi: 200);
      final dir = await FileService.tempDir();
      final paths = <String>[];
      for (var i = 0; i < rendered.length; i++) {
        final p = '${dir.path}/ocr_$i.jpg';
        await File(p).writeAsBytes(rendered[i].jpg);
        paths.add(p);
      }
      final text = await OcrService.recognizeFiles(paths);
      for (final p in paths) {
        try {
          await File(p).delete();
        } catch (_) {}
      }
      return text;
    });
  }

  Future<void> _run(Future<String> Function() task) async {
    setState(() => _busy = true);
    try {
      final text = await task();
      setState(() => _text = text.isEmpty ? 'No text found.' : text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OCR failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text ?? ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _exportTxt() async {
    final out = await FileService.newOutputPath('OCR', 'txt');
    await File(out).writeAsString(_text ?? '');
    await SharePlus.instance.share(
      ShareParams(files: [XFile(out)], subject: FileService.fileName(out)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Text OCR')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _fromImages,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('From images'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _fromPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('From PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : _text == null
                        ? Center(
                            child: Text(
                              'Pick images or a PDF to extract text',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(_text!),
                          ),
              ),
            ),
            if (_text != null && !_busy) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _exportTxt,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Export .txt'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
