import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/file_service.dart';

/// In-app library of everything PrivaPDF has saved on this device.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final files = await FileService.listOutputs();
    if (!mounted) return;
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _share(File f) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(f.path)], subject: FileService.fileName(f.path)),
    );
  }

  Future<void> _rename(File f) async {
    final current = FileService.fileName(f.path);
    final dot = current.lastIndexOf('.');
    final ext = dot >= 0 ? current.substring(dot) : '';
    final controller =
        TextEditingController(text: dot >= 0 ? current.substring(0, dot) : current);

    final newBase = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Rename')),
        ],
      ),
    );
    if (newBase == null || newBase.isEmpty) return;
    final dir = f.parent.path;
    try {
      await f.rename('$dir${Platform.pathSeparator}$newBase$ext');
      await _load();
    } catch (e) {
      _snack('Could not rename: $e');
    }
  }

  Future<void> _delete(File f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text(FileService.fileName(f.path)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await f.delete();
      await _load();
    } catch (e) {
      _snack('Could not delete: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _actions(File f) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Share / Open'),
              onTap: () {
                Navigator.pop(context);
                _share(f);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _rename(f);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _delete(f);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _date(File f) {
    final d = f.statSync().modified;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Files')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_outlined,
                            size: 64, color: scheme.primary),
                        const SizedBox(height: 16),
                        Text('Nothing saved yet',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Documents you create appear here.',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _files.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final f = _files[i];
                      final name = FileService.fileName(f.path);
                      final isImage = RegExp(r'\.(jpe?g|png)$',
                              caseSensitive: false)
                          .hasMatch(name);
                      final isTxt =
                          name.toLowerCase().endsWith('.txt');
                      return Card(
                        color: scheme.surfaceContainerHighest,
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(
                            isImage
                                ? Icons.image_outlined
                                : isTxt
                                    ? Icons.description_outlined
                                    : Icons.picture_as_pdf_outlined,
                            color: scheme.primary,
                          ),
                          title: Text(name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_date(f)),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _actions(f),
                          ),
                          onTap: () => _share(f),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
