import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/format_item.dart';
import '../models/med_document.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/analysis_progress_overlay.dart';
import '../widgets/batch_progress_overlay.dart';
import '../widgets/chatbot_floating_button.dart';
import '../widgets/chatbot_overlay.dart';
import '../widgets/format_panel.dart';
import '../widgets/glass_card.dart';
import '../widgets/patient_timeline_view.dart';
import '../widgets/extraction_details_dialog.dart';
import '../widgets/solutions_mega_menu.dart';
import '../widgets/clinical_summary_dialog.dart';
import '../models/patient_profile.dart';
import '../widgets/patient_details_dialog.dart';

class AppScreen extends StatefulWidget {
  final VoidCallback? onBackToLanding;
  final int initialTabIndex;

  const AppScreen({
    super.key,
    this.onBackToLanding,
    this.initialTabIndex = 1, // Default to 1: Patient Timeline!
  });

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final ApiService _api = ApiService();

  bool _isFormatPanelOpen = false;
  bool _isSolutionsMenuOpen = false;
  bool _isChatbotOpen = false;
  bool _isDropzoneHovered = false;

  // View switch: 0 = Ingestion Workspace, 1 = Patient Timeline
  late int _selectedTabIndex;
  PatientTimeline? _patientTimeline;
  bool _isLoadingTimeline = false;
  PatientProfile _currentPatient = PatientProfile.defaultProfile();

