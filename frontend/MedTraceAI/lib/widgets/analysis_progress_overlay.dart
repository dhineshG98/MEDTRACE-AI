import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Represents one step in the analysis pipeline.
class _AnalysisStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Duration duration;

  const _AnalysisStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.duration,
  });
}

/// A premium, animated overlay that shows multi-stage analysis progress.
///
/// Each step animates its progress bar, then shows a checkmark before
/// moving to the next step.  The overlay auto-closes when all steps
/// finish and calls [onComplete].
class AnalysisProgressOverlay extends StatefulWidget {
  final String filename;
  final VoidCallback onComplete;

  /// External signals that mark pipeline stages as "actually done".
  /// When a key becomes true the corresponding step's timer is accelerated
  /// so the overlay stays in sync with real backend latency.
  final Stream<int>? completedStepStream;

  const AnalysisProgressOverlay({
    super.key,
    required this.filename,
    required this.onComplete,
    this.completedStepStream,
  });

  @override
  State<AnalysisProgressOverlay> createState() =>
      _AnalysisProgressOverlayState();
}

class _AnalysisProgressOverlayState extends State<AnalysisProgressOverlay>
    with TickerProviderStateMixin {
  static const _steps = [
    _AnalysisStep(
      title: 'Uploading Document',
      subtitle: 'Securely transferring to MedTrace pipeline…',
      icon: Icons.cloud_upload_outlined,
      duration: Duration(milliseconds: 400),
    ),
    _AnalysisStep(
      title: 'Extracting Text Layers',
      subtitle: 'Running PyMuPDF extraction with OCR fallback…',
      icon: Icons.text_snippet_outlined,
      duration: Duration(milliseconds: 500),
    ),
    _AnalysisStep(
      title: 'Clinical Entity Recognition',
      subtitle: 'Identifying conditions, medications & lab values…',
      icon: Icons.biotech_outlined,
      duration: Duration(milliseconds: 550),
    ),
    _AnalysisStep(
      title: 'Negation & Relationship Mapping',
      subtitle: 'Analyzing context, negation cues & treats linkage…',
      icon: Icons.schema_rounded,
      duration: Duration(milliseconds: 450),
    ),
    _AnalysisStep(
      title: 'Quality Scoring & Validation',
      subtitle: 'Computing confidence tiers & flagging review items…',
      icon: Icons.verified_outlined,
      duration: Duration(milliseconds: 350),
    ),
  ];

  int _currentStep = 0;
  bool _isComplete = false;

  late List<AnimationController> _progressControllers;
  late List<Animation<double>> _progressAnimations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription<int>? _stepSub;

  @override
  void initState() {
    super.initState();

    // Per-step progress bar animations
    _progressControllers = List.generate(
      _steps.length,
      (i) => AnimationController(
        vsync: this,
        duration: _steps[i].duration,
      ),
    );
    _progressAnimations = _progressControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeInOut);
    }).toList();

    // Overlay fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // Pulsing glow on the active step icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    // Listen for backend completion signals
    _stepSub = widget.completedStepStream?.listen((stepIndex) {
      if (stepIndex < _steps.length &&
          stepIndex == _currentStep &&
          _progressControllers[stepIndex].isAnimating) {
        // Jump to end quickly
        _progressControllers[stepIndex].duration =
            const Duration(milliseconds: 300);
        _progressControllers[stepIndex].forward(from: _progressControllers[stepIndex].value);
      }
    });

    _runPipeline();
  }

  Future<void> _runPipeline() async {
    for (var i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _currentStep = i);

      _progressControllers[i].forward();
      await _progressControllers[i].forward().orCancel.catchError((_) {});

      // Tiny pause between steps for the checkmark reveal
      await Future.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted) return;
    setState(() => _isComplete = true);
    await Future.delayed(const Duration(milliseconds: 250));
    widget.onComplete();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    for (final c in _progressControllers) {
      c.dispose();
    }
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.82),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.08),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 28),

                // Pipeline Steps
                ..._steps.asMap().entries.map((e) =>
                    _buildStepRow(e.key, e.value)),

                const SizedBox(height: 24),

                // Bottom status line
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: _pulseAnimation.value * 0.25),
                    AppColors.indigo.withValues(alpha: _pulseAnimation.value * 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: _pulseAnimation.value * 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: _pulseAnimation.value * 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isComplete ? Icons.check_rounded : Icons.psychology_rounded,
                color: AppColors.cyan,
                size: 28,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          _isComplete ? 'Analysis Complete' : 'Analyzing Document',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.filename,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStepRow(int index, _AnalysisStep step) {
    final isActive = index == _currentStep && !_isComplete;
    final isDone = index < _currentStep || _isComplete;
    final isPending = index > _currentStep && !_isComplete;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.cyan.withValues(alpha: 0.06)
              : isDone
                  ? AppColors.emerald.withValues(alpha: 0.04)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.cyan.withValues(alpha: 0.2)
                : isDone
                    ? AppColors.emerald.withValues(alpha: 0.12)
                    : AppColors.borderSubtle.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Step Icon / Checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isDone
                  ? Container(
                      key: ValueKey('done_$index'),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.emerald,
                        size: 18,
                      ),
                    )
                  : isActive
                      ? AnimatedBuilder(
                          key: ValueKey('active_$index'),
                          animation: _pulseAnimation,
                          builder: (context, _) {
                            return Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.cyan
                                    .withValues(alpha: _pulseAnimation.value * 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cyan
                                      .withValues(alpha: _pulseAnimation.value * 0.5),
                                ),
                              ),
                              child: Icon(
                                step.icon,
                                color: AppColors.cyan,
                                size: 16,
                              ),
                            );
                          },
                        )
                      : Container(
                          key: ValueKey('pending_$index'),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHover.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          child: Icon(
                            step.icon,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            size: 16,
                          ),
                        ),
            ),
            const SizedBox(width: 14),

            // Step Text & Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPending
                          ? AppColors.textMuted.withValues(alpha: 0.5)
                          : isDone
                              ? AppColors.emerald
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone ? 'Completed' : step.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDone
                          ? AppColors.emerald.withValues(alpha: 0.6)
                          : isPending
                              ? AppColors.textMuted.withValues(alpha: 0.35)
                              : AppColors.textMuted,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedBuilder(
                        animation: _progressAnimations[index],
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: _progressAnimations[index].value,
                            backgroundColor:
                                AppColors.surfaceHover.withValues(alpha: 0.8),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.cyan.withValues(alpha: 0.85),
                            ),
                            minHeight: 4,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Duration badge
            if (isDone)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(step.duration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emerald.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final completedCount =
        _isComplete ? _steps.length : _currentStep;

    return Row(
      children: [
        // Progress fraction
        Text(
          '$completedCount / ${_steps.length} stages',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _isComplete
                ? AppColors.emerald.withValues(alpha: 0.12)
                : AppColors.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isComplete
                  ? AppColors.emerald.withValues(alpha: 0.3)
                  : AppColors.cyan.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isComplete) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.cyan.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                _isComplete ? '✓ Pipeline finished' : 'Processing…',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isComplete ? AppColors.emerald : AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
