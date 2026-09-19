import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blur;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool borderGlow;
  final bool enableHover;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.blur = 0.0,
    this.boxShadow,
    this.onTap,
    this.borderGlow = false,
    this.enableHover = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final baseBorderColor = widget.borderColor ?? AppColors.borderSubtle;
    final effectiveBorderColor = (_isHovered && (widget.enableHover || widget.onTap != null))
        ? Colors.white.withValues(alpha: 0.45)
        : baseBorderColor;

    final effectiveBg = _isHovered
        ? (widget.backgroundColor != null
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.04), widget.backgroundColor!)
            : AppColors.glassCardHover)
        : (widget.backgroundColor ?? AppColors.glassCard);

    final shouldLift = _isHovered && (widget.enableHover || widget.onTap != null);

    Widget innerContent = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: shouldLift ? 1.4 : 1.0,
        ),
      ),
      child: widget.child,
    );

    Widget contentBody = (widget.blur > 0)
        ? ClipRRect(
            borderRadius: effectiveRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
              child: innerContent,
            ),
          )
        : ClipRRect(
            borderRadius: effectiveRadius,
            child: innerContent,
          );

    Widget cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, shouldLift ? -3.0 : 0, 0),
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: widget.boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: shouldLift ? 0.7 : 0.45),
            blurRadius: shouldLift ? 18 : 10,
            offset: Offset(0, shouldLift ? 8 : 4),
          ),
        ],
      ),
      child: contentBody,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: (widget.onTap != null) ? SystemMouseCursors.click : MouseCursor.defer,
      child: widget.onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: effectiveRadius,
                onTap: widget.onTap,
                child: cardBody,
              ),
            )
          : cardBody,
    );
  }
}