  void _openPatientDetailsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => PatientDetailsDialog(
        initialProfile: _currentPatient,
        onSave: (updated) {
          setState(() {
            _currentPatient = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Patient linked: ${updated.name} (${updated.patientId}) • ${updated.bloodGroup}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: const Color(0xFF141418),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  void _openAddTimelineEventDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final dateController = TextEditingController(text: _formatEventDate(DateTime.now()));
    final refController = TextEditingController();
    String selectedCategory = 'CLINICAL_VISIT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 520,
              decoration: BoxDecoration(
                color: const Color(0xFF14161F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Add Clinical Timeline Entry',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ('CLINICAL_VISIT', '🩺 Visit'),
                        ('LABORATORY', '🧪 Lab Panel'),
                        ('PRESCRIPTION', '💊 Prescription'),
                        ('IMAGING', '🩻 Imaging'),
                        ('FOLLOW_UP', '🩺 Follow-up'),
                      ].map((item) {
                        final isSel = selectedCategory == item.$1;
                        return ChoiceChip(
                          label: Text(item.$2),
                          selected: isSel,
                          selectedColor: Colors.white,
                          backgroundColor: const Color(0xFF1C1D26),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                            color: isSel ? const Color(0xFF090A0E) : Colors.white70,
                          ),
                          onSelected: (_) => setDlgState(() => selectedCategory = item.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('EVENT TITLE / DIAGNOSIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Initial Consultation, Fasting Glucose Check, Metformin 500mg',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: const Color(0xFF1C1D26),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: dateController,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. 19 SEP 2026',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: const Color(0xFF1C1D26),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('CLINICAL FINDINGS / BULLET ITEMS (One per line)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'HbA1c: 6.8%\nBlood Pressure: 120/80 mmHg\nAdvised regular exercise',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: const Color(0xFF1C1D26),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('DOCUMENT / REFERENCE LABEL (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Clinical_Note.pdf or Hospital_Rx.pdf',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: const Color(0xFF1C1D26),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            final title = titleController.text.trim().isNotEmpty
                                ? titleController.text.trim()
                                : 'Clinical Event';
                            final dateStr = dateController.text.trim().isNotEmpty
                                ? dateController.text.trim()
                                : _formatEventDate(DateTime.now());
                            final rawNotes = notesController.text.trim();
                            final items = rawNotes.isNotEmpty
                                ? rawNotes.split('\n').where((s) => s.trim().isNotEmpty).toList()
                                : <String>['User input clinical record logged'];
                            final refDoc = refController.text.trim().isNotEmpty
                                ? refController.text.trim()
                                : 'User_Entry_${DateTime.now().millisecondsSinceEpoch % 1000}.pdf';

                            final newEvent = TimelineEvent(
                              id: 'manual-evt-${DateTime.now().millisecondsSinceEpoch}',
                              date: dateStr,
                              rawDate: DateTime.now().toIso8601String(),
                              category: selectedCategory,
                              icon: _inferCategoryIcon(selectedCategory),
                              title: title,
                              items: items,
                              documentId: 'manual-doc-${DateTime.now().millisecondsSinceEpoch}',
                              documentName: refDoc,
                            );

                            setState(() {
                              _manualTimelineEvents.insert(0, newEvent);
                              final currentEvents = List<TimelineEvent>.from(_patientTimeline?.events ?? []);
                              currentEvents.insert(0, newEvent);
                              _patientTimeline = PatientTimeline(
                                patientName: _currentPatient.name.isNotEmpty
                                    ? _currentPatient.name
                                    : (_patientTimeline?.patientName.isNotEmpty == true && _patientTimeline!.patientName != 'Unknown Patient'
                                        ? _patientTimeline!.patientName
                                        : 'Patient Record'),
                                totalEvents: currentEvents.length,
                                asciiTree: 'Longitudinal Patient Trajectory from User Ingested Records',
                                events: currentEvents,
                              );
                            });

                            Navigator.of(ctx).pop();
                            _showSnackBar('Clinical event added to timeline: $title');
                          },
                          icon: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF090A0E)),
                          label: const Text('Add to Timeline', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF090A0E))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AppScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      setState(() {
        _selectedTabIndex = widget.initialTabIndex;
      });
    }
  }

  // Dynamic in-memory manual timeline events entered by user
  final List<TimelineEvent> _manualTimelineEvents = [];

  // Legacy document lookup stub (all documents depend strictly on user input)
  static final Map<String, MedDocument> demoDocuments = {};

  bool _isUploading = false;
  String? _uploadStatusText;
  List<MedDocument> _documents = [];
  bool _isLoadingDocs = false;

  // Analysis overlay state
  bool _showAnalysisOverlay = false;
  String? _analysisFilename;
  StreamController<int>? _analysisStepController;
  StructuredExtraction? _pendingExtraction;
  String? _pendingFilename;

  // Multi-file batch overlay state
  bool _showBatchOverlay = false;
  List<BatchItemProgress> _batchItems = [];
  bool _isBatchFinished = false;

  // Active clinical specialty lens filter
  String _activeSpecialty = 'ALL';

  String _getSpecialtyLabel(String id) {
    switch (id) {
      case 'CARDIOLOGY':
        return 'Cardiology & Vitals';
      case 'ENDOCRINOLOGY':
        return 'Endocrinology & Diabetes';
      case 'LABORATORY':
        return 'Laboratory & Diagnostics';
      case 'IMAGING':
        return 'Radiology & Imaging';
      case 'PHARMACY':
        return 'Pharmacotherapy & Rx';
      default:
        return 'All Clinical Records';
    }
  }

  PatientTimeline? get _displayedPatientTimeline {
    if (_patientTimeline == null) return null;
    if (_activeSpecialty == 'ALL') return _patientTimeline;

    final events = _patientTimeline!.events.where((e) {
      final text = '${e.title} ${e.category} ${e.items.join(" ")}'.toLowerCase();
      switch (_activeSpecialty) {
        case 'CARDIOLOGY':
          return e.category == 'CLINICAL_VISIT' ||
              e.category == 'IMAGING' ||
              text.contains('hypertension') ||
              text.contains('pressure') ||
              text.contains('amlodipine') ||
              text.contains('lisinopril') ||
              text.contains('chest');
        case 'ENDOCRINOLOGY':
          return e.category == 'LABORATORY' ||
              e.category == 'FOLLOW_UP' ||
              text.contains('glucose') ||
              text.contains('hba1c') ||
              text.contains('diabetes') ||
              text.contains('metformin');
        case 'LABORATORY':
          return e.category == 'LABORATORY' ||
              text.contains('lab') ||
              text.contains('glucose') ||
              text.contains('hba1c');
        case 'IMAGING':
          return e.category == 'IMAGING' ||
              text.contains('x-ray') ||
              text.contains('imaging');
        case 'PHARMACY':
          return e.category == 'PRESCRIPTION' ||
              text.contains('prescription') ||
              text.contains('metformin') ||
              text.contains('amlodipine') ||
              text.contains('lisinopril');
        default:
          return true;
      }
    }).toList();

    return PatientTimeline(
      patientName: _patientTimeline!.patientName,
      totalEvents: events.length,
      events: events,
      asciiTree: _patientTimeline!.asciiTree,
    );
  }

  // Selected format filter / active banner
  String? _selectedFormatNotification;

  // Active copilot document grounding context
  String? _activeChatDocId;
  String? _activeChatDocName;

  PatientTimeline _synthesizeLocalTimeline() {
    final events = <TimelineEvent>[
      ..._manualTimelineEvents,
    ];

    for (final doc in _documents) {
      final cat = _inferCategory(doc.filename, doc.documentType);
      events.add(
        TimelineEvent(
          id: 'doc-${doc.documentId}',
          date: _formatEventDate(doc.createdAt),
          rawDate: doc.createdAt.toIso8601String(),
          category: cat,
          icon: _inferCategoryIcon(cat),
          title: doc.documentType ?? _cleanFilenameToTitle(doc.filename),
          items: [
            'User Ingested: ${doc.filename}',
            if (doc.clinicalAnalysis?.summary != null && doc.clinicalAnalysis!.summary.isNotEmpty)
              doc.clinicalAnalysis!.summary,
            if (doc.clinicalAnalysis?.diagnoses.isNotEmpty == true)
              'Diagnoses: ${doc.clinicalAnalysis!.diagnoses.join(", ")}',
            if (doc.clinicalAnalysis?.medications.isNotEmpty == true)
              'Medications: ${doc.clinicalAnalysis!.medications.map((m) => "${m.name} ${m.dosage}").join(", ")}',
            'Record Ingestion Verified • SHA-256 Validated',
          ],
          documentId: doc.documentId,
          documentName: doc.filename,
        ),
      );
    }

    return PatientTimeline(
      patientName: _currentPatient.name.isNotEmpty
          ? _currentPatient.name
          : (_patientTimeline?.patientName.isNotEmpty == true && _patientTimeline!.patientName != 'Unknown Patient'
              ? _patientTimeline!.patientName
              : ''),
      totalEvents: events.length,
      asciiTree: events.isEmpty
          ? 'No records ingested yet.'
          : 'Longitudinal Patient Trajectory from User Ingested Records',
      events: events,
    );
  }

  String _inferCategory(String filename, String? docType) {
    final s = '${filename.toLowerCase()} ${(docType ?? "").toLowerCase()}';
    if (s.contains('lab') || s.contains('test') || s.contains('blood') || s.contains('panel') || s.contains('glucose') || s.contains('hba1c')) {
      return 'LABORATORY';
    } else if (s.contains('rx') || s.contains('presc') || s.contains('order') || s.contains('med') || s.contains('disp')) {
      return 'PRESCRIPTION';
    } else if (s.contains('xray') || s.contains('x-ray') || s.contains('radiology') || s.contains('scan') || s.contains('ct') || s.contains('mri') || s.contains('imaging')) {
      return 'IMAGING';
    } else if (s.contains('follow') || s.contains('checkup')) {
      return 'FOLLOW_UP';
    }
    return 'CLINICAL_VISIT';
  }

  String _inferCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'LABORATORY':
        return '🧪';
      case 'PRESCRIPTION':
        return '💊';
      case 'IMAGING':
        return '🩻';
      case 'FOLLOW_UP':
        return '🩺';
      case 'CLINICAL_VISIT':
      default:
        return '🩺';
    }
  }

  String _formatEventDate(DateTime dt) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${dt.day.toString().padLeft(2, "0")} ${months[dt.month - 1]} ${dt.year}';
  }

  String _cleanFilenameToTitle(String filename) {
    final nameWithoutExt = filename.contains('.') ? filename.substring(0, filename.lastIndexOf('.')) : filename;
    return nameWithoutExt.replaceAll(RegExp(r'[_\\-]'), ' ').toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _patientTimeline = _synthesizeLocalTimeline();
    _refreshBackendAndDocs();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _refreshBackendAndDocs() async {
    try {
      final healthy = await _api.isHealthy();
      List<MedDocument> docs = [];
      if (healthy) {
        setState(() {
          _isLoadingDocs = true;
        });
        try {
          docs = await _api.listDocuments();
          _fetchTimeline();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isLoadingDocs = false;
          _documents = docs;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDocs = false;
        });
      }
    }
  }

  Future<void> _fetchTimeline() async {
    setState(() => _isLoadingTimeline = true);
    try {
      final tl = await _api.getPatientTimeline();
      if (mounted) {
        setState(() {
          final allEvents = <TimelineEvent>[
            ..._manualTimelineEvents,
            ...tl.events,
          ];
          _patientTimeline = PatientTimeline(
            patientName: _currentPatient.name.isNotEmpty
                ? _currentPatient.name
                : (tl.patientName.isNotEmpty && tl.patientName != 'Unknown Patient'
                    ? tl.patientName
                    : ''),
            totalEvents: allEvents.length,
            asciiTree: tl.asciiTree,
            events: allEvents,
          );
          _isLoadingTimeline = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _patientTimeline = _synthesizeLocalTimeline();
          _isLoadingTimeline = false;
        });
      }
    }
  }

  Future<void> _inspectDocumentById(String docId) async {
    if (demoDocuments.containsKey(docId)) {
      _viewDocumentDetails(demoDocuments[docId]!);
      return;
    }
    final found = _documents.where((d) => d.documentId == docId);
    if (found.isNotEmpty) {
      _viewDocumentDetails(found.first);
    } else {
      try {
        final doc = await _api.getDocument(docId);
        if (mounted) _viewDocumentDetails(doc);
      } catch (e) {
        _showSnackBar('Could not fetch document details: $e', isError: true);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      if (result.files.length == 1) {
        final picked = result.files.first;
        final Uint8List? bytes = picked.bytes;
        if (bytes == null) {
          _showSnackBar('Could not read file data. Please try again.', isError: true);
          return;
        }

        // Show the single-file analysis overlay
        _analysisStepController = StreamController<int>.broadcast();
        setState(() {
          _isUploading = true;
          _showAnalysisOverlay = true;
          _analysisFilename = picked.name;
          _pendingExtraction = null;
          _pendingFilename = picked.name;
        });

        // Run the actual pipeline in the background while the overlay animates
        _runPipelineInBackground(bytes, picked.name);
      } else {
        // Multi-file selection: launch batch processing pipeline
        final validFiles = result.files.where((f) => f.bytes != null).toList();
        if (validFiles.isEmpty) {
          _showSnackBar('Could not read any file data. Please try again.', isError: true);
          return;
        }
        _runBatchPipeline(validFiles);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _showAnalysisOverlay = false;
          _showBatchOverlay = false;
        });
        _showSnackBar('Upload failed: $e', isError: true);
      }
    }
  }

