import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the bundled PDFium engine used to read and render existing PDFs.
  await pdfrxFlutterInitialize();
  runApp(const ProviderScope(child: PrivaPdfApp()));
}

class PrivaPdfApp extends ConsumerWidget {
  const PrivaPdfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'PrivaPDF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
