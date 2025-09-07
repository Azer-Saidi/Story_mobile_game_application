import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/models/summary_model.dart';
import 'package:storyapp/models/teacher_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== AI USAGE LIMIT FUNCTION ==========

  // Daily AI usage limit, set to 2.
  static const int dailyAILimit = 2;

  /// Checks if a student can use the AI feedback feature.
  /// If usage is allowed, this method also updates the student's counter.
  /// Returns `true` if the student is allowed, otherwise `false`.
  Future<bool> canUseAIFeature(String studentId) async {
    // The document reference is in the 'users' collection.
    final studentRef = _db.collection('users').doc(studentId);

    try {
      final doc = await studentRef.get();
      if (!doc.exists) {
        print('Error: Student document not found for ID: $studentId');
        return false; // Student does not exist, block access.
      }

      final studentData = doc.data() as Map<String, dynamic>;
      final int currentCount = studentData['aiFeedbackCount'] ?? 0;
      final Timestamp? lastDate = studentData['lastFeedbackDate'] as Timestamp?;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime? lastUsageDay;
      if (lastDate != null) {
        final lastUsage = lastDate.toDate();
        lastUsageDay = DateTime(lastUsage.year, lastUsage.month, lastUsage.day);
      }

      // Case 1: First use today (or ever).
      // Reset the counter to 1 and update the date.
      if (lastUsageDay == null || lastUsageDay.isBefore(today)) {
        await studentRef.update({
          'aiFeedbackCount': 1,
          'lastFeedbackDate': Timestamp.now(),
        });
        return true; // Allowed.
      }

      // Case 2: Already used today, check if the limit is reached.
      if (currentCount < dailyAILimit) {
        // Limit not reached, increment the counter.
        await studentRef.update({'aiFeedbackCount': FieldValue.increment(1)});
        return true; // Allowed.
      } else {
        // Case 3: The daily limit has been reached.
        print(
            'Student $studentId has reached the daily AI limit of $dailyAILimit.');
        return false; // Blocked.
      }
    } catch (e) {
      print('Error checking AI usage limit for student $studentId: $e');
      return false; // Block access on error for safety.
    }
  }

  // ========== USERS ==========
  Future<void> saveStudent(Student student) async {
    await _db.collection('users').doc(student.uid).set(student.toMap());
  }

  Future<void> saveTeacher(Teacher teacher) async {
    await _db.collection('users').doc(teacher.id).set(teacher.toMap());
  }

  Future<dynamic> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final role = data['role']?.toString().toLowerCase();
    // Use fromFirestore for consistency as it's designed for DocumentSnapshots
    if (role == 'teacher') return Teacher.fromFirestore(doc);
    if (role == 'student') return Student.fromFirestore(doc);
    throw Exception('Unknown user role: $role');
  }

  Future<void> updateUser(String uid, Map<String, dynamic> newData) async {
    await _db.collection('users').doc(uid).update(newData);
  }

  Future<void> addPointsToStudent(String studentId, int pointsToAdd) async {
    if (pointsToAdd <= 0) return;
    final userRef = _db.collection('users').doc(studentId);
    await userRef.update({'points': FieldValue.increment(pointsToAdd)});
  }

  // ========== STORIES ==========
  Future<void> saveStory(StoryModel story) async {
    try {
      await _db.collection('stories').doc(story.id).set(story.toDeepMap());
    } catch (e) {
      print('Error saving story: $e');
      rethrow;
    }
  }

  Future<void> deleteStory(String storyId) async {
    await _db.collection('stories').doc(storyId).delete();
  }

  Future<List<StoryModel>> getStoriesByCategoryOnce(String? category) async {
    Query query = _db.collection('stories');
    if (category != null && category.toLowerCase() != 'all') {
      query = query.where('type', isEqualTo: category.toLowerCase());
    }
    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) {
          try {
            return StoryModel.fromMap(doc.data() as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing story document ${doc.id}: $e');
            return null;
          }
        })
        .whereType<StoryModel>()
        .toList();
  }

  Stream<List<StoryModel>> getStoriesByAuthor(String authorId) {
    return _db
        .collection("stories")
        .where("authorId", isEqualTo: authorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => StoryModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<StoryModel>> getStoriesByAuthorOnce(String authorId) async {
    final snapshot = await _db
        .collection('stories')
        .where('authorId', isEqualTo: authorId)
        .get();
    return snapshot.docs
        .map((doc) => StoryModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<StoryModel> getStoryById(String storyId) async {
    final doc = await _db.collection('stories').doc(storyId).get();
    if (!doc.exists) throw Exception('Story not found');
    return StoryModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // ========== STORY UNLOCKING ==========
  Future<void> unlockStoryForStudent({
    required String studentId,
    required String storyId,
    required int cost,
  }) async {
    final userRef = _db.collection('users').doc(studentId);
    final storyUnlockRef = userRef.collection('unlockedStories').doc(storyId);

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception("User does not exist!");

      final currentPoints = (userDoc.data()!['points'] as num?)?.toInt() ?? 0;
      if (currentPoints < cost) throw Exception("Not enough points!");

      transaction.update(userRef, {'points': FieldValue.increment(-cost)});
      transaction
          .set(storyUnlockRef, {'unlockedAt': FieldValue.serverTimestamp()});
    });
  }

  Stream<List<String>> getUnlockedStoryIdsStream(String studentId) {
    return _db
        .collection('users')
        .doc(studentId)
        .collection('unlockedStories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // ========== READING HISTORY ==========
  Future<void> recordReadingHistory({
    required String studentId,
    required StoryModel story,
  }) async {
    try {
      final historyRef =
          _db.collection('users').doc(studentId).collection('readingHistory');
      final historyData = {
        'storyId': story.id,
        'title': story.title,
        'description': story.description ?? '',
        'imageUrl': story.imageUrl,
        'type': story.type,
        'timestamp': FieldValue.serverTimestamp(),
      };
      // Use set with merge:true on a named document to create or update efficiently.
      await historyRef.doc(story.id).set(historyData, SetOptions(merge: true));
    } catch (e) {
      print('Error recording history: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getReadingHistory(String studentId) {
    return _db
        .collection('users')
        .doc(studentId)
        .collection('readingHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['docId'] = doc.id;
              return data;
            }).toList());
  }

  // ========== SUMMARIES ==========
  Future<void> submitSummary({
    required StoryModel story,
    required Student student,
    required String summaryText,
    List<Map<String, String>>? storyPath,
    String? aiReview,
    double? aiAccuracyScore,
    Map<String, String>? structuredAnswers,
    bool isStructuredSummary = false,
  }) async {
    final summary = SummaryModel(
      id: '', // Will be auto-generated by Firestore
      storyId: story.id,
      storyTitle: story.title,
      studentId: student.uid,
      studentName: student.displayName,
      teacherId: story.authorId,
      summaryText: summaryText,
      submittedAt: DateTime.now(),
      storyPath: storyPath ?? [],
      aiReview: aiReview,
      aiAccuracyScore: aiAccuracyScore,
      structuredAnswers: structuredAnswers,
      isStructuredSummary: isStructuredSummary,
    );
    await _db.collection('summaries').add(summary.toMap());
  }

  Future<void> updateSummaryAIReview({
    required String summaryId,
    required String aiReview,
    required double aiAccuracyScore,
  }) async {
    await _db.collection('summaries').doc(summaryId).update({
      'aiReview': aiReview,
      'aiAccuracyScore': aiAccuracyScore,
    });
  }

  Stream<List<SummaryModel>> getSummariesForTeacher(String teacherId) {
    return _db
        .collection('summaries')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SummaryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<SummaryModel>> getSummariesForStudent(String studentId) {
    return _db
        .collection('summaries')
        .where('studentId', isEqualTo: studentId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SummaryModel.fromFirestore(doc))
            .toList());
  }

  Future<Map<String, dynamic>> getAIReviewStats(String teacherId) async {
    try {
      final snapshot = await _db
          .collection('summaries')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final summaries =
          snapshot.docs.map((doc) => SummaryModel.fromFirestore(doc)).toList();
      if (summaries.isEmpty) {
        return {
          'totalSummaries': 0,
          'reviewedSummaries': 0,
          'averageAccuracyScore': 0.0,
          'reviewProgress': 0.0
        };
      }

      final reviewedCount = summaries.where((s) => s.aiReview != null).length;
      final scores = summaries
          .where((s) => s.aiAccuracyScore != null)
          .map((s) => s.aiAccuracyScore!)
          .toList();
      final averageScore = scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0;

      return {
        'totalSummaries': summaries.length,
        'reviewedSummaries': reviewedCount,
        'averageAccuracyScore': averageScore,
        'reviewProgress': (reviewedCount / summaries.length) * 100,
      };
    } catch (e) {
      throw Exception('Failed to get AI review stats: $e');
    }
  }

  Future<void> rateSummary(String summaryId, int rating) async {
    await _db.collection('summaries').doc(summaryId).update({'rating': rating});
  }
}
