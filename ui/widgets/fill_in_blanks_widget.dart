import 'package:flutter/material.dart';

class FillInBlanksWidget extends StatefulWidget {
  final String storyTitle;
  final String storyContent;
  final Function(Map<String, String>) onAnswersChanged;
  final Map<String, String> initialAnswers;

  const FillInBlanksWidget({
    super.key,
    required this.storyTitle,
    required this.storyContent,
    required this.onAnswersChanged,
    required this.initialAnswers,
  });

  @override
  State<FillInBlanksWidget> createState() => _FillInBlanksWidgetState();
}

class _FillInBlanksWidgetState extends State<FillInBlanksWidget> {
  final Map<String, String> _answers = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize with provided answers
    _answers.addAll(widget.initialAnswers);

    // Create controllers for each field
    _controllers['main_character'] =
        TextEditingController(text: _answers['main_character']);
    _controllers['setting'] = TextEditingController(text: _answers['setting']);
    _controllers['problem'] = TextEditingController(text: _answers['problem']);
    _controllers['solution'] =
        TextEditingController(text: _answers['solution']);
    _controllers['favorite_part'] =
        TextEditingController(text: _answers['favorite_part']);
    _controllers['feeling'] = TextEditingController(text: _answers['feeling']);
  }

  @override
  void dispose() {
    // Dispose all controllers
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _updateAnswer(String key, String value) {
    setState(() {
      _answers[key] = value;
    });
    widget.onAnswersChanged(_answers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Summary Requirements',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Fields marked with * are required. For a complete summary, also fill in at least one of the optional fields.',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildQuestionField(
          'main_character',
          'Who was the main character in the story?',
          'Example: a brave knight, a curious rabbit',
          true,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          'setting',
          'Where did the story happen?',
          'Example: in a magical forest, in a spaceship',
          true,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          'problem',
          'What was the main problem in the story?',
          'Example: they were lost, someone was missing',
          true,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          'solution',
          'How was the problem solved?',
          'Example: they worked together, they found a magic key',
          false,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          'favorite_part',
          'What was your favorite part?',
          'Example: when they flew on a dragon, the funny joke',
          true,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          'feeling',
          'How did the story make you feel?',
          'Example: happy, excited, curious',
          false,
        ),
        const SizedBox(height: 20),
        // Preview of the generated summary
        if (_answers.values.any((answer) => answer.isNotEmpty))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your summary will look like:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ComicNeue',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _generatePreviewText(),
                  style: const TextStyle(
                    fontFamily: 'ComicNeue',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionField(
      String key, String question, String hint, bool required) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'ComicNeue',
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          maxLines: 2,
          onChanged: (value) => _updateAnswer(key, value),
        ),
      ],
    );
  }

  String _generatePreviewText() {
    final parts = <String>[];

    if (_answers['main_character']?.isNotEmpty == true) {
      parts.add('The main character was ${_answers['main_character']}.');
    }
    if (_answers['setting']?.isNotEmpty == true) {
      parts.add('The story happened in ${_answers['setting']}.');
    }
    if (_answers['problem']?.isNotEmpty == true) {
      parts.add('The problem was ${_answers['problem']}.');
    }
    if (_answers['solution']?.isNotEmpty == true) {
      parts.add('They solved it by ${_answers['solution']}.');
    }
    if (_answers['favorite_part']?.isNotEmpty == true) {
      parts.add('My favorite part was ${_answers['favorite_part']}.');
    }
    if (_answers['feeling']?.isNotEmpty == true) {
      parts.add('This made me feel ${_answers['feeling']}.');
    }

    return parts.isNotEmpty
        ? parts.join(' ')
        : 'Fill in some answers to see your summary preview.';
  }
}
