import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/med_document.dart';
import '../theme/app_colors.dart';

enum BatchFileStage {
  queued,
  encryptingAndUploading,
  ocrProcessing,
  clinicalExtracting,
  completed,
  failed,
}

class BatchItemProgress {
  final String filename;
  final int sizeBytes;
  BatchFileStage stage;
  String statusMessage;
  String? documentType;
  int? entitiesCount;
  String? errorMessage;
  MedDocument? document;

  BatchItemProgress({
    required this.filename,
    required this.sizeBytes,
    this.stage = BatchFileStage.queued,
    this.statusMessage = 'Waiting in queue...',
    this.documentType,
    this.entitiesCount,
    this.errorMessage,
    this.document,
  });
}

class BatchProgressOverlay extends StatelessWidget {
  final List<BatchItemProgress> items;
  final bool isFinished;
  final VoidCallback onDismiss;
  final VoidCallback onViewTimeline;

  const BatchProgressOverlay({
    super.key,
    required this.items,
    required this.isFinished,
    required this.onDismiss,
    required this.onViewTimeline,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  IconData _getFileIcon(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return Icons.image_rounded;
    }
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = items.where((e) => e.stage == BatchFileStage.completed).length;
    final failedCount = items.where((e) => e.stage == BatchFileStage.failed).length;
    final totalCount = items.length;
    final progressFraction = totalCount > 0 ? (completedCount + failedCount) / totalCount : 0.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Glassmorphic backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: AppColors.background.withValues(alpha: 0.85),
              ),
            ),
          ),

          // Central modal
          Center(
            child: Container(
              width: 660,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isFinished
                      ? AppColors.emerald.withValues(alpha: 0.5)
                      : AppColors.cyan.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFinished ? AppColors.emerald : AppColors.cyan).withValues(alpha: 0.18),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isFinished ? AppColors.emerald : AppColors.cyan).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isFinished ? AppColors.emerald : AppColors.cyan).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFinished ? Icons.verified_rounded : Icons.lock_clock_rounded,
                              size: 14,
                              color: isFinished ? AppColors.emerald : AppColors.cyan,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isFinished
                                  ? 'BATCH EXTRACTION COMPLETE'
                                  : 'MULTI-DOCUMENT PIPELINE ACTIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isFinished ? AppColors.emerald : AppColors.cyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isFinished)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: onDismiss,
                          tooltip: 'Close overlay',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Description
                  Text(
                    isFinished
                        ? 'Batch Ingestion Complete'
                        : 'Processing Medical Documents ($totalCount Files)',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isFinished
                        ? '$completedCount of $totalCount documents encrypted and synthesized into the patient timeline.'
                        : 'AES-256-GCM storage encryption, OCR text extraction, and clinical entity recognition.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Overall Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Progress: $completedCount of $totalCount finished',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${(progressFraction * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isFinished ? AppColors.emerald : AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFinished ? AppColors.emerald : AppColors.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scrollable File Items
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildFileItemCard(item);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isFinished) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cyan,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Processing queue sequentially...',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ] else ...[
                        OutlinedButton(
                          onPressed: onDismiss,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.borderMedium),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Dismiss'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: onViewTimeline,
                          icon: const Icon(Icons.timeline_rounded, size: 16),
                          label: const Text('View Updated Patient Timeline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: const Color(0xFF090A0D),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItemCard(BatchItemProgress item) {
    Color borderColor;
    Color iconColor;
    Widget statusWidget;

    switch (item.stage) {
      case BatchFileStage.queued:
        borderColor = AppColors.borderSubtle;
        iconColor = AppColors.textMuted;
        statusWidget = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 14, color: AppColors.textMuted),
            SizedBox(width: 5),
            Text('In Queue', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        );
        break;

      case BatchFileStage.encryptingAndUploading:
        borderColor = AppColors.cyan.withValues(alpha: 0.5);
        iconColor = AppColors.cyan;
        statusWidget = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
            ),
            SizedBox(width: 6),
            Text(
              'Encrypting (AES-256-GCM)...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyan),
            ),
          ],
        );
        break;

      case BatchFileStage.ocrProcessing:
        borderColor = AppColors.amber.withValues(alpha: 0.5);
        iconColor = AppColors.amber;
        statusWidget = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
            ),
            SizedBox(width: 6),
            Text(
              'Running OCR & Text Extraction...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.amber),
            ),
          ],
        );
        break;

      case BatchFileStage.clinicalExtracting:
        borderColor = AppColors.purple.withValues(alpha: 0.5);
        iconColor = AppColors.purple;
        statusWidget = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
            ),
            SizedBox(width: 6),
            Text(
              'Extracting Clinical Entities...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purple),
            ),
          ],
        );
        break;

      case BatchFileStage.completed:
        borderColor = AppColors.emerald.withValues(alpha: 0.5);
        iconColor = AppColors.emerald;
        statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.emerald),
            const SizedBox(width: 6),
            Text(
              item.documentType != null
                  ? '${item.documentType} • Completed'
                  : 'Completed & Timeline Synced',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.emerald,
              ),
            ),
          ],
        );
        break;

      case BatchFileStage.failed:
        borderColor = AppColors.rose.withValues(alpha: 0.5);
        iconColor = AppColors.rose;
        statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.rose),
            const SizedBox(width: 6),
            Text(
              item.errorMessage ?? 'Failed',
              style: const TextStyle(fontSize: 12, color: AppColors.rose),
            ),
          ],
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getFileIcon(item.filename), size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Name and status details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.filename,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatSize(item.sizeBytes),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                statusWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
