import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  String? _path;
  final _text = TextEditingController(text: 'CONFIDENTIAL');
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _path = picked.first);
  }

  Future<void> _apply() async {
    final path = _path;
    if (path == null || _text.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final rendered = await PdfRenderService.render(path, dpi: 150);
      final specs = [
        for (final rp in rendered) PageSpec(rp.jpg, rp.widthPt, rp.heightPt),
      ];
      final out = await FileService.newOutputPath('Watermarked', 'pdf');
      final result = await PdfService.assemble(
        pages: specs,
        outputPath: out,
        watermark: _text.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen.single(outputPath: result, title: 'Add Watermark'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not apply: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Watermark')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: scheme.surfaceContainerHighest,
              child: ListTile(
                leading:
                    Icon(Icons.picture_as_pdf_outlined, color: scheme.primary),
                title: Text(
                  _path == null ? 'No PDF chosen' : FileService.fileName(_path!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: TextButton(
                  onPressed: _busy ? null : _pick,
                  child: Text(_path == null ? 'Choose' : 'Change'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _text,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Watermark text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stamped diagonally across every page, semi-transparent.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: (_busy || _path == null) ? null : _apply,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.branding_watermark_outlined),
              label: Text(_busy ? 'Applying…' : 'Apply watermark'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
