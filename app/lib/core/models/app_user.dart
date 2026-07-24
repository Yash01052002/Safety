/// Represents an authenticated user of the app.
class AppUser {
  final String id;
  final String phone;
  final String name;
  final String? medicalNote;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.phone,
    required this.name,
    this.medicalNote,
    required this.createdAt,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      phone: map['phone'] as String? ?? '',
      name: map['name'] as String? ?? '',
      medicalNote: map['medicalNote'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'name': name,
        'medicalNote': medicalNote,
        'createdAt': createdAt.toIso8601String(),
      };
}
