enum AlertSeverity {
  critical,
  high,
  moderate,
  info,
}

enum AlertType {
  drugInteraction,
  allergyConflict,
  contraindication,
  doseWarning,
}

class ClinicalSafetyAlert {
  final String id;
  final String title;
  final AlertType type;
  final AlertSeverity severity;
  final String primaryAgent;
  final String conflictingAgent;
  final String clinicalRisk;
  final String recommendedAction;
  final List<String> sourceDocuments;
  final DateTime detectedAt;
  final bool isAcknowledged;

  const ClinicalSafetyAlert({
    required this.id,
    required this.title,
    required this.type,
    required this.severity,
    required this.primaryAgent,
    required this.conflictingAgent,
    required this.clinicalRisk,
    required this.recommendedAction,
    this.sourceDocuments = const [],
    required this.detectedAt,
    this.isAcknowledged = false,
  });

  ClinicalSafetyAlert copyWith({
    String? id,
    String? title,
    AlertType? type,
    AlertSeverity? severity,
    String? primaryAgent,
    String? conflictingAgent,
    String? clinicalRisk,
    String? recommendedAction,
    List<String>? sourceDocuments,
    DateTime? detectedAt,
    bool? isAcknowledged,
  }) {
    return ClinicalSafetyAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      primaryAgent: primaryAgent ?? this.primaryAgent,
      conflictingAgent: conflictingAgent ?? this.conflictingAgent,
      clinicalRisk: clinicalRisk ?? this.clinicalRisk,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      sourceDocuments: sourceDocuments ?? this.sourceDocuments,
      detectedAt: detectedAt ?? this.detectedAt,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.critical:
        return 'CRITICAL SAFETY ALERT';
      case AlertSeverity.high:
        return 'HIGH RISK CONFLICT';
      case AlertSeverity.moderate:
        return 'MODERATE INTERACTION';
      case AlertSeverity.info:
        return 'CLINICAL ADVISORY';
    }
  }

  String get typeLabel {
    switch (type) {
      case AlertType.drugInteraction:
        return 'DRUG-DRUG INTERACTION';
      case AlertType.allergyConflict:
        return 'ALLERGY CONTRAINDICATION';
      case AlertType.contraindication:
        return 'CLINICAL CONTRAINDICATION';
      case AlertType.doseWarning:
        return 'DOSING WARNING';
    }
  }
}
