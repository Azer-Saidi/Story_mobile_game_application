import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:storyapp/utils/type_helpers.dart';

class Student {
  final String uid;
  final String email;
  final String displayName;
  final int gradeLevel;
  final String schoolName;
  final DateTime createdAt;
  final int age;
  final int storiesRead;
  final int points;
  final DateTime lastLoginDate;
  final int loginStreak;
  // NOUVEAUX CHAMPS POUR LA LIMITE D'IA
  final int aiFeedbackCount;
  final Timestamp? lastFeedbackDate;

  // NEW: Avatar related fields
  final Map<String, int> avatarTraits; // e.g., {'helpful': 10, 'brave': 5}
  final String? selectedAvatarId; // The ID of the chosen avatar style
  final bool hasCompletedAvatarSetup; // To track if initial setup is done

  Student({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.gradeLevel,
    required this.schoolName,
    required this.createdAt,
    required this.age,
    this.storiesRead = 0,
    this.points = 0,
    required this.lastLoginDate,
    this.loginStreak = 0,
    // NOUVEAUX CHAMPS
    this.aiFeedbackCount = 0,
    this.lastFeedbackDate,
    // NEW: Avatar related fields
    this.avatarTraits = const {
      'helpful': 0,
      'brave': 0,
      'kind': 0,
      'curious': 0,
      'creative': 0,
      'honest': 0,
    },
    this.selectedAvatarId,
    this.hasCompletedAvatarSetup = false,
  });

  Student copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? gradeLevel,
    String? schoolName,
    DateTime? createdAt,
    int? age,
    int? storiesRead,
    int? points,
    DateTime? lastLoginDate,
    int? loginStreak,
    // NOUVEAUX CHAMPS
    int? aiFeedbackCount,
    Timestamp? lastFeedbackDate,
    // NEW: Avatar related fields
    Map<String, int>? avatarTraits,
    String? selectedAvatarId,
    bool? hasCompletedAvatarSetup,
  }) {
    return Student(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      schoolName: schoolName ?? this.schoolName,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      storiesRead: storiesRead ?? this.storiesRead,
      points: points ?? this.points,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      loginStreak: loginStreak ?? this.loginStreak,
      // NOUVEAUX CHAMPS
      aiFeedbackCount: aiFeedbackCount ?? this.aiFeedbackCount,
      lastFeedbackDate: lastFeedbackDate ?? this.lastFeedbackDate,
      // NEW: Avatar related fields
      avatarTraits: avatarTraits ?? this.avatarTraits,
      selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
      hasCompletedAvatarSetup:
          hasCompletedAvatarSetup ?? this.hasCompletedAvatarSetup,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'gradeLevel': gradeLevel,
      'schoolName': schoolName,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': 'student',
      'age': age,
      'storiesRead': storiesRead,
      'points': points,
      'lastLoginDate': Timestamp.fromDate(lastLoginDate),
      'loginStreak': loginStreak,
      // NOUVEAUX CHAMPS
      'aiFeedbackCount': aiFeedbackCount,
      'lastFeedbackDate': lastFeedbackDate,
      // NEW: Avatar related fields
      'avatarTraits': avatarTraits,
      'selectedAvatarId': selectedAvatarId,
      'hasCompletedAvatarSetup': hasCompletedAvatarSetup,
    };
  }

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Student(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Student',
      gradeLevel: (data['gradeLevel'] as num?)?.toInt() ?? 0,
      schoolName: data['schoolName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      age: (data['age'] as num?)?.toInt() ?? 0,
      storiesRead: (data['storiesRead'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 0,
      lastLoginDate:
          (data['lastLoginDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      loginStreak: (data['loginStreak'] as num?)?.toInt() ?? 0,
      // NOUVEAUX CHAMPS
      aiFeedbackCount: (data['aiFeedbackCount'] as num?)?.toInt() ?? 0,
      lastFeedbackDate: data['lastFeedbackDate'] as Timestamp?,
      // NEW: Avatar related fields
      avatarTraits: TypeHelpers.toIntMap(data['avatarTraits']),
      selectedAvatarId: data['selectedAvatarId'] as String?,
      hasCompletedAvatarSetup:
          data['hasCompletedAvatarSetup'] as bool? ?? false,
    );
  }

  factory Student.fromMap(Map<String, dynamic> data) {
    return Student(
      uid: data['uid'] ?? const Uuid().v4(),
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Student',
      gradeLevel: (data['gradeLevel'] as num?)?.toInt() ?? 0,
      schoolName: data['schoolName'] ?? '',

      // UTILISATION DE L'UTILITAIRE ROBUSTE
      createdAt: TypeHelpers.toDateTime(data['createdAt']) ?? DateTime.now(),
      lastLoginDate:
          TypeHelpers.toDateTime(data['lastLoginDate']) ?? DateTime.now(),

      age: (data['age'] as num?)?.toInt() ?? 0,
      storiesRead: (data['storiesRead'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 0,
      loginStreak: (data['loginStreak'] as num?)?.toInt() ?? 0,

      aiFeedbackCount: (data['aiFeedbackCount'] as num?)?.toInt() ?? 0,

      // UTILISATION DE L'UTILITAIRE ROBUSTE
      lastFeedbackDate: TypeHelpers.toTimestamp(data['lastFeedbackDate']),
      // NEW: Avatar related fields
      avatarTraits: TypeHelpers.toIntMap(data['avatarTraits']),
      selectedAvatarId: data['selectedAvatarId'] as String?,
      hasCompletedAvatarSetup:
          data['hasCompletedAvatarSetup'] as bool? ?? false,
    );
  }

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty)
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (displayName.length >= 2)
      return displayName.substring(0, 2).toUpperCase();
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    return 'S';
  }

  String get generatedAvatarUrl {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=random&size=128';
  }

  // NEW: Get total trait points
  int get totalTraitPoints {
    return avatarTraits.values.fold(0, (sum, element) => sum + element);
  }

  // NEW: Get dominant trait
  String get dominantTrait {
    if (avatarTraits.isEmpty) return 'curious'; // Default trait

    String dominant = 'curious';
    int maxPoints = -1;

    avatarTraits.forEach((trait, points) {
      if (points > maxPoints) {
        maxPoints = points;
        dominant = trait;
      }
    });
    return dominant;
  }

  // NEW: Get trait percentages for visualization
  Map<String, double> get traitPercentages {
    final total = totalTraitPoints;
    if (total == 0) return {};
    return avatarTraits.map((key, value) => MapEntry(key, value / total));
  }

  @override
  String toString() {
    return 'Student(uid: $uid, points: $points, loginStreak: $loginStreak, avatarTraits: $avatarTraits)';
  }
}
