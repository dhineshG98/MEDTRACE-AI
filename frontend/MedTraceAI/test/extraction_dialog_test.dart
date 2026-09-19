import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace_ai/models/med_document.dart';
import 'package:medtrace_ai/widgets/extraction_details_dialog.dart';

void main() {
  testWidgets('ExtractionDetailsDialog renders entities, negation, treats link, and labs', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final sampleExtraction = StructuredExtraction(
      id: 'ext-001',
      documentId: 'doc-001',
      documentType: 'Pathology & Lab Panel',
      documentTypeConfidence: 0.95,
      patient: const PatientInfoModel(
        name: 'Eleanor Rigby',
        ageOrDob: '14/08/1965 (Age 59)',
        gender: 'Female',
        mrn: 'MRN-884210',
        date: '15 Jan 2025',
      ),
      conditions: const [
        ConditionItemModel(
          name: 'Essential Hypertension',
          icd10: 'I10',
          isNegated: true,
          confidence: 0.95,
          tier: 'High',
        ),
        ConditionItemModel(
          name: 'Type 2 Diabetes Mellitus',
          icd10: 'E11.9',
          isNegated: false,
          confidence: 0.95,
          tier: 'High',
        ),
      ],
      medications: const [
        MedicationItemModel(
          name: 'Metformin',
          canonicalName: 'Metformin',
          dosage: '500 mg',
          frequency: 'Twice Daily',
          route: 'Oral',
          treats: 'Type 2 Diabetes Mellitus',
          confidence: 1.0,
          tier: 'High',
        ),
        MedicationItemModel(
          name: 'Amlodipine',
          canonicalName: 'Amlodipine',
          dosage: '5 mg',
          frequency: 'Once Daily',
          route: 'Oral',
          treats: 'Essential Hypertension',
          confidence: 1.0,
          tier: 'High',
        ),
      ],
      allergies: const [
        AllergyItemModel(
          name: 'No Known Drug Allergies (NKDA)',
          isNegated: true,
          confidence: 0.98,
          tier: 'High',
        ),
      ],
      labResults: const [
        LabResultItemModel(
          testName: 'HbA1c',
          value: '8.4',
          unit: '%',
          referenceRange: '< 5.7%',
          flag: 'High',
          confidence: 1.0,
          tier: 'High',
        ),
        LabResultItemModel(
          testName: 'Fasting Blood Glucose',
          value: '168',
          unit: 'mg/dL',
          referenceRange: '70 - 99 mg/dL',
          flag: 'High',
          confidence: 1.0,
          tier: 'High',
        ),
      ],
      dates: const [
        DateItemModel(date: '15 Jan 2025', type: 'Encounter Date'),
      ],
      doctors: const ['Dr. Marcus Vance'],
      qualityScore: 98,
      requiresReview: false,
      summary: 'Patient evaluation shows controlled glycemic status with metformin.',
      providerUsed: 'heuristic',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExtractionDetailsDialog(
            extraction: sampleExtraction,
            filename: 'Clinical_Note_01.pdf',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Patient Information
    expect(find.text('Eleanor Rigby'), findsOneWidget);
    expect(find.text('MRN: MRN-884210'), findsOneWidget);

    // Verify Diagnoses & Negation Badges
    expect(find.text('Essential Hypertension'), findsNWidgets(2)); // condition chip & treats chip
    expect(find.text('NEGATED'), findsOneWidget);
    expect(find.text('Type 2 Diabetes Mellitus'), findsNWidgets(2)); // condition & treats chip
    expect(find.text('AFFIRMED'), findsOneWidget);
    expect(find.text('I10'), findsOneWidget);
    expect(find.text('E11.9'), findsOneWidget);

    // Verify Medications & Treats mapping
    expect(find.text('Metformin'), findsOneWidget);
    expect(find.text('500 mg'), findsOneWidget);
    expect(find.text('Amlodipine'), findsOneWidget);

    // Verify Allergies & Labs
    expect(find.text('No Known Drug Allergies (NKDA)'), findsOneWidget);
    expect(find.text('HbA1c'), findsOneWidget);
    expect(find.text('8.4 %'), findsOneWidget);
    expect(find.text('High'), findsAtLeastNWidgets(2)); // High lab flags & tier badges

    // Verify Quality Score & Doctor
    expect(find.textContaining('Quality 98/100'), findsOneWidget);
    expect(find.text('Dr. Marcus Vance'), findsOneWidget);
  });
}
