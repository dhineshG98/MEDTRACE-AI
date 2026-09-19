import 'package:flutter/material.dart';

/// Interactive Lab Biomarker Trendline Graph.
/// Visualizes clinical recovery curves (e.g., Blood Glucose, HbA1c, eGFR)
/// over time with normal reference corridors and therapeutic milestones.
class LabTrendChart extends StatefulWidget {
  const LabTrendChart({super.key});

  @override
  State<LabTrendChart> createState() => _LabTrendChartState();
}

class _LabTrendChartState extends State<LabTrendChart> {
  int _selectedBiomarker = 0; // 0 = Fasting Glucose, 1 = HbA1c, 2 = eGFR

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Metric Selector Tabs
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.show_chart_rounded,
                    color: Color(0xFF38BDF8),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BIOMARKER LONGITUDINAL TRAJECTORY',
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Multi-point clinical laboratory recovery curve',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              // Switcher Chips
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMetricChip(0, 'Glucose (mg/dL)'),
                    _buildMetricChip(1, 'HbA1c (%)'),
                    _buildMetricChip(2, 'eGFR'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Active Biomarker Metric Card
          _buildActiveMetricView(),
        ],
      ),
    );
  }

  Widget _buildMetricChip(int index, String label) {
    final isSelected = _selectedBiomarker == index;
    return InkWell(
      onTap: () => setState(() => _selectedBiomarker = index),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F1117) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMetricView() {
    if (_selectedBiomarker == 0) {
      // Fasting Blood Glucose Trend
      return _buildGlucoseTrend();
    } else if (_selectedBiomarker == 1) {
      // HbA1c Trend
      return _buildHbA1cTrend();
    } else {
      // eGFR Renal Trend
      return _buildEgfrTrend();
    }
  }

  Widget _buildGlucoseTrend() {
    return Column(
      children: [
        // Summary row
        Row(
          children: [
            _buildStatBox(
              label: 'BASELINE (10 JAN)',
              value: '168 mg/dL',
              status: 'Markedly Elevated',
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(width: 12),
            _buildStatBox(
              label: 'POST-METFORMIN (15 JAN)',
              value: '145 mg/dL',
              status: '-23 mg/dL Reduction',
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 12),
            _buildStatBox(
              label: 'LATEST (24 FEB)',
              value: '118 mg/dL',
              status: 'TARGET NORMALIZED',
              color: const Color(0xFF10B981),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Visual Progress Corridors
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF191D2B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Target Glycemic Corridor: 70 – 130 mg/dL (Normal Fasting Window)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                  ),
                  Spacer(),
                  Text(
                    'Net Response: -50 mg/dL (-29.8%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented visual bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 65,
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                      Expanded(
                        flex: 20,
                        child: Container(color: const Color(0xFFF59E0B)),
                      ),
                      Expanded(
                        flex: 15,
                        child: Container(color: const Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('70 mg/dL (Lower Limit)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('118 mg/dL (Current)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  Text('130 mg/dL (Threshold)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('168 mg/dL (Peak)', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHbA1cTrend() {
    return Row(
      children: [
        _buildStatBox(
          label: 'INITIAL HbA1c (10 JAN)',
          value: '8.4%',
          status: 'Diagnostic of T2D (> 6.5%)',
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          label: 'PROJECTED 90-DAY HbA1c',
          value: '6.8%',
          status: 'Projected Target Window',
          color: const Color(0xFF38BDF8),
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          label: 'CLINICAL GOAL',
          value: '< 7.0%',
          status: 'ADA Standard of Care',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildEgfrTrend() {
    return Row(
      children: [
        _buildStatBox(
          label: 'SERUM CREATININE',
          value: '0.98 mg/dL',
          status: 'Normal Reference (0.6 - 1.1)',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          label: 'eGFR CLEARANCE',
          value: '78 mL/min/1.73m²',
          status: 'Mildly Decreased (Stage G2)',
          color: const Color(0xFF38BDF8),
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          label: 'METFORMIN ELIGIBILITY',
          value: 'APPROVED (> 45)',
          status: 'Zero Dose Reduction Required',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF191D2B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Helvetica',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
