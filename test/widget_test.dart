import 'package:flutter_test/flutter_test.dart';
import 'package:turtle_nesting_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TurtleNestingApp());
    // ...
  });
}
