import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paynest/core/theme/app_theme.dart';
import 'package:paynest/core/utils/app_utils.dart';

void main() {
  testWidgets('Renders UGX currency badge widget properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Text(
              AppUtils.formatCurrency(50000),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );

    expect(find.text('UGX 50,000'), findsOneWidget);
  });
}
