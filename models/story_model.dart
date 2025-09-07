import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

// NEW: Model for avatar intervention points
class AvatarInterventionPoint {
  final String id;
  final String storySection; // Which part of the story this applies to
  final String triggerCondition; // When to show the intervention
  final String message; // What the avatar says
  final List<String> requiredTraits; // Which traits trigger this intervention
  final int minTraitLevel; // Minimum trait level required
  final String interventionType; // Type of intervention (encouragement, etc.)
  final Map<String, dynamic>?
      additionalData; // Extra data for complex interventions

  AvatarInterventionPoint({
    required this.id,
    required this.storySection,
    required this.triggerCondition,
    required this.message,
    this.requiredTraits = const [],
    this.minTraitLevel = 1,
    this.interventionType = 'guidance',
    this.additionalData,
  });

  factory AvatarInterventionPoint.fromMap(Map<String, dynamic> data) {
    return AvatarInterventionPoint(
      id: data['id'] ?? '',
      storySection: data['storySection'] ?? '',
      triggerCondition: data['triggerCondition'] ?? '',
      message: data['message'] ?? '',
      requiredTraits: (data['requiredTraits'] as List<dynamic>?)
              ?.map((trait) => trait.toString())
              .toList() ??
          [],
      minTraitLevel: (data['minTraitLevel'] as num?)?.toInt() ?? 1,
      interventionType: data['interventionType'] ?? 'guidance',
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storySection': storySection,
      'triggerCondition': triggerCondition,
      'message': message,
      'requiredTraits': requiredTraits,
      'minTraitLevel': minTraitLevel,
      'interventionType': interventionType,
      'additionalData': additionalData,
    };
  }
}

class StoryChoice {
  String id;
  String label;
  String? childId;
  StoryModel? child;
  final String? traitKey; // NEW: For avatar trait tracking

  StoryChoice({
    required this.id,
    required this.label,
    this.childId,
    this.child,
    this.traitKey, // NEW: Optional trait key
  });

  factory StoryChoice.fromMap(Map<String, dynamic> map) {
    return StoryChoice(
      id: map['id'],
      label: map['label'],
      childId: map['childId'],
      child: map['child'] != null ? StoryModel.fromMap(map['child']) : null,
      traitKey: map['traitKey'], // NEW: Parse trait key
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'childId': childId,
      'traitKey': traitKey, // NEW: Include trait key
    };
  }
}

class StoryModel {
  String id;
  String title;
  String content;
  File? imageFile;
  String imageUrl;
  File? audioFile;
  String audioUrl;
  List<StoryChoice> choices;
  String authorId;
  DateTime createdAt;
  String? description;
  String type;
  int pointsToUnlock;
  final List<AvatarInterventionPoint> avatarInterventionPoints; // NEW

  StoryModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageFile,
    this.imageUrl = '',
    this.audioFile,
    this.audioUrl = '',
    required this.choices,
    required this.authorId,
    required this.createdAt,
    this.description,
    required this.type,
    this.pointsToUnlock = 0,
    this.avatarInterventionPoints = const [], // NEW: Default empty list
  });

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final type = map['type']?.toString().toLowerCase();
    return StoryModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      choices: (map['choices'] as List<dynamic>? ?? []).map((choice) {
        return StoryChoice.fromMap(choice);
      }).toList(),
      authorId: map['authorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'],
      type: type ?? StoryType.allTypes.first,
      pointsToUnlock: (map['pointsToUnlock'] as num?)?.toInt() ?? 0,
      // NEW: Parse avatar intervention points
      avatarInterventionPoints:
          (map['avatarInterventionPoints'] as List<dynamic>?)
                  ?.map((point) => AvatarInterventionPoint.fromMap(
                      point as Map<String, dynamic>))
                  .toList() ??
              [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'choices': choices.map((c) => c.toMap()).toList(),
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'type': type.toLowerCase(),
      'pointsToUnlock': pointsToUnlock,
      'avatarInterventionPoints': avatarInterventionPoints
          .map((point) => point.toMap())
          .toList(), // NEW
    };
  }

  Map<String, dynamic> toDeepMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'type': type.toLowerCase(),
      'choices': choices.map((choice) {
        return {
          'id': choice.id,
          'label': choice.label,
          'child': choice.child?.toDeepMap(),
          'traitKey': choice.traitKey, // NEW
        };
      }).toList(),
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'pointsToUnlock': pointsToUnlock,
      'avatarInterventionPoints': avatarInterventionPoints
          .map((point) => point.toMap())
          .toList(), // NEW
    };
  }

  // NEW: Helper method to check if the story has avatar interventions
  bool get hasAvatarInterventions => avatarInterventionPoints.isNotEmpty;
}

class StoryType {
  static const String adventure = 'adventure';
  static const String mystery = 'mystery';
  static const String fantasy = 'fantasy';
  static const String educational = 'educational';

  static List<String> get allTypes => [
        adventure,
        mystery,
        fantasy,
        educational,
      ];

  static String normalize(String? type) {
    return type?.toLowerCase() ?? '';
  }
}
extension AvatarInterventionPointExtension on AvatarInterventionPoint {
  bool shouldTriggerForStudent(Map<String, int> studentTraits, String currentSection) {
    // Check if we're in the right story section
    if (storySection != currentSection) return false;

    // Check if student has required traits at minimum level
    for (final trait in requiredTraits) {
      final studentTraitLevel = studentTraits[trait] ?? 0;
      if (studentTraitLevel < minTraitLevel) return false;
    }

    return true;
  }
}

