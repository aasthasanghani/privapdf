import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class _Page {
  _Page(this.rendered);
  final RenderedPage rendered;
  int turns = 0;
}

class ReorderRotateScreen extends StatefulWidget {
  const ReorderRotateScreen({super.key});

  @override
  State<ReorderRotateScreen> createState() => _ReorderRotateScreenState();
}

class _ReorderRotateScreenState extends State<ReorderRotateScreen> {
  List<_Page> _pages = [];
  bool _busy = false;
  bool _loaded = false;

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    try {
      final rendered = await PdfRenderService.render(picked.first, dpi: 130);
      setState(() {
        _pages = [for (final rp in rendered) _Page(rp)];
        _loaded = true;
      });
    } catch (e) {
      _snack('Could not open PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _pages.insert(newIndex, _pages.removeAt(oldIndex));
    });
  }

  Future<void> _apply() async {
    if (_pages.isEmpty) return;
    setState(() => _busy = true);
    try {
      final specs = [
        for (final p in _pages)
          PageSpec(
            p.rendered.jpg,
            p.rendered.widthPt,
            p.rendered.heightPt,
            quarterTurns: p.turns,
          ),
      ];
      final out = await FileService.newOutputPath('Organized', 'pdf');
      final result = await PdfService.assemble(pages: specs, outputPath: out);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen.single(
              outputPath: result, title: 'Reorder & Rotate'),
        ),
      );
    } catch (e) {
      _snack('Could not save: $e');
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
      appBar: AppBar(title: const Text('Reorder & Rotate')),
      body: !_loaded
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert_outlined,
                        size: 64, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text('Reorder and rotate the pages of a PDF',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.file_open_outlined),
                      label: Text(_busy ? 'Opening…' : 'Choose a PDF'),
                    ),
                  ],
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pages.length,
              onReorder: _reorder,
              itemBuilder: (context, i) {
                final p = _pages[i];
                return Card(
                  key: ValueKey(p),
                  color: scheme.surfaceContainerHighest,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: RotatedBox(
                            quarterTurns: p.turns,
                            child: Image.memory(
                              p.rendered.jpg,
                              width: 48,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text('Page ${i + 1}')),
                        IconButton(
                          tooltip: 'Rotate',
                          icon: const Icon(Icons.rotate_right),
                          onPressed: () =>
                              setState(() => p.turns = (p.turns + 1) % 4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: !_loaded
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : _apply,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_busy ? 'Saving…' : 'Save PDF'),
            ),
    );
  }
}
