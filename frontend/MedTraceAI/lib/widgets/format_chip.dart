import 'package:flutter/material.dart';
import '../models/format_item.dart';
import '../theme/app_colors.dart';

class FormatChipWidget extends StatefulWidget {
  final FormatItem format;
  final VoidCallback? onTap;

  const FormatChipWidget({
    super.key,
    required this.format,
    this.onTap,
  });

  @override
  State<FormatChipWidget> createState() => _FormatChipWidgetState();
}

class _FormatChipWidgetState extends State<FormatChipWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final format = widget.format;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? format.accentColor.withOpacity(0.16)
                  : AppColors.surfaceElevated.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? format.accentColor.withOpacity(0.65)
                    : AppColors.borderSubtle,
                width: 1.2,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: format.accentColor.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: format.accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    format.icon,
                    size: 16,
                    color: format.accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      format.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: _isHovered
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      format.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _isHovered
                            ? format.accentColor.withOpacity(0.9)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
