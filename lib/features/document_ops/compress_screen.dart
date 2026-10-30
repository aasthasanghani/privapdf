import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

/// Compression presets map to a render DPI and JPEG quality.
enum CompressLevel { light, medium, strong }

extension on CompressLevel {
  String get label => switch (this) {
        CompressLevel.light => 'Light',
        CompressLevel.medium => 'Medium',
        CompressLevel.strong => 'Strong',
      };
  double get dpi => switch (this) {
        CompressLevel.light => 150,
        CompressLevel.medium => 120,
        CompressLevel.strong => 96,
      };
  int get quality => switch (this) {
        CompressLevel.light => 70,
        CompressLevel.medium => 55,
        CompressLevel.strong => 45,
      };
}

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  String? _path;
  String? _originalSize;
  CompressLevel _level = CompressLevel.medium;
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    final size = await FileService.readableSize(picked.first);
    setState(() {
      _path = picked.first;
      _originalSize = size;
    });
  }

  Future<void> _compress() async {
    final path = _path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final rendered = await PdfRenderService.render(
        path,
        dpi: _level.dpi,
        quality: _level.quality,
      );
      final specs = [
        for (final r in rendered) PageSpec(r.jpg, r.widthPt, r.heightPt),
      ];
      final out = await FileService.newOutputPath('Compressed', 'pdf');
      final result = await PdfService.assemble(pages: specs, outputPath: out);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen.single(outputPath: result, title: 'Compress PDF'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not compress: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Compress PDF')),
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
                subtitle:
                    _originalSize == null ? null : Text('Current: $_originalSize'),
                trailing: TextButton(
                  onPressed: _busy ? null : _pick,
                  child: Text(_path == null ? 'Choose' : 'Change'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('COMPRESSION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: scheme.onSurfaceVariant,
                )),
            const SizedBox(height: 6),
            SegmentedButton<CompressLevel>(
              showSelectedIcon: false,
              segments: [
                for (final l in CompressLevel.values)
                  ButtonSegment(value: l, label: Text(l.label)),
              ],
              selected: {_level},
              onSelectionChanged: (s) => setState(() => _level = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              'Pages are re-rendered at a lower resolution and quality. Stronger '
              'compression means smaller files and softer images.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: (_busy || _path == null) ? null : _compress,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.compress),
              label: Text(_busy ? 'Compressing…' : 'Compress'),
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
