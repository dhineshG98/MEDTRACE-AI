import 'package:flutter/material.dart';

/// Processing lifecycle, mirroring the backend `status` field.
enum DocStatus { idle, uploading, uploaded, processing, extracted, completed, failed }

DocStatus docStatusFromString(String? value) {
  switch (value) {
    case 'uploaded':
      return DocStatus.uploaded;
    case 'processing':
      return DocStatus.processing;
    case 'extracted':
      return DocStatus.extracted;
    case 'completed':
      return DocStatus.completed;
    case 'failed':
      return DocStatus.failed;
    default:
      return DocStatus.idle;
  }
}

/// A document as returned by the backend.
///
/// [toCardMap] produces exactly the map shape the existing dashboard card in
/// `app_screen.dart` already reads, so the UI does not have to change.
class MedDocument {
  final String documentId;
  final String filename;
  final String fileType;
  final int fileSize;
  final DocStatus status;
  final String? documentType;
  final int? qualityScore;
  final String? extractionMethod;
  final int? pageCount;
  final int? wordCount;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? errorMessage;
  final String? rawText;
  final ClinicalAnalysis? clinicalAnalysis;

  const MedDocument({
    required this.documentId,
    required this.filename,
    required this.fileType,
    required this.fileSize,
    required this.status,
    required this.createdAt,
    this.documentType,
    this.qualityScore,
    this.extractionMethod,
    this.pageCount,
    this.wordCount,
    this.processedAt,
    this.errorMessage,
    this.rawText,
    this.clinicalAnalysis,
  });

  factory MedDocument.fromJson(Map<String, dynamic> json) {
    return MedDocument(
      documentId: json['document_id'] as String,
      filename: json['filename'] as String? ?? 'untitled',
      fileType: (json['file_type'] as String? ?? '').toUpperCase(),
      fileSize: json['file_size'] as int? ?? 0,
      status: docStatusFromString(json['status'] as String?),
      documentType: json['document_type'] as String?,
      qualityScore: json['quality_score'] as int?,
      extractionMethod: json['extraction_method'] as String?,
      pageCount: json['page_count'] as int?,
      wordCount: json['word_count'] as int?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      processedAt: DateTime.tryParse(json['processed_at'] as String? ?? '')?.toLocal(),
      errorMessage: json['error_message'] as String?,
      rawText: json['raw_text'] as String?,
      clinicalAnalysis: json['clinical_analysis'] != null
          ? ClinicalAnalysis.fromJson(json['clinical_analysis'] as Map<String, dynamic>)
          : json['entities'] != null
              ? ClinicalAnalysis.fromJson(json['entities'] as Map<String, dynamic>)
              : null,
    );
  }

