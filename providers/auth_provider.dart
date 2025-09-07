import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/models/teacher_model.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/services/auth_service.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService = FirestoreService();

  String? _errorMessage;
  bool _isOffline = false;
  bool _isLoading = false;
  bool _isInitialized = false; // ✅ Added
  dynamic _currentUser;

  AuthProvider(this._authService) {
    _init();
  }

  // ✅ Getters
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  dynamic get currentUser => _currentUser;

  /// Initialize connectivity and restore session
  Future<void> _init() async {
    // Check initial connectivity
    _isOffline =
        (await Connectivity().checkConnectivity()) == ConnectivityResult.none;
    notifyListeners();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = _isOffline;
      _isOffline = result == ConnectivityResult.none;

      // Only notify if the state actually changed
      if (wasOffline != _isOffline) {
        debugPrint(
            "🌐 Connectivity changed: ${_isOffline ? 'OFFLINE' : 'ONLINE'}");
        notifyListeners();
      }
    });

    await _restoreSession();

    _isInitialized = true; // ✅ Mark as initialized
    notifyListeners();
  }

  void setCurrentUser(dynamic user) {
    _currentUser = user;
    notifyListeners();
  }

  // Restore Firebase session
  Future<void> _restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        try {
          await _authService.getAccessToken(forceRefresh: true);
          _currentUser = await _authService.getUserData(firebaseUser.uid);
        } catch (e) {
          print("Using cached user data: ${e.toString()}");
          _currentUser = await _authService.getCachedUserData(firebaseUser.uid);
        }

        if (_currentUser != null && _isValidUserData(_currentUser)) {
          await handleLoginStreak();
        } else {
          // Try to recover from corrupted data
          await _recoverFromCorruptedData();
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _errorMessage = "Session restore failed: ${e.toString()}";
      _currentUser = null;
      // Try to recover from corrupted data
      await _recoverFromCorruptedData();
    } finally {
      _isLoading = false;
    }
  }

  /// Recover from corrupted data by clearing and restarting
  Future<void> _recoverFromCorruptedData() async {
    try {
      debugPrint("🔄 Attempting to recover from corrupted data...");
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = "Session data was corrupted. Please log in again.";
      debugPrint("✅ Recovery completed - user signed out");
    } catch (e) {
      debugPrint("❌ Recovery failed: $e");
      _errorMessage = "Critical error. Please reinstall the app.";
    }
  }

  /// Validate user data integrity
  bool _isValidUserData(dynamic user) {
    if (user == null) return false;

    try {
      if (user is Student) {
        // Check if required fields are present and valid
        return user.uid.isNotEmpty &&
            user.email.isNotEmpty &&
            user.displayName.isNotEmpty &&
            user.gradeLevel > 0 &&
            user.age > 0;
      } else if (user is Teacher) {
        return user.id.isNotEmpty &&
            user.email.isNotEmpty &&
            user.displayName.isNotEmpty &&
            user.cin.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint("❌ User data validation failed: $e");
      return false;
    }
  }

  /// --- LOGIN STREAK LOGIC ---
  Future<void> handleLoginStreak() async {
    if (_currentUser is! Student) return;

    Student student = _currentUser as Student;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = DateTime(
      student.lastLoginDate.year,
      student.lastLoginDate.month,
      student.lastLoginDate.day,
    );

    if (lastLogin.isAtSameMomentAs(today)) return;

    int newStreak = student.loginStreak;
    int pointsToAdd = 0;
    final difference = today.difference(lastLogin).inDays;

    if (difference == 1) {
      newStreak++;
      if (newStreak >= 7) {
        pointsToAdd = 100;
        newStreak = 0;
        _errorMessage = 'STREAK_REWARD_100';
      } else {
        pointsToAdd = 10;
      }
    } else {
      newStreak = 1;
      pointsToAdd = 10;
    }

    await _firestoreService.updateUser(student.uid, {
      'lastLoginDate': Timestamp.fromDate(now),
      'loginStreak': newStreak,
      'points': FieldValue.increment(pointsToAdd),
    });

    _currentUser = student.copyWith(
      lastLoginDate: now,
      loginStreak: newStreak,
      points: student.points + pointsToAdd,
    );
    notifyListeners();
  }

  // --- Points, unlock stories, and other helper methods remain the same ---
  Future<void> addPoints(int pointsToAdd) async {
    if (_currentUser is Student && pointsToAdd > 0) {
      Student student = _currentUser as Student;
      try {
        await _firestoreService.addPointsToStudent(student.uid, pointsToAdd);
        _currentUser = student.copyWith(points: student.points + pointsToAdd);
        notifyListeners();
      } catch (e) {
        print("Could not add points: $e");
      }
    }
  }

  Future<bool> unlockStory(StoryModel story) async {
    if (_currentUser is Student) {
      Student student = _currentUser as Student;
      if (student.points < story.pointsToUnlock) {
        _errorMessage = "Not enough points to unlock this story!";
        notifyListeners();
        return false;
      }
      try {
        await _firestoreService.unlockStoryForStudent(
          studentId: student.uid,
          storyId: story.id,
          cost: story.pointsToUnlock,
        );
        _currentUser = student.copyWith(
          points: student.points - story.pointsToUnlock,
        );
        notifyListeners();
        return true;
      } catch (e) {
        _errorMessage = "Failed to unlock story: ${e.toString()}";
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<void> incrementStoriesRead() async {
    if (_currentUser is Student) {
      Student student = _currentUser as Student;
      Student updatedStudent = student.copyWith(
        storiesRead: student.storiesRead + 1,
      );
      try {
        await _firestoreService.updateUser(student.uid, {
          'storiesRead': updatedStudent.storiesRead,
        });
        _currentUser = updatedStudent;
        notifyListeners();
      } catch (e) {
        print("Could not update storiesRead count: $e");
      }
    }
  }

  // --- Authentication methods ---
  Future<void> signUpStudent({
    required String email,
    required String password,
    required String displayName,
    required int gradeLevel,
    required String schoolName,
    required int age,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _authService.signUpStudent(
        email: email,
        password: password,
        displayName: displayName,
        gradeLevel: gradeLevel,
        schoolName: schoolName,
        age: age,
      );
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
        await handleLoginStreak();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUpTeacher({
    required String email,
    required String password,
    required String displayName,
    required String cin,
    required String school,
    required String specialty,
    required String phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _authService.signUpTeacher(
        email: email,
        password: password,
        displayName: displayName,
        cin: cin,
        school: school,
        specialty: specialty,
        phoneNumber: phoneNumber,
      );
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (_currentUser != null) {
        await handleLoginStreak();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Logout failed: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
