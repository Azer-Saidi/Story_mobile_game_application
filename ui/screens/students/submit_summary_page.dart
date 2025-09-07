import 'package:flutter/material.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/services/gemini_service_t.dart';
import 'package:storyapp/ui/widgets/fill_in_blanks_widget.dart';

class SubmitSummaryPage extends StatefulWidget {
  final StoryModel story;
  final Student student;
  final List<Map<String, String>> storyPath;

  const SubmitSummaryPage({
    super.key,
    required this.story,
    required this.student,
    required this.storyPath,
  });

  @override
  State<SubmitSummaryPage> createState() => _SubmitSummaryPageState();
}

class _SubmitSummaryPageState extends State<SubmitSummaryPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _geminiService = GeminiService();

  late TabController _tabController;

  bool _isSubmitting = false;
  bool _isLoadingAI = false;

  // AI limit states
  bool _isAILimitReached = false;
  int _aiUsesLeft = FirestoreService.dailyAILimit;

  List<String> _writingPrompts = [];
  List<String> _summarySuggestions = [];
  List<String> _storyPathSuggestions = [];

  // Fill-in-the-blanks state
  Map<String, String> _fillInBlanksAnswers = {};
  bool _useStructuredSummary = false;

  @override
  void initState() {
    super.initState();

    // Determine if student should use fill-in-the-blanks based on age (6-9 years)
    _useStructuredSummary = widget.student.age >= 6 && widget.student.age <= 9;

    _tabController = TabController(length: 3, vsync: this);

    // Only load AI assistance for older students or if not using structured summary
    if (!_useStructuredSummary) {
      _loadAIAssistance();
      _checkInitialAILimit();
    }
  }

  Future<void> _checkInitialAILimit() async {
    try {
      final canUseAI =
          await _firestoreService.canUseAIFeature(widget.student.uid);
      setState(() {
        _isAILimitReached = !canUseAI;
        _aiUsesLeft = canUseAI
            ? (FirestoreService.dailyAILimit -
                (widget.student.aiFeedbackCount %
                    FirestoreService.dailyAILimit))
            : 0;
      });
    } catch (e) {
      print('Error checking AI limit: $e');
    }
  }

  Future<void> _loadAIAssistance() async {
    if (_useStructuredSummary) return; // Skip AI for structured summaries

    setState(() => _isLoadingAI = true);

    try {
      final futures = await Future.wait([
        _geminiService.generateWritingPrompts(widget.story.title),
        _geminiService.generateSummarySuggestions(
          widget.story.title,
          widget.story.content ??
              widget.story.description ??
              widget.storyPath.map((e) => e['storyContent'] ?? '').join('\n\n'),
        ),
        _geminiService.generateStoryPathSuggestions([], widget.story.title),
      ]);

      if (mounted) {
        setState(() {
          _writingPrompts = futures[0];
          _summarySuggestions = futures[1];
          _storyPathSuggestions = futures[2];
        });
      }
    } catch (e) {
      print('Error loading AI assistance: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAI = false);
      }
    }
  }

  String _getStoryPathSummary() {
    if (widget.storyPath.isEmpty) return 'No path recorded';
    return widget.storyPath.map((step) {
      final choice = step['choiceLabel'] ?? 'Unknown';
      return choice;
    }).join(' → ');
  }

  // Generate summary text from fill-in-the-blanks answers
  String _generateStructuredSummaryText() {
    final parts = <String>[];

    if (_fillInBlanksAnswers['main_character']?.isNotEmpty == true) {
      parts.add(
          'The main character in this story was ${_fillInBlanksAnswers['main_character']}.');
    }
    if (_fillInBlanksAnswers['setting']?.isNotEmpty == true) {
      parts.add('The story happened in ${_fillInBlanksAnswers['setting']}.');
    }
    if (_fillInBlanksAnswers['problem']?.isNotEmpty == true) {
      parts.add(
          'The problem in the story was ${_fillInBlanksAnswers['problem']}.');
    }
    if (_fillInBlanksAnswers['solution']?.isNotEmpty == true) {
      parts.add(
          'The problem was solved by ${_fillInBlanksAnswers['solution']}.');
    }
    if (_fillInBlanksAnswers['favorite_part']?.isNotEmpty == true) {
      parts.add(
          'My favorite part was when ${_fillInBlanksAnswers['favorite_part']}.');
    }
    if (_fillInBlanksAnswers['feeling']?.isNotEmpty == true) {
      parts.add('This story made me feel ${_fillInBlanksAnswers['feeling']}.');
    }

    return parts.join(' ');
  }

  // Check if structured summary has enough content
  bool _isStructuredSummaryValid() {
    final summaryText = _generateStructuredSummaryText();
    return summaryText.trim().isNotEmpty && summaryText.length >= 20;
  }

  // Submit summary with story path and structured answers support
  Future<void> _submitSummary() async {
    if (_useStructuredSummary) {
      // Enhanced validation for fill-in-the-blanks - require more fields for better summaries
      final requiredFields = [
        'main_character',
        'favorite_part',
        'setting',
        'problem'
      ];
      final emptyFields = <String>[];

      for (final field in requiredFields) {
        if (_fillInBlanksAnswers[field]?.trim().isEmpty == true) {
          emptyFields.add(field);
        }
      }

      if (emptyFields.isNotEmpty) {
        final fieldNames = emptyFields.map((field) {
          switch (field) {
            case 'main_character':
              return 'main character';
            case 'favorite_part':
              return 'favorite part';
            case 'setting':
              return 'setting';
            case 'problem':
              return 'problem';
            default:
              return field;
          }
        }).join(', ');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill in the required fields: $fieldNames\n\n'
              'These fields help create a complete story summary!',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Also check if at least one of solution or feeling is filled
      if (_fillInBlanksAnswers['solution']?.trim().isEmpty == true &&
          _fillInBlanksAnswers['feeling']?.trim().isEmpty == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please also fill in either "How was the problem solved?" or "How did the story make you feel?"\n\n'
              'This makes your summary more complete and personal!',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Check if the generated summary has enough content
      if (!_isStructuredSummaryValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your summary needs more details. Please fill in more fields to create a complete summary.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    } else {
      // Validate free text
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final summaryText = _useStructuredSummary
          ? _generateStructuredSummaryText()
          : _summaryController.text.trim();

      await _firestoreService.submitSummary(
        story: widget.story,
        student: widget.student,
        summaryText: summaryText,
        storyPath: widget.storyPath,
        structuredAnswers: _useStructuredSummary ? _fillInBlanksAnswers : null,
        isStructuredSummary: _useStructuredSummary,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting summary: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        _useStructuredSummary
                            ? 'Complete Your Story Summary'
                            : 'Summarize Your Adventure',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'ComicNeue',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Story Title and Path Info
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'You read: "${widget.story.title}"',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'ComicNeue',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.storyPath.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Path: ${_getStoryPathSummary()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontFamily: 'ComicNeue',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content based on student age
              Expanded(
                child: _useStructuredSummary
                    ? _buildStructuredSummaryContent()
                    : _buildFreeTextSummaryContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStructuredSummaryContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Age-appropriate message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.child_care, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fill in the blanks to tell us about your story!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Fill-in-the-blanks widget
          Expanded(
            child: SingleChildScrollView(
              child: FillInBlanksWidget(
                storyTitle: widget.story.title,
                storyContent: widget.story.content,
                onAnswersChanged: (answers) {
                  setState(() {
                    _fillInBlanksAnswers = answers;
                  });
                },
                initialAnswers: _fillInBlanksAnswers,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitSummary,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeTextSummaryContent() {
    return Container(
      child: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: const Color(0xFF6A11CB),
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
                fontSize: 12,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.edit, size: 20), text: 'Write'),
                Tab(icon: Icon(Icons.lightbulb, size: 20), text: 'Ideas'),
                Tab(icon: Icon(Icons.explore, size: 20), text: 'Next'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWriteTab(),
                _buildIdeasTab(),
                _buildNextTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteTab() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'In your own words, what happened in this story?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
                color: Color(0xFF6A11CB),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Writing Prompts
            if (_writingPrompts.isNotEmpty) ...[
              Text(
                'Need help getting started? Try these prompts:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ComicNeue',
                ),
              ),
              const SizedBox(height: 8),
              ...(_writingPrompts.take(2).map(
                    (prompt) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'ComicNeue',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: TextFormField(
                controller: _summaryController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Your Summary',
                  hintText: 'Start writing here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a summary.';
                  }
                  if (value.trim().length < 20) {
                    return 'Please write a little more (at least 20 characters).';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitSummary,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeasTab() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary Ideas',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
              color: Color(0xFF6A11CB),
            ),
          ),
          const SizedBox(height: 16),
          if (_summarySuggestions.isNotEmpty) ...[
            ..._summarySuggestions.map(
              (suggestion) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 14, fontFamily: 'ComicNeue'),
                ),
              ),
            ),
          ] else if (_isLoadingAI) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            const Text(
              'AI suggestions will appear here to help you structure your summary.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextTab() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Next?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
              color: Color(0xFF6A11CB),
            ),
          ),
          const SizedBox(height: 16),
          if (_storyPathSuggestions.isNotEmpty) ...[
            ..._storyPathSuggestions.map(
              (suggestion) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 14, fontFamily: 'ComicNeue'),
                ),
              ),
            ),
          ] else if (_isLoadingAI) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            const Text(
              'AI will suggest other stories you might enjoy based on your reading path.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