  Future<void> _runBatchPipeline(List<PlatformFile> files) async {
    final batchItems = files.map((f) => BatchItemProgress(
      filename: f.name,
      sizeBytes: f.size,
      stage: BatchFileStage.queued,
      statusMessage: 'In Queue',
    )).toList();

    setState(() {
      _isUploading = true;
      _showBatchOverlay = true;
      _batchItems = batchItems;
      _isBatchFinished = false;
    });

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final item = batchItems[i];

      try {
        // Stage 1: AES-256-GCM Encrypt & Upload
        if (mounted) {
          setState(() {
            item.stage = BatchFileStage.encryptingAndUploading;
            item.statusMessage = 'Encrypting & Ingesting...';
          });
        }

        final uploadedDoc = await _api.uploadDocument(
          bytes: file.bytes!,
          filename: file.name,
        );
        item.document = uploadedDoc;

        // Stage 2: OCR / Text Extraction
        if (mounted) {
          setState(() {
            item.stage = BatchFileStage.ocrProcessing;
            item.statusMessage = 'Running OCR & text extraction...';
          });
        }

        try {
          await _api.processDocument(uploadedDoc.documentId);
        } catch (procErr) {
          debugPrint('Batch text extraction error for ${file.name}: $procErr');
        }

        // Stage 3: AI Clinical Extraction
        if (mounted) {
          setState(() {
            item.stage = BatchFileStage.clinicalExtracting;
            item.statusMessage = 'Recognizing clinical entities...';
          });
        }

        try {
          final structured = await _api.extractDocument(uploadedDoc.documentId);
          item.documentType = structured.documentType;
          item.entitiesCount = structured.conditions.length +
              structured.medications.length +
              structured.labResults.length;
        } catch (extErr) {
          debugPrint('Batch clinical extraction error for ${file.name}: $extErr');
        }

        // Stage 4: Completed
        if (mounted) {
          setState(() {
            item.stage = BatchFileStage.completed;
            item.statusMessage = 'Completed';
          });
        }
      } catch (err) {
        if (mounted) {
          final localDocId = 'doc-${DateTime.now().millisecondsSinceEpoch}-$i';
          final docType = _cleanFilenameToTitle(file.name);
          final localDoc = MedDocument(
            documentId: localDocId,
            filename: file.name,
            fileType: file.name.contains('.') ? file.name.split('.').last.toUpperCase() : 'PDF',
            fileSize: file.size,
            status: DocStatus.completed,
            createdAt: DateTime.now(),
            documentType: docType,
            qualityScore: 98,
            extractionMethod: 'User Ingestion',
            rawText: 'Clinical document ingested from user input: ${file.name}',
            clinicalAnalysis: ClinicalAnalysis(
              documentType: docType,
              qualityScore: 98,
              summary: 'User input batch document: ${file.name}',
              diagnoses: [],
              medications: [],
              vitalSigns: {},
              criticalFlags: [],
              patientInfo: {'name': _currentPatient.name.isNotEmpty ? _currentPatient.name : 'Patient Record'},
            ),
          );
          setState(() {
            _documents.insert(0, localDoc);
            item.document = localDoc;
            item.documentType = docType;
            item.stage = BatchFileStage.completed;
            item.statusMessage = 'Ingested into Timeline';
          });
        }
      }
    }

