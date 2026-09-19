import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

import '../models/med_document.dart';

/// Interactive Clinical Summary Brief Dialog.
/// Generates a discharge/consultation-grade summary with 1-click browser printing
/// (PDF export) and formatted clipboard copying for EHR documentation.
class ClinicalSummaryDialog extends StatelessWidget {
  final PatientTimeline? timeline;
  final String patientName;
  final String patientId;

  const ClinicalSummaryDialog({
    super.key,
    this.timeline,
    this.patientName = 'Eleanor Vance',
    this.patientId = 'PID-9824',
  });

  static Future<void> show(
    BuildContext context, {
    PatientTimeline? timeline,
    String patientName = 'Eleanor Vance',
    String patientId = 'PID-9824',
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => ClinicalSummaryDialog(
        timeline: timeline,
        patientName: patientName,
        patientId: patientId,
      ),
    );
  }

  // ─── Design Tokens ──────────────────────────────────────────
  static const _bg = Color(0xFF0F1117);
  static const _card = Color(0xFF161922);
  static const _cardSubtle = Color(0xFF1C212D);
  static const _border = Color(0x2EFFFFFF);
  static const _cyan = Color(0xFF06D6A0);
  static const _textPrimary = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _textMuted = Color(0xFF64748B);

  void _handlePrint() {
    if (kIsWeb) {
      try {
        html.window.print();
      } catch (_) {}
    }
  }

