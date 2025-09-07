import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/services/sync_service.dart';

class AvatarService {
  final FirestoreService _firestoreService = FirestoreService();
  final SyncService _syncService = SyncService();

  // Trait color schemes
  Map<String, Map<String, String>> getTraitColorSchemes() {
    return {
      'helpful': {'primary': '#4CAF50', 'secondary': '#8BC34A'},
      'brave': {'primary': '#F44336', 'secondary': '#FF9800'},
      'kind': {'primary': '#E91E63', 'secondary': '#FF4081'},
      'curious': {'primary': '#9C27B0', 'secondary': '#E040FB'},
      'creative': {'primary': '#3F51B5', 'secondary': '#536DFE'},
      'honest': {'primary': '#009688', 'secondary': '#4DB6AC'},
    };
  }

  Map<String, String> getTraitColorScheme(String trait) {
    return getTraitColorSchemes()[trait] ??
        {'primary': '#9E9E9E', 'secondary': '#BDBDBD'};
  }

  // Trait icons
  String getTraitIcon(String trait) {
    switch (trait) {
      case 'helpful':
        return '🙋‍♂️';
      case 'brave':
        return '🛡️';
      case 'kind':
        return '❤️';
      case 'curious':
        return '🔍';
      case 'creative':
        return '🎨';
      case 'honest':
        return '✅';
      default:
        return '👤';
    }
  }

  // Update traits based on story choices
  Future<void> updateTraitsFromChoice(Student student, String traitKey) async {
    final updatedTraits = Map<String, int>.from(student.avatarTraits);
    updatedTraits.update(traitKey, (value) => value + 5, ifAbsent: () => 5);

    try {
      await _firestoreService.updateUser(student.uid, {
        'avatarTraits': updatedTraits,
      });
    } catch (e) {
      // If offline, queue the update
      await _syncService.enqueueOperation('update_avatar_traits', {
        'studentId': student.uid,
        'avatarTraits': updatedTraits,
      });
    }
  }

  // Update traits based on reading time
  Future<void> updateTraitsFromReading(
      Student student, String storyType, int secondsSpent) async {
    final updatedTraits = Map<String, int>.from(student.avatarTraits);
    final pointsEarned = (secondsSpent / 60).ceil(); // 1 point per minute

    // Determine which traits to update based on story type
    switch (storyType.toLowerCase()) {
      case 'adventure':
        updatedTraits.update('brave', (value) => value + pointsEarned,
            ifAbsent: () => pointsEarned);
        break;
      case 'educational':
        updatedTraits.update('curious', (value) => value + pointsEarned,
            ifAbsent: () => pointsEarned);
        break;
      case 'fantasy':
        updatedTraits.update('creative', (value) => value + pointsEarned,
            ifAbsent: () => pointsEarned);
        break;
      case 'mystery':
        updatedTraits.update('curious', (value) => value + pointsEarned,
            ifAbsent: () => pointsEarned);
        break;
      default:
        updatedTraits.update('curious', (value) => value + pointsEarned,
            ifAbsent: () => pointsEarned);
    }

    try {
      await _firestoreService.updateUser(student.uid, {
        'avatarTraits': updatedTraits,
      });
    } catch (e) {
      // If offline, queue the update
      await _syncService.enqueueOperation('update_avatar_traits', {
        'studentId': student.uid,
        'avatarTraits': updatedTraits,
      });
    }
  }

  // Get avatar intervention messages based on student traits
  List<String> getAvatarInterventionMessages(Student student, String context) {
    final dominantTrait = student.dominantTrait;
    final messages = <String>[];

    switch (context) {
      case 'reading_encouragement':
        switch (dominantTrait) {
          case 'helpful':
            messages.add(
                'Keep going! Your helpful nature will guide you through this story!');
            break;
          case 'brave':
            messages.add('Be brave as you explore this new adventure!');
            break;
          case 'kind':
            messages
                .add('Your kindness shines through in every story you read!');
            break;
          case 'curious':
            messages.add(
                'Your curiosity will help you discover amazing things in this story!');
            break;
          case 'creative':
            messages.add('Let your creativity flow as you imagine this story!');
            break;
          case 'honest':
            messages.add(
                'Your honesty helps you understand the true meaning of stories!');
            break;
        }
        break;

      case 'story_choice':
        switch (dominantTrait) {
          case 'helpful':
            messages.add(
                'Think about which choice would be most helpful to others.');
            break;
          case 'brave':
            messages.add('Choose the path that requires the most courage!');
            break;
          case 'kind':
            messages.add('Which choice shows the most kindness?');
            break;
          case 'curious':
            messages
                .add('Follow your curiosity to the most interesting choice!');
            break;
          case 'creative':
            messages.add('Imagine the most creative outcome for each choice!');
            break;
          case 'honest':
            messages.add('Which choice feels the most honest and true?');
            break;
        }
        break;
    }

    return messages;
  }
}
