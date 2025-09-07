import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storyapp/models/summary_model.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/services/gemini_service_t.dart';

class SummaryReviewPage extends StatefulWidget {
  final SummaryModel summary;

  const SummaryReviewPage({
    super.key,
    required this.summary,
    required List<SummaryModel> summaries,
  });

  @override
  State<SummaryReviewPage> createState() => _SummaryReviewPageState();
}

class _SummaryReviewPageState extends State<SummaryReviewPage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();

  int? _currentRating;
  late TabController _tabController;

  // AI Review states
  bool _isLoadingAIReview = false;
  String? _aiReview;
  double? _aiAccuracyScore;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.summary.rating;
    _tabController = TabController(length: 3, vsync: this);

    // Load existing AI review if available
    _aiReview = widget.summary.aiReview;
    _aiAccuracyScore = widget.summary.aiAccuracyScore;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _rateSummary(int rating) async {
    try {
      await _firestoreService.rateSummary(widget.summary.id, rating);
      setState(() {
        _currentRating = rating;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rating saved!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving rating: $e")));
    }
  }

  // UPDATED: Trigger AI review with concise output handling
  Future<void> _triggerAIReview() async {
    setState(() => _isLoadingAIReview = true);

    try {
      String storyContent = '';

      try {
        // Fetch the full story using storyId
        final story = await _firestoreService.getStoryById(
          widget.summary.storyId,
        );

        // Extract all content from the nested story structure
        storyContent = _extractStoryContent(story);
      } catch (e) {
        print('Could not fetch story content: $e');
        // Fallback: build content from story path
        storyContent = _buildEnhancedContentFromPath(
          widget.summary.storyPath,
          widget.summary.storyTitle,
        );
      }

      // Ensure we have meaningful content for AI analysis
      if (storyContent.isEmpty || storyContent.length < 50) {
        storyContent =
            '''
Story Title: ${widget.summary.storyTitle}

Student's Journey:
${_buildPathSummary(widget.summary.storyPath)}

Note: This analysis is based on the student's recorded path through the story.
''';
      }

      // Get concise AI analysis
      final aiResult = await _geminiService.getDetailedSummaryReview(
        widget.summary.summaryText,
        widget.summary.storyTitle,
        storyContent,
        widget.summary.storyPath,
      );

      // Update Firestore with AI review
      await _firestoreService.updateSummaryAIReview(
        summaryId: widget.summary.id,
        aiReview: aiResult['review'] ?? 'AI review completed',
        aiAccuracyScore: (aiResult['accuracyScore'] ?? 75).toDouble(),
      );

      setState(() {
        _aiReview = aiResult['review'];
        _aiAccuracyScore = (aiResult['accuracyScore'] ?? 75).toDouble();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI review completed successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error in _triggerAIReview: $e');
      String userFriendlyError;

      // Check if it's a Gemini API error (503 overloaded)
      if (e.toString().contains('503') || e.toString().contains('overloaded')) {
        userFriendlyError =
            'The AI service is currently busy. Please try again in a few moments.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        userFriendlyError =
            'An unexpected error occurred while generating the review.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$userFriendlyError Please check the console for details.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Update the UI state to show the error message directly on the card
      setState(() {
        _aiReview =
            userFriendlyError; // This displays the error in the review text area
        _aiAccuracyScore = 0; // Reset the score
      });
    } finally {
      setState(() => _isLoadingAIReview = false);
    }
  }

  // Extract story content from nested StoryModel structure
  String _extractStoryContent(StoryModel story) {
    List<String> contentParts = [];

    // Add main story content and description
    if (story.description != null && story.description!.isNotEmpty) {
      contentParts.add('Story Description: ${story.description}');
    }

    if (story.content != null && story.content!.isNotEmpty) {
      contentParts.add('Story Content: ${story.content}');
    }

    // Recursively extract content from all story choices
    void extractFromChoices(List<StoryChoice> choices, String prefix) {
      for (int i = 0; i < choices.length; i++) {
        final choice = choices[i];

        // Add choice label
        contentParts.add('$prefix Choice ${i + 1}: ${choice.label}');

        // Add child story content if it exists
        if (choice.child != null) {
          final child = choice.child!;

          if (child.title != null && child.title!.isNotEmpty) {
            contentParts.add('$prefix → Title: ${child.title}');
          }

          if (child.content != null && child.content!.isNotEmpty) {
            contentParts.add('$prefix → Content: ${child.content}');
          }

          // Recursively extract from nested choices
          if (child.choices != null && child.choices!.isNotEmpty) {
            extractFromChoices(child.choices!, '$prefix  ');
          }
        }
      }
    }

    // Extract content from all choices
    if (story.choices != null && story.choices!.isNotEmpty) {
      extractFromChoices(story.choices!, '');
    }

    return contentParts.isNotEmpty
        ? contentParts.join('\n\n')
        : 'No story content available';
  }

  // Build comprehensive content from story path and title
  String _buildEnhancedContentFromPath(
    List<Map<String, String>> storyPath,
    String storyTitle,
  ) {
    if (storyPath.isEmpty) {
      return 'Story Title: $storyTitle\n\nNo detailed path information available.';
    }

    List<String> pathContent = ['Story Title: $storyTitle', ''];

    for (int i = 0; i < storyPath.length; i++) {
      final step = storyPath[i];
      final title = step['storyTitle'] ?? 'Unknown';
      final content = step['storyContent'] ?? '';
      final choice = step['choiceLabel'] ?? '';

      if (i == 0) {
        pathContent.add('=== Story Beginning ===');
        pathContent.add('Scene: $title');
      } else {
        pathContent.add('=== Step ${i + 1} ===');
        pathContent.add('Previous Choice: "$choice"');
        pathContent.add('Led to Scene: $title');
      }

      if (content.isNotEmpty) {
        pathContent.add('Content: $content');
      }

      pathContent.add(''); // Empty line for separation
    }

    return pathContent.join('\n');
  }

  // Helper method to build path summary
  String _buildPathSummary(List<Map<String, String>> storyPath) {
    if (storyPath.isEmpty) return 'No path recorded';

    return storyPath
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final step = entry.value;
          final choice = step['choiceLabel'] ?? 'Unknown choice';
          final title = step['storyTitle'] ?? 'Unknown story';

          if (index == 0) {
            return '1. Started: $title';
          } else {
            return '${index + 1}. Chose "$choice" → $title';
          }
        })
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review: ${widget.summary.studentName}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.rate_review), text: 'Summary'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Review'),
            Tab(icon: Icon(Icons.route), text: 'Story Path'),
          ],
        ),
        actions: [
          // AI Review trigger button
          if (_aiReview == null)
            IconButton(
              onPressed: _isLoadingAIReview ? null : _triggerAIReview,
              icon: _isLoadingAIReview
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.auto_awesome),
              tooltip: 'Generate AI Review',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildAIReviewTab(),
          _buildStoryPathTab(),
        ],
      ),
    );
  }

  // Summary tab
  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 20),
        _buildRatingSection(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.summary.studentName.isNotEmpty
                        ? widget.summary.studentName[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.summary.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Story: "${widget.summary.storyTitle}"',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // AI Score Badge
                if (_aiAccuracyScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(_aiAccuracyScore!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${_aiAccuracyScore!.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Submitted: ${DateFormat.yMMMd().add_jm().format(widget.summary.submittedAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.summary.summaryText,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Rating:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final ratingValue = index + 1;
                return GestureDetector(
                  onTap: () => _rateSummary(ratingValue),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentRating != null &&
                              ratingValue <= _currentRating!
                          ? Colors.amber.shade100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _currentRating != null && ratingValue <= _currentRating!
                          ? Icons.star
                          : Icons.star_border,
                      size: 36,
                      color: Colors.amber.shade600,
                    ),
                  ),
                );
              }),
            ),
            if (_currentRating != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Rated: $_currentRating/5 stars',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // UPDATED: AI Review tab with concise display
  Widget _buildAIReviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_aiReview != null) ...[
          _buildAIReviewCard(),
          const SizedBox(height: 20),
        ],
        if (_isLoadingAIReview)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Generating AI review...'),
                ],
              ),
            ),
          ) else if (_aiReview == null)
            Center(
              child: Column(
                children: [
                  const Text(
                    'No AI review available yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _triggerAIReview,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate AI Review'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildAIReviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.deepPurple.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'AI Review',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                if (_aiAccuracyScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(_aiAccuracyScore!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Score: ${_aiAccuracyScore!.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _aiReview ?? 'No AI review generated yet.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // Story Path tab
  Widget _buildStoryPathTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade50, Colors.lightGreen.shade50],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Story Path',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green,
                  ),
                ),
                const Divider(height: 24),
                Text(
                  _buildPathSummary(widget.summary.storyPath),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) {
      return Colors.green.shade600;
    } else if (score >= 70) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  String _getScoreText(double score) {
    if (score >= 90) {
      return 'Excellent';
    } else if (score >= 70) {
      return 'Good';
    } else if (score >= 50) {
      return 'Fair';
    } else {
      return 'Needs Work';
    }
  }
}


