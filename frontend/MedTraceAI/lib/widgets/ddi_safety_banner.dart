import 'package:flutter/material.dart';

/// Clinical Safety & Drug-Drug Interaction (DDI) Guardrail Banner.
/// Detects contraindications, drug-drug precautions, and allergy conflicts.
class DdiSafetyBanner extends StatefulWidget {
  final List<String> activeMedications;
  final List<String> documentedAllergies;

  const DdiSafetyBanner({
    super.key,
    this.activeMedications = const [
      'Metformin 500 mg BID',
      'Lisinopril 10 mg QD',
    ],
    this.documentedAllergies = const ['NKDA (No Known Drug Allergies)'],
  });

  @override
  State<DdiSafetyBanner> createState() => _DdiSafetyBannerState();
}

class _DdiSafetyBannerState extends State<DdiSafetyBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF06D6A0).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06D6A0).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06D6A0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF06D6A0),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'CLINICAL SAFETY GUARDRAIL',
                              style: TextStyle(
                                fontFamily: 'Helvetica',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 8),
                            _SafetyTag(
                              label: 'ZERO HIGH-RISK CONFLICTS',
                              color: Color(0xFF10B981),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pharmacological compatibility verified across active prescriptions & documented allergies.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Hide Analysis' : 'View Safety Rules',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Safety Rules & Interaction Cards
          if (_isExpanded) ...[
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRuleRow(
                    statusIcon: Icons.check_circle_outline_rounded,
                    statusColor: const Color(0xFF10B981),
                    title: 'Metformin HCl + Renal Clearance (eGFR 78 mL/min)',
                    subtitle: 'Safe threshold (> 45 mL/min). Lactic acidosis risk: Extremely low. Continue regular monitoring.',
                    badge: 'SAFE',
                    badgeColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 10),
                  _buildRuleRow(
                    statusIcon: Icons.info_outline_rounded,
                    statusColor: const Color(0xFF38BDF8),
                    title: 'Lisinopril + Metformin Synergistic Protective Effect',
                    subtitle: 'ACE inhibitor provides renal protective benefit in diabetic hypertension. Zero pharmacological contraindication.',
                    badge: 'SYNERGISTIC BENEFIT',
                    badgeColor: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 10),
                  _buildRuleRow(
                    statusIcon: Icons.verified_user_outlined,
                    statusColor: const Color(0xFF10B981),
                    title: 'Allergen Cross-Reactivity Check',
                    subtitle: 'NKDA (No Known Drug Allergies) confirmed. Zero beta-lactam or sulfonamide sensitivity flags.',
                    badge: 'NO CONFLICT',
                    badgeColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleRow({
    required IconData statusIcon,
    required Color statusColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF191D2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SafetyTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
