import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/biomarker_trend.dart';
import '../theme/app_colors.dart';

class BiomarkerTrendChart extends StatefulWidget {
  final List<BiomarkerSeries>? seriesList;
  final VoidCallback? onExpandFullHistory;

  const BiomarkerTrendChart({
    super.key,
    this.seriesList,
    this.onExpandFullHistory,
  });

  @override
  State<BiomarkerTrendChart> createState() => _BiomarkerTrendChartState();
}

class _BiomarkerTrendChartState extends State<BiomarkerTrendChart> {
  late List<BiomarkerSeries> _allSeries;
  int _selectedSeriesIndex = 0;
  int? _hoveredPointIndex;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _allSeries = widget.seriesList ?? BiomarkerSeries.getDefaultSeries();
  }

  BiomarkerSeries get _currentSeries => _allSeries[_selectedSeriesIndex];

  @override
  Widget build(BuildContext context) {
    final series = _currentSeries;
    final delta = series.deltaPercentage;
    final isTargetMet = series.isLatestInTarget;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.show_chart_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'LONGITUDINAL BIOMARKER RECOVERY TRAJECTORY',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isTargetMet
                        ? const Color(0xFF30D158).withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isTargetMet
                          ? const Color(0xFF30D158).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTargetMet ? Icons.check_circle_rounded : Icons.trending_down_rounded,
                        size: 11,
                        color: isTargetMet ? const Color(0xFF30D158) : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTargetMet ? 'TARGET ACHIEVED' : 'THERAPEUTIC RECOVERY',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isTargetMet ? const Color(0xFF30D158) : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Metric Selector Pills
                Row(
                  children: List.generate(_allSeries.length, (idx) {
                    final item = _allSeries[idx];
                    final isSelected = idx == _selectedSeriesIndex;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSeriesIndex = idx;
                            _hoveredPointIndex = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF141418),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.metricName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                  tooltip: _isCollapsed ? 'Expand Trendline' : 'Collapse Trendline',
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          if (!_isCollapsed) ...[
            const Divider(color: Colors.white12, height: 1),

            // Metrics Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _buildMetricStat(
                    label: 'BASELINE',
                    value: '${series.initialValue} ${series.unit}',
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white38),
                  const SizedBox(width: 16),
                  _buildMetricStat(
                    label: 'CURRENT LEVEL',
                    value: '${series.latestValue} ${series.unit}',
                    color: isTargetMet ? const Color(0xFF30D158) : Colors.white,
                  ),
                  const SizedBox(width: 16),
                  _buildMetricStat(
                    label: 'OVERALL DELTA',
                    value: '${delta < 0 ? "" : "+"}${delta.toStringAsFixed(1)}%',
                    color: delta < 0 ? const Color(0xFF30D158) : const Color(0xFFFF9F0A),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF30D158).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF30D158).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF30D158),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Safe Target Zone: ${series.targetRangeLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF30D158),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chart Canvas
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                height: 170,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return MouseRegion(
                      onHover: (event) {
                        final width = constraints.maxWidth;
                        final pointsCount = series.points.length;
                        final stepX = width / (pointsCount - 1);
                        final hoverIndex = (event.localPosition.dx / stepX).round().clamp(0, pointsCount - 1);
                        if (_hoveredPointIndex != hoverIndex) {
                          setState(() => _hoveredPointIndex = hoverIndex);
                        }
                      },
                      onExit: (_) => setState(() => _hoveredPointIndex = null),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(constraints.maxWidth, 170),
                            painter: BiomarkerChartPainter(
                              series: series,
                              hoveredIndex: _hoveredPointIndex,
                            ),
                          ),
                          if (_hoveredPointIndex != null)
                            _buildHoverTooltip(
                              constraints.maxWidth,
                              series,
                              _hoveredPointIndex!,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Milestone History Chips Row
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: List.generate(series.points.length, (idx) {
                  final pt = series.points[idx];
                  final isHovered = _hoveredPointIndex == idx;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _hoveredPointIndex = idx),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        margin: EdgeInsets.only(right: idx < series.points.length - 1 ? 6 : 0),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFF141418),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isHovered
                                ? Colors.white
                                : (pt.isTargetMet
                                    ? const Color(0xFF30D158).withValues(alpha: 0.3)
                                    : Colors.white12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pt.formattedDate,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                                Text(
                                  '${pt.value}${series.unit}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: pt.isTargetMet ? const Color(0xFF30D158) : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pt.milestone,
                              style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.white54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildHoverTooltip(double chartWidth, BiomarkerSeries series, int index) {
    final pt = series.points[index];
    final stepX = chartWidth / (series.points.length - 1);
    final posX = index * stepX;
    final isRightSide = posX > chartWidth * 0.6;

    return Positioned(
      top: 10,
      left: isRightSide ? null : posX + 12,
      right: isRightSide ? (chartWidth - posX) + 12 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white38, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${pt.formattedDate} 2025 • ${pt.value} ${series.unit}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: pt.isTargetMet ? const Color(0xFF30D158) : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pt.milestone,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              pt.isTargetMet ? '✓ Within Safe Target Zone' : '⚠ Above Glycemic Target',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: pt.isTargetMet ? const Color(0xFF30D158) : const Color(0xFFFF9F0A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BiomarkerChartPainter extends CustomPainter {
  final BiomarkerSeries series;
  final int? hoveredIndex;

  BiomarkerChartPainter({
    required this.series,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = series.points;
    if (points.isEmpty) return;

    final values = points.map((p) => p.value).toList();
    final minValue = math.min(series.targetThreshold * 0.85, values.reduce(math.min) * 0.9);
    final maxValue = math.max(series.targetThreshold * 1.15, values.reduce(math.max) * 1.1);
    final range = maxValue - minValue;

    double getY(double val) {
      final ratio = (val - minValue) / range;
      return size.height - (ratio * (size.height - 30)) - 15;
    }

    final stepX = size.width / (points.length - 1);

    // 1. Draw Safe Target Range Band
    final targetY = getY(series.targetThreshold);
    final bottomY = size.height - 10;
    if (series.lowerIsBetter) {
      final targetRect = Rect.fromLTRB(0, targetY, size.width, bottomY);
      final targetBandPaint = Paint()
        ..color = const Color(0xFF30D158).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRect(targetRect, targetBandPaint);
    }

    // 2. Draw Target Guideline
    final targetLinePaint = Paint()
      ..color = const Color(0xFF30D158).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, targetY), Offset(size.width, targetY), targetLinePaint);

    // 3. Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 4; i++) {
      final gy = (size.height - 30) / 3 * i + 15;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    // 4. Smooth Bezier Curve
    final path = Path();
    final pointOffsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = getY(points[i].value);
      final offset = Offset(x, y);
      pointOffsets.add(offset);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prev = pointOffsets[i - 1];
        final controlX1 = prev.dx + (x - prev.dx) / 2;
        final controlY1 = prev.dy;
        final controlX2 = prev.dx + (x - prev.dx) / 2;
        final controlY2 = y;
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 5. Draw Data Points
    for (int i = 0; i < pointOffsets.length; i++) {
      final offset = pointOffsets[i];
      final isHovered = hoveredIndex == i;
      final isTarget = points[i].isTargetMet;

      final outerPaint = Paint()
        ..color = isHovered
            ? Colors.white
            : (isTarget ? const Color(0xFF30D158) : Colors.white)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, isHovered ? 6.0 : 4.0, outerPaint);

      final innerPaint = Paint()
        ..color = const Color(0xFF0D0D11)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, isHovered ? 3.0 : 2.0, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BiomarkerChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.hoveredIndex != hoveredIndex;
  }
}
