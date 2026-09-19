import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace_ai/models/med_document.dart';
import 'package:medtrace_ai/widgets/patient_timeline_view.dart';

void main() {
  testWidgets('PatientTimelineView renders chronological nodes, filters by category, and copies ASCII tree', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockTimeline = PatientTimeline(
      patientName: 'Jane Doe',
      totalEvents: 4,
      asciiTree: '''PATIENT TIMELINE
════════════════════════════════════════════════════════════

10 JAN 2025
│
├── 🧪 LABORATORY
│   HbA1c: 8.4%
│   Fasting Glucose: 168 mg/dL
│   📄 Lab_Report_01.pdf
│
│
15 JAN 2025
│
├── 🩺 CLINICAL VISIT
│   Diagnosis: Type 2 Diabetes
│   Diagnosis: Hypertension
│   📄 Clinical_Note_01.pdf
│
│
15 JAN 2025
│
├── 💊 PRESCRIPTION
│   Metformin 500 mg
│   Twice daily
│   📄 Prescription_01.pdf
│
│
18 JAN 2025
│
└── 🩻 IMAGING
    Chest X-Ray
    Finding: No acute abnormality
    📄 Imaging_Report_01.pdf
''',
      events: const [
        TimelineEvent(
          id: 'evt-1',
          date: '10 JAN 2025',
          rawDate: '2025-01-10T09:00:00',
          category: 'LABORATORY',
          icon: '🧪',
          title: 'LABORATORY',
          items: ['HbA1c: 8.4%', 'Fasting Glucose: 168 mg/dL'],
          documentId: 'doc-1',
          documentName: 'Lab_Report_01.pdf',
        ),
        TimelineEvent(
          id: 'evt-2',
          date: '15 JAN 2025',
          rawDate: '2025-01-15T10:00:00',
          category: 'CLINICAL_VISIT',
          icon: '🩺',
          title: 'CLINICAL VISIT',
          items: ['Diagnosis: Type 2 Diabetes', 'Diagnosis: Hypertension'],
          documentId: 'doc-2',
          documentName: 'Clinical_Note_01.pdf',
        ),
        TimelineEvent(
          id: 'evt-3',
          date: '15 JAN 2025',
          rawDate: '2025-01-15T11:00:00',
          category: 'PRESCRIPTION',
          icon: '💊',
          title: 'PRESCRIPTION',
          items: ['Metformin 500 mg', 'Twice daily'],
          documentId: 'doc-3',
          documentName: 'Prescription_01.pdf',
        ),
        TimelineEvent(
          id: 'evt-4',
          date: '18 JAN 2025',
          rawDate: '2025-01-18T14:00:00',
          category: 'IMAGING',
          icon: '🩻',
          title: 'IMAGING',
          items: ['Chest X-Ray', 'Finding: No acute abnormality'],
          documentId: 'doc-4',
          documentName: 'Imaging_Report_01.pdf',
        ),
      ],
    );

    String? inspectedDoc;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PatientTimelineView(
              timeline: mockTimeline,
              isLoading: false,
              onRefresh: () {},
              onInspectDocument: (id) => inspectedDoc = id,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Title & Event Count badge
    expect(find.text('PATIENT TIMELINE'), findsOneWidget);
    expect(find.text('4 Events'), findsOneWidget);

    // Verify dates & items
    expect(find.text('10 JAN 2025'), findsOneWidget);
    expect(find.text('HbA1c: 8.4%'), findsOneWidget);
    expect(find.text('Fasting Glucose: 168 mg/dL'), findsOneWidget);
    expect(find.text('Lab_Report_01.pdf'), findsOneWidget);

    expect(find.text('Diagnosis: Type 2 Diabetes'), findsOneWidget);
    expect(find.text('Metformin 500 mg'), findsOneWidget);
    expect(find.text('Chest X-Ray'), findsOneWidget);

    // Test Inspect document click
    await tester.ensureVisible(find.text('Lab_Report_01.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lab_Report_01.pdf'));
    await tester.pump();
    expect(inspectedDoc, equals('doc-1'));

    // Test Category filter: tap 🧪 Labs
    await tester.ensureVisible(find.text('🧪 Labs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🧪 Labs'));
    await tester.pump();

    // Now only lab event is displayed, prescription is filtered out
    expect(find.text('HbA1c: 8.4%'), findsOneWidget);
    expect(find.text('Metformin 500 mg'), findsNothing);

    // Tap All Events to reset filter
    await tester.ensureVisible(find.text('All Events'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Events'));
    await tester.pump();
    expect(find.text('Metformin 500 mg'), findsOneWidget);

    // Test Copy ASCII Tree button
    await tester.ensureVisible(find.text('Copy ASCII Tree'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy ASCII Tree'));
    await tester.pump();
    expect(find.text('Clinical ASCII timeline copied to clipboard!'), findsOneWidget);
  });
}
