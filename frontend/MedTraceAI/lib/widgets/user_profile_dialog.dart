import 'package:flutter/material.dart';
import '../models/patient_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Comprehensive Account & Clinician Profile Dialog
class UserProfileDialog extends StatefulWidget {
  final PatientProfile currentPatient;
  final VoidCallback onOpenPatientProfile;
  final VoidCallback? onSignOut;

  const UserProfileDialog({
    super.key,
    required this.currentPatient,
    required this.onOpenPatientProfile,
    this.onSignOut,
  });

  static Future<void> show(
    BuildContext context, {
    required PatientProfile currentPatient,
    required VoidCallback onOpenPatientProfile,
    VoidCallback? onSignOut,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => UserProfileDialog(
        currentPatient: currentPatient,
        onOpenPatientProfile: onOpenPatientProfile,
        onSignOut: onSignOut,
      ),
    );
  }

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _licenseController;
  late TextEditingController _hospitalController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    final initialName = user?.name ?? 'Dr. R. Latha';
    _nameController = TextEditingController(text: initialName);
    _specialtyController = TextEditingController(text: 'Attending Physician & Clinical Intelligence');
    _licenseController = TextEditingController(text: 'MD-84291-MED');
    _hospitalController = TextEditingController(text: 'MedTrace AI Healthcare System');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final user = AuthService.instance.currentUser;
    final email = user?.email ?? 'rlatha@hospital.org';
    final updatedName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Dr. Clinician';

    await AuthService.instance.signInWithGoogle(
      email: email,
      name: updatedName,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated for $updatedName',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFF141418),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (user?.name ?? 'Dr. R. Latha');
    final email = user?.email ?? 'rlatha@hospital.org';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Container(
        width: 540,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1118),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              spreadRadius: 4,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF161924),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.account_circle_rounded,
                        color: AppColors.cyan,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account & Clinician Profile',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Helvetica',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Provider credentials & clinical account settings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),

              // Body content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Identity Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1B2030),
                              const Color(0xFF131722),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppColors.cyan,
                                  child: CircleAvatar(
                                    radius: 34,
                                    backgroundColor: const Color(0xFF0F1118),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.cyan,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF0F1118), width: 2.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() => _isEditing = !_isEditing);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                                                size: 13,
                                                color: Colors.white70,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _isEditing ? 'Cancel' : 'Edit',
                                                style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF10B981)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Verified Medical Clinician Session',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161924),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EDIT ACCOUNT DETAILS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cyan,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInputField('Clinician Full Name', _nameController, Icons.person_rounded),
                              const SizedBox(height: 12),
                              _buildInputField('Specialty / Department', _specialtyController, Icons.medical_services_rounded),
                              const SizedBox(height: 12),
                              _buildInputField('License / Provider ID', _licenseController, Icons.badge_rounded),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() => _isEditing = false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    icon: _isSaving
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                        : const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Save Changes'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cyan,
                                      foregroundColor: Colors.black,
                                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Linked Patient Record Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141620),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.personal_injury_rounded, color: Color(0xFFA78BFA), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Patient Record',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white54,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.currentPatient.name.isNotEmpty
                                        ? widget.currentPatient.name
                                        : 'Patient Record (${widget.currentPatient.patientId})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${widget.currentPatient.patientId} • Blood: ${widget.currentPatient.bloodGroup}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onOpenPatientProfile();
                              },
                              icon: const Icon(Icons.edit_note_rounded, size: 16),
                              label: const Text('Edit Patient'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFA78BFA),
                                side: BorderSide(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Session & Security Controls
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141620),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.switch_account_rounded, size: 18, color: Colors.white),
                              ),
                              title: const Text(
                                'Switch Clinician Account',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Connect with a different Google or institutional email',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white54),
                              onTap: () async {
                                Navigator.of(context).pop();
                                if (widget.onSignOut != null) {
                                  widget.onSignOut!();
                                }
                              },
                            ),
                            Divider(color: Colors.white.withValues(alpha: 0.08), height: 16),
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFF87171)),
                              ),
                              title: const Text(
                                'Sign Out of Session',
                                style: TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Securely terminate this browser session',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFF87171)),
                              onTap: () async {
                                Navigator.of(context).pop();
                                await AuthService.instance.signOut();
                                if (widget.onSignOut != null) {
                                  widget.onSignOut!();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF12141E),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MedTrace AI Security • HIPAA-Ready',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1118),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 16, color: AppColors.cyan),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
