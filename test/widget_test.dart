import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messkhojo_flutter/widgets/global_error_boundary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GlobalErrorBoundary renders branded error UI on widget failure', (WidgetTester tester) async {
    final errorDetails = FlutterErrorDetails(
      exception: Exception('Test UI Crash'),
      library: 'test_library',
      context: ErrorDescription('while building test widget'),
    );

    final errorWidget = GlobalErrorBoundary.buildErrorWidget(errorDetails);

    await tester.pumpWidget(
      MaterialApp(
        home: errorWidget,
      ),
    );

    expect(find.text('Something Went Wrong'), findsOneWidget);
    expect(find.text('Reload App'), findsOneWidget);
  });
}
