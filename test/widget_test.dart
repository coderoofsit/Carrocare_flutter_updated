import 'package:carrocare_flutter/app/app.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders introduction loader', (WidgetTester tester) async {
    await configureDependencies();
    await tester.pumpWidget(const CarroCareApp());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
