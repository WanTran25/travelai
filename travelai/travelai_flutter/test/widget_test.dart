import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:travelai_flutter/theme/app_theme.dart';

// Test cơ bản: đảm bảo theme hoạt động và render được widget
void main() {
  testWidgets('Light theme render duoc text', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Text('TravelAI', style: TextStyle(fontSize: 24)),
      ),
    ));

    expect(find.text('TravelAI'), findsOneWidget);
  });

  test('Light theme co brightness light', () {
    expect(AppTheme.light.brightness, equals(Brightness.light));
    expect(AppTheme.light.colorScheme.primary, isNotNull);
  });

  test('Dark theme co brightness dark', () {
    expect(AppTheme.dark.brightness, equals(Brightness.dark));
    expect(AppTheme.dark.colorScheme.primary, isNotNull);
  });
}
