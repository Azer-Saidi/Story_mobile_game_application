import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/services/avatar_service.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/services/story_cach_manager.dart';
import 'package:storyapp/ui/screens/students/submit_summary_page.dart';
import 'package:storyapp/ui/widgets/avatar_intervention_widget.dart';
import 'package:storyapp/ui/widgets/offline_indicator.dart';

class StoryReaderPage extends StatefulWidget {
  final StoryModel story;
  final Student student;
  final bool isRootStory;
  final List<Map<String, String>>? storyPath;

  const StoryReaderPage({
    super.key,
    required this.story,
    required this.student,
    required this.isRootStory,
    this.storyPath,
  });

  @override
  State<StoryReaderPage> createState() => _StoryReaderPageState();
}

class _StoryReaderPageState extends State<StoryReaderPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirestoreService _firestoreService = FirestoreService();
  final AvatarService _avatarService = AvatarService();
  final PageController _pageController = PageController();

  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  File? _cachedAudioFile;
  int _currentPageIndex = 0;
  String _currentStorySection = 'start';
  DateTime? _readingStartTime;
  bool _isLoading = false;

  // Track the current story path
  late List<Map<String, String>> _currentStoryPath;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _readingStartTime = DateTime.now();
    _recordReadingHistory();

    // Initialize the story path
    _currentStoryPath = widget.storyPath ?? [];

    // Add current story to path if it's not already there
    if (widget.isRootStory || _currentStoryPath.isEmpty) {
      _currentStoryPath.add({
        'storyId': widget.story.id,
        'storyTitle': widget.story.title,
        'storyContent': widget.story.content,
        'choiceLabel': widget.isRootStory ? 'Story Start' : 'Unknown',
      });
    }

    if (widget.isRootStory) {
      _recordCurrentStoryInHistory();
    }
    _precacheMedia(widget.story);
  }

  void _initAudio() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  void _precacheMedia(StoryModel story) {
    final cacheManager = StoryCacheManager();
    if (story.imageUrl.isNotEmpty) {
      cacheManager.getSingleFile(story.imageUrl);
    }
    if (story.audioUrl.isNotEmpty) {
      cacheManager.getSingleFile(story.audioUrl).then((file) {
        if (mounted) setState(() => _cachedAudioFile = file);
      });
    }
  }

  Future<void> _recordReadingHistory() async {
    final authProvider = context.read<AuthProvider>();
    final student = authProvider.currentUser as Student?;

    if (student != null) {
      try {
        await _firestoreService.recordReadingHistory(
          studentId: student.uid,
          story: widget.story,
        );
      } catch (e) {
        print('Error recording reading history: $e');
      }
    }
  }

  void _recordCurrentStoryInHistory() {
    _firestoreService.recordReadingHistory(
      studentId: widget.student.uid,
      story: widget.story,
    );
  }

  @override
  void dispose() {
    _updateReadingTraits();
    // Increment story count before disposing
    _incrementStoryReadCount();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// ✅ Increment the story read count when story is finished
  Future<void> _incrementStoryReadCount() async {
    final authProvider = context.read<AuthProvider>();
    final student = authProvider.currentUser as Student?;

    if (student != null && _readingStartTime != null) {
      // Only count as read if they spent at least 10 seconds reading
      final timeSpent = DateTime.now().difference(_readingStartTime!).inSeconds;
      if (timeSpent >= 10) {
        try {
          await authProvider.incrementStoriesRead();
          debugPrint(
              "✅ Story read count incremented for ${student.displayName}");
        } catch (e) {
          debugPrint("❌ Error incrementing story read count: $e");
        }
      }
    }
  }

  Future<void> _updateReadingTraits() async {
    final authProvider = context.read<AuthProvider>();
    final student = authProvider.currentUser as Student?;

    if (student != null && _readingStartTime != null) {
      final timeSpent = DateTime.now().difference(_readingStartTime!).inSeconds;
      try {
        await _avatarService.updateTraitsFromReading(
          student,
          widget.story.type,
          timeSpent,
        );
      } catch (e) {
        print('Error updating reading traits: $e');
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (widget.story.audioUrl.isEmpty) return;
    setState(() => _isLoadingAudio = true);
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        Source source = _cachedAudioFile != null
            ? DeviceFileSource(_cachedAudioFile!.path)
            : UrlSource(widget.story.audioUrl);
        await _audioPlayer.play(source);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAudio = false);
      }
    }
  }

  String _getOptimizedImageUrl(String url) {
    if (!url.contains('res.cloudinary.com')) return url;
    return url.replaceFirst('/upload/', '/upload/q_auto,f_auto,w_600,c_fill/');
  }

  @override
  Widget build(BuildContext context) {
    final optimizedImageUrl = _getOptimizedImageUrl(widget.story.imageUrl);
    final cacheManager = StoryCacheManager();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return OfflineIndicator(
          child: AvatarInterventionOverlay(
            student: widget.student,
            interventionPoints: widget.story.avatarInterventionPoints,
            currentStorySection: _currentStorySection,
            onInterventionResponse: _handleAvatarInterventionResponse,
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.story.title),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showStoryMenu,
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    if (widget.story.imageUrl.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: optimizedImageUrl,
                            fit: BoxFit.cover,
                            cacheManager: cacheManager,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 60),
                            ),
                          ),
                        ),
                      ),
                    // Audio Player
                    if (widget.story.audioUrl.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: _isLoadingAudio
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 3),
                                    )
                                  : Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.deepPurple,
                                      size: 32,
                                    ),
                              onPressed: _isLoadingAudio ? null : _toggleAudio,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                "Sound",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_cachedAudioFile != null)
                              const Icon(Icons.offline_bolt,
                                  color: Colors.green),
                          ],
                        ),
                      ),
                    // Story Content
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.story.content,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.5,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Avatar encouragement based on student traits
                          _buildTraitBasedEncouragement(widget.student),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Choices
                    if (widget.story.choices.isNotEmpty)
                      const Text(
                        "What happens next?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Choice guidance
                    if (widget.story.choices.isNotEmpty)
                      _buildChoiceGuidance(
                          widget.story.choices.first, widget.student),

                    const SizedBox(height: 16),

                    ...widget.story.choices.map((choice) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChoiceCard(
                          choice: choice,
                          onSelect: () =>
                              _handleChoiceSelection(choice, widget.student),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              floatingActionButton: widget.story.choices.isEmpty
                  ? FloatingActionButton.extended(
                      onPressed: () => _navigateToSummary(widget.student),
                      label: const Text("Finish & Summarize"),
                      icon: const Icon(Icons.check_circle_outline),
                      backgroundColor: Colors.green,
                    )
                  : null,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTraitBasedEncouragement(Student student) {
    final messages = _avatarService.getAvatarInterventionMessages(
      student,
      'reading_encouragement',
    );

    if (messages.isEmpty) return const SizedBox.shrink();

    final colorScheme =
        _avatarService.getTraitColorScheme(student.dominantTrait);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(
                int.parse(colorScheme['primary']!.substring(1), radix: 16) +
                    0xFF000000)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(
                  int.parse(colorScheme['primary']!.substring(1), radix: 16) +
                      0xFF000000)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(
                  int.parse(colorScheme['primary']!.substring(1), radix: 16) +
                      0xFF000000),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTraitIcon(student.dominantTrait),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              messages.first,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'ComicNeue',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceGuidance(StoryChoice choice, Student student) {
    final messages = _avatarService.getAvatarInterventionMessages(
      student,
      'story_choice',
    );

    if (messages.isEmpty) return const SizedBox.shrink();

    final colorScheme =
        _avatarService.getTraitColorScheme(student.dominantTrait);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(
                int.parse(colorScheme['secondary']!.substring(1), radix: 16) +
                    0xFF000000)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(
                  int.parse(colorScheme['secondary']!.substring(1), radix: 16) +
                      0xFF000000)
              .withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(int.parse(colorScheme['primary']!.substring(1),
                          radix: 16) +
                      0xFF000000),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTraitIcon(student.dominantTrait),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Your ${StringCapitalization(student.dominantTrait).capitalize()} Avatar says:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse(colorScheme['primary']!.substring(1),
                          radix: 16) +
                      0xFF000000),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            messages.first,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'ComicNeue',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTraitIcon(String trait) {
    switch (trait) {
      case 'helpful':
        return Icons.volunteer_activism;
      case 'brave':
        return Icons.shield;
      case 'kind':
        return Icons.favorite;
      case 'curious':
        return Icons.search;
      case 'creative':
        return Icons.palette;
      case 'honest':
        return Icons.verified;
      default:
        return Icons.person;
    }
  }

  Future<void> _handleChoiceSelection(
      StoryChoice choice, Student student) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add choice to story path
      _currentStoryPath.add({
        'storyId': choice.child?.id ?? widget.story.id,
        'storyTitle': choice.child?.title ?? choice.label,
        'storyContent': choice.child?.content ?? '',
        'choiceLabel': choice.label,
      });

      // Update avatar traits if choice has trait key
      if (choice.traitKey != null) {
        await _avatarService.updateTraitsFromChoice(student, choice.traitKey!);
      }

      // Update current story section for interventions
      setState(() {
        _currentStorySection = 'choice_${choice.id}';
      });

      // Navigate to next story if available
      if (choice.child != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryReaderPage(
              story: choice.child!,
              student: widget.student,
              isRootStory: false,
              storyPath: _currentStoryPath,
            ),
          ),
        );
      } else {
        // Show choice result or navigate to summary
        _showChoiceResult(choice, student);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing choice: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showChoiceResult(StoryChoice choice, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'You chose: ${choice.label}',
          style: const TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (choice.child != null && choice.child!.content.isNotEmpty) ...[
              Text(
                choice.child!.content,
                style: const TextStyle(
                  fontFamily: 'ComicNeue',
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Trait update notification
            if (choice.traitKey != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your ${choice.traitKey} trait has grown!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSummary(student);
            },
            child: const Text(
              'Continue to Summary',
              style: TextStyle(fontFamily: 'ComicNeue'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAvatarInterventionResponse(
    AvatarInterventionPoint intervention,
    String response,
  ) {
    print('Avatar intervention response: ${intervention.id} -> $response');
    // Handle the response based on intervention type and student's answer
  }

  void _navigateToSummary(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitSummaryPage(
          story: widget.story,
          student: student,
          storyPath: _currentStoryPath,
        ),
      ),
    );
  }

  void _showStoryMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmark Story'),
              onTap: () {
                Navigator.pop(context);
                // Implement bookmark functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Story'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Issue'),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  final StoryChoice choice;
  final VoidCallback onSelect;

  const ChoiceCard({super.key, required this.choice, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.arrow_forward, color: Colors.deepPurple),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  choice.label,
                  style: const TextStyle(fontSize: 16, fontFamily: 'ComicNeue'),
                ),
              ),
              if (choice.child == null)
                const Text(
                  "End",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
