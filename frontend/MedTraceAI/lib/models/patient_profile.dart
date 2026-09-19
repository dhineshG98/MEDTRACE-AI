class PatientProfile {
  final String patientId;
  final String name;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String phone;

  const PatientProfile({
    required this.patientId,
    required this.name,
    required this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.phone,
  });

  factory PatientProfile.defaultProfile() {
    return const PatientProfile(
      patientId: '',
      name: '',
      dob: '',
      gender: '',
      bloodGroup: '',
      phone: '',
    );
  }

  PatientProfile copyWith({
    String? patientId,
    String? name,
    String? dob,
    String? gender,
    String? bloodGroup,
    String? phone,
  }) {
    return PatientProfile(
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phone: phone ?? this.phone,
    );
  }
}
