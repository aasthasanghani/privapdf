import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  String? _path;
  int _pages = 0;
  final Set<int> _selected = {}; // zero-based page indices
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    try {
      final count = await PdfRenderService.pageCount(picked.first);
      setState(() {
        _path = picked.first;
        _pages = count;
        _selected.clear();
      });
    } catch (e) {
      _snack('Could not open PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extract() async {
    final path = _path;
    if (path == null || _selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      final indices = _selected.toList()..sort();
      final rendered =
          await PdfRenderService.render(path, dpi: 150, indices: indices);
      final specs = [
        for (final rp in rendered) PageSpec(rp.jpg, rp.widthPt, rp.heightPt),
      ];
      final out = await FileService.newOutputPath('Extract', 'pdf');
      final result = await PdfService.assemble(pages: specs, outputPath: out);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen.single(
              outputPath: result, title: 'Split & Extract'),
        ),
      );
    } catch (e) {
      _snack('Could not extract: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split & Extract'),
        actions: [
          if (_path != null)
            TextButton(
              onPressed: () => setState(() {
                if (_selected.length == _pages) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(List.generate(_pages, (i) => i));
                }
              }),
              child: Text(_selected.length == _pages ? 'None' : 'All'),
            ),
        ],
      ),
      body: _path == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.content_cut_outlined,
                        size: 64, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text('Pick pages to pull into a new PDF',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Choose a PDF'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${FileService.fileName(_path!)} · $_pages pages',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      TextButton(
                          onPressed: _busy ? null : _pick,
                          child: const Text('Change')),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _pages; i++)
                          FilterChip(
                            label: Text('${i + 1}'),
                            selected: _selected.contains(i),
                            onSelected: (v) => setState(() {
                              if (v) {
                                _selected.add(i);
                              } else {
                                _selected.remove(i);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: (_path == null || _selected.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : _extract,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.content_cut),
              label: Text(_busy
                  ? 'Extracting…'
                  : 'Extract ${_selected.length} page${_selected.length == 1 ? '' : 's'}'),
            ),
    );
  }
}
