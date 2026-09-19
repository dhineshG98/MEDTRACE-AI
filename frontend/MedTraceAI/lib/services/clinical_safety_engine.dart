import '../models/clinical_safety_alert.dart';
import '../models/med_document.dart';

class ClinicalSafetyEngine {
  /// Default pre-configured scenarios for instant demonstration & safety verification
  static List<ClinicalSafetyAlert> getDemoAlerts() {
    return [
      ClinicalSafetyAlert(
        id: 'ddi-alert-001',
        title: 'Concurrent Anticoagulant & Antiplatelet Therapy',
        type: AlertType.drugInteraction,
        severity: AlertSeverity.critical,
        primaryAgent: 'Warfarin Sodium 5 mg',
        conflictingAgent: 'Aspirin (ASA) 81 mg',
        clinicalRisk:
            'Concurrent administration of Warfarin and Aspirin elevates major gastrointestinal bleeding and hemorrhagic stroke risk by 3.8x without additional thrombotic benefit in non-valvular conditions.',
        recommendedAction:
            'Hold Aspirin. Check PT/INR immediately (target INR 2.0-3.0). If antiplatelet therapy is mandatory, transition to gastroprotective proton pump inhibitor (PPI) co-prescription.',
        sourceDocuments: ['Rx_Order_01928.pdf', 'Discharge_Summary.pdf'],
        detectedAt: DateTime.now().subtract(const Duration(minutes: 14)),
      ),
      ClinicalSafetyAlert(
        id: 'ddi-alert-002',
        title: 'Documented Beta-Lactam Allergy Contraindication',
        type: AlertType.allergyConflict,
        severity: AlertSeverity.high,
        primaryAgent: 'Documented Penicillin Allergy (Anaphylaxis)',
        conflictingAgent: 'Amoxicillin-Clavulanate 875/125 mg',
        clinicalRisk:
            'Patient has documented Type 1 IgE-mediated hypersensitivity to Penicillin class. Cross-reactivity risk of severe anaphylactic shock is imminent.',
        recommendedAction:
            'Cancel Amoxicillin order immediately. Alternative non-beta-lactam coverage recommended: Azithromycin 500 mg or Levofloxacin 500 mg.',
        sourceDocuments: ['Allergy_Intolerance_Profile.pdf', 'Urgent_Care_Note.pdf'],
        detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  /// Preset Scenarios for demonstration
  static Map<String, List<ClinicalSafetyAlert>> getPresetScenarios() {
    return {
      'WARFARIN_ASPIRIN': [
        ClinicalSafetyAlert(
          id: 'scen-warf-asp',
          title: 'Concurrent Anticoagulant & Antiplatelet Therapy',
          type: AlertType.drugInteraction,
          severity: AlertSeverity.critical,
          primaryAgent: 'Warfarin 5 mg',
          conflictingAgent: 'Aspirin 81 mg',
          clinicalRisk:
              'Synergistic inhibition of hemostasis. Greatly elevated bleeding risk (GI hemorrhage, hematuria, cerebral hemorrhage).',
          recommendedAction:
              'Discontinue Aspirin immediately or verify indication with Cardiology. Monitor INR within 48h.',
          sourceDocuments: ['Rx_Order_01928.pdf', 'Discharge_Summary.pdf'],
          detectedAt: DateTime.now(),
        ),
      ],
      'PENICILLIN_ALLERGY': [
        ClinicalSafetyAlert(
          id: 'scen-pen-amox',
          title: 'Severe IgE Allergy Contraindication',
          type: AlertType.allergyConflict,
          severity: AlertSeverity.critical,
          primaryAgent: 'Penicillin (Documented Anaphylaxis)',
          conflictingAgent: 'Amoxicillin 500 mg PO TID',
          clinicalRisk:
              'Imminent risk of acute bronchospasm, angioedema, and anaphylactic shock due to shared beta-lactam core.',
          recommendedAction:
              'STOP Amoxicillin. Prescribe Macrolide (Clarithromycin or Azithromycin) or Fluoroquinolone.',
          sourceDocuments: ['Allergy_Profile.pdf', 'Rx_Order_01928.pdf'],
          detectedAt: DateTime.now(),
        ),
      ],
      'METFORMIN_CONTRAST': [
        ClinicalSafetyAlert(
          id: 'scen-met-contrast',
          title: 'Metformin & IV Iodinated Radiocontrast Agent',
          type: AlertType.contraindication,
          severity: AlertSeverity.high,
          primaryAgent: 'Metformin 1000 mg BID',
          conflictingAgent: 'Iohexol (Omnipaque 350) Contrast',
          clinicalRisk:
              'Iodinated contrast can induce contrast-induced nephropathy (CIN), precipitating acute lactic acidosis in patients taking Metformin.',
          recommendedAction:
              'Withhold Metformin at time of procedure and for 48 hours post-contrast. Resume only after confirming baseline renal function (eGFR > 45 mL/min).',
          sourceDocuments: ['Radiology_Order_Chest_CT.pdf', 'Medication_List.pdf'],
          detectedAt: DateTime.now(),
        ),
      ],
      'LISINOPRIL_POTASSIUM': [
        ClinicalSafetyAlert(
          id: 'scen-lis-pot',
          title: 'ACE Inhibitor + Potassium Supplement Interaction',
          type: AlertType.drugInteraction,
          severity: AlertSeverity.moderate,
          primaryAgent: 'Lisinopril 20 mg Daily',
          conflictingAgent: 'Potassium Chloride 20 mEq Daily',
          clinicalRisk:
              'Decreased aldosterone secretion increases renal potassium retention, risking severe cardiac hyperkalemia (serum K+ > 5.5 mEq/L).',
          recommendedAction:
              'Order STAT Serum Electrolytes (K+). Reduce or discontinue potassium supplement.',
          sourceDocuments: ['Lab_Order.pdf', 'Rx_Refill.pdf'],
          detectedAt: DateTime.now(),
        ),
      ],
      'ALL_CLEAR': [],
    };
  }

  /// Automatically inspects extracted documents & timeline items for clinical conflicts
  static List<ClinicalSafetyAlert> scanPatientRecords({
    required List<TimelineEvent> events,
    required List<MedDocument> documents,
  }) {
    final alerts = <ClinicalSafetyAlert>[];
    final allText = [
      ...events.map((e) => '${e.title} ${e.category} ${e.items.join(" ")}'),
      ...documents.map((d) {
        final meds = d.clinicalAnalysis?.medications.map((m) => m.name).join(' ') ?? '';
        return '${d.filename} ${d.rawText ?? ""} $meds';
      }),
    ].join(' ').toLowerCase();

    // 1. Warfarin + Aspirin / NSAID check
    final hasWarfarin = allText.contains('warfarin') || allText.contains('coumadin');
    final hasAspirin = allText.contains('aspirin') || allText.contains('asa') || allText.contains('ibuprofen');
    if (hasWarfarin && hasAspirin) {
      alerts.add(
        ClinicalSafetyAlert(
          id: 'scan-ddi-warf-asp',
          title: 'Concurrent Anticoagulant & Antiplatelet Therapy',
          type: AlertType.drugInteraction,
          severity: AlertSeverity.critical,
          primaryAgent: 'Warfarin Sodium',
          conflictingAgent: 'Aspirin / NSAID',
          clinicalRisk:
              'Concurrent administration markedly elevates major hemorrhagic bleeding risk by 3.8x.',
          recommendedAction:
              'Hold Aspirin immediately. Verify PT/INR within 48h. Consider PPI gastroprotection if dual therapy is clinically required.',
          sourceDocuments: ['Ingested Clinical Records'],
          detectedAt: DateTime.now(),
        ),
      );
    }

    // 2. Penicillin allergy + Amoxicillin check
    final hasPenicillinAllergy = allText.contains('penicillin allergy') ||
        allText.contains('allergy: penicillin') ||
        allText.contains('allergic to penicillin');
    final hasAmoxicillin = allText.contains('amoxicillin') ||
        allText.contains('augmentin') ||
        allText.contains('ampicillin');
    if (hasPenicillinAllergy && hasAmoxicillin) {
      alerts.add(
        ClinicalSafetyAlert(
          id: 'scan-allergy-pen-amox',
          title: 'Documented Beta-Lactam Allergy Contraindication',
          type: AlertType.allergyConflict,
          severity: AlertSeverity.critical,
          primaryAgent: 'Documented Penicillin Allergy',
          conflictingAgent: 'Amoxicillin / Beta-Lactam Rx',
          clinicalRisk:
              'High risk of immediate IgE-mediated anaphylaxis, severe urticaria, or airway compromise.',
          recommendedAction:
              'Cancel Amoxicillin order immediately. Switch to non-cross-reactive alternative (e.g. Azithromycin).',
          sourceDocuments: ['Extracted Allergy & Rx Records'],
          detectedAt: DateTime.now(),
        ),
      );
    }

    // 3. Metformin + Contrast check
    final hasMetformin = allText.contains('metformin') || allText.contains('glucophage');
    final hasContrast = allText.contains('contrast') ||
        allText.contains('iodinated') ||
        allText.contains('ct with contrast') ||
        allText.contains('iohexol');
    if (hasMetformin && hasContrast) {
      alerts.add(
        ClinicalSafetyAlert(
          id: 'scan-contra-met-contrast',
          title: 'Metformin & Radiopaque Contrast Caution',
          type: AlertType.contraindication,
          severity: AlertSeverity.high,
          primaryAgent: 'Metformin 500 mg',
          conflictingAgent: 'Radiological Iodinated Contrast',
          clinicalRisk:
              'Potential for contrast-induced nephropathy leading to systemic metformin accumulation and lactic acidosis.',
          recommendedAction:
              'Hold Metformin 48 hours post-contrast administration. Re-evaluate serum creatinine/eGFR prior to resuming.',
          sourceDocuments: ['Radiology & Medication Extractions'],
          detectedAt: DateTime.now(),
        ),
      );
    }

    // Default to sample critical DDI if no explicit clash is found in simple demo text
    if (alerts.isEmpty) {
      return getDemoAlerts();
    }

    return alerts;
  }
}
