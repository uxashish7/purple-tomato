import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/features/advisor/widgets/ai_insight_card.dart';

void main() {
  testWidgets('AiInsightCard renders user message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiInsightCard(
            content: 'Hello AI Assistant',
            isUser: true,
          ),
        ),
      ),
    );

    expect(find.text('Hello AI Assistant'), findsOneWidget);
    expect(find.byIcon(Icons.psychology), findsNothing);
  });

  testWidgets('AiInsightCard renders AI message with psychology icon and educational disclaimer', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiInsightCard(
            content: 'Here is an educational analysis of your portfolio',
            isUser: false,
          ),
        ),
      ),
    );

    expect(find.text('Here is an educational analysis of your portfolio'), findsOneWidget);
    expect(find.byIcon(Icons.psychology), findsOneWidget);
    expect(find.text('For educational simulation only. Not SEBI registered financial advice.'), findsOneWidget);
  });
}
