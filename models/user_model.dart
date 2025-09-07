import 'package:cloud_firestore/cloud_firestore.dart';

abstract class User {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  String get role;
}

class Student extends User {
  final int gradeLevel;
  final List<String> completedStories;

  Student({
    required super.id,
    required super.email,
    required super.displayName,
    required super.createdAt,
    required this.gradeLevel,
    this.completedStories = const [], required String uid, required String schoolName, required int age,
  });

  @override
  String get role => 'student';
}

class Teacher extends User {
  final String school;
  final String specialty;

  Teacher({
    required super.id,
    required super.email,
    required super.displayName,
    required super.createdAt,
    required this.school,
    required this.specialty,
  });

  @override
  String get role => 'teacher';

  static fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {}
}
