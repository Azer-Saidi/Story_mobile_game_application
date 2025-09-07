import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  late final GenerativeModel _textModel;
  late final GenerativeModel _reviewModel;
  DateTime? _lastApiCall;
  final Duration _minCallInterval = const Duration(milliseconds: 500);

  GeminiService() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
        'Error: GEMINI_API_KEY not found in .env file or is empty.',
      );
    }

    _textModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );

    _reviewModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        temperature: 0.5,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 512,
      ),
    );
  }

  Future<T> _withRetry<T>(
    Future<T> Function() apiCall, {
    String? context,
  }) async {
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 1);
    int attempt = 0;
    dynamic lastError;

    // Handle rate-limiting between consecutive calls
    if (_lastApiCall != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
      if (timeSinceLastCall < _minCallInterval) {
        await Future.delayed(_minCallInterval - timeSinceLastCall);
      }
    }

    while (attempt < maxRetries) {
      try {
        _lastApiCall = DateTime.now();
        return await apiCall();
      } on GenerativeAIException catch (e) {
        lastError = e;

        // Enhanced error handling
        if (e.message != null) {
          if (e.message!.contains('location not supported')) {
            throw Exception('API not available in your region');
          }
          if (e.message!.contains('API_KEY_INVALID')) {
            throw Exception('Invalid API key');
          }
        }

        // Retry on known transient errors
        if (e.message != null &&
            (e.message!.contains('resource_exhausted') ||
                e.message!.contains('unavailable') ||
                e.message!.contains('503'))) {
          attempt++;
          if (attempt >= maxRetries) rethrow;

          final delay =
              initialDelay * (1 << (attempt - 1)); // Exponential backoff
          print(
            '${context ?? 'API'} overloaded (attempt $attempt), retrying in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
          continue;
        }

        rethrow;
      } catch (e) {
        // Other unexpected error
        lastError = e;
        rethrow;
      }
    }

    throw lastError ?? Exception('Unknown error after $maxRetries attempts');
  }

  // Helper to truncate long content
  String _truncateContent(String content, {int maxLength = 10000}) {
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '... [TRUNCATED]';
  }

  Future<Map<String, dynamic>> generateStoryTree(String prompt) async {
    try {
      return await _withRetry(() async {
        final content = Content.text('''
Generate a branching adventure story in JSON format based on this concept: "$prompt"

Use this structure:
{
  "title": "Scene title",
  "content": "2-3 sentence scene description.",
  "description": "1-2 sentence story concept summary (root only).",
  "image": "suggested_image_filename.jpg",
  "audio": "optional_audio.mp3",
  "choices": [
    {
      "label": "Choice text",
      "child": { /* nested structure */ }
    }
  ]
}

RULES:
1. Up to 3 branching levels.
2. Each node: 1-3 choices. Vary count.
3. "description" only in root, null/absent in children.
4. Last nodes: empty "choices" array [].
5. Include image suggestions. Audio optional.
6. Output PURE JSON only. No markdown or extra text.
7. Content: child-friendly, educational.
''');

        final response = await _textModel.generateContent([content]);
        final raw = response.text ?? '{}';

        final jsonStart = raw.indexOf('{');
        final jsonEnd = raw.lastIndexOf('}');
        if (jsonStart == -1 || jsonEnd == -1) {
          throw Exception('Invalid JSON response');
        }

        final jsonString = raw.substring(jsonStart, jsonEnd + 1);
        return jsonDecode(jsonString);
      }, context: 'Story generation');
    } catch (e) {
      print('Error in generateStoryTree: $e');
      return {'error': 'Failed to generate story. Please try again.'};
    }
  }

  Future<String?> analyzeSummary(
    String summary,
    String storyTitle,
    String storyContent,
  ) async {
    try {
      return await _withRetry(() async {
        final prompt =
            '''
Review student summary for "$storyTitle".
Summary: "$summary"
Story: "${_truncateContent(storyContent)}"

Feedback: accuracy, key elements, writing quality, improvement suggestions. Keep it encouraging and educational. Max 150 words.
''';

        final response = await _reviewModel.generateContent([
          Content.text(prompt),
        ]);
        return response.text;
      }, context: 'Summary analysis');
    } catch (e) {
      print('Error in analyzeSummary: $e');
      return null;
    }
  }

  Future<String?> analyzeSummaryWithPath(
    String summary,
    String storyTitle,
    String storyContent,
    List<Map<String, String>> storyPath,
  ) async {
    try {
      return await _withRetry(() async {
        final pathSummary = _buildPathSummary(storyPath);
        final prompt =
            '''
Review student summary for "$storyTitle" against their path.
Summary: "$summary"
Path: $pathSummary

Feedback: path match, key events, missed choices, overall accuracy, writing quality. Be honest but encouraging. Max 200 words.
''';

        final response = await _reviewModel.generateContent([
          Content.text(prompt),
        ]);
        return response.text;
      }, context: 'Path analysis');
    } catch (e) {
      print('Error in analyzeSummaryWithPath: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getDetailedSummaryReview(
    String summary,
    String storyTitle,
    String storyContent,
    List<Map<String, String>> storyPath,
  ) async {
    try {
      return await _withRetry(() async {
        final pathSummary = _buildPathSummary(storyPath);
        final truncatedContent = _truncateContent(storyContent);

        final prompt =
            '''
Provide EXACTLY in this format:
<accuracy_score> - <review_text>

Where:
- <accuracy_score> is a number 0-100
- <review_text> is a 2-3 sentence review

RULES:
1. Score MUST be first
2. MUST use dash separator (-)
3. Review MUST follow dash
4. No additional text or formatting

STORY TITLE: "$storyTitle"
STUDENT SUMMARY: "$summary"
STUDENT PATH: 
$pathSummary

FULL CONTENT: 
$truncatedContent

YOUR RESPONSE FORMAT EXAMPLE:
85 - The summary accurately captured the main conflict but missed the resolution...
''';

        final response = await _reviewModel.generateContent([
          Content.text(prompt),
        ]);

        final text = response.text?.trim() ?? '';
        print('Gemini Raw Response: $text');

        // Robust parsing
        double score = 0;
        String review = '';

        final formatMatch = RegExp(
          r'^(\d{1,3})\s*[-–]\s*(.+)$',
          dotAll: true,
        ).firstMatch(text);

        if (formatMatch != null) {
          score = double.tryParse(formatMatch.group(1)!) ?? 0;
          review = formatMatch.group(2)!.trim();
        } else {
          // Fallback: search for score anywhere
          final scoreMatch = RegExp(r'\b(\d{1,3})\b').firstMatch(text);
          score = scoreMatch != null ? double.parse(scoreMatch.group(1)!) : 0;
          review = text.isNotEmpty ? text : 'Invalid response format';
        }

        return {'review': review, 'accuracyScore': score};
      }, context: 'Detailed review');
    } catch (e) {
      print('Detailed Review Error: $e');
      return {'review': 'Error: ${e.toString()}', 'accuracyScore': 0};
    }
  }

  Future<Map<String, dynamic>> compareWithStoryElements(
    String summary,
    List<Map<String, String>> storyPath,
  ) async {
    try {
      return await _withRetry(() async {
        final pathSummary = _buildPathSummary(storyPath);
        final keyElements = _extractKeyElements(storyPath);

        final prompt =
            '''
Compare summary: "$summary" against:
Path: $pathSummary
Key Elements: ${keyElements.join(', ')}

Output JSON: {"overallScore": 0-100, "feedback": "text"}
''';

        final response = await _reviewModel.generateContent([
          Content.text(prompt),
        ]);
        final text = response.text ?? '';

        try {
          return jsonDecode(text);
        } catch (_) {
          return {'overallScore': 70, 'feedback': text};
        }
      }, context: 'Compare summary');
    } catch (e) {
      print('Error in compareWithStoryElements: $e');
      return {'overallScore': 0, 'feedback': 'Comparison failed'};
    }
  }

  Future<String?> generateTeacherReview(
    String summary,
    String studentName,
    List<Map<String, String>> storyPath,
    Map<String, dynamic> aiAnalysis,
  ) async {
    try {
      return await _withRetry(() async {
        final pathSummary = _buildPathSummary(storyPath);
        final prompt =
            '''
Teacher review for $studentName:
Summary: "$summary"
Path: $pathSummary
AI Score: ${aiAnalysis['accuracyScore']}
AI Review: ${aiAnalysis['review']}

Include: assessment, grade, strengths, improvement tips. Max 200 words.
''';

        final response = await _reviewModel.generateContent([
          Content.text(prompt),
        ]);
        return response.text;
      }, context: 'Teacher review');
    } catch (e) {
      print('Error in generateTeacherReview: $e');
      return null;
    }
  }

  Future<List<String>> generateWritingPrompts(String storyTitle) async {
    try {
      return await _withRetry(() async {
        final prompt =
            'Give 3 writing prompts for summarizing "$storyTitle". One per line.';

        final response = await _textModel.generateContent([
          Content.text(prompt),
        ]);
        return (response.text ?? '')
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .take(3)
            .toList();
      }, context: 'Writing prompts');
    } catch (e) {
      print('Error in generateWritingPrompts: $e');
      return [
        'What is the main idea of the story?',
        'What challenges did the character face?',
        'How did the story end?',
      ];
    }
  }

  Future<List<String>> generateSummarySuggestions(
    String title,
    String content,
  ) async {
    try {
      return await _withRetry(() async {
        final prompt = 'Suggest 3 summary ideas for "$title": $content';

        final response = await _textModel.generateContent([
          Content.text(prompt),
        ]);
        return (response.text ?? '')
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .take(3)
            .toList();
      }, context: 'Summary suggestions');
    } catch (e) {
      print('Error in generateSummarySuggestions: $e');
      return [
        'Start with the character\'s goal.',
        'Explain what they went through.',
        'Wrap up with the ending.',
      ];
    }
  }

  Future<List<String>> generateStoryPathSuggestions(
    List<dynamic> history,
    String currentTitle,
  ) async {
    try {
      return await _withRetry(() async {
        final prompt =
            'Suggest 3 story paths based on "$currentTitle". One per line.';

        final response = await _textModel.generateContent([
          Content.text(prompt),
        ]);
        return (response.text ?? '')
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .take(3)
            .toList();
      }, context: 'Story path suggestions');
    } catch (e) {
      print('Error in generateStoryPathSuggestions: $e');
      return [
        'Explore another ending',
        'Try a different genre',
        'Change your choices',
      ];
    }
  }

  String _buildPathSummary(List<Map<String, String>> storyPath) {
    return storyPath
        .asMap()
        .entries
        .map((e) {
          final index = e.key;
          final step = e.value;
          final choice = step['choiceLabel'] ?? 'Unknown';
          final title = step['storyTitle'] ?? 'Unknown';
          return index == 0
              ? '${index + 1}. Start: $title'
              : '${index + 1}. Chose "$choice" → $title';
        })
        .join('\n');
  }

  String _buildFullStoryContent(List<Map<String, String>> storyPath) {
    return storyPath
        .map((step) {
          final title = step['storyTitle'] ?? 'Unknown';
          final content = step['storyContent'] ?? '';
          return '--- $title ---\n$content';
        })
        .join('\n\n');
  }

  List<String> _extractKeyElements(List<Map<String, String>> storyPath) {
    return storyPath.expand((step) {
      final elements = <String>[];
      if (step['storyTitle']?.isNotEmpty ?? false) {
        elements.add('Title: ${step['storyTitle']}');
      }
      if (step['choiceLabel']?.isNotEmpty ?? false) {
        elements.add('Choice: ${step['choiceLabel']}');
      }
      return elements;
    }).toList();
  }
}
