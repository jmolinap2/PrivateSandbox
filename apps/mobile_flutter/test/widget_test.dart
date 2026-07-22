import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/presentation/widgets/pin_dots.dart';

void main() {
  testWidgets('PinDots renders one indicator per digit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PinDots(length: 6, filled: 3)),
      ),
    );

    expect(find.byType(Container), findsNWidgets(6));
  });
}
