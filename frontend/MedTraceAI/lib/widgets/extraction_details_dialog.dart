import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/med_document.dart';

class ExtractionDetailsDialog extends StatelessWidget {
  final StructuredExtraction extraction;
  final String filename;

  const ExtractionDetailsDialog({
    super.key,
    required this.extraction,
    required this.filename,
  });

  static Future<void> show(
    BuildContext context, {
    required StructuredExtraction extraction,
    required String filename,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => ExtractionDetailsDialog(
        extraction: extraction,
        filename: filename,
      ),
    );
  }

  // ─── Color Palette (Monochrome AI System) ─────────────────
  static const _bg = Color(0xFF0F1115);
  static const _card = Color(0xFF161920);
  static const _cardHover = Color(0xFF222630);
  static const _border = Color(0x2EFFFFFF);

  static const _cyan = Color(0xFFFFFFFF);
  static const _emerald = Color(0xFFE2E8F0);
  static const _purple = Color(0xFF94A3B8);
  static const _blue = Color(0xFFCBD5E1);
  static const _amber = Color(0xFFD4D4D8);
  static const _rose = Color(0xFFF43F5E);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFF9CA3AF);
  static const _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _cyan.withValues(alpha: 0.15)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
        child: Column(
          children: [
            _buildTitleBar(context),
            _buildQuickStats(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (extraction.requiresReview) ...[
                      _buildReviewBanner(),
                      const SizedBox(height: 20),
                    ],
                    _buildPatientCard(),
                    const SizedBox(height: 20),
                    _buildSectionGrid(),
                    const SizedBox(height: 20),
                    if (extraction.labResults.isNotEmpty) ...[
                      _buildLabResultsTable(),
                      const SizedBox(height: 20),
                    ],
                    if (extraction.doctors.isNotEmpty || extraction.dates.isNotEmpty) ...[
                      _buildMetadataRow(),
                      const SizedBox(height: 20),
                    ],
                    if (extraction.summary != null && extraction.summary!.isNotEmpty)
                      _buildSummaryCard(),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ─── Title Bar ────────────────────────────────────────────
  Widget _buildTitleBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6))),
        gradient: LinearGradient(
          colors: [
            _cyan.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _cyan.withValues(alpha: 0.2),
                  _purple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cyan.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.schema_rounded, color: _cyan, size: 22),
          ),
          const SizedBox(width: 14),
          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        filename,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildPill(
                      extraction.documentType,
                      _blue,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 12, color: _textMuted.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Engine: ${extraction.providerUsed.toUpperCase()}',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.gps_fixed_rounded, size: 12, color: _textMuted.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Confidence: ${(extraction.documentTypeConfidence * 100).toInt()}%',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildQualityGauge(extraction.qualityScore),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textSecondary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ─── Quick Stats Bar ──────────────────────────────────────
  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          _buildStatItem(Icons.medical_information_outlined, '${extraction.conditions.length}', 'Conditions', _purple),
          _buildStatDivider(),
          _buildStatItem(Icons.medication_outlined, '${extraction.medications.length}', 'Medications', _emerald),
          _buildStatDivider(),
          _buildStatItem(Icons.biotech_outlined, '${extraction.labResults.length}', 'Lab Results', _cyan),
          _buildStatDivider(),
          _buildStatItem(Icons.shield_outlined, '${extraction.allergies.length}', 'Allergies', _rose),
          if (extraction.dates.isNotEmpty) ...[
            _buildStatDivider(),
            _buildStatItem(Icons.event_outlined, '${extraction.dates.length}', 'Dates', _amber),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: _border.withValues(alpha: 0.5),
    );
  }

  // ─── Review Banner ────────────────────────────────────────
  Widget _buildReviewBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _rose.withValues(alpha: 0.08),
            _amber.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rose.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _rose.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manual Clinical Review Required',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                if (extraction.reviewReasons.isNotEmpty)
                  ...extraction.reviewReasons.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
                          Expanded(
                            child: Text(
                              r,
                              style: TextStyle(color: _textPrimary.withValues(alpha: 0.8), fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    'One or more critical fields fell below the confidence threshold (0.75).',
                    style: TextStyle(color: _textPrimary.withValues(alpha: 0.8), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Patient Card ─────────────────────────────────────────
  Widget _buildPatientCard() {
    final p = extraction.patient;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF60A5FA), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Patient Information',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (p.mrn != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _cardHover,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    'MRN: ${p.mrn}',
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildPatientField('Name', p.name ?? 'Unspecified'),
                if (p.ageOrDob != null)
                  _buildPatientField('DOB / Age', p.ageOrDob!),
                if (p.gender != null)
                  _buildPatientField('Gender', p.gender!),
                if (p.date != null)
                  _buildPatientField('Encounter', p.date!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientField(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _textMuted.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Conditions + Medications + Allergies Grid ────────────
  Widget _buildSectionGrid() {
    return Column(
      children: [
        // Conditions Section
        _buildSectionCard(
          icon: Icons.medical_information_outlined,
          title: 'Diagnoses & Conditions',
          color: _purple,
          count: extraction.conditions.length,
          child: extraction.conditions.isEmpty
              ? _buildEmptyState('No conditions identified')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: extraction.conditions.map((c) => _buildConditionChip(c)).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Medications Section
        _buildSectionCard(
          icon: Icons.medication_outlined,
          title: 'Medications & Treatments',
          color: _emerald,
          count: extraction.medications.length,
          child: extraction.medications.isEmpty
              ? _buildEmptyState('No medications prescribed')
              : Column(
                  children: extraction.medications.map((m) => _buildMedicationRow(m)).toList(),
                ),
        ),

        if (extraction.allergies.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.shield_outlined,
            title: 'Allergies & Adverse Reactions',
            color: _rose,
            count: extraction.allergies.length,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: extraction.allergies.map((a) => _buildAllergyChip(a)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required int count,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: _textMuted.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(message, style: TextStyle(color: _textMuted.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Condition Chip ───────────────────────────────────────
  Widget _buildConditionChip(ConditionItemModel cond) {
    final isNegated = cond.isNegated;
    final color = isNegated ? _rose : _purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNegated ? Icons.cancel_outlined : Icons.check_circle_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            cond.name,
            style: TextStyle(
              color: isNegated ? const Color(0xFFFCA5A5) : _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              decoration: isNegated ? TextDecoration.lineThrough : null,
              decorationColor: _rose.withValues(alpha: 0.5),
            ),
          ),
          if (cond.icd10 != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _textPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                cond.icd10!,
                style: TextStyle(
                  color: _textSecondary.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: (isNegated ? _rose : _emerald).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              isNegated ? 'NEGATED' : 'AFFIRMED',
              style: TextStyle(
                color: isNegated ? const Color(0xFFF87171) : const Color(0xFF34D399),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Medication Row ───────────────────────────────────────
  Widget _buildMedicationRow(MedicationItemModel med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.vaccines_rounded, color: Color(0xFF34D399), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        med.canonicalName ?? med.name,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (med.dosage != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: _cyan.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          med.dosage!,
                          style: const TextStyle(
                            color: _cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (med.frequency != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          med.frequency!,
                          style: TextStyle(color: _textSecondary.withValues(alpha: 0.8), fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
                // Treats relationship
                if (med.treats != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _amber.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_forward_rounded, color: _amber, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              'Treats: ',
                              style: TextStyle(color: _textMuted, fontSize: 11),
                            ),
                            Text(
                              med.treats!,
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildConfidenceBadge(med.confidence, med.tier),
        ],
      ),
    );
  }

  // ─── Allergy Chip ─────────────────────────────────────────
  Widget _buildAllergyChip(AllergyItemModel a) {
    final isNegated = a.isNegated;
    final color = isNegated ? _emerald : _rose;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNegated ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            a.name,
            style: TextStyle(
              color: isNegated ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lab Results Table ────────────────────────────────────
  Widget _buildLabResultsTable() {
    return _buildSectionCard(
      icon: Icons.biotech_outlined,
      title: 'Laboratory Investigations',
      color: _cyan,
      count: extraction.labResults.length,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: _bg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _cardHover.withValues(alpha: 0.7),
                  border: Border(bottom: BorderSide(color: _border)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text('Test', style: _tableHeaderStyle())),
                    Expanded(flex: 3, child: Text('Result', style: _tableHeaderStyle())),
                    Expanded(flex: 3, child: Text('Reference', style: _tableHeaderStyle())),
                    SizedBox(width: 70, child: Text('Status', style: _tableHeaderStyle(), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Table rows
              ...extraction.labResults.asMap().entries.map((entry) {
                final lab = entry.value;
                final isLast = entry.key == extraction.labResults.length - 1;
                final isHigh = lab.flag == 'High';
                final isLow = lab.flag == 'Low';
                final flagColor = isHigh ? _rose : isLow ? _amber : _emerald;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(bottom: BorderSide(color: _border.withValues(alpha: 0.4))),
                    color: (isHigh || isLow) ? flagColor.withValues(alpha: 0.03) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          lab.testName,
                          style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${lab.value} ${lab.unit ?? ''}'.trim(),
                          style: TextStyle(
                            color: (isHigh || isLow) ? flagColor : _textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          lab.referenceRange ?? '—',
                          style: TextStyle(color: _textMuted, fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: flagColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: flagColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              lab.flag ?? 'Normal',
                              style: TextStyle(
                                color: flagColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      color: _textMuted.withValues(alpha: 0.7),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
  }

  // ─── Metadata Row (Doctors + Dates) ───────────────────────
  Widget _buildMetadataRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (extraction.doctors.isNotEmpty)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.person_pin_circle_outlined, color: _cyan, size: 14),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Attending Clinicians',
                        style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...extraction.doctors.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: _cyan.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(doc, style: const TextStyle(color: _textPrimary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (extraction.doctors.isNotEmpty && extraction.dates.isNotEmpty)
          const SizedBox(width: 12),
        if (extraction.dates.isNotEmpty)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: _purple, size: 14),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Chronology',
                        style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...extraction.dates.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${d.date} (${d.type})',
                              style: const TextStyle(color: _textPrimary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Clinical Summary ─────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cyan.withValues(alpha: 0.05),
            _purple.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _cyan, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Clinical Summary',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            extraction.summary!,
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border.withValues(alpha: 0.6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user_rounded, color: _emerald, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clinical extraction complete',
                  style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Powered by ${extraction.providerUsed.toUpperCase()} • Quality ${extraction.qualityScore}/100',
                  style: TextStyle(color: _textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildFooterButton(
            icon: Icons.copy_rounded,
            label: 'Copy Summary',
            onTap: () {
              Clipboard.setData(ClipboardData(text: extraction.summary ?? filename));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Clinical summary copied to clipboard'),
                  backgroundColor: _card,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _cyan.withValues(alpha: 0.15),
              foregroundColor: _cyan,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: _cyan.withValues(alpha: 0.25)),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: _textSecondary),
      label: Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: _border),
        ),
      ),
    );
  }

  // ─── Shared Helpers ───────────────────────────────────────
  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQualityGauge(int score) {
    final color = score >= 80 ? _emerald : score >= 60 ? _amber : _rose;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 2.5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                'Quality',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double score, String tier) {
    final color = tier == 'High' ? _emerald : tier == 'Medium' ? _amber : _rose;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${(score * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            tier,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
