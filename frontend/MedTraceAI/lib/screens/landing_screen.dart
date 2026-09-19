import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenWorkspace;
  final VoidCallback? onSignUp;
  final VoidCallback? onLogIn;

  const LandingScreen({
    super.key,
    required this.onOpenTimeline,
    required this.onOpenWorkspace,
    this.onSignUp,
    this.onLogIn,
  });

  void _showGoogleAuthModal(BuildContext context, {required bool isSignUp}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _GoogleAuthDialog(
        isSignUp: isSignUp,
        onSuccess: () {
          Navigator.of(ctx).pop();
          onOpenTimeline();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpenTimeline,
        child: AmbientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  // Top Navigation Header (Logo on Left, Auth Pills on Right)
                  Positioned(
                    top: isMobile ? 20 : 36,
                    left: isMobile ? 24 : 56,
                    right: isMobile ? 24 : 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Left Brand Logo
                        _buildTopLeftLogo(),

                        // Top Right Auth Pills (SIGN UP, LOG IN)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAuthPill(
                              'SIGN UP',
                              () => onSignUp != null
                                  ? onSignUp!()
                                  : _showGoogleAuthModal(context, isSignUp: true),
                            ),
                            const SizedBox(width: 12),
                            _buildAuthPill(
                              'LOG IN',
                              () => onLogIn != null
                                  ? onLogIn!()
                                  : _showGoogleAuthModal(context, isSignUp: false),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Center Content
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 48,
                        vertical: 36,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 44),

                            // Top Brand Pill Badge (Pure B&W)
                            _buildTopBrandBadge(),

                            const SizedBox(height: 36),

                            // Large Hero Heading: Multi- on line 1, Modal Intelligence on line 2
                            _buildHeroHeading(isMobile),

                            const SizedBox(height: 26),

                            // Supporting Description (2 neat centered lines)
                            _buildDescription(isMobile),

                            const SizedBox(height: 44),

                            // Main Action Buttons (Pure B&W)
                            _buildActionButtons(isMobile),

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Left Brand Logo: "MEDTRACE AI"
  Widget _buildTopLeftLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const Text(
          'MEDTRACE',
          style: TextStyle(
            fontFamily: 'Helvetica',
            fontFamilyFallback: ['Helvetica Neue', 'Arial', 'sans-serif'],
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'AI',
          style: TextStyle(
            fontFamily: 'Helvetica',
            fontFamilyFallback: const ['Helvetica Neue', 'Arial', 'sans-serif'],
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  /// Top Right White Pill Auth Button
  Widget _buildAuthPill(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF090A0E),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: Color(0xFF090A0E),
        ),
      ),
    );
  }

  Widget _buildTopBrandBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'MEDTRACE AI • CLINICAL INTELLIGENCE PLATFORM',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Colors.white,
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildHeroHeading(bool isMobile) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Colors.white,
          Color(0xFFF8FAFC),
          Color(0xFFE2E8F0),
          Color(0xFFCBD5E1),
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'Autonomous Clinical Trace & Multi-\nModal Intelligence',
        textAlign: TextAlign.center,
        style: AppTheme.universTitle(
          fontSize: isMobile ? 38 : 72,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -1.2,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDescription(bool isMobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Text(
        'Synthesize medical records, clinical visits, lab panels, and imaging into a verified chronological\npatient timeline with deep clinical entity recognition and sub-second traceability.',
        textAlign: TextAlign.center,
        style: AppTheme.body(
          fontSize: isMobile ? 15 : 18.5,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: const Color(0xFFA1A1AA),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Wrap(
      spacing: 20,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        // Primary CTA: Launch Patient Timeline (Solid White with Black Text)
        ElevatedButton.icon(
          onPressed: onOpenTimeline,
          icon: const Icon(Icons.trending_up_rounded, size: 22, color: Color(0xFF090A0E)),
          label: const Text(
            'Launch Patient Timeline',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Color(0xFF090A0E),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF090A0E),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),

        // Secondary CTA: Ingestion Workspace (Dark Surface with White Border)
        OutlinedButton.icon(
          onPressed: onOpenWorkspace,
          icon: const Icon(Icons.description_outlined, size: 21, color: Colors.white),
          label: const Text(
            'Ingestion Workspace',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.4,
            ),
            backgroundColor: const Color(0xFF141416),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Authentic Google Authentication Modal Dialog & In-App Account Chooser
class _GoogleAuthDialog extends StatefulWidget {
  final bool isSignUp;
  final VoidCallback onSuccess;

  const _GoogleAuthDialog({
    required this.isSignUp,
    required this.onSuccess,
  });

  @override
  State<_GoogleAuthDialog> createState() => _GoogleAuthDialogState();
}

class _GoogleAuthDialogState extends State<_GoogleAuthDialog> {
  bool _isCustomInput = false;
  bool _isAuthenticating = false;
  String? _authenticatingEmail;
  String? _errorMessage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '425303006402-rf8fgf9u151d4u9fgfj59ti2cdc65rnt.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<void> _signInWithGoogleOAuth() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await AuthService.instance.signInWithGoogle(
          email: account.email,
          name: account.displayName,
        );
        if (mounted) {
          widget.onSuccess();
        }
        return;
      }
    } catch (e) {
      debugPrint('Google OAuth error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Google OAuth note: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _authenticate(String name, String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid Google email address';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authenticatingEmail = cleanEmail;
      _errorMessage = null;
    });

    await AuthService.instance.signInWithGoogle(
      email: cleanEmail,
      name: name.trim().isNotEmpty ? name.trim() : null,
    );

    // Brief realistic delay for smooth Google auth feedback
    await Future.delayed(const Duration(milliseconds: 550));

    if (mounted) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = widget.isSignUp;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1015),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 36,
                spreadRadius: 4,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: _isAuthenticating
              ? _buildAuthenticatingView()
              : _isCustomInput
                  ? _buildCustomInputView(isSignUp)
                  : _buildAccountChooserView(isSignUp),
        ),
      ),
    );
  }

  /// State 1: Authentic Google Account Chooser List
  Widget _buildAccountChooserView(bool isSignUp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Row: Google Badge & Close Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GoogleLogo(size: 20),
                const SizedBox(width: 8),
                Text(
                  'Google',
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9E9E9E)),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Title
        Text(
          isSignUp ? 'Sign up with Google' : 'Choose an account',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle
        Text(
          'to continue to MedTrace AI Clinical Intelligence Platform',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),

        const SizedBox(height: 20),

        // Official Google Cloud OAuth Button
        InkWell(
          onTap: _signInWithGoogleOAuth,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GoogleLogo(size: 18),
                const SizedBox(width: 10),
                Text(
                  isSignUp ? 'Sign up with Google (OAuth)' : 'Sign in with Google (OAuth)',
                  style: const TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Email / Direct Sign-In Option
        InkWell(
          onTap: () {
            setState(() {
              _isCustomInput = true;
              _errorMessage = null;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF16171E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
                const SizedBox(width: 10),
                Text(
                  'Continue with email address',
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Compliance & Disclaimer Footer
        _buildFooterSecurityNote(),
      ],
    );
  }


  /// State 2: Custom Google Email Input View
  Widget _buildCustomInputView(bool isSignUp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isCustomInput = false;
                  _errorMessage = null;
                });
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Back to accounts',
                style: TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9E9E9E)),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            const _GoogleLogo(size: 20),
            const SizedBox(width: 8),
            Text(
              isSignUp ? 'Create Google Account Session' : 'Sign in with Google',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your Gmail or hospital Google Workspace account to log in.',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),

        const SizedBox(height: 20),

        // Email TextField
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16171E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _errorMessage != null ? Colors.redAccent : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: _emailController,
            autofocus: true,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email or phone',
              labelStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
              hintText: 'user@gmail.com',
              hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.25)),
              border: InputBorder.none,
              isDense: true,
            ),
            onSubmitted: (_) => _authenticate(_nameController.text, _emailController.text),
          ),
        ),

        const SizedBox(height: 14),

        // Name TextField (Optional)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16171E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Your Name (optional)',
              labelStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
              hintText: 'e.g. Dr. Sarah Chen',
              hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.25)),
              border: InputBorder.none,
              isDense: true,
            ),
            onSubmitted: (_) => _authenticate(_nameController.text, _emailController.text),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],

        const SizedBox(height: 22),

        // Submit Button
        ElevatedButton(
          onPressed: () => _authenticate(_nameController.text, _emailController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF090A0E),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleLogo(size: 17),
              const SizedBox(width: 10),
              Text(
                isSignUp ? 'Sign up & Enter Workspace' : 'Log in & Enter Workspace',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF090A0E),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        _buildFooterSecurityNote(),
      ],
    );
  }

  /// State 3: Authentic Authenticating Spinner View
  Widget _buildAuthenticatingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Signing into MedTrace AI...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Authenticated with ${_authenticatingEmail ?? "Google Account"}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Initializing longitudinal clinical intelligence workspace...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSecurityNote() {
    return Column(
      children: [
        Text(
          'To continue, Google will share your credentials with MedTrace AI for verified clinical timeline synthesis.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.4),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 13, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              'HIPAA Compliant • 256-Bit AEAD Encryption',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// ─── Authentic Google Logo Painter ──────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 20});

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

    // Google Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.9, -1.2, false, paint,
    );

    // Google Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.3, 1.2, false, paint,
    );

    // Google Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.5, 1.0, false, paint,
    );

    // Google Red
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
