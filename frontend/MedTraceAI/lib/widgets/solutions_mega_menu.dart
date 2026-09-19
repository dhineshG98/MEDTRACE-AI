import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ClinicalSpecialtyOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int eventCount;
  final List<String> verifiedNegations;
  final List<MapEntry<String, String>> therapyLinks;
  final String safetyNote;

  const ClinicalSpecialtyOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.eventCount,
    required this.verifiedNegations,
    required this.therapyLinks,
    required this.safetyNote,
  });
}

class SolutionsMegaMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String activeSpecialty;
  final ValueChanged<String> onSelectSpecialty;

  const SolutionsMegaMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.activeSpecialty = 'ALL',
    required this.onSelectSpecialty,
  });

  @override
  State<SolutionsMegaMenu> createState() => _SolutionsMegaMenuState();
}

class _SolutionsMegaMenuState extends State<SolutionsMegaMenu>
    with SingleTickerProviderStateMixin {
  late String _hoveredSpecialty;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const List<ClinicalSpecialtyOption> specialties = [
    ClinicalSpecialtyOption(
      id: 'ALL',
      label: 'All Clinical Records',
      subtitle: 'Complete longitudinal patient journey',
      icon: Icons.all_inclusive_rounded,
      color: Colors.white,
      eventCount: 6,
      verifiedNegations: [
        'No acute cardiopulmonary disease',
        'Denies chest pain, orthopnea, or GI distress',
      ],
      therapyLinks: [
        MapEntry('Type 2 Diabetes Mellitus', 'Metformin 500 mg BID'),
        MapEntry('Essential Hypertension', 'Amlodipine 5 mg QD'),
      ],
      safetyNote: 'NKDA (No Known Drug Allergies) confirmed across all encounters.',
    ),
    ClinicalSpecialtyOption(
      id: 'CARDIOLOGY',
      label: 'Cardiology & Vitals',
      subtitle: 'Hypertension, vascular & telemetry records',
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFFE2E8F0),
      eventCount: 3,
      verifiedNegations: [
        'No acute cardiopulmonary disease',
        'Denies palpitations, dizziness, or chest tightness',
      ],
      therapyLinks: [
        MapEntry('Essential Hypertension', 'Amlodipine 5 mg QD'),
        MapEntry('Vascular Target BP', 'Controlled at 128/82 mmHg'),
      ],
      safetyNote: 'Blood pressure and resting heart rate normalized on dual therapy.',
    ),
    ClinicalSpecialtyOption(
      id: 'ENDOCRINOLOGY',
      label: 'Endocrinology & Diabetes',
      subtitle: 'Glycemic control, HbA1c & metabolic markers',
      icon: Icons.bloodtype_rounded,
      color: Color(0xFFCBD5E1),
      eventCount: 3,
      verifiedNegations: [
        'No diabetic ketoacidosis (DKA) indicators',
        'No hypoglycemic events reported by patient',
      ],
      therapyLinks: [
        MapEntry('Type 2 Diabetes Mellitus', 'Metformin 500 mg BID'),
        MapEntry('Glycemic Progression', 'HbA1c 8.4% → 7.6% (Normalized)'),
      ],
      safetyNote: 'Renal function intact (eGFR 78 mL/min). Metformin well tolerated.',
    ),
    ClinicalSpecialtyOption(
      id: 'LABORATORY',
      label: 'Laboratory & Diagnostics',
      subtitle: 'Metabolic profiles, lipid panels & blood work',
      icon: Icons.science_rounded,
      color: Color(0xFFFFFFFF),
      eventCount: 2,
      verifiedNegations: [
        'No microalbuminuria detected',
        'Serum electrolytes within reference limits',
      ],
      therapyLinks: [
        MapEntry('Fasting Glucose', '168 mg/dL → 142 mg/dL'),
        MapEntry('Lipid Evaluation', 'Total Cholesterol 218 mg/dL'),
      ],
      safetyNote: 'Serum creatinine 0.92 mg/dL confirms stable filtration clearance.',
    ),
    ClinicalSpecialtyOption(
      id: 'IMAGING',
      label: 'Radiology & Imaging',
      subtitle: 'Chest radiographs, scans & visual findings',
      icon: Icons.filter_center_focus_rounded,
      color: Color(0xFF94A3B8),
      eventCount: 1,
      verifiedNegations: [
        'No focal consolidation or infiltrates',
        'No pneumothorax or pleural effusion',
        'No acute abnormality detected',
      ],
      therapyLinks: [
        MapEntry('PA & Lateral Chest X-Ray', 'Normal cardiothoracic ratio'),
      ],
      safetyNote: 'Clear lung fields bilaterally. Visual inspection negative for acute findings.',
    ),
    ClinicalSpecialtyOption(
      id: 'PHARMACY',
      label: 'Pharmacotherapy & Rx',
      subtitle: 'Active prescriptions, dosages & refilling schedules',
      icon: Icons.medication_rounded,
      color: Color(0xFFE2E8F0),
      eventCount: 2,
      verifiedNegations: [
        'No adverse drug reactions (ADR) flagged',
        'No drug-drug contraindications detected',
      ],
      therapyLinks: [
        MapEntry('Metformin Hydrochloride', '500 mg Oral Tablet (Twice daily)'),
        MapEntry('Amlodipine Besylate', '5 mg Oral Tablet (Once daily)'),
      ],
      safetyNote: 'Medication adherence confirmed. Refill authorizations active.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _hoveredSpecialty = widget.activeSpecialty;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    if (widget.isOpen) _animController.forward();
  }

  @override
  void didUpdateWidget(covariant SolutionsMegaMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _hoveredSpecialty = widget.activeSpecialty;
      _animController.forward(from: 0.0);
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  ClinicalSpecialtyOption get _currentOption {
    return specialties.firstWhere(
      (s) => s.id == _hoveredSpecialty,
      orElse: () => specialties.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen && _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Clean dark backdrop overlay without blur filter
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ),

        // Centered / Anchored Lens Popover
        Positioned(
          top: 66,
          left: 0,
          right: 0,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: 820,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D11),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Top Header Bar
                        _buildHeader(),

                        // Body Matrix (Two Columns)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 410),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left Column: Specialty selector rail (330px)
                              SizedBox(
                                width: 330,
                                child: _buildSpecialtyRail(),
                              ),

                              // Vertical Divider
                              Container(
                                width: 1,
                                color: AppColors.borderSubtle,
                              ),

                              // Right Column: Active Clinical Intelligence (490px)
                              Expanded(
                                child: _buildIntelligencePanel(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Specialty Lenses & Intelligence',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Filter patient timeline and verify live negation & therapy alignment',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
            onPressed: widget.onClose,
            splashRadius: 18,
            tooltip: 'Close menu',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyRail() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      itemCount: specialties.length,
      itemBuilder: (context, index) {
        final spec = specialties[index];
        final isSelected = widget.activeSpecialty == spec.id;
        final isHovered = _hoveredSpecialty == spec.id;

        return InkWell(
          onTap: () {
            widget.onSelectSpecialty(spec.id);
            widget.onClose();
          },
          onHover: (hovering) {
            if (hovering) {
              setState(() => _hoveredSpecialty = spec.id);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.1)
                  : isHovered
                      ? const Color(0xFF1C1C22)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.35)
                    : isHovered
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    spec.icon,
                    size: 16,
                    color: isSelected ? const Color(0xFF090A0E) : Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${spec.eventCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntelligencePanel() {
    final spec = _currentOption;

    return Container(
      color: const Color(0xFF0D0D11),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of detail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(spec.icon, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    spec.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '${spec.eventCount} Matched Records',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Card 1: Verified Negation Shield
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'VERIFIED CLINICAL NEGATIONS (RULE-OUT SHIELD)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...spec.verifiedNegations.map((neg) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                      Expanded(
                        child: Text(
                          neg,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFE4E4E7)),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Card 2: Confirmed Therapy Links
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schema_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'CONFIRMED THERAPY & DIAGNOSTIC LINKS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...spec.therapyLinks.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_right_alt_rounded, size: 14, color: Color(0xFFA1A1AA)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFD4D4D8)),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const Spacer(),

          // Safety note and action button
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.safetyNote,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  widget.onSelectSpecialty(spec.id);
                  widget.onClose();
                },
                icon: const Icon(Icons.filter_list_rounded, size: 14),
                label: Text(
                  widget.activeSpecialty == spec.id ? 'Active Lens' : 'Apply Lens',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF090A0E),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
