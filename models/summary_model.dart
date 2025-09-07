import 'package:cloud_firestore/cloud_firestore.dart';

class SummaryModel {
  final String id;
  final String storyId;
  final String storyTitle;
  final String studentId;
  final String studentName;
  final String teacherId; // Added teacherId
  final String summaryText;
  final DateTime submittedAt;
  final int? rating;
  final List<Map<String, String>> storyPath; // NEW: Store the story path
  final String? aiReview; // NEW: Store AI review/feedback
  final double? aiAccuracyScore; // NEW: Store AI accuracy score (0-100)
  final Map<String, String>? structuredAnswers; // NEW: For fill-in-the-blanks
  final bool
      isStructuredSummary; // NEW: Flag to indicate if it's fill-in-the-blanks

  SummaryModel({
    required this.id,
    required this.storyId,
    required this.storyTitle,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.summaryText,
    required this.submittedAt,
    this.rating,
    this.storyPath = const [], // NEW: Default empty path
    this.aiReview, // NEW: AI review
    this.aiAccuracyScore, // NEW: AI accuracy score
    this.structuredAnswers, // NEW: Structured answers
    this.isStructuredSummary = false, // NEW: Default to false
  });

  factory SummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SummaryModel(
      id: doc.id,
      storyId: data['storyId'] ?? '',
      storyTitle: data['storyTitle'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      teacherId: data['teacherId'] ?? '', // Parse teacherId
      summaryText: data['summaryText'] ?? '',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] as num?)?.toInt(),
      // NEW: Parse story path from Firestore
      storyPath: (data['storyPath'] as List<dynamic>?)
              ?.map((item) => Map<String, String>.from(item as Map))
              .toList() ??
          [],
      aiReview: data['aiReview'] as String?, // NEW: AI review
      aiAccuracyScore:
          (data['aiAccuracyScore'] as num?)?.toDouble(), // NEW: AI score
      structuredAnswers: data['structuredAnswers'] != null
          ? Map<String, String>.from(data['structuredAnswers'] as Map)
          : null, // NEW: Structured answers
      isStructuredSummary:
          data['isStructuredSummary'] as bool? ?? false, // NEW: Structured flag
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'storyTitle': storyTitle,
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId, // Include teacherId
      'summaryText': summaryText,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'rating': rating,
      'storyPath': storyPath, // NEW: Include story path
      'aiReview': aiReview, // NEW: Include AI review
      'aiAccuracyScore': aiAccuracyScore, // NEW: Include AI score
      'structuredAnswers': structuredAnswers, // NEW: Include structured answers
      'isStructuredSummary':
          isStructuredSummary, // NEW: Include structured flag
    };
  }

  SummaryModel copyWith({
    String? id,
    String? storyId,
    String? storyTitle,
    String? studentId,
    String? studentName,
    String? teacherId,
    String? summaryText,
    DateTime? submittedAt,
    int? rating,
    List<Map<String, String>>? storyPath,
    String? aiReview,
    double? aiAccuracyScore,
    Map<String, String>? structuredAnswers,
    bool? isStructuredSummary,
  }) {
    return SummaryModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      storyTitle: storyTitle ?? this.storyTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teacherId: teacherId ?? this.teacherId,
      summaryText: summaryText ?? this.summaryText,
      submittedAt: submittedAt ?? this.submittedAt,
      rating: rating ?? this.rating,
      storyPath: storyPath ?? this.storyPath,
      aiReview: aiReview ?? this.aiReview,
      aiAccuracyScore: aiAccuracyScore ?? this.aiAccuracyScore,
      structuredAnswers: structuredAnswers ?? this.structuredAnswers,
      isStructuredSummary: isStructuredSummary ?? this.isStructuredSummary,
    );
  }

  // NEW: Helper method to get a readable story path summary
  String getStoryPathSummary() {
    if (storyPath.isEmpty) return 'No path recorded';

    final pathSteps = storyPath.map((step) {
      final choice = step['choiceLabel'] ?? 'Unknown choice';
      final title = step['storyTitle'] ?? 'Unknown story';
      return '$choice → $title';
    }).join('\n');

    return pathSteps;
  }

  // NEW: Helper method to get full story content from path
  String getFullStoryContent() {
    if (storyPath.isEmpty) return 'No story content available';

    return storyPath.map((step) => step['storyContent'] ?? '').join('\n\n');
  }

  // NEW: Helper method to get structured summary display text
  String getStructuredSummaryDisplay() {
    if (!isStructuredSummary || structuredAnswers == null) {
      return summaryText;
    }

    final parts = <String>[];
    final answers = structuredAnswers!;

    if (answers['main_character']?.isNotEmpty == true) {
      parts.add(
          'The main character in this story was ${answers['main_character']}.');
    }
    if (answers['setting']?.isNotEmpty == true) {
      parts.add('The story happened in ${answers['setting']}.');
    }
    if (answers['problem']?.isNotEmpty == true) {
      parts.add('The problem in the story was ${answers['problem']}.');
    }
    if (answers['solution']?.isNotEmpty == true) {
      parts.add('The problem was solved by ${answers['solution']}.');
    }
    if (answers['favorite_part']?.isNotEmpty == true) {
      parts.add('My favorite part was when ${answers['favorite_part']}.');
    }
    if (answers['feeling']?.isNotEmpty == true) {
      parts.add('This story made me feel ${answers['feeling']}.');
    }

    return parts.join(' ');
  }
}
