/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/teacher_model.dart';
import '../models/admin_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get dashboard statistics
  Future<AdminDashboardStats> getDashboardStats() async {
    // Implement Firestore queries to get all metrics
    return AdminDashboardStats(
      totalUsers: 0,
      activeTeachers: 0,
      pendingVerifications: 0,
      premiumSubscribers: 0,
      totalStories: 0,
      dailyActiveUsers: 0,
    );
  }

  // Get all users
  Stream<List<User>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final role = data['role'] ?? 'student';

        if (role == 'teacher') {
          return Teacher.fromFirestore(doc);
        } else if (role == 'admin') {
          return AdminUser.fromFirestore(doc);
        } else {
          return Student.fromFirestore(doc);
        }
      }).toList();
    });
  }

  // Verify teacher CIN
  Future<void> verifyTeacher(String teacherId) async {
    await _firestore.collection('teachers').doc(teacherId).update({
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    // Add to activity log
    await logAdminAction(
      action: 'TEACHER_VERIFIED',
      details: {'teacherId': teacherId},
    );
  }

  // Log admin actions
  Future<void> logAdminAction({
    required String action,
    required Map<String, dynamic> details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('admin_logs').add({
      'adminId': user.uid,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
      'details': details,
    });
  }

  // Get pending teacher verifications
  Stream<List<Teacher>> getPendingVerifications() {
    return _firestore
        .collection('teachers')
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList(),
        );
  }
}

class AdminUser extends User {
  final List<String> permissions;

  AdminUser({
    required String id,
    required String email,
    required String displayName,
    required DateTime createdAt,
    required this.permissions,
  }) : super(
         id: id,
         email: email,
         displayName: displayName,
         createdAt: createdAt,
         role: 'admin',
       );

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      permissions: List<String>.from(data['permissions'] ?? []),
    );
  }
}*/
