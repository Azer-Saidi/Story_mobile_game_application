class AdminDashboardStats {
  final int totalUsers;
  final int activeTeachers;
  final int pendingVerifications;
  final int premiumSubscribers;
  final int totalStories;
  final int dailyActiveUsers;

  AdminDashboardStats({
    required this.totalUsers,
    required this.activeTeachers,
    required this.pendingVerifications,
    required this.premiumSubscribers,
    required this.totalStories,
    required this.dailyActiveUsers,
  });
}

class UserActivityLog {
  final String userId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  UserActivityLog({
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.details,
  });
}
class AdminModel {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  // Serialize to Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'role': 'admin',
    };
  }

  // Deserialize from Firestore
  factory AdminModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AdminModel(
      id: id,
      email: data['email'],
      displayName: data['displayName'],
      createdAt: DateTime.parse(data['createdAt']),
    );
  }
}
