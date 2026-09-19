import 'package:flutter/material.dart';
import '../models/format_item.dart';
import '../theme/app_colors.dart';
import 'format_chip.dart';

class FormatPanel extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final ValueChanged<FormatItem>? onFormatSelected;

  const FormatPanel({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.onFormatSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Full screen transparent dismiss area
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
        ),

        // Semi-rectangular rounded glassmorphic panel
        Positioned(
          top: 76,
          left: 0,
          right: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 680,
                maxHeight: 520,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * -16),
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D11),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 36,
                        spreadRadius: -2,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Supported Ingestion Formats',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Select a format to prepare ingestion pipeline or drop file anywhere',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary.withOpacity(0.8),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: onClose,
                                  icon: const Icon(Icons.close_rounded),
                                  iconSize: 20,
                                  color: AppColors.textSecondary,
                                  splashRadius: 20,
                                  tooltip: 'Close panel',
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            const Divider(color: AppColors.borderSubtle, height: 1),
                            const SizedBox(height: 20),

                            // Grid of Formats
                            Flexible(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: FormatItem.supportedFormats.map((format) {
                                    return FormatChipWidget(
                                      format: format,
                                      onTap: () {
                                        if (onFormatSelected != null) {
                                          onFormatSelected!(format);
                                        }
                                        onClose();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            const Divider(color: AppColors.borderSubtle, height: 1),
                            const SizedBox(height: 14),

                            // Footer info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'HIPAA & GDPR Compliant • Zero Data Retention Mode Available',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textMuted,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '12 Native Formats',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD4D4D8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }
}
