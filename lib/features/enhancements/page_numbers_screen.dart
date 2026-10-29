import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class PageNumbersScreen extends StatefulWidget {
  const PageNumbersScreen({super.key});

  @override
  State<PageNumbersScreen> createState() => _PageNumbersScreenState();
}

class _PageNumbersScreenState extends State<PageNumbersScreen> {
  String? _path;
  PageNumberPosition _position = PageNumberPosition.footer;
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _path = picked.first);
  }

  Future<void> _apply() async {
    final path = _path;
    if (path == null || _position == PageNumberPosition.none) return;
    setState(() => _busy = true);
    try {
      final rendered = await PdfRenderService.render(path, dpi: 150);
      final specs = [
        for (final rp in rendered) PageSpec(rp.jpg, rp.widthPt, rp.heightPt),
      ];
      final out = await FileService.newOutputPath('Numbered', 'pdf');
      final result = await PdfService.assemble(
        pages: specs,
        outputPath: out,
        pageNumbers: _position,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen.single(
              outputPath: result, title: 'Add Page Numbers'),
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
      appBar: AppBar(title: const Text('Add Page Numbers')),
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
            Text('POSITION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: scheme.onSurfaceVariant,
                )),
            const SizedBox(height: 6),
            SegmentedButton<PageNumberPosition>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: PageNumberPosition.footer, label: Text('Footer')),
                ButtonSegment(
                    value: PageNumberPosition.header, label: Text('Header')),
              ],
              selected: {_position},
              onSelectionChanged: (s) => setState(() => _position = s.first),
            ),
            const SizedBox(height: 8),
            Text('Numbers appear as "page / total" centered on each page.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            const Spacer(),
            FilledButton.icon(
              onPressed: (_busy || _path == null) ? null : _apply,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.format_list_numbered),
              label: Text(_busy ? 'Applying…' : 'Add page numbers'),
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
