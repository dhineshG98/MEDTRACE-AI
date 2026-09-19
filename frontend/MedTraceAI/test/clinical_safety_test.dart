import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace_ai/models/biomarker_trend.dart';
import 'package:medtrace_ai/models/clinical_safety_alert.dart';
import 'package:medtrace_ai/models/med_document.dart';
import 'package:medtrace_ai/services/clinical_safety_engine.dart';
import 'package:medtrace_ai/widgets/biomarker_trend_chart.dart';
import 'package:medtrace_ai/widgets/clinical_safety_banner.dart';

void main() {
  group('ClinicalSafetyEngine Tests', () {
    test('Detects Warfarin + Aspirin DDI conflict', () {
      final events = [
        const TimelineEvent(
          id: 'e1',
          date: '10 Jan 2025',
          rawDate: '2025-01-10',
          category: 'PRESCRIPTION',
          icon: '💊',
          title: 'Warfarin Anticoagulant Rx',
          items: ['Warfarin Sodium 5 mg daily'],
          documentId: 'd1',
          documentName: 'Rx1.pdf',
        ),
        const TimelineEvent(
          id: 'e2',
          date: '12 Jan 2025',
          rawDate: '2025-01-12',
          category: 'PRESCRIPTION',
          icon: '💊',
          title: 'Aspirin Antiplatelet Rx',
          items: ['Aspirin 81 mg daily'],
          documentId: 'd2',
          documentName: 'Rx2.pdf',
        ),
      ];

      final alerts = ClinicalSafetyEngine.scanPatientRecords(
        events: events,
        documents: [],
      );

      expect(alerts.isNotEmpty, isTrue);
      final hasWarfarinAspirin = alerts.any((a) =>
          a.primaryAgent.contains('Warfarin') && a.conflictingAgent.contains('Aspirin'));
      expect(hasWarfarinAspirin, isTrue);
      expect(alerts.first.severity, AlertSeverity.critical);
    });

    test('Detects Penicillin allergy with Amoxicillin prescription', () {
      final events = [
        const TimelineEvent(
          id: 'e1',
          date: '10 Jan 2025',
          rawDate: '2025-01-10',
          category: 'CLINICAL_VISIT',
          icon: '🩺',
          title: 'Allergy Record',
          items: ['Documented Penicillin allergy (anaphylaxis history)'],
          documentId: 'd1',
          documentName: 'Allergies.pdf',
        ),
        const TimelineEvent(
          id: 'e2',
          date: '15 Jan 2025',
          rawDate: '2025-01-15',
          category: 'PRESCRIPTION',
          icon: '💊',
          title: 'Antibiotic Prescription',
          items: ['Amoxicillin 500 mg PO TID for 7 days'],
          documentId: 'd2',
          documentName: 'Rx.pdf',
        ),
      ];

      final alerts = ClinicalSafetyEngine.scanPatientRecords(
        events: events,
        documents: [],
      );

      expect(alerts.isNotEmpty, isTrue);
      final hasAllergyConflict = alerts.any(
        (a) => a.type == AlertType.allergyConflict,
      );
      expect(hasAllergyConflict, isTrue);
    });

    test('Provides preset scenarios for interactive evaluation', () {
      final scenarios = ClinicalSafetyEngine.getPresetScenarios();
      expect(scenarios.containsKey('WARFARIN_ASPIRIN'), isTrue);
      expect(scenarios.containsKey('PENICILLIN_ALLERGY'), isTrue);
      expect(scenarios.containsKey('METFORMIN_CONTRAST'), isTrue);
      expect(scenarios.containsKey('ALL_CLEAR'), isTrue);
      expect(scenarios['ALL_CLEAR']!.isEmpty, isTrue);
    });
  });

  group('BiomarkerSeries Tests', () {
    test('Calculates delta percentage and target achievement correctly', () {
      final series = BiomarkerSeries(
        id: 'hba1c',
        metricName: 'HbA1c',
        unit: '%',
        targetRangeLabel: '< 7.0%',
        targetThreshold: 7.0,
        lowerIsBetter: true,
        points: [
          BiomarkerDataPoint(
            date: DateTime(2025, 1, 10),
            formattedDate: '10 Jan',
            value: 8.4,
            milestone: 'Initial High Baseline',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 8, 20),
            formattedDate: '20 Aug',
            value: 6.2,
            milestone: 'Controlled Goal Met',
            isTargetMet: true,
          ),
        ],
      );

      expect(series.initialValue, 8.4);
      expect(series.latestValue, 6.2);
      expect(series.isImproved, isTrue);
      expect(series.isLatestInTarget, isTrue);
      expect(series.deltaPercentage, closeTo(-26.19, 0.1));
    });
  });

  group('Clinical Safety & Biomarker Widget Tests', () {
    testWidgets('ClinicalSafetyBanner renders alert details and supports acknowledgment', (tester) async {
      final testAlert = ClinicalSafetyAlert(
        id: 'test-1',
        title: 'Concurrent Anticoagulant & Antiplatelet Therapy',
        type: AlertType.drugInteraction,
        severity: AlertSeverity.critical,
        primaryAgent: 'Warfarin Sodium',
        conflictingAgent: 'Aspirin 81 mg',
        clinicalRisk: 'Elevates gastrointestinal bleeding risk.',
        recommendedAction: 'Hold Aspirin immediately.',
        detectedAt: DateTime.now(),
      );

      bool acknowledged = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClinicalSafetyBanner(
                alerts: [testAlert],
                onAcknowledge: (alert) => acknowledged = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('CRITICAL SAFETY ALERT'), findsOneWidget);
      expect(find.textContaining('Warfarin Sodium'), findsWidgets);
      expect(find.textContaining('Aspirin 81 mg'), findsWidgets);

      // Tap Acknowledge button
      final ackButton = find.text('Acknowledge & Override');
      expect(ackButton, findsOneWidget);
      await tester.tap(ackButton);
      await tester.pumpAndSettle();

      expect(acknowledged, isTrue);
    });

    testWidgets('BiomarkerTrendChart renders metric pills and target zone', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BiomarkerTrendChart(),
            ),
          ),
        ),
      );

      expect(find.text('LONGITUDINAL BIOMARKER RECOVERY TRAJECTORY'), findsOneWidget);
      expect(find.text('HbA1c'), findsOneWidget);
      expect(find.text('Fasting Glucose'), findsOneWidget);
      expect(find.text('Blood Pressure (Sys)'), findsOneWidget);

      // Verify initial HbA1c metrics are visible (unit = %)
      expect(find.textContaining('%'), findsWidgets);

      // Tap Fasting Glucose metric pill
      await tester.ensureVisible(find.text('Fasting Glucose'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fasting Glucose'));
      await tester.pumpAndSettle();

      // Verify Fasting Glucose baseline value appears
      expect(find.textContaining('168.0'), findsWidgets);
    });
  });
}
