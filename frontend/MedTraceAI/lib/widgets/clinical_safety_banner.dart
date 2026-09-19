import 'package:flutter/material.dart';
import '../models/clinical_safety_alert.dart';
import '../services/clinical_safety_engine.dart';
import '../theme/app_colors.dart';

class ClinicalSafetyBanner extends StatefulWidget {
  final List<ClinicalSafetyAlert> alerts;
  final Function(ClinicalSafetyAlert alert)? onAcknowledge;
  final Function(String query)? onAskCopilot;
  final Function(List<ClinicalSafetyAlert> alerts)? onScenarioChanged;

  const ClinicalSafetyBanner({
    super.key,
    required this.alerts,
    this.onAcknowledge,
    this.onAskCopilot,
    this.onScenarioChanged,
  });

  @override
  State<ClinicalSafetyBanner> createState() => _ClinicalSafetyBannerState();
}

class _ClinicalSafetyBannerState extends State<ClinicalSafetyBanner> {
  bool _isExpanded = true;
  String _activeScenarioKey = 'WARFARIN_ASPIRIN';
  final Set<String> _dismissedAlertIds = {};

  List<ClinicalSafetyAlert> get _visibleAlerts {
    return widget.alerts.where((a) => !_dismissedAlertIds.contains(a.id)).toList();
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFF453A); // High-contrast clinical crimson
      case AlertSeverity.high:
        return const Color(0xFFFF9F0A); // Clinical amber
      case AlertSeverity.moderate:
        return const Color(0xFFE5C07B);
      case AlertSeverity.info:
        return Colors.white70;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.dangerous_rounded;
      case AlertSeverity.high:
        return Icons.warning_amber_rounded;
      case AlertSeverity.moderate:
        return Icons.info_outline_rounded;
      case AlertSeverity.info:
        return Icons.lightbulb_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = _visibleAlerts;

    if (visibleAlerts.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1410),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF30D158).withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF30D158), size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Clinical Safety Engine: 0 Active Drug Interactions or Allergy Conflicts Detected.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            _buildScenarioDropdown(),
          ],
        ),
      );
    }

    final topAlert = visibleAlerts.first;
    final alertColor = _getSeverityColor(topAlert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: alertColor.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: alertColor.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getSeverityIcon(topAlert.severity), size: 14, color: alertColor),
                        const SizedBox(width: 5),
                        Text(
                          topAlert.severityLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: alertColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      topAlert.typeLabel,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${topAlert.primaryAgent}  +  ${topAlert.conflictingAgent}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (visibleAlerts.length > 1)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${visibleAlerts.length - 1} More',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  _buildScenarioDropdown(),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Detail Card
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // Conflict agent tags
                  Row(
                    children: [
                      _buildAgentPill('Primary Agent', topAlert.primaryAgent, Colors.white),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                      ),
                      _buildAgentPill('Conflicting Agent', topAlert.conflictingAgent, alertColor),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Clinical Risk Rationale
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141418),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.biotech_rounded, size: 14, color: Colors.white70),
                            SizedBox(width: 6),
                            Text(
                              'CLINICAL MECHANISM & RISK PROFILE',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          topAlert.clinicalRisk,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Recommended Action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: alertColor.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.healing_rounded, size: 14, color: alertColor),
                            const SizedBox(width: 6),
                            Text(
                              'RECOMMENDED DOCTOR ACTION',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: alertColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          topAlert.recommendedAction,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (topAlert.sourceDocuments.isNotEmpty)
                        Expanded(
                          child: Text(
                            'Sources: ${topAlert.sourceDocuments.join(", ")}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (widget.onAskCopilot != null) {
                            widget.onAskCopilot!(
                              'Evaluate clinical safety conflict: ${topAlert.primaryAgent} with ${topAlert.conflictingAgent}. ${topAlert.clinicalRisk}',
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                        label: const Text('Consult MedBot', style: TextStyle(fontSize: 11.5, color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                          backgroundColor: const Color(0xFF141418),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _dismissedAlertIds.add(topAlert.id);
                          });
                          if (widget.onAcknowledge != null) {
                            widget.onAcknowledge!(topAlert);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Acknowledged safety alert for ${topAlert.primaryAgent}.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 14, color: Colors.black),
                        label: const Text('Acknowledge & Override', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgentPill(String role, String name, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accent),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioDropdown() {
    return PopupMenuButton<String>(
      tooltip: 'Simulate Clinical Safety Scenarios',
      initialValue: _activeScenarioKey,
      color: const Color(0xFF141418),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white24),
      ),
      onSelected: (key) {
        setState(() {
          _activeScenarioKey = key;
          _dismissedAlertIds.clear();
        });
        final scenarios = ClinicalSafetyEngine.getPresetScenarios();
        final selectedAlerts = scenarios[key] ?? [];
        if (widget.onScenarioChanged != null) {
          widget.onScenarioChanged!(selectedAlerts);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'SIMULATE SAFETY SCENARIOS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
          ),
        ),
        const PopupMenuItem(
          value: 'WARFARIN_ASPIRIN',
          child: Text('🔴 Warfarin + Aspirin (DDI Bleeding Risk)', style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'PENICILLIN_ALLERGY',
          child: Text('🔴 Penicillin Allergy + Amoxicillin (Anaphylaxis)', style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'METFORMIN_CONTRAST',
          child: Text('🟠 Metformin + Contrast (Lactic Acidosis)', style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'LISINOPRIL_POTASSIUM',
          child: Text('🟡 Lisinopril + Potassium (Hyperkalemia)', style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'ALL_CLEAR',
          child: Text('🟢 All Clear (0 Conflicts)', style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text('Simulate DDI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
