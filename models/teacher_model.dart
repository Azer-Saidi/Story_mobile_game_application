import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:storyapp/utils/type_helpers.dart';

class Teacher {
  final String id; // This will be the Firebase Auth UID
  final String email;
  final String displayName;
  final String cin;
  final String school;
  final String specialty;
  final DateTime createdAt;
  final bool isVerified;
  final String avatarUrl;
  final String phoneNumber;
  final List<String> createdStoryIds;

  Teacher({
    required this.id,
    required this.email,
    required this.displayName,
    required this.cin,
    required this.school,
    required this.specialty,
    required this.createdAt,
    this.isVerified = false,
    this.avatarUrl = '',
    this.phoneNumber = '',
    this.createdStoryIds = const [],
  });

  Teacher copyWith({
    String? id,
    String? email,
    String? displayName,
    String? cin,
    String? school,
    String? specialty,
    DateTime? createdAt,
    bool? isVerified,
    String? avatarUrl,
    String? phoneNumber,
    List<String>? createdStoryIds,
  }) {
    return Teacher(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      cin: cin ?? this.cin,
      school: school ?? this.school,
      specialty: specialty ?? this.specialty,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdStoryIds: createdStoryIds ?? this.createdStoryIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'cin': cin,
      'school': school,
      'specialty': specialty,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'createdStoryIds': createdStoryIds,
      'role': 'teacher',
    };
  }

  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Teacher(
      id: doc.id, // Use the document ID as the teacher's ID
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      cin: data['cin'] ?? '',
      school: data['school'] ?? '',
      specialty: data['specialty'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      avatarUrl: data['avatarUrl'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      createdStoryIds: List<String>.from(data['createdStoryIds'] ?? []),
    );
  }

  factory Teacher.fromMap(Map<String, dynamic> data) {
    return Teacher(
      id: data['id'] ?? const Uuid().v4(),
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      cin: data['cin'] ?? '',
      school: data['school'] ?? '',
      specialty: data['specialty'] ?? '',

      // UTILISATION DE L'UTILITAIRE ROBUSTE
      createdAt: TypeHelpers.toDateTime(data['createdAt']) ?? DateTime.now(),

      isVerified: data['isVerified'] ?? false,
      avatarUrl: data['avatarUrl'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      createdStoryIds: List<String>.from(data['createdStoryIds'] ?? []),
    );
  }
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (displayName.isNotEmpty) {
      return displayName.substring(0, 2).toUpperCase();
    }
    return 'T';
  }

  String get generatedAvatarUrl {
    return 'https://ui-avatars.com/api/?name=$initials&background=random&size=128';
  }

  @override
  String toString() {
    return 'Teacher(id: $id, email: $email, displayName: $displayName, '
        'cin: $cin, school: $school, specialty: $specialty, '
        'createdAt: $createdAt, isVerified: $isVerified, '
        'avatarUrl: $avatarUrl, phoneNumber: $phoneNumber, '
        'createdStoryIds: $createdStoryIds)';
  }
}
