class BiomarkerDataPoint {
  final DateTime date;
  final String formattedDate;
  final double value;
  final String milestone;
  final bool isTargetMet;

  const BiomarkerDataPoint({
    required this.date,
    required this.formattedDate,
    required this.value,
    required this.milestone,
    required this.isTargetMet,
  });
}

class BiomarkerSeries {
  final String id;
  final String metricName;
  final String unit;
  final String targetRangeLabel;
  final double targetThreshold;
  final bool lowerIsBetter;
  final List<BiomarkerDataPoint> points;

  const BiomarkerSeries({
    required this.id,
    required this.metricName,
    required this.unit,
    required this.targetRangeLabel,
    required this.targetThreshold,
    this.lowerIsBetter = true,
    required this.points,
  });

  double get initialValue => points.isNotEmpty ? points.first.value : 0.0;
  double get latestValue => points.isNotEmpty ? points.last.value : 0.0;

  double get deltaPercentage {
    if (initialValue == 0) return 0;
    return ((latestValue - initialValue) / initialValue) * 100.0;
  }

  bool get isImproved {
    if (lowerIsBetter) {
      return latestValue < initialValue;
    }
    return latestValue > initialValue;
  }

  bool get isLatestInTarget {
    if (lowerIsBetter) {
      return latestValue <= targetThreshold;
    }
    return latestValue >= targetThreshold;
  }

  static List<BiomarkerSeries> getDefaultSeries() {
    return [
      BiomarkerSeries(
        id: 'hba1c',
        metricName: 'HbA1c',
        unit: '%',
        targetRangeLabel: '< 7.0% (ADA Glycemic Goal)',
        targetThreshold: 7.0,
        lowerIsBetter: true,
        points: [
          BiomarkerDataPoint(
            date: DateTime(2025, 1, 10),
            formattedDate: '10 Jan',
            value: 8.4,
            milestone: 'Baseline Diagnostic (Uncontrolled T2D)',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 2, 15),
            formattedDate: '15 Feb',
            value: 7.6,
            milestone: 'Metformin 500mg Titration',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 3, 30),
            formattedDate: '30 Mar',
            value: 7.1,
            milestone: 'Dose Optimization to 1000mg BID',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 6, 15),
            formattedDate: '15 Jun',
            value: 6.5,
            milestone: 'Target Met (Therapeutic Control)',
            isTargetMet: true,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 8, 20),
            formattedDate: '20 Aug',
            value: 6.2,
            milestone: 'Longitudinal Safe Range Maintained',
            isTargetMet: true,
          ),
        ],
      ),
      BiomarkerSeries(
        id: 'glucose',
        metricName: 'Fasting Glucose',
        unit: 'mg/dL',
        targetRangeLabel: '< 100 mg/dL (Normal Fasting)',
        targetThreshold: 100.0,
        lowerIsBetter: true,
        points: [
          BiomarkerDataPoint(
            date: DateTime(2025, 1, 10),
            formattedDate: '10 Jan',
            value: 168.0,
            milestone: 'Initial Hyperglycemia on presentation',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 2, 15),
            formattedDate: '15 Feb',
            value: 142.0,
            milestone: 'Dietary counseling + pharmacotherapy',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 3, 30),
            formattedDate: '30 Mar',
            value: 126.0,
            milestone: 'Consistent morning fasting improvement',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 6, 15),
            formattedDate: '15 Jun',
            value: 108.0,
            milestone: 'Near-normal glycemic homeostasis',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 8, 20),
            formattedDate: '20 Aug',
            value: 96.0,
            milestone: 'Normoglycemic fasting state (<100)',
            isTargetMet: true,
          ),
        ],
      ),
      BiomarkerSeries(
        id: 'systolic_bp',
        metricName: 'Blood Pressure (Sys)',
        unit: 'mmHg',
        targetRangeLabel: '< 120 mmHg (Normotensive)',
        targetThreshold: 120.0,
        lowerIsBetter: true,
        points: [
          BiomarkerDataPoint(
            date: DateTime(2025, 1, 10),
            formattedDate: '10 Jan',
            value: 146.0,
            milestone: 'Stage 1 Hypertension on exam',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 2, 15),
            formattedDate: '15 Feb',
            value: 138.0,
            milestone: 'Lisinopril 10mg morning regimen',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 3, 30),
            formattedDate: '30 Mar',
            value: 128.0,
            milestone: 'Vascular resistance reduction',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 6, 15),
            formattedDate: '15 Jun',
            value: 122.0,
            milestone: 'Target range approximation',
            isTargetMet: false,
          ),
          BiomarkerDataPoint(
            date: DateTime(2025, 8, 20),
            formattedDate: '20 Aug',
            value: 118.0,
            milestone: 'Optimal normotensive control',
            isTargetMet: true,
          ),
        ],
      ),
    ];
  }
}
