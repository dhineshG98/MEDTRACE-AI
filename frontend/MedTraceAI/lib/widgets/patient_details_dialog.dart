import 'package:flutter/material.dart';
import '../models/patient_profile.dart';

class PatientDetailsDialog extends StatefulWidget {
  final PatientProfile initialProfile;
  final ValueChanged<PatientProfile> onSave;

  const PatientDetailsDialog({
    super.key,
    required this.initialProfile,
    required this.onSave,
  });

  @override
  State<PatientDetailsDialog> createState() => _PatientDetailsDialogState();
}

class _PatientDetailsDialogState extends State<PatientDetailsDialog> {
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late String _selectedGender;
  late String _selectedBloodGroup;

  final List<String> _genders = const ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = const ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialProfile.patientId);
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _dobController = TextEditingController(text: widget.initialProfile.dob);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
    _selectedGender = widget.initialProfile.gender.isNotEmpty ? widget.initialProfile.gender : 'Male';
    _selectedBloodGroup = widget.initialProfile.bloodGroup.isNotEmpty ? widget.initialProfile.bloodGroup : 'O+';
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final patientId = _idController.text.trim().isNotEmpty
        ? _idController.text.trim()
        : 'PID-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Patient Record';

    final updated = PatientProfile(
      patientId: patientId,
      name: name,
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      phone: _phoneController.text.trim(),
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 780),
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
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: Color(0xFF090A0E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Patient Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Link demographic records to multi-modal document extraction pipeline',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFA1A1AA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFFA1A1AA)),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient ID and Name Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              label: 'Patient ID',
                              controller: _idController,
                              hint: 'PAT-0001',
                              icon: Icons.tag_rounded,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              label: 'Full Name',
                              controller: _nameController,
                              hint: 'Arun Kumar',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // DOB and Phone Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Date of Birth (DOB)',
                              controller: _dobController,
                              hint: '15-06-1998',
                              icon: Icons.calendar_today_rounded,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              hint: 'XXXXX XXXXX',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Gender Selector
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4D4D8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _genders.map((g) {
                          final isSelected = _selectedGender == g;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(g),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedGender = g);
                              },
                              selectedColor: Colors.white,
                              backgroundColor: const Color(0xFF141418),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF090A0E) : Colors.white,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.18),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Blood Group Selector
                      const Text(
                        'Blood Group',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4D4D8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bloodGroups.map((bg) {
                          final isSelected = _selectedBloodGroup == bg;
                          return ChoiceChip(
                            label: Text(bg),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedBloodGroup = bg);
                            },
                            selectedColor: Colors.white,
                            backgroundColor: const Color(0xFF141418),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF090A0E) : Colors.white,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.18),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Trajectory Pipeline Visualization Card
                      _buildPipelineCard(),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12.5)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text(
                        'Save & Link Trajectory',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF090A0E),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD4D4D8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 16, color: Colors.white70),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF71717A)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineCard() {
    final patientId = _idController.text.trim().isEmpty ? 'PAT-0001' : _idController.text.trim();
    final patientName = _nameController.text.trim().isEmpty ? 'Arun Kumar' : _nameController.text.trim();
    final dob = _dobController.text.trim().isEmpty ? '15-06-1998' : _dobController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF090A0E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Clinical Trajectory Pipeline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Auto-Synthesizing',
                  style: TextStyle(fontSize: 10, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Step 1: Patient Details
          _buildPipelineStep(
            icon: Icons.person_rounded,
            title: 'Patient Profile: $patientId • $patientName',
            subtitle: 'DOB: $dob | Gender: $_selectedGender | Blood: $_selectedBloodGroup',
            isTop: true,
          ),

          // Arrow Down
          _buildPipelineArrow(),

          // Step 2: Medical Documents
          _buildPipelineStep(
            icon: Icons.folder_shared_outlined,
            title: 'Medical Documents Ingestion',
            subtitle: '├── 🧪 Lab Report\n├── 💊 Prescription\n├── 📋 Discharge Summary\n└── 🩻 Imaging Report',
            isTree: true,
          ),

          // Arrow Down
          _buildPipelineArrow(),

          // Step 3: Unified Timeline
          _buildPipelineStep(
            icon: Icons.timeline_rounded,
            title: 'Unified Patient Timeline',
            subtitle: 'Chronological events linked to $patientId with neural entity verification',
            isBottom: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isTop = false,
    bool isBottom = false,
    bool isTree = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isTop || isBottom)
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF090A0E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: isTree ? 'Courier' : null,
                    color: const Color(0xFFA1A1AA),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 18),
      child: Center(
        child: Icon(
          Icons.arrow_downward_rounded,
          size: 14,
          color: Color(0xFF71717A),
        ),
      ),
    );
  }
}
