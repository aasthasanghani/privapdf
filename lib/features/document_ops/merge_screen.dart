import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  final List<String> _paths = [];
  bool _busy = false;

  Future<void> _add() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _paths.addAll(picked));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _paths.insert(newIndex, _paths.removeAt(oldIndex));
    });
  }

  Future<void> _merge() async {
    if (_paths.length < 2) return;
    setState(() => _busy = true);
    try {
      final specs = <PageSpec>[];
      for (final path in _paths) {
        final pages = await PdfRenderService.render(path, dpi: 150);
        for (final rp in pages) {
          specs.add(PageSpec(rp.jpg, rp.widthPt, rp.heightPt));
        }
      }
      final out = await FileService.newOutputPath('Merged', 'pdf');
      final result = await PdfService.assemble(pages: specs, outputPath: out);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen.single(outputPath: result, title: 'Merge PDFs'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not merge: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Merge PDFs')),
      body: _paths.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.merge_outlined, size: 64, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text('Combine several PDFs into one',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                      label: const Text('Add PDFs'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Drag to set the order. Pages are combined top to bottom.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _paths.length,
                    onReorder: _reorder,
                    itemBuilder: (context, i) {
                      final path = _paths[i];
                      return Card(
                        key: ValueKey(path + i.toString()),
                        color: scheme.surfaceContainerHighest,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            child: Text('${i + 1}'),
                          ),
                          title: Text(FileService.fileName(path),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _paths.removeAt(i)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                      label: const Text('Add more PDFs'),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _paths.length < 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : _merge,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.merge),
              label: Text(_busy ? 'Merging…' : 'Merge ${_paths.length} PDFs'),
            ),
    );
  }
}
