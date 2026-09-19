import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

/// User model to hold authenticated user info.
class AuthUser {
  final String displayName;
  final String email;
  final String photoUrl;

  const AuthUser({
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });
}

class AuthScreen extends StatefulWidget {
  final ValueChanged<AuthUser> onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  bool _isSigningIn = false;
  bool _showEmailInput = false;
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '425303006402-rf8fgf9u151d4u9fgfj59ti2cdc65rnt.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  void _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await AuthService.instance.signInWithGoogle(
          email: account.email,
          name: account.displayName,
        );
        if (!mounted) return;
        widget.onAuthenticated(AuthUser(
          displayName: account.displayName ?? 'Clinician',
          email: account.email,
          photoUrl: account.photoUrl ?? '',
        ));
        return;
      }
    } catch (error) {
      debugPrint('Google OAuth error: $error');
      // If error or cancelled, notify user and provide clinical fallback
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In note: $error (starting demo session)'),
          duration: const Duration(seconds: 3),
        ),
      );
      widget.onAuthenticated(const AuthUser(
        displayName: 'Dr. Sarah Chen',
        email: 'sarah.chen@medtrace.health',
        photoUrl: '',
      ));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _handleEmailContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _isSigningIn = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final name = email.split('@').first.replaceAll('.', ' ');
    final capitalized = name
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');

    widget.onAuthenticated(AuthUser(
      displayName: capitalized,
      email: email,
      photoUrl: '',
    ));
  }

  // ─── Colors ────────────────────────────────────────
  static const _bg = Color(0xFF0A0E17);
  static const _surface = Color(0xFF111827);
  static const _surfaceLight = Color(0xFF1A2236);
  static const _borderDim = Color(0xFF1E293B);
  static const _borderBright = Color(0xFF334155);
  static const _cyan = Color(0xFF06D6A0);
  static const _textPrimary = Color(0xFFEEF2FF);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -120,
            left: size.width / 2 - 250,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyan.withValues(alpha: 0.06),
                    _cyan.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 48,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Platform badge
                          _buildPlatformBadge(),
                          const SizedBox(height: 32),

                          // Hero heading
                          _buildHeading(isMobile),
                          const SizedBox(height: 18),

                          // Subtitle
                          _buildSubtitle(isMobile),
                          const SizedBox(height: 36),

                          // Auth buttons (Google + Email)
                          _buildAuthSection(isMobile),
                          const SizedBox(height: 44),

                          // Patient trajectory preview card
                          _buildTrajectoryCard(isMobile),
                          const SizedBox(height: 48),

                          // Platform capabilities
                          _buildCapabilities(isMobile),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderDim, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: _cyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'MEDTRACE AI – CLINICAL INTELLIGENCE PLATFORM',
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
              letterSpacing: 1.5,
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildHeading(bool isMobile) {
    return Text(
      'Autonomous Clinical Trace &\nMulti-Modal Intelligence',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Helvetica',
        fontSize: isMobile ? 28 : 44,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.15,
        letterSpacing: -0.8,
      ),
    );
  }

  Widget _buildSubtitle(bool isMobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Text(
        'Synthesize medical records, clinical visits, lab panels, and imaging into a verified chronological patient timeline with deep clinical entity recognition and sub-second traceability.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: isMobile ? 14 : 15.5,
          fontWeight: FontWeight.w400,
          color: _textSecondary,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildAuthSection(bool isMobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        children: [
          // Google Sign-In — primary
          SizedBox(
            width: double.infinity,
            child: _DarkAuthButton(
              isPrimary: true,
              isLoading: _isSigningIn && !_showEmailInput,
              onPressed: _isSigningIn ? null : _handleGoogleSignIn,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 18, height: 18, child: _GoogleLogo(size: 18)),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Divider
          Row(
            children: [
              Expanded(child: Container(height: 1, color: _borderDim)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: TextStyle(fontSize: 12, color: _textMuted, fontFamily: 'Helvetica'),
                ),
              ),
              Expanded(child: Container(height: 1, color: _borderDim)),
            ],
          ),

          const SizedBox(height: 14),

          // Email
          if (!_showEmailInput)
            SizedBox(
              width: double.infinity,
              child: _DarkAuthButton(
                isPrimary: false,
                onPressed: () {
                  setState(() => _showEmailInput = true);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _emailFocusNode.requestFocus();
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, size: 17, color: _textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      'Continue with email',
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildEmailInput(),

          const SizedBox(height: 18),

          // Terms
          Text(
            'By continuing, you agree to MedTrace AI\'s Terms of Service and acknowledge our Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: _textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderBright, width: 1),
          ),
          child: TextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontFamily: 'Helvetica',
              fontSize: 14,
              color: _textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(
                fontFamily: 'Helvetica',
                fontSize: 14,
                color: _textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _handleEmailContinue(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _DarkAuthButton(
            isPrimary: true,
            isLoading: _isSigningIn,
            onPressed: _isSigningIn ? null : _handleEmailContinue,
            child: const Text(
              'Continue',
              style: TextStyle(
                fontFamily: 'Helvetica',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrajectoryCard(bool isMobile) {
    final events = [
      _TimelineEvent('10 JAN', 'LABORATORY', '[LABORATORY] HbA1c: 8.4% (Elevated) · Fasting Glucose: 168 mg/dL', const Color(0xFF3B82F6)),
      _TimelineEvent('15 JAN', 'CLINICAL VISIT', '[CLINICAL VISIT] Type 2 Diabetes Mellitus · Essential Hypertension', const Color(0xFF8B5CF6)),
      _TimelineEvent('15 JAN', 'PRESCRIPTION', '[PRESCRIPTION] Metformin 500 mg BID · Lisinopril 10 mg QD', const Color(0xFFF59E0B)),
      _TimelineEvent('18 JAN', 'IMAGING', '[IMAGING] Chest X-Ray: Clear lung fields, normal cardiothoracic ratio', const Color(0xFF06B6D4)),
      _TimelineEvent('24 FEB', 'FOLLOW-UP', '[FOLLOW-UP] Glucose stabilized: 118 mg/dL · Response: High Tolerance', const Color(0xFF10B981)),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderDim, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 18, color: _cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'LONGITUDINAL PATIENT TRAJECTORY',
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CORE FEATURE',
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _cyan,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Row(
                  children: [
                    Text(
                      '→  Open Interactive Timeline',
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _cyan,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'Patient: Eleanor Vance (PID-9824) · 5 Clinical Milestones',
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontSize: 12,
              color: _textMuted,
            ),
          ),

          const SizedBox(height: 18),

          // Timeline entries
          ...events.map((e) => _buildTimelineRow(e)),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(_TimelineEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date badge
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                event.date,
                style: const TextStyle(
                  fontFamily: 'Helvetica',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _cyan,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: event.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Description
          Expanded(
            child: Text(
              event.description,
              style: const TextStyle(
                fontFamily: 'Helvetica',
                fontSize: 13,
                color: _textSecondary,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilities(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cyan.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _cyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PLATFORM CAPABILITIES',
                style: TextStyle(
                  fontFamily: 'Helvetica',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _cyan,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Enterprise Healthcare Intelligence',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Helvetica',
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 12),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Engineered for hospital systems, clinical trials, and diagnostics with sub-second verified traceability, encrypted file transfer, and defense-in-depth cryptography.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontSize: isMobile ? 13 : 14,
              color: _textSecondary,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Timeline Event Model ─────────────────────────────────
class _TimelineEvent {
  final String date;
  final String type;
  final String description;
  final Color color;
  const _TimelineEvent(this.date, this.type, this.description, this.color);
}

// ─── Dark Auth Button ─────────────────────────────────────
class _DarkAuthButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const _DarkAuthButton({
    required this.child,
    this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  State<_DarkAuthButton> createState() => _DarkAuthButtonState();
}

class _DarkAuthButtonState extends State<_DarkAuthButton> {
  bool _hovered = false;

  static const _cyan = Color(0xFF06D6A0);
  static const _surface = Color(0xFF111827);
  static const _surfaceLight = Color(0xFF1A2236);
  static const _borderDim = Color(0xFF1E293B);
  static const _borderBright = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? (_hovered ? _cyan : _cyan.withValues(alpha: 0.9))
                : (_hovered ? _surfaceLight : _surface),
            borderRadius: BorderRadius.circular(10),
            border: isPrimary
                ? null
                : Border.all(
                    color: _hovered ? _borderBright : _borderDim,
                    width: 1,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: _cyan.withValues(alpha: _hovered ? 0.25 : 0.15),
                      blurRadius: _hovered ? 20 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : widget.child,
        ),
      ),
    );
  }
}

// ─── Google Logo Painter ──────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double cx = s / 2;
    final double cy = s / 2;
    final double r = s * 0.45;
    final double strokeW = s * 0.18;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.9, -1.2, false, paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.3, 1.2, false, paint,
    );

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.5, 1.0, false, paint,
    );

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      2.5, 1.0, false, paint,
    );

    // Horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx - s * 0.02, cy - strokeW / 2, r + strokeW / 2, strokeW),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