  /// Accent colour per file type, matching FormatItem.supportedFormats.
  Color get accentColor {
    switch (fileType) {
      case 'PDF':
        return const Color(0xFFF43F5E);
      case 'DOCX':
        return const Color(0xFF2563EB);
      case 'PNG':
        return const Color(0xFF8B5CF6);
      case 'JPG':
      case 'JPEG':
        return const Color(0xFFA855F7);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String get sizeLabel {
    if (fileSize >= 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (fileSize >= 1024) return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    return '$fileSize B';
  }

  String get timeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  /// Human-readable status for the pill on the right of each card.
  String get statusLabel {
    switch (status) {
      case DocStatus.uploading:
        return 'Uploading';
      case DocStatus.uploaded:
        return 'Uploaded';
      case DocStatus.processing:
        return 'Processing';
      case DocStatus.extracted:
        return 'Extracted';
      case DocStatus.completed:
        return 'Analyzed';
      case DocStatus.failed:
        return 'Failed';
      case DocStatus.idle:
        return 'Pending';
    }
  }

  /// Subtext line. Reports only what the backend actually measured --
  /// no invented accuracy or compliance claims.
  String get metricsLabel {
    if (status == DocStatus.failed) {
      return errorMessage ?? 'Processing failed';
    }
    final parts = <String>[];
    if (pageCount != null) parts.add('$pageCount page${pageCount == 1 ? '' : 's'}');
    if (wordCount != null) parts.add('$wordCount words');
    if (extractionMethod != null) {
      parts.add(extractionMethod == 'pdf_text' ? 'Text layer' : 'OCR');
    }
    if (qualityScore != null) parts.add('Quality $qualityScore/100');
    return parts.isEmpty ? 'Awaiting processing' : parts.join(' • ');
  }

  /// Shape consumed by the existing `_documents` list in app_screen.dart.
  Map<String, dynamic> toCardMap() => {
        'id': documentId,
        'name': filename,
        'type': fileType,
        'color': accentColor,
        'size': sizeLabel,
        'time': timeLabel,
        'status': statusLabel,
        'metrics': metricsLabel,
      };
}

/// Result of the text-extraction call.
class ExtractionResult {
  final String documentId;
  final String text;
  final String extractionMethod;
  final int? pageCount;
  final int? ocrPages;
  final int charCount;
  final int wordCount;
  final List<String> warnings;

  const ExtractionResult({
    required this.documentId,
    required this.text,
    required this.extractionMethod,
    required this.charCount,
    required this.wordCount,
    this.pageCount,
    this.ocrPages,
    this.warnings = const [],
  });

  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    return ExtractionResult(
      documentId: json['document_id'] as String,
      text: json['text'] as String? ?? '',
      extractionMethod: json['extraction_method'] as String? ?? 'unknown',
      pageCount: json['page_count'] as int?,
      ocrPages: json['ocr_pages'] as int?,
      charCount: json['char_count'] as int? ?? 0,
      wordCount: json['word_count'] as int? ?? 0,
      warnings: (json['warnings'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class MedicationEntity {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? route;

  const MedicationEntity({
    required this.name,
    this.dosage,
    this.frequency,
    this.route,
  });

  factory MedicationEntity.fromJson(Map<String, dynamic> json) {
    return MedicationEntity(
      name: json['name'] as String? ?? 'Unknown Medication',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      route: json['route'] as String?,
    );
  }
}

class ClinicalAnalysis {
  final String documentType;
  final int qualityScore;
  final String summary;
  final List<String> diagnoses;
  final List<MedicationEntity> medications;
  final Map<String, String> vitalSigns;
  final List<String> criticalFlags;
  final Map<String, String?> patientInfo;

  const ClinicalAnalysis({
    required this.documentType,
    required this.qualityScore,
    required this.summary,
    this.diagnoses = const [],
    this.medications = const [],
    this.vitalSigns = const {},
    this.criticalFlags = const [],
    this.patientInfo = const {},
  });

  factory ClinicalAnalysis.fromJson(Map<String, dynamic> json) {
    return ClinicalAnalysis(
      documentType: json['document_type'] as String? ?? 'Unknown Medical Document',
      qualityScore: json['quality_score'] as int? ?? 50,
      summary: json['summary'] as String? ?? '',
      diagnoses: (json['diagnoses'] as List<dynamic>? ?? []).cast<String>(),
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((m) => MedicationEntity.fromJson(m as Map<String, dynamic>))
          .toList(),
      vitalSigns: (json['vital_signs'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
      criticalFlags: (json['critical_flags'] as List<dynamic>? ?? []).cast<String>(),
      patientInfo: (json['patient_info'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v?.toString())),
    );
  }
}

class TimelineEvent {
  final String id;
  final String date;
  final String rawDate;
  final String category;
  final String icon;
  final String title;
  final List<String> items;
  final String documentId;
  final String documentName;
  final String? summary;

  const TimelineEvent({
    required this.id,
    required this.date,
    required this.rawDate,
    required this.category,
    required this.icon,
    required this.title,
    this.items = const [],
    required this.documentId,
    required this.documentName,
    this.summary,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      rawDate: json['raw_date'] as String? ?? '',
      category: json['category'] as String? ?? 'CLINICAL_VISIT',
      icon: json['icon'] as String? ?? '🩺',
      title: json['title'] as String? ?? 'CLINICAL VISIT',
      items: (json['items'] as List<dynamic>? ?? []).cast<String>(),
      documentId: json['document_id'] as String? ?? '',
      documentName: json['document_name'] as String? ?? '',
      summary: json['summary'] as String?,
    );
  }
}

class PatientTimeline {
  final String patientName;
  final int totalEvents;
  final List<TimelineEvent> events;
  final String asciiTree;

  const PatientTimeline({
    required this.patientName,
    required this.totalEvents,
    required this.events,
    required this.asciiTree,
  });

  factory PatientTimeline.fromJson(Map<String, dynamic> json) {
    return PatientTimeline(
      patientName: json['patient_name'] as String? ?? 'Patient Record',
      totalEvents: json['total_events'] as int? ?? 0,
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      asciiTree: json['ascii_tree'] as String? ?? '',
    );
  }
}

class PatientInfoModel {
  final String? name;
  final String? ageOrDob;
  final String? gender;
  final String? mrn;
  final String? date;

  const PatientInfoModel({
    this.name,
    this.ageOrDob,
    this.gender,
    this.mrn,
    this.date,
  });

  factory PatientInfoModel.fromJson(Map<String, dynamic> json) {
    return PatientInfoModel(
      name: json['name'] as String?,
      ageOrDob: json['age_or_dob'] as String?,
      gender: json['gender'] as String?,
      mrn: json['mrn'] as String?,
      date: json['date'] as String?,
    );
  }
}

class ConditionItemModel {
  final String name;
  final String? icd10;
  final bool isNegated;
  final double confidence;
  final String tier;

  const ConditionItemModel({
    required this.name,
    this.icd10,
    this.isNegated = false,
    this.confidence = 0.90,
    this.tier = 'High',
  });

  factory ConditionItemModel.fromJson(Map<String, dynamic> json) {
    return ConditionItemModel(
      name: json['name'] as String? ?? 'Condition',
      icd10: json['icd10'] as String?,
      isNegated: json['is_negated'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
      tier: json['tier'] as String? ?? 'High',
    );
  }
}

class MedicationItemModel {
  final String name;
  final String? canonicalName;
  final String? dosage;
  final String? frequency;
  final String? route;
  final String? treats;
  final double confidence;
  final String tier;

  const MedicationItemModel({
    required this.name,
    this.canonicalName,
    this.dosage,
    this.frequency,
    this.route,
    this.treats,
    this.confidence = 0.90,
    this.tier = 'High',
  });

  factory MedicationItemModel.fromJson(Map<String, dynamic> json) {
    return MedicationItemModel(
      name: json['name'] as String? ?? 'Medication',
      canonicalName: json['canonical_name'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      route: json['route'] as String?,
      treats: json['treats'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
      tier: json['tier'] as String? ?? 'High',
    );
  }
}

class AllergyItemModel {
  final String name;
  final bool isNegated;
  final double confidence;
  final String tier;

  const AllergyItemModel({
    required this.name,
    this.isNegated = false,
    this.confidence = 0.90,
    this.tier = 'High',
  });

  factory AllergyItemModel.fromJson(Map<String, dynamic> json) {
    return AllergyItemModel(
      name: json['name'] as String? ?? 'Allergy',
      isNegated: json['is_negated'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
      tier: json['tier'] as String? ?? 'High',
    );
  }
}

class LabResultItemModel {
  final String testName;
  final String value;
  final String? unit;
  final String? referenceRange;
  final String? flag;
  final String? date;
  final double confidence;
  final String tier;

  const LabResultItemModel({
    required this.testName,
    required this.value,
    this.unit,
    this.referenceRange,
    this.flag,
    this.date,
    this.confidence = 0.90,
    this.tier = 'High',
  });

  factory LabResultItemModel.fromJson(Map<String, dynamic> json) {
    return LabResultItemModel(
      testName: json['test_name'] as String? ?? 'Lab Test',
      value: json['value']?.toString() ?? '',
      unit: json['unit'] as String?,
      referenceRange: json['reference_range'] as String?,
      flag: json['flag'] as String?,
      date: json['date'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
      tier: json['tier'] as String? ?? 'High',
    );
  }
}

class DateItemModel {
  final String date;
  final String type;

  const DateItemModel({
    required this.date,
    this.type = 'Encounter',
  });

  factory DateItemModel.fromJson(Map<String, dynamic> json) {
    return DateItemModel(
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'Encounter',
    );
  }
}

class StructuredExtraction {
  final String id;
  final String documentId;
  final String documentType;
  final double documentTypeConfidence;
  final PatientInfoModel patient;
  final List<ConditionItemModel> conditions;
  final List<MedicationItemModel> medications;
  final List<AllergyItemModel> allergies;
  final List<LabResultItemModel> labResults;
  final List<DateItemModel> dates;
  final List<String> doctors;
  final int qualityScore;
  final bool requiresReview;
  final List<String> reviewReasons;
  final String? summary;
  final String providerUsed;
  final DateTime createdAt;

  const StructuredExtraction({
    required this.id,
    required this.documentId,
    required this.documentType,
    required this.documentTypeConfidence,
    required this.patient,
    this.conditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.labResults = const [],
    this.dates = const [],
    this.doctors = const [],
    required this.qualityScore,
    this.requiresReview = false,
    this.reviewReasons = const [],
    this.summary,
    required this.providerUsed,
    required this.createdAt,
  });

  factory StructuredExtraction.fromJson(Map<String, dynamic> json) {
    return StructuredExtraction(
      id: json['id'] as String? ?? '',
      documentId: json['document_id'] as String? ?? '',
      documentType: json['document_type'] as String? ?? 'Clinical Medical Document',
      documentTypeConfidence: (json['document_type_confidence'] as num?)?.toDouble() ?? 0.90,
      patient: json['patient'] != null
          ? PatientInfoModel.fromJson(json['patient'] as Map<String, dynamic>)
          : const PatientInfoModel(),
      conditions: (json['conditions'] as List<dynamic>? ?? [])
          .map((c) => ConditionItemModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((m) => MedicationItemModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      allergies: (json['allergies'] as List<dynamic>? ?? [])
          .map((a) => AllergyItemModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      labResults: (json['lab_results'] as List<dynamic>? ?? [])
          .map((l) => LabResultItemModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      dates: (json['dates'] as List<dynamic>? ?? [])
          .map((d) => DateItemModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      doctors: (json['doctors'] as List<dynamic>? ?? []).cast<String>(),
      qualityScore: json['quality_score'] as int? ?? 50,
      requiresReview: json['requires_review'] as bool? ?? false,
      reviewReasons: (json['review_reasons'] as List<dynamic>? ?? []).cast<String>(),
      summary: json['summary'] as String?,
      providerUsed: json['provider_used'] as String? ?? 'heuristic',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
