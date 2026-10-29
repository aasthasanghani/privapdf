import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_service.dart';
import '../shared/result_screen.dart';

class ImagesToPdfScreen extends StatefulWidget {
  const ImagesToPdfScreen({super.key});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  final List<String> _paths = [];
  PdfMargin _margin = PdfMargin.small;
  PdfOrientation _orientation = PdfOrientation.auto;
  bool _busy = false;

  Future<void> _pick() async {
    // file_picker 13.x: pickFiles is static and returns a list (multi-select).
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    setState(() {
      for (final f in files) {
        if (f.path != null) _paths.add(f.path!);
      }
    });
  }

  void _removeAt(int i) => setState(() => _paths.removeAt(i));

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _paths.insert(newIndex, _paths.removeAt(oldIndex));
    });
  }

  Future<void> _create() async {
    if (_paths.isEmpty) return;
    setState(() => _busy = true);
    try {
      final out = await FileService.newOutputPath('Images', 'pdf');
      final path = await PdfService.imagesToPdf(
        imagePaths: List.of(_paths),
        outputPath: out,
        margin: _margin,
        orientation: _orientation,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(outputPath: path, title: 'Images to PDF'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Images to PDF')),
      body: Column(
        children: [
          Expanded(
            child: _paths.isEmpty
                ? _EmptyState(onPick: _pick)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _paths.length,
                    onReorder: _reorder,
                    itemBuilder: (context, i) {
                      final path = _paths[i];
                      return Card(
                        key: ValueKey(path + i.toString()),
                        color: scheme.surfaceContainerHighest,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(path),
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text('Page ${i + 1}'),
                          subtitle: Text(
                            FileService.fileName(path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeAt(i),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _OptionsBar(
            margin: _margin,
            orientation: _orientation,
            onMargin: (m) => setState(() => _margin = m),
            onOrientation: (o) => setState(() => _orientation = o),
            visible: _paths.isNotEmpty,
          ),
        ],
      ),
      floatingActionButton: _paths.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : _create,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_busy ? 'Creating…' : 'Create PDF'),
            ),
      bottomNavigationBar: _paths.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add more images'),
                ),
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text('Pick images to combine into a PDF',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Select images'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsBar extends StatelessWidget {
  const _OptionsBar({
    required this.margin,
    required this.orientation,
    required this.onMargin,
    required this.onOrientation,
    required this.visible,
  });

  final PdfMargin margin;
  final PdfOrientation orientation;
  final ValueChanged<PdfMargin> onMargin;
  final ValueChanged<PdfOrientation> onOrientation;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OptionLabel('Margin'),
          SegmentedButton<PdfMargin>(
            showSelectedIcon: false,
            segments: [
              for (final m in PdfMargin.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {margin},
            onSelectionChanged: (s) => onMargin(s.first),
          ),
          const SizedBox(height: 10),
          const _OptionLabel('Orientation'),
          SegmentedButton<PdfOrientation>(
            showSelectedIcon: false,
            segments: [
              for (final o in PdfOrientation.values)
                ButtonSegment(value: o, label: Text(o.label)),
            ],
            selected: {orientation},
            onSelectionChanged: (s) => onOrientation(s.first),
          ),
        ],
      ),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