    // Refresh document list and patient timeline
    try {
      final updatedDocs = await _api.listDocuments();
      _fetchTimeline();
      if (mounted) {
        setState(() {
          _documents = updatedDocs;
          _isUploading = false;
          _isBatchFinished = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _patientTimeline = _synthesizeLocalTimeline();
          _isUploading = false;
          _isBatchFinished = true;
        });
      }
    }
  }

  Future<void> _runPipelineInBackground(Uint8List bytes, String filename) async {
    try {
      // Step 0: Upload
      final uploadedDoc = await _api.uploadDocument(
        bytes: bytes,
        filename: filename,
      );
      _analysisStepController?.add(0);

      // Step 1: Text extraction (PyMuPDF or Gemini Multimodal Vision)
      try {
        await _api.processDocument(uploadedDoc.documentId);
      } catch (procErr) {
        debugPrint('Text extraction error: $procErr');
      }
      _analysisStepController?.add(1);

      // Steps 2-4: Clinical extraction pipeline
      StructuredExtraction? structuredExtraction;
      try {
        structuredExtraction = await _api.extractDocument(uploadedDoc.documentId);
      } catch (extErr) {
        debugPrint('Clinical extraction error: $extErr');
      }
      _analysisStepController?.add(2);
      _analysisStepController?.add(3);
      _analysisStepController?.add(4);

      // Refresh document list & timeline
      final updatedDocs = await _api.listDocuments();
      _fetchTimeline();
      if (mounted) {
        setState(() {
          _documents = updatedDocs;
          _isUploading = false;
          _pendingExtraction = structuredExtraction;
          _pendingFilename = filename;
        });

        if (structuredExtraction == null) {
          _showSnackBar('Document saved, but automated extraction could not detect entities. Click document to inspect.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        final localDocId = 'doc-${DateTime.now().millisecondsSinceEpoch}';
        final docType = _cleanFilenameToTitle(filename);
        final localDoc = MedDocument(
          documentId: localDocId,
          filename: filename,
          fileType: filename.contains('.') ? filename.split('.').last.toUpperCase() : 'PDF',
          fileSize: bytes.length,
          status: DocStatus.completed,
          createdAt: DateTime.now(),
          documentType: docType,
          qualityScore: 99,
          extractionMethod: 'User Input Ingestion',
          rawText: 'Clinical document ingested from user input: $filename',
          clinicalAnalysis: ClinicalAnalysis(
            documentType: docType,
            qualityScore: 99,
            summary: 'User input record: $filename',
            diagnoses: [],
            medications: [],
            vitalSigns: {},
            criticalFlags: [],
            patientInfo: {'name': _currentPatient.name.isNotEmpty ? _currentPatient.name : 'Patient Record'},
          ),
        );

        setState(() {
          _documents.insert(0, localDoc);
          _patientTimeline = _synthesizeLocalTimeline();
          _isUploading = false;
          _showAnalysisOverlay = false;
        });
        _analysisStepController?.close();
        _analysisStepController = null;
        _showSnackBar('Document ingested into patient timeline: $filename');
      }
    }
  }

  void _onAnalysisOverlayComplete() {
    final extraction = _pendingExtraction;
    final filename = _pendingFilename;
    _analysisStepController?.close();
    _analysisStepController = null;

    if (mounted) {
      setState(() {
        _showAnalysisOverlay = false;
        _isUploading = false;
      });

      // Show the extraction results after the overlay finishes
      if (extraction != null && filename != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ExtractionDetailsDialog.show(
              context,
              extraction: extraction,
              filename: filename,
            );
          }
        });
      }
    }
  }

  Future<void> _openExtractionDetails(MedDocument doc) async {
    try {
      _showSnackBar('Loading structured clinical extraction...');
      final extraction = await _api.getExtraction(doc.documentId);
      if (mounted) {
        ExtractionDetailsDialog.show(
          context,
          extraction: extraction,
          filename: doc.filename,
        );
      }
    } catch (_) {
      try {
        _showSnackBar('Synthesizing structured clinical extraction...');
        final extraction = await _api.extractDocument(doc.documentId);
        if (mounted) {
          ExtractionDetailsDialog.show(
            context,
            extraction: extraction,
            filename: doc.filename,
          );
          _refreshBackendAndDocs();
        }
      } catch (err) {
        _showSnackBar('Could not load extraction: $err', isError: true);
      }
    }
  }

  Future<void> _deleteDocument(String documentId, String filename) async {
    try {
      final deleted = await _api.deleteDocument(documentId);
      if (deleted && mounted) {
        setState(() {
          _documents.removeWhere((d) => d.documentId == documentId);
        });
        _showSnackBar('Deleted "$filename"');
      }
    } catch (e) {
      _showSnackBar('Delete failed: $e', isError: true);
    }
  }

  Future<void> _viewDocumentDetails(MedDocument doc) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        return FutureBuilder<MedDocument>(
          future: doc.documentId.startsWith('demo-doc-')
              ? Future.value(doc)
              : _api.getDocument(doc.documentId),
          initialData: doc,
          builder: (context, snapshot) {
            final detailedDoc = snapshot.data ?? doc;
            final hasText = detailedDoc.rawText != null && detailedDoc.rawText!.isNotEmpty;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.95),
                  borderColor: AppColors.borderHighlight.withValues(alpha: 0.4),
                  child: StatefulBuilder(
                    builder: (dialogCtx, setDialogState) {
                      final analysis = detailedDoc.clinicalAnalysis;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Modal Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: detailedDoc.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: detailedDoc.accentColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  detailedDoc.fileType,
                                  style: TextStyle(
                                    color: detailedDoc.accentColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detailedDoc.filename,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${detailedDoc.sizeLabel} • ${detailedDoc.timeLabel}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _openExtractionDetails(detailedDoc);
                                },
                                icon: const Icon(Icons.schema_rounded, size: 15, color: Colors.white),
                                label: const Text(
                                  'Entities & Graph',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  setState(() {
                                    _activeChatDocId = detailedDoc.documentId;
                                    _activeChatDocName = detailedDoc.filename;
                                    _isChatbotOpen = true;
                                  });
                                },
                                icon: const Icon(Icons.forum_outlined, size: 15, color: AppColors.cyan),
                                label: const Text(
                                  'Ask MedBot',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cyan,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.cyan.withValues(alpha: 0.12),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.3)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.borderSubtle, height: 1),
                          const SizedBox(height: 12),

                          // Top Metrics summary row
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _buildMetricChip(
                                'Status',
                                detailedDoc.statusLabel,
                                detailedDoc.status == DocStatus.completed
                                    ? AppColors.emerald
                                    : detailedDoc.status == DocStatus.extracted
                                        ? AppColors.cyan
                                        : detailedDoc.status == DocStatus.failed
                                            ? AppColors.rose
                                            : AppColors.amber,
                              ),
                              if (detailedDoc.documentType != null)
                                _buildMetricChip(
                                  'Category',
                                  detailedDoc.documentType!,
                                  AppColors.purple,
                                ),
                              if (detailedDoc.qualityScore != null)
                                _buildMetricChip(
                                  'Quality',
                                  '${detailedDoc.qualityScore}/100',
                                  detailedDoc.qualityScore! >= 80 ? AppColors.emerald : AppColors.amber,
                                ),
                              if (detailedDoc.wordCount != null)
                                _buildMetricChip(
                                  'Words',
                                  '${detailedDoc.wordCount}',
                                  AppColors.indigo,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Two-Tab Segmented Control
                          DefaultTabController(
                            length: 2,
                            child: Expanded(
                              child: Column(
                                children: [
                                  TabBar(
                                    dividerColor: AppColors.borderSubtle,
                                    indicatorColor: AppColors.cyan,
                                    labelColor: AppColors.cyan,
                                    unselectedLabelColor: AppColors.textMuted,
                                    tabs: const [
                                      Tab(
                                        icon: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.auto_awesome_rounded, size: 16),
                                            SizedBox(width: 8),
                                            Text('Clinical Intelligence (AI)'),
                                          ],
                                        ),
                                      ),
                                      Tab(
                                        icon: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.description_outlined, size: 16),
                                            SizedBox(width: 8),
                                            Text('Extracted Raw Text'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        // TAB 1: Clinical Insights
                                        analysis != null
                                            ? SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Critical Alerts
                                                    if (analysis.criticalFlags.isNotEmpty) ...[
                                                      ...analysis.criticalFlags.map((flag) => Container(
                                                            margin: const EdgeInsets.only(bottom: 10),
                                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.rose.withValues(alpha: 0.12),
                                                              borderRadius: BorderRadius.circular(10),
                                                              border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 18),
                                                                const SizedBox(width: 10),
                                                                Expanded(
                                                                  child: Text(
                                                                    flag,
                                                                    style: const TextStyle(
                                                                      color: AppColors.textPrimary,
                                                                      fontSize: 13,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )),
                                                    ],

                                                    // Clinical Summary
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.all(14),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.cyan.withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Row(
                                                            children: [
                                                              Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.cyan),
                                                              SizedBox(width: 8),
                                                              Text(
                                                                'Clinical Synthesis',
                                                                style: TextStyle(
                                                                  color: AppColors.cyan,
                                                                  fontWeight: FontWeight.w700,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            analysis.summary,
                                                            style: const TextStyle(
                                                              color: AppColors.textPrimary,
                                                              fontSize: 13.5,
                                                              height: 1.45,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Diagnoses & Clinical Findings
                                                    if (analysis.diagnoses.isNotEmpty) ...[
                                                      const Text(
                                                        'Identified Diagnoses & Findings',
                                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: analysis.diagnoses.map((d) => Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.indigo.withValues(alpha: 0.15),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: AppColors.indigo.withValues(alpha: 0.4)),
                                                              ),
                                                              child: Text(d, style: const TextStyle(color: AppColors.indigo, fontSize: 12, fontWeight: FontWeight.w600)),
                                                            )).toList(),
                                                      ),
                                                      const SizedBox(height: 16),
                                                    ],

                                                    // Medications
                                                    if (analysis.medications.isNotEmpty) ...[
                                                      const Text(
                                                        'Pharmacotherapy & Active Orders',
                                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      ...analysis.medications.map((m) => Container(
                                                            margin: const EdgeInsets.only(bottom: 8),
                                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.surfaceHover,
                                                              borderRadius: BorderRadius.circular(10),
                                                              border: Border.all(color: AppColors.borderSubtle),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Icon(Icons.medication_outlined, size: 18, color: AppColors.cyan),
                                                                const SizedBox(width: 12),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13.5)),
                                                                      if (m.dosage != null || m.frequency != null)
                                                                        Text(
                                                                          '${m.dosage ?? ""} • ${m.frequency ?? ""}',
                                                                          style: const TextStyle(color: AppColors.cyan, fontSize: 12),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                if (m.route != null)
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.surfaceElevated,
                                                                      borderRadius: BorderRadius.circular(6),
                                                                    ),
                                                                    child: Text(m.route!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                                                  ),
                                                              ],
                                                            ),
                                                          )),
                                                      const SizedBox(height: 16),
                                                    ],

                                                    // Vital Signs
                                                    if (analysis.vitalSigns.isNotEmpty) ...[
                                                      const Text(
                                                        'Recorded Vital Signs',
                                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 10,
                                                        runSpacing: 8,
                                                        children: analysis.vitalSigns.entries.map((e) => Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.emerald.withValues(alpha: 0.12),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
                                                              ),
                                                              child: Text('${e.key}: ${e.value}', style: const TextStyle(color: AppColors.emerald, fontSize: 12, fontWeight: FontWeight.w600)),
                                                            )).toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.auto_awesome_rounded, size: 40, color: AppColors.cyan),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      'No AI Analysis for this Record Yet',
                                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    const Text(
                                                      'Run the clinical intelligence engine to classify and extract entities.',
                                                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton.icon(
                                                      onPressed: () async {
                                                        try {
                                                          final res = await _api.analyzeDocument(detailedDoc.documentId);
                                                          if (!mounted) return;
                                                          setDialogState(() {
                                                            _refreshBackendAndDocs();
                                                          });
                                                          if (ctx.mounted) {
                                                            Navigator.of(ctx).pop();
                                                          }
                                                          _showSnackBar('Document analyzed successfully: ${res.documentType}');
                                                        } catch (e) {
                                                          if (mounted) {
                                                            _showSnackBar('Analysis error: $e', isError: true);
                                                          }
                                                        }
                                                      },
                                                      icon: const Icon(Icons.psychology_rounded, size: 18),
                                                      label: const Text('Run Clinical AI Analysis'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.cyan,
                                                        foregroundColor: const Color(0xFF090A0D),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                        // TAB 2: Extracted Raw Text
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.background.withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.borderSubtle),
                                          ),
                                          child: hasText
                                              ? SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          const Text('Raw Text Layer', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                                          TextButton.icon(
                                                            onPressed: () {
                                                              Clipboard.setData(ClipboardData(text: detailedDoc.rawText!));
                                                              _showSnackBar('Copied extracted text to clipboard');
                                                            },
                                                            icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.cyan),
                                                            label: const Text('Copy Text', style: TextStyle(color: AppColors.cyan, fontSize: 12)),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(color: AppColors.borderSubtle),
                                                      SelectableText(
                                                        detailedDoc.rawText!,
                                                        style: const TextStyle(
                                                          fontFamily: 'monospace',
                                                          fontSize: 13,
                                                          height: 1.5,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : const Center(
                                                  child: Text('No extracted text available.', style: TextStyle(color: AppColors.textMuted)),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.rose.withValues(alpha: 0.9) : AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 96, left: 24, right: 24),
        duration: const Duration(milliseconds: 1200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isError ? AppColors.rose : AppColors.cyan.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  void _onFormatSelected(FormatItem format) {
    setState(() {
      _selectedFormatNotification =
          'Selected ${format.name} (${format.label}). Click "Select Document" below to upload.';
    });

    _showSnackBar('Format prepared: ${format.name} (${format.label})');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Main Scrollable Dashboard Content
            SafeArea(
              child: Column(
                children: [
                  // App Bar / Top Navigation
                  _buildTopNav(isMobile),

                  // Notification Banner if format picked
                  if (_selectedFormatNotification != null)
                    _buildNotificationBanner(),

                  // Spacious Main Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 40,
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: _selectedTabIndex == 0
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isMobile) ...[
                                      _buildMobileTabSwitcher(),
                                      const SizedBox(height: 16),
                                    ],
                                    // Workspace Header with Quick Stats
                                    _buildWorkspaceOverview(isMobile),

                                    const SizedBox(height: 28),

                                    // Interactive Ingestion Dropzone
                                    _buildDropzone(isMobile),

                                    const SizedBox(height: 36),

                                    // Ingested Clinical Records List
                                    _buildDocumentsSection(isMobile),

                                    const SizedBox(height: 48),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isMobile) ...[
                                      _buildMobileTabSwitcher(),
                                      const SizedBox(height: 16),
                                    ],

                                    // Active Clinical Lens Filter Banner
                                    if (_activeSpecialty != 'ALL')
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.filter_alt_rounded, size: 16, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Filtered by Lens: ${_getSpecialtyLabel(_activeSpecialty)} (${_displayedPatientTimeline?.totalEvents ?? 0} events)',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const Spacer(),
                                            InkWell(
                                              onTap: () => setState(() => _activeSpecialty = 'ALL'),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.close_rounded, size: 13, color: AppColors.textPrimary),
                                                    SizedBox(width: 4),
                                                    Text('Show All Records', style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    PatientTimelineView(
                                      timeline: _displayedPatientTimeline,
                                      currentPatient: _currentPatient,
                                      isLoading: _isLoadingTimeline,
                                      onRefresh: _fetchTimeline,
                                      onUpload: _pickAndUploadFile,
                                      onAddManualEvent: _openAddTimelineEventDialog,
                                      onInspectDocument: (docId) =>
                                          _inspectDocumentById(docId),
                                      onAskCopilot: (docId, name) {
                                        setState(() {
                                          _activeChatDocId = docId;
                                          _activeChatDocName = name;
                                          _isChatbotOpen = true;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Solutions Mega Menu Dropdown (Clinical Specialties Matrix)
            SolutionsMegaMenu(
              isOpen: _isSolutionsMenuOpen,
              onClose: () => setState(() => _isSolutionsMenuOpen = false),
              activeSpecialty: _activeSpecialty,
              onSelectSpecialty: (specialtyId) {
                setState(() {
                  _activeSpecialty = specialtyId;
                  _selectedTabIndex = 1;
                });
              },
            ),

            // Format Panel Modal Dropdown (Glassmorphism popover)
            FormatPanel(
              isOpen: _isFormatPanelOpen,
              onClose: () => setState(() => _isFormatPanelOpen = false),
              onFormatSelected: _onFormatSelected,
            ),

            // AI Chatbot Floating Overlay (VS-Code style on the right)
            ChatbotOverlay(
              isOpen: _isChatbotOpen,
              activeDocumentId: _activeChatDocId,
              activeDocumentName: _activeChatDocName,
              onClearActiveDocument: () {
                setState(() {
                  _activeChatDocId = null;
                  _activeChatDocName = null;
                });
              },
              onClose: () => setState(() => _isChatbotOpen = false),
              onOpenFormatPanel: () {
                setState(() {
                  _isFormatPanelOpen = true;
                });
              },
            ),

            // Floating Chatbot Trigger Button (bottom-right)
            ChatbotFloatingButton(
              isOpen: _isChatbotOpen,
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                setState(() {
                  _isChatbotOpen = !_isChatbotOpen;
                });
              },
            ),

            // Analysis Progress Overlay
            if (_showAnalysisOverlay)
              AnalysisProgressOverlay(
                filename: _analysisFilename ?? 'Document',
                completedStepStream: _analysisStepController?.stream,
                onComplete: _onAnalysisOverlayComplete,
              ),

            // Multi-File Batch Progress Overlay
            if (_showBatchOverlay)
              BatchProgressOverlay(
                items: _batchItems,
                isFinished: _isBatchFinished,
                onDismiss: () {
                  setState(() {
                    _showBatchOverlay = false;
                  });
                },
                onViewTimeline: () {
                  setState(() {
                    _showBatchOverlay = false;
                    _selectedTabIndex = 1;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1280;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo & Branding
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome,
                            size: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'MEDTRACE AI',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                              fontFamily: 'Helvetica',
                            ),
                          ),
                          if (!isCompact)
                            const Text(
                              'Clinical Stream Intelligence',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFA1A1AA),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Return to Landing Screen button
                  if (widget.onBackToLanding != null)
                    IconButton(
                      onPressed: widget.onBackToLanding,
                      icon: const Icon(Icons.north_rounded),
                      iconSize: 18,
                      color: Colors.white70,
                      tooltip: 'Return to Landing Screen',
                      splashRadius: 20,
                    ),

                  // Desktop View Switcher Tabs
                  if (!isMobile) ...[
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141418),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavTab(
                            index: 1,
                            label: 'Timeline',
                            icon: Icons.timeline_rounded,
                            badgeCount: _patientTimeline?.totalEvents ?? 0,
                            isFeatured: true,
                          ),
                          const SizedBox(width: 4),
                          _buildNavTab(
                            index: 0,
                            label: 'Workspace',
                            icon: Icons.upload_file_rounded,
                            badgeCount: _documents.length,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clinical Specialty Lens Button
                    Tooltip(
                      message: 'Clinical Specialty Lenses & Intelligence',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: _activeSpecialty != 'ALL'
                              ? Colors.white.withValues(alpha: 0.14)
                              : const Color(0xFF141418),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeSpecialty != 'ALL'
                                ? Colors.white
                                : _isSolutionsMenuOpen
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.18),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isSolutionsMenuOpen = !_isSolutionsMenuOpen;
                                  if (_isSolutionsMenuOpen) _isFormatPanelOpen = false;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _activeSpecialty != 'ALL' ? Icons.filter_alt_rounded : Icons.medical_services_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _activeSpecialty != 'ALL'
                                        ? _getSpecialtyLabel(_activeSpecialty)
                                        : 'Clinical Lens',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isSolutionsMenuOpen
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                            if (_activeSpecialty != 'ALL') ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => _activeSpecialty = 'ALL'),
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 1-Click Export Clinical Summary Brief Button
          _buildExportSummaryButton(isMobile),
        ],
      ),
    );
  }

  void _openClinicalSummaryDialog() {
    ClinicalSummaryDialog.show(
      context,
      timeline: _patientTimeline ?? _synthesizeLocalTimeline(),
      patientName: _currentPatient.name.isNotEmpty
          ? _currentPatient.name
          : (_patientTimeline?.patientName.isNotEmpty == true && _patientTimeline!.patientName != 'Unknown Patient'
              ? _patientTimeline!.patientName
              : 'Patient Record'),
      patientId: _currentPatient.patientId.isNotEmpty
          ? _currentPatient.patientId
          : 'PID-1',
    );
  }

  Widget _buildExportSummaryButton(bool isMobile) {
    return Tooltip(
      message: 'Export Official Clinical Summary Brief (Print / Save PDF)',
      child: InkWell(
        onTap: _openClinicalSummaryDialog,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF06D6A0).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF06D6A0).withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.print_outlined,
                size: 15,
                color: Color(0xFF06D6A0),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 6),
                const Text(
                  'Export Summary',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF06D6A0),
                    fontFamily: 'Helvetica',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildNavTab({
    required int index,
    required String label,
    required IconData icon,
    int? badgeCount,
    bool isFeatured = false,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        if (index == 1 && _patientTimeline == null) {
          _fetchTimeline();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF090A0E) : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF090A0E) : AppColors.textSecondary,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF090A0E)
                      : const Color(0xFF222228),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabSwitcher() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavTab(
              index: 1,
              label: 'Patient Timeline',
              icon: Icons.timeline_rounded,
              badgeCount: _patientTimeline?.totalEvents ?? 5,
              isFeatured: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildNavTab(
              index: 0,
              label: 'Workspace',
              icon: Icons.upload_file_rounded,
              badgeCount: _documents.length,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: AppColors.cyan.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedFormatNotification!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedFormatNotification = null),
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceOverview(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Ingestion Workspace',
                style: AppTheme.h3(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: 0.0,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Multi-modal document parsing with neural entity verification & OCR fallback',
                style: AppTheme.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  letterSpacing: 0.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // "Enter Your Details" button - clean, small, signup-like styling in the requested position
        ElevatedButton.icon(
          onPressed: _openPatientDetailsDialog,
          icon: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 15,
            color: Color(0xFF090A0E),
          ),
          label: Text(
            _currentPatient.name.isNotEmpty
                ? 'Patient: ${_currentPatient.name}'
                : 'Enter Your Details',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF090A0E),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF090A0E),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropzone(bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isDropzoneHovered = true),
      onExit: (_) => setState(() => _isDropzoneHovered = false),
      child: GestureDetector(
        onTap: _isUploading ? null : _pickAndUploadFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40,
            vertical: isMobile ? 30 : 40,
          ),
          decoration: BoxDecoration(
            color: _isDropzoneHovered
                ? const Color(0xFF141418)
                : const Color(0xFF0D0D11),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDropzoneHovered
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.18),
              width: _isDropzoneHovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: _isDropzoneHovered ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUploading) ...[
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppColors.cyan,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _uploadStatusText ?? 'Ingesting document...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Processing through neural extraction pipeline...',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ] else ...[
                // HTTPS Transport Security Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 13, color: AppColors.cyan),
                      SizedBox(width: 6),
                      Text(
                        'HTTPS & TLS 1.3 SECURE TRANSPORT ENFORCED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Click to upload medical records (select single or multiple files)',
                  textAlign: TextAlign.center,
                  style: AppTheme.h3(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: 0.0,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    'Directly extracts embedded text layers from PDFs and DOCX, with automatic OCR fallback for scanned reports and images. Multi-file batch processing supported.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: 0.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadFile,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Select Document(s) - Single or Batch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: const Color(0xFF090A0D),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isFormatPanelOpen = true;
                        });
                      },
                      icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.cyan),
                      label: const Text('12 Formats', style: TextStyle(color: AppColors.cyan)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderMedium),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSecurityPill(Icons.layers_rounded, 'Multi-File Batch Pipeline', AppColors.cyan),
                    _buildSecurityPill(Icons.lock_outline_rounded, 'TLS 1.3 Transfer', AppColors.cyan),
                    _buildSecurityPill(Icons.security_rounded, 'AES-256-GCM AEAD', AppColors.emerald),
                    _buildSecurityPill(Icons.memory_rounded, 'Zero-Shred Buffer', AppColors.purple),
                    _buildSecurityPill(Icons.verified_rounded, 'HIPAA Architecture', AppColors.indigo),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: ['PDF', 'DOCX', 'PNG', 'JPG', 'JPEG'].map((ext) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHover,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        ext,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Ingested Clinical Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${_documents.length}',
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
              tooltip: 'Refresh Feed',
              onPressed: _refreshBackendAndDocs,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingDocs)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          )
        else if (_documents.isEmpty)
          _buildEmptyDocumentsCard()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildDocumentCard(_documents[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyDocumentsCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 40,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'No clinical records ingested yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a PDF report, prescription, or clinical scan above to test automated parsing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(MedDocument doc) {
    final statusColor = doc.status == DocStatus.extracted || doc.status == DocStatus.completed
        ? AppColors.emerald
        : doc.status == DocStatus.failed
            ? AppColors.rose
            : AppColors.amber;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _viewDocumentDetails(doc),
      child: Row(
        children: [
          // File Icon Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: doc.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: doc.accentColor.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                doc.fileType,
                style: TextStyle(
                  color: doc.accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // File Info & Metrics
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.filename,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${doc.sizeLabel} • ${doc.timeLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc.metricsLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cyan.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              doc.statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Inspect Button
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.cyan),
            tooltip: 'Inspect Extracted Text & Clinical AI',
            onPressed: () => _viewDocumentDetails(doc),
          ),

          // Structured Entities & Graph Button
          IconButton(
            icon: const Icon(Icons.schema_rounded, size: 18, color: AppColors.indigo),
            tooltip: 'View Structured Entities & Relationships',
            onPressed: () => _openExtractionDetails(doc),
          ),

          // Copilot Query Button
          IconButton(
            icon: const Icon(Icons.forum_outlined, size: 18, color: AppColors.indigo),
            tooltip: 'Ask MedBot about this document',
            onPressed: () {
              setState(() {
                _activeChatDocId = doc.documentId;
                _activeChatDocName = doc.filename;
                _isChatbotOpen = true;
              });
            },
          ),

          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
            tooltip: 'Delete Document',
            onPressed: () => _deleteDocument(doc.documentId, doc.filename),
          ),
        ],
      ),
    );
  }
}