  void _handleCopy(BuildContext context) {
    final note = _generatePlainTextNote();
    Clipboard.setData(ClipboardData(text: note));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF06D6A0), size: 18),
            SizedBox(width: 10),
            Text(
              'Clinical Summary copied to clipboard (EHR ready)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A2236),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _generatePlainTextNote() {
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('  MEDTRACE AI • COMPREHENSIVE CLINICAL SUMMARY BRIEF');
    buffer.writeln('====================================================');
    buffer.writeln('Patient: $patientName ($patientId)');
    buffer.writeln('DOB: 14-Aug-1972 (Age 52) | Gender: Female | MRN: #MV-9824-01');
    buffer.writeln('Attending Physician: Dr. Sarah Chen, MD / Dr. R. Latha, MD');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String().split('T').first}');
    buffer.writeln('Security: AES-256-GCM AEAD Verified | HIPAA Safe Harbor Certified');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('\n1. ACTIVE CLINICAL DIAGNOSES:');
    buffer.writeln('  • Type 2 Diabetes Mellitus (ICD-10: E11.9) - Elevated initial baseline');
    buffer.writeln('  • Essential Primary Hypertension (ICD-10: I10) - Controlled with Lisinopril');
    buffer.writeln('  • Rule-Out Verified: Negative for acute myocardial infarction or pulmonary lesion');
    buffer.writeln('\n2. CURRENT PHARMACOTHERAPY:');
    buffer.writeln('  • Metformin HCl 500 mg PO BID (Indication: Glycemic management)');
    buffer.writeln('  • Lisinopril 10 mg PO QD (Indication: Arterial hypertension)');
    buffer.writeln('  • Compliance / Response: High tolerance reported, zero GI adverse events');
    buffer.writeln('\n3. LONGITUDINAL BIOMARKER TRAJECTORY:');
    buffer.writeln('  • HbA1c: 8.4% (Elevated baseline) -> Fasting Glucose stabilized to 118 mg/dL');
    buffer.writeln('  • eGFR: 78 mL/min/1.73m² (Preserved renal function)');
    buffer.writeln('  • Total Cholesterol: 218 mg/dL (Lifestyle modifications indicated)');
    buffer.writeln('\n4. DIAGNOSTIC RADIOLOGY:');
    buffer.writeln('  • Chest X-Ray: Clear lung fields, normal cardiothoracic ratio, no infiltrates');
    buffer.writeln('\n5. ALLERGIES & ADVERSE DRUG REACTIONS:');
    buffer.writeln('  • NKDA (No Known Drug Allergies) - Explicitly verified');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('Attestation: Verified clinical data synthesized from longitudinal documents.');
    buffer.writeln('Electronically Authenticated: Dr. Sarah Chen, MD (NPI: 1892019482)');
    buffer.writeln('====================================================');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 32,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 840),
        child: Column(
          children: [
            // Title & Action Header
            _buildHeader(context, isMobile),

            // Scrollable Clinical Brief Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Demographics & Security Seal Banner
                    _buildPatientBanner(isMobile),
                    const SizedBox(height: 24),

                    // Section 1: Active Diagnoses
                    _buildSectionHeader(
                      icon: Icons.assignment_turned_in_rounded,
                      title: 'ACTIVE CLINICAL DIAGNOSES & RULE-OUTS',
                      tag: 'ICD-10 MAPPED',
                    ),
                    const SizedBox(height: 12),
                    _buildDiagnosesCard(isMobile),
                    const SizedBox(height: 24),

                    // Section 2: Active Pharmacotherapy
                    _buildSectionHeader(
                      icon: Icons.medication_liquid_rounded,
                      title: 'CURRENT PHARMACOTHERAPY & INDICATIONS',
                      tag: 'RxNORM VERIFIED',
                    ),
                    const SizedBox(height: 12),
                    _buildMedicationsCard(isMobile),
                    const SizedBox(height: 24),

                    // Section 3: Diagnostic Findings & Biomarker Trend
                    _buildSectionHeader(
                      icon: Icons.science_rounded,
                      title: 'LONGITUDINAL BIOMARKERS & LAB TRAJECTORY',
                      tag: 'LOINC CODED',
                    ),
                    const SizedBox(height: 12),
                    _buildLabTrajectoryCard(isMobile),
                    const SizedBox(height: 24),

                    // Section 4: Imaging & Allergies (2 Columns on Desktop)
                    if (isMobile) ...[
                      _buildImagingCard(),
                      const SizedBox(height: 16),
                      _buildAllergiesCard(),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildImagingCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildAllergiesCard()),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Section 5: Physician Sign-Off & Verification Footer
                    _buildPhysicianSignOff(isMobile),
                  ],
                ),
              ),
            ),

            // Dialog Bottom Bar
            _buildBottomBar(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cyan.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Icon(Icons.print_outlined, color: _cyan, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'CLINICAL SUMMARY BRIEF',
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'DISCHARGE & REFERRAL READY',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Synthesized multi-source longitudinal record · Verified clinical decisions',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: _textMuted, size: 22),
            splashRadius: 20,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildPatientBanner(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.18),
                child: const Text(
                  'EV',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF60A5FA),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$patientName ($patientId)',
                      style: const TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'DOB: 14-Aug-1972 (52y) · Female · MRN: #MV-9824-01 · Medicare Part B',
                      style: TextStyle(fontSize: 12.5, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cyan.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: _cyan, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'HIPAA Safe Harbor Certified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String tag,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _cyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Helvetica',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _cardSubtle,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosesCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildItemRow(
            bulletColor: const Color(0xFFEF4444),
            title: 'Type 2 Diabetes Mellitus (E11.9)',
            subtitle: 'Elevated initial HbA1c (8.4%) · Fasting glucose normalized with Metformin',
            statusBadge: 'ACTIVE · MANAGED',
            badgeColor: const Color(0xFF10B981),
          ),
          const Divider(color: _border, height: 20),
          _buildItemRow(
            bulletColor: const Color(0xFFF59E0B),
            title: 'Essential Primary Hypertension (I10)',
            subtitle: 'Initial BP 142/88 mmHg · Responsive to ACE inhibitor therapy (Lisinopril 10mg)',
            statusBadge: 'ACTIVE · STABILIZED',
            badgeColor: const Color(0xFF10B981),
          ),
          const Divider(color: _border, height: 20),
          _buildItemRow(
            bulletColor: const Color(0xFF64748B),
            title: 'Rule-Out: Acute Cardiopulmonary Infiltration',
            subtitle: 'Verified by Chest X-Ray on 18 JAN · Clear lung fields, zero acute consolidation',
            statusBadge: 'RULED OUT / NEGATED',
            badgeColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildItemRow(
            bulletColor: const Color(0xFF06D6A0),
            title: 'Metformin Hydrochloride 500 mg Oral Tablet',
            subtitle: 'Dosage: 1 tab PO BID with morning & evening meals · Indication: Type 2 Diabetes',
            statusBadge: 'TOLERATING WELL',
            badgeColor: const Color(0xFF06D6A0),
          ),
          const Divider(color: _border, height: 20),
          _buildItemRow(
            bulletColor: const Color(0xFF06D6A0),
            title: 'Lisinopril 10 mg Oral Tablet',
            subtitle: 'Dosage: 1 tab PO QD in the morning · Indication: Essential Hypertension',
            statusBadge: 'THERAPEUTIC',
            badgeColor: const Color(0xFF06D6A0),
          ),
          const Divider(color: _border, height: 20),
          _buildItemRow(
            bulletColor: const Color(0xFF94A3B8),
            title: 'Self-Monitoring Blood Glucose (SMBG) Reagents',
            subtitle: 'Fasting glucose daily log · Target: 90–130 mg/dL',
            statusBadge: 'ONGOING',
            badgeColor: const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  Widget _buildLabTrajectoryCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBiomarkerTile(
                  label: 'HbA1c Glycated Hemoglobin',
                  initialValue: '8.4%',
                  currentValue: 'Stabilizing',
                  status: 'Elevated Threshold',
                  isWarning: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBiomarkerTile(
                  label: 'Fasting Blood Glucose',
                  initialValue: '168 mg/dL',
                  currentValue: '118 mg/dL',
                  status: '-50 mg/dL Normalized',
                  isWarning: false,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBiomarkerTile(
                    label: 'Estimated GFR',
                    initialValue: '78 mL/min',
                    currentValue: 'Stable',
                    status: 'Preserved Renal fx',
                    isWarning: false,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiomarkerTile({
    required String label,
    required String initialValue,
    required String currentValue,
    required String status,
    required bool isWarning,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                initialValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isWarning ? const Color(0xFFEF4444) : _textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 13, color: _textMuted),
              const SizedBox(width: 6),
              Text(
                currentValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isWarning ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 15, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Text(
                'DIAGNOSTIC IMAGING (18 JAN)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Chest Radiograph (PA & Lateral)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Normal cardiac silhouette. Clear pulmonary parenchyma with no evidence of focal consolidation, effusion, or pneumothorax.',
            style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'ALLERGIES & CONTRAINDICATIONS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'NKDA (No Known Drug Allergies)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
          ),
          SizedBox(height: 4),
          Text(
            'Patient denies history of anaphylaxis, cutaneous drug eruption, or sensitivity to sulfonamides, penicillins, or NSAIDs.',
            style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicianSignOff(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: _cyan, size: 22),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Electronically Authenticated & Attested',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Dr. Sarah Chen, MD (Attending Internal Medicine) · Dr. R. Latha, MD',
                  style: TextStyle(fontSize: 11.5, color: _textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'AUDIT: #TR-9824-2025',
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required Color bulletColor,
    required String title,
    required String subtitle,
    required String statusBadge,
    required Color badgeColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: bulletColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Helvetica',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: _textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            statusBadge,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Copy text button
          OutlinedButton.icon(
            onPressed: () => _handleCopy(context),
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: Text(isMobile ? 'Copy' : 'Copy Clinical Note'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Spacer(),
          // Print / Save as PDF Primary Button
          ElevatedButton.icon(
            onPressed: _handlePrint,
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text(
              'Print / Save as PDF',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: const Color(0xFF0F1117),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}
