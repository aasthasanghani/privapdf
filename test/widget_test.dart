import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:privapdf/main.dart';

void main() {
  testWidgets('Home dashboard renders core sections', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PrivaPdfApp()));
    await tester.pumpAndSettle();

    expect(find.text('PrivaPDF'), findsOneWidget);
    expect(find.text('Scan Document'), findsWidgets);
    expect(find.text('Merge PDFs'), findsOneWidget);
    expect(find.textContaining('on-device'), findsOneWidget);
  });
}
