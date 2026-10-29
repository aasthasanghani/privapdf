import 'package:flutter/material.dart';

import 'tool_catalog.dart';

/// Temporary destination for tools whose implementation is still landing.
/// Replaced per-tool as each feature screen is built.
class ToolPlaceholderScreen extends StatelessWidget {
  const ToolPlaceholderScreen({super.key, required this.tool});

  final ToolDef tool;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tool.label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tool.icon, size: 64, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                '${tool.label} is being built',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This tool runs fully on your device. It will be wired up in an upcoming build.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
