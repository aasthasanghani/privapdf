import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/password_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class PasswordProtectScreen extends StatefulWidget {
  const PasswordProtectScreen({super.key});

  @override
  State<PasswordProtectScreen> createState() => _PasswordProtectScreenState();
}

class _PasswordProtectScreenState extends State<PasswordProtectScreen> {
  String? _path;
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _path = picked.first);
  }

  String? _validate() {
    if (_path == null) return 'Choose a PDF first.';
    if (_pass.text.isEmpty) return 'Enter a password.';
    if (_pass.text != _confirm.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _protect() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _busy = true);
    try {
      final out = await PasswordService.protect(_path!, _pass.text);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen.single(outputPath: out, title: 'Password Protect'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not protect: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Password Protect')),
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
              controller: _pass,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AES-256. The PDF asks for this password to open. There is no '
                    'way to recover it if you forget it.',
                    style:
                        TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _busy ? null : _protect,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock_outline),
              label: Text(_busy ? 'Protecting…' : 'Protect PDF'),
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
