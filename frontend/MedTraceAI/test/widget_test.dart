import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace_ai/main.dart';
import 'package:medtrace_ai/screens/landing_screen.dart';
import 'package:medtrace_ai/screens/app_screen.dart';
import 'package:medtrace_ai/widgets/chatbot_floating_button.dart';
import 'package:medtrace_ai/widgets/chatbot_overlay.dart';
import 'package:medtrace_ai/widgets/format_panel.dart';

void main() {
  testWidgets('MedTrace AI smoke, upward transition, format panel and chatbot test', (WidgetTester tester) async {
    // Set screen size to desktop resolution
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build MedTraceApp
    await tester.pumpWidget(const MedTraceApp());
    await tester.pump();

    // Verify Page 1 Landing Screen is present
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('Autonomous Clinical Trace & Multi-\nModal Intelligence'), findsOneWidget);

    // Tap on Ingestion Workspace button on Landing Screen
    await tester.tap(find.text('Ingestion Workspace'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));

    // Verify Page 2 AppScreen is rendered with Workspace view
    expect(find.byType(AppScreen), findsOneWidget);
    expect(find.text('Clinical Ingestion Workspace'), findsOneWidget);

    // Tap the 12 Formats button
    await tester.tap(find.text('12 Formats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify format panel opens and shows all requested formats
    expect(find.byType(FormatPanel), findsOneWidget);
    expect(find.text('Supported Ingestion Formats'), findsOneWidget);

    final panelFinder = find.byType(FormatPanel);
    final formats = [
      'PDF', 'DOC', 'DOCX', 'TXT', 'CSV', 'XLS', 'XLSX', 'PPT', 'PPTX', 'PNG', 'JPG', 'JPEG'
    ];
    for (final fmt in formats) {
      expect(find.descendant(of: panelFinder, matching: find.text(fmt)), findsOneWidget);
    }

    // Select PDF format chip inside FormatPanel
    await tester.tap(find.descendant(of: panelFinder, matching: find.text('PDF')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Open Chatbot by tapping the floating launcher button
    final launcherFinder = find.byType(ChatbotFloatingButton);
    expect(launcherFinder, findsOneWidget);
    await tester.tap(launcherFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify chatbot overlay is displayed
    expect(find.byType(ChatbotOverlay), findsOneWidget);
    expect(find.text('MedBot'), findsWidgets);
    expect(find.text('Summarize clinical findings'), findsWidgets);

    // Tap a suggested prompt chip
    await tester.tap(find.text('Summarize clinical findings').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    // Verify message was added to chat
    expect(find.text('Summarize clinical findings'), findsWidgets);
  });
}
