import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pick_service.dart';
import '../../core/services/searchable_pdf_service.dart';
import '../shared/result_screen.dart';

class SearchablePdfScreen extends StatefulWidget {
  const SearchablePdfScreen({super.key});

  @override
  State<SearchablePdfScreen> createState() => _SearchablePdfScreenState();
}

class _SearchablePdfScreenState extends State<SearchablePdfScreen> {
  String? _path;
  bool _busy = false;
  int _done = 0;
  int _total = 0;

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _path = picked.first);
  }

  Future<void> _run() async {
    final path = _path;
    if (path == null) return;
    setState(() {
      _busy = true;
      _done = 0;
      _total = 0;
    });
    try {
      final out = await SearchablePdfService.build(
        path,
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _done = done;
              _total = total;
            });
          }
        },
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen.single(outputPath: out, title: 'Searchable PDF'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not process: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Searchable PDF')),
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
            Text(
              'Adds an invisible text layer over a scanned or image-only PDF, so '
              'you can select, copy and search its text in any PDF viewer. '
              'Runs entirely on your device.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const Spacer(),
            if (_busy && _total > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _total == 0 ? null : _done / _total,
                    ),
                    const SizedBox(height: 8),
                    Text('Reading page $_done of $_total…',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            FilledButton.icon(
              onPressed: (_busy || _path == null) ? null : _run,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.text_snippet_outlined),
              label: Text(_busy ? 'Processing…' : 'Make searchable'),
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
