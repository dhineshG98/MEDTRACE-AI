import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'landing_screen.dart';
import 'app_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final Animation<Offset> _page1SlideAnimation;
  late final Animation<double> _page1FadeAnimation;
  late final Animation<double> _page2FadeAnimation;
  late final Animation<double> _page2ScaleAnimation;

  int _targetTabIndex = 1; // Default to Patient Timeline!
  bool _isPage1Active = true;

  @override
  void initState() {
    super.initState();

    // 420ms snappy, silky transition without frame drops
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isPage1Active) {
          setState(() => _isPage1Active = false);
        }
      } else if (status == AnimationStatus.reverse) {
        if (!_isPage1Active) {
          setState(() => _isPage1Active = true);
        }
      }
    });

    final curve = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Page 1 slides gently upward and fades out
    _page1SlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(curve);

    _page1FadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));

    // Page 2 smoothly fades in with a gentle micro-scale
    _page2FadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
    ));

    _page2ScaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(curve);
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _triggerUpwardTransition(int tabIndex) {
    setState(() {
      _targetTabIndex = tabIndex;
      _isPage1Active = true;
    });
    if (_transitionController.status != AnimationStatus.forward &&
        _transitionController.status != AnimationStatus.completed) {
      _transitionController.forward();
    }
  }

  void _reverseToLanding() {
    setState(() => _isPage1Active = true);
    if (_transitionController.status != AnimationStatus.reverse &&
        _transitionController.status != AnimationStatus.dismissed) {
      _transitionController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // PAGE 2 – Pre-warmed underneath with hardware-accelerated transitions
          FadeTransition(
            opacity: _page2FadeAnimation,
            child: ScaleTransition(
              scale: _page2ScaleAnimation,
              child: RepaintBoundary(
                child: AppScreen(
                  key: const ValueKey('medtrace_app_screen_stable'),
                  initialTabIndex: _targetTabIndex,
                  onBackToLanding: _reverseToLanding,
                ),
              ),
            ),
          ),

          // PAGE 1 – Landing Screen
          if (_isPage1Active)
            Positioned.fill(
              child: FadeTransition(
                opacity: _page1FadeAnimation,
                child: SlideTransition(
                  position: _page1SlideAnimation,
                  child: RepaintBoundary(
                    child: LandingScreen(
                      onOpenTimeline: () => _triggerUpwardTransition(1),
                      onOpenWorkspace: () => _triggerUpwardTransition(0),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
