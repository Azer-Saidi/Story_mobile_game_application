import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// You must import your actual model files here for the service to work.
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/models/teacher_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Connectivity _connectivity = Connectivity();

  // Keys for secure storage
  static const _tokenKey = 'auth_token';
  static const _userKey = 'cached_user';
  static const _cachedUidKey = 'cached_uid';

  /// Checks if the device has an active internet connection.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Gets the currently authenticated Firebase user, if any.
  User? get currentUser => _auth.currentUser;

  /// Retrieves the Firebase authentication token for the current user.
  /// Handles fetching a new token if online or returning a cached one if offline.
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (currentUser == null) return null;

    if (await isOnline) {
      try {
        final token = await currentUser!.getIdToken(forceRefresh);
        await _secureStorage.write(key: _tokenKey, value: token);
        return token;
      } catch (e) {
        print("Error getting access token: $e");
        // If online but token refresh fails, try to use the cached token as a fallback.
        return _secureStorage.read(key: _tokenKey);
      }
    } else {
      // If offline, return the cached token.
      return _secureStorage.read(key: _tokenKey);
    }
  }

  // Add this method to your existing AuthService class
  Future<dynamic> getCachedUserData(String uid) async {
    try {
      final cachedData = await _secureStorage.read(key: _userKey);
      if (cachedData != null) {
        final restoredData = _restoreTimestamps(jsonDecode(cachedData));
        return _parseUserData(restoredData);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get cached user data: ${e.toString()}");
    }
  }

  /// Recursively converts Firestore Timestamps to integers (millisecondsSinceEpoch) for JSON serialization.
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      }
      if (value is Map) {
        return MapEntry(key, _convertTimestamps(value as Map<String, dynamic>));
      }
      if (value is List) {
        return MapEntry(
            key,
            value
                .map((item) => (item is Map)
                    ? _convertTimestamps(item as Map<String, dynamic>)
                    : item)
                .toList());
      }
      return MapEntry(key, value);
    });
  }

  /// Recursively restores integer timestamps back to Firestore Timestamps after JSON deserialization.
  Map<String, dynamic> _restoreTimestamps(Map<String, dynamic> data) {
    final timestampKeys = [
      'createdAt',
      'lastLoginDate',
      'lastFeedbackDate',
      'timestamp',
      'submittedAt'
    ];

    return data.map((key, value) {
      if (value is int && timestampKeys.contains(key)) {
        return MapEntry(key, Timestamp.fromMillisecondsSinceEpoch(value));
      }
      if (value is Map) {
        return MapEntry(key, _restoreTimestamps(value as Map<String, dynamic>));
      }
      if (value is List) {
        return MapEntry(
            key,
            value
                .map((item) => (item is Map)
                    ? _restoreTimestamps(item as Map<String, dynamic>)
                    : item)
                .toList());
      }
      return MapEntry(key, value);
    });
  }

  /// Fetches user data from Firestore if online, otherwise retrieves it from the local cache.
  Future<dynamic> getUserData(String uid) async {
    try {
      if (uid.isEmpty) return null;

      // If online, always try to fetch fresh data from Firestore.
      if (await isOnline) {
        try {
          final doc = await _firestore.collection("users").doc(uid).get();
          if (doc.exists && doc.data() != null) {
            // Cache the data for offline use.
            await _cacheUserData(uid, _convertTimestamps(doc.data()!));
            // Parse the original data with Timestamps intact.
            return _parseUserData(doc.data()!);
          }
        } catch (e) {
          print("Error fetching user data online: $e. Falling back to cache.");
        }
      }

      // If offline or if the online fetch failed, use cached data.
      final cachedUid = await _secureStorage.read(key: _cachedUidKey);
      if (cachedUid == uid) {
        final cachedData = await _secureStorage.read(key: _userKey);
        if (cachedData != null) {
          final restoredData = _restoreTimestamps(jsonDecode(cachedData));
          return _parseUserData(restoredData);
        }
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get user data: ${e.toString()}");
    }
  }

  /// Parses a map of user data into a `Student` or `Teacher` object based on the 'role' field.
  dynamic _parseUserData(Map<String, dynamic> data) {
    final role = data['role']?.toString().toLowerCase();
    if (role == 'student') return Student.fromMap(data);
    if (role == 'teacher') return Teacher.fromMap(data);
    print("Warning: Could not parse user data. Unknown or missing role.");
    return null;
  }

  /// Caches the user's UID and data into secure storage.
  Future<void> _cacheUserData(String uid, Map<String, dynamic> data) async {
    await Future.wait([
      _secureStorage.write(key: _cachedUidKey, value: uid),
      _secureStorage.write(key: _userKey, value: jsonEncode(data)),
    ]);
  }

  /// Signs up a new student, creates a user record in Firestore, and caches the data.
  Future<void> signUpStudent({
    required String email,
    required String password,
    required String displayName,
    required int gradeLevel,
    required String schoolName,
    required int age,
  }) async {
    if (!await isOnline) throw _networkException();

    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;
    if (user == null) throw Exception("User creation failed.");

    final student = Student(
      uid: user.uid,
      email: email,
      displayName: displayName,
      gradeLevel: gradeLevel,
      schoolName: schoolName,
      createdAt: DateTime.now(),
      age: age,
      lastLoginDate: DateTime.now(),
      hasCompletedAvatarSetup: false, // Explicitly set this field
    );

    await _firestore.collection('users').doc(student.uid).set(student.toMap());
    await _cacheUserData(student.uid, _convertTimestamps(student.toMap()));
  }

  /// Signs up a new teacher, creates a user record in Firestore, and caches the data.
  Future<void> signUpTeacher({
    required String email,
    required String password,
    required String displayName,
    required String cin,
    required String school,
    required String specialty,
    required String phoneNumber,
  }) async {
    if (!await isOnline) throw _networkException();

    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;
    if (user == null) throw Exception("User creation failed.");

    final teacher = Teacher(
      id: user.uid,
      email: email,
      displayName: displayName,
      cin: cin,
      school: school,
      specialty: specialty,
      createdAt: DateTime.now(),
      phoneNumber: phoneNumber,
    );

    await _firestore.collection('users').doc(teacher.id).set(teacher.toMap());
    await _cacheUserData(teacher.id, _convertTimestamps(teacher.toMap()));
  }

  /// Signs in a user with email and password. Handles both online and offline scenarios.
  Future<dynamic> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (await isOnline) {
      // Online: sign in with Firebase and fetch/update user data.
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return currentUser != null ? await getUserData(currentUser!.uid) : null;
    } else {
      // Offline: check for cached credentials.
      final cachedData = await _secureStorage.read(key: _userKey);
      if (cachedData != null) {
        final decodedData = jsonDecode(cachedData);
        // This is a simplified offline check. It does NOT verify the password.
        if (decodedData['email'] == email) {
          print("Authenticated offline for ${decodedData['email']}");
          final restoredData = _restoreTimestamps(decodedData);
          return _parseUserData(restoredData);
        }
      }
      throw _networkException(
          "Offline login failed: No cached credentials for this user.");
    }
  }

  /// Signs out the current user and clears all cached data.
  Future<void> signOut() async {
    await _auth.signOut();
    await _secureStorage.deleteAll();
  }

  /// Sends a password reset email to the specified address.
  Future<void> resetPassword(String email) async {
    if (!await isOnline) throw _networkException();
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Creates a standard exception for network-related errors.
  FirebaseAuthException _networkException([String? message]) =>
      FirebaseAuthException(
        code: 'network-request-failed',
        message: message ?? 'This operation requires an internet connection.',
      );
}
