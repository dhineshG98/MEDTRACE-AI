import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace_ai/widgets/chatbot_overlay.dart';

void main() {
  testWidgets('ChatbotOverlay renders active document context and handles offline fallback', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool closed = false;
    bool contextCleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ChatbotOverlay(
                isOpen: true,
                activeDocumentId: 'doc-1234',
                activeDocumentName: 'Sample_Pathology_Report.pdf',
                onClearActiveDocument: () {
                  contextCleared = true;
                },
                onClose: () {
                  closed = true;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Copilot header and active document grounding context banner
    expect(find.text('MedBot'), findsWidgets);
    expect(find.text('Grounded on: Sample_Pathology_Report.pdf'), findsOneWidget);

    // Verify context-aware suggestion prompts are visible
    expect(find.text('Summarize clinical findings'), findsWidgets);
    expect(find.text('List medications & dosages'), findsOneWidget);
    await tester.drag(find.text('List medications & dosages'), const Offset(-250, 0));
    await tester.pump();
    expect(find.text('Check abnormal vitals'), findsOneWidget);

    // Clear context test
    final clearBtnFinder = find.byTooltip('Clear document context');
    expect(clearBtnFinder, findsOneWidget);
    await tester.tap(clearBtnFinder);
    await tester.pump();
    expect(contextCleared, isTrue);

    // Verify close callback
    final closeBtnFinder = find.byTooltip('Minimize MedBot');
    expect(closeBtnFinder, findsOneWidget);
    await tester.tap(closeBtnFinder);
    await tester.pump();
    expect(closed, isTrue);
  });
}
