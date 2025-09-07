import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Base URL for the Gemini API
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // API Key for Gemini, loaded from .env file
  static final String _apiKey =
      dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY_NOT_FOUND';

  // ========== PUBLIC METHODS ==========

  /// Generates 3 summary suggestions for a given story.
  Future<List<String>> generateSummarySuggestions(
    String storyTitle,
    String storyContent,
  ) async {
    final prompt =
        '''
Based on the story titled "$storyTitle", provide 3 different summary suggestions that a student could use as inspiration. Each summary should be:
- Age-appropriate for children
- 2-3 sentences long
- Capture the main events and themes
- Be written in simple, clear language

Story content: $storyContent

Please format your response as a JSON array of strings, like this:
["Summary 1", "Summary 2", "Summary 3"]
''';

    final response = await _makeGeminiRequest(prompt);
    if (response != null) {
      try {
        final cleanedResponse = _cleanJsonString(response);
        final List<dynamic> suggestions = json.decode(cleanedResponse);
        return suggestions.cast<String>();
      } catch (e) {
        print('Error parsing JSON for summary suggestions: $e');
        // Fallback for non-JSON responses
        return response
            .split('\n')
            .where((line) => line.trim().isNotEmpty && !line.contains('```'))
            .map((line) => line.replaceAll(RegExp(r'^[0-9]+\.\s*'), '').trim())
            .take(3)
            .toList();
      }
    }
    return _getDefaultSuggestions();
  }

  /// Analyzes a student's summary and provides feedback.
  Future<String?> analyzeSummary(
    String studentSummary,
    String storyTitle,
    String storyContent,
  ) async {
    final prompt =
        '''
A student has written this summary for the story "$storyTitle":

Student's summary: "$studentSummary"

Original story: $storyContent

Please provide helpful, encouraging feedback for the student. Focus on:
1. What they did well
2. One or two gentle suggestions for improvement
3. Encouragement to keep reading and writing

Keep the feedback positive, age-appropriate, and constructive. Limit to 2-3 sentences.
''';
    // This method expects a plain string, so no JSON cleaning is needed here.
    final result = await _makeGeminiRequest(prompt);
    return result;
  }

  /// Generates 3 story path suggestions based on reading history.
  Future<List<String>> generateStoryPathSuggestions(
    List<String> readStories,
    String currentStory,
  ) async {
    final prompt =
        '''
A student has read these stories: ${readStories.join(', ')}
They just finished reading: "$currentStory"

Based on their reading history, suggest 3 similar stories or themes they might enjoy next. Focus on:
- Similar genres or themes
- Age-appropriate content
- Progressive difficulty
- Engaging topics for children

Format as a JSON array of story suggestions:
["Story suggestion 1", "Story suggestion 2", "Story suggestion 3"]
''';

    final response = await _makeGeminiRequest(prompt);
    if (response != null) {
      try {
        final cleanedResponse = _cleanJsonString(response);
        final List<dynamic> suggestions = json.decode(cleanedResponse);
        return suggestions.cast<String>();
      } catch (e) {
        print('Error parsing JSON for story path suggestions: $e');
        return response
            .split('\n')
            .where((line) => line.trim().isNotEmpty && !line.contains('```'))
            .map((line) => line.replaceAll(RegExp(r'^[0-9]+\.\s*'), '').trim())
            .take(3)
            .toList();
      }
    }
    return _getDefaultPathSuggestions();
  }

  /// Generates 3 writing prompts for a given story title.
  Future<List<String>> generateWritingPrompts(String storyTitle) async {
    final prompt =
        '''
For the story "$storyTitle", generate 3 helpful writing prompts that can help a student start writing their summary. Each prompt should:
- Be a question or starter sentence
- Help them think about key story elements
- Be encouraging and supportive
- Be age-appropriate

Format as a JSON array:
["Prompt 1", "Prompt 2", "Prompt 3"]
''';

    final response = await _makeGeminiRequest(prompt);
    if (response != null) {
      try {
        final cleanedResponse = _cleanJsonString(response);
        final List<dynamic> prompts = json.decode(cleanedResponse);
        return prompts.cast<String>();
      } catch (e) {
        print('Error parsing JSON for writing prompts: $e');
        return response
            .split('\n')
            .where((line) => line.trim().isNotEmpty && !line.contains('```'))
            .map((line) => line.replaceAll(RegExp(r'^[0-9]+\.\s*'), '').trim())
            .take(3)
            .toList();
      }
    }
    return _getDefaultWritingPrompts();
  }

  // ========== PRIVATE METHODS ==========

  /// Cleans the raw response from the API to extract a valid JSON string.
  String _cleanJsonString(String rawResponse) {
    final RegExp jsonBlockRegex = RegExp(
      r'```(json)?\s*([\s\S]*?)\s*```',
      multiLine: true,
    );

    final match = jsonBlockRegex.firstMatch(rawResponse);

    if (match != null) {
      // Extract content from the Markdown code block
      return match.group(2)!.trim();
    } else {
      // If no code block is found, return the raw string for parsing
      return rawResponse.trim();
    }
  }

  /// Makes a request to the Gemini API with the given prompt.
  Future<String?> _makeGeminiRequest(String prompt) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_NOT_FOUND' || _apiKey.isEmpty) {
      print(
        'Gemini API Key not found in .env file. Please ensure it is set up correctly.',
      );
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check for candidates and parts before accessing them
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data["candidates"][0]["content"]["parts"][0]["text"];
        } else if (data['error'] != null) {
          print('Gemini API error: ${data['error']['message']}');
        } else {
          print('Unexpected Gemini API response format: ${response.body}');
        }
      } else {
        print(
          'Gemini API request failed with status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error making Gemini request: $e');
    }

    return null;
  }

  // Defaults for when Gemini API fails or returns unexpected format
  List<String> _getDefaultSuggestions() => [
    "This story was about a character who went on an adventure and learned something important.",
    "The main character faced a challenge and found a way to solve it with help from friends.",
    "This was an exciting story about friendship, courage, and discovering new things.",
  ];

  List<String> _getDefaultPathSuggestions() => [
    "Try reading more adventure stories with brave characters",
    "Look for stories about friendship and teamwork",
    "Explore tales with magical elements and wonder",
  ];

  List<String> _getDefaultWritingPrompts() => [
    "What was your favorite part of this story and why?",
    "Who was the main character and what did they learn?",
    "How did the story make you feel, and what happened that was exciting?",
  ];
}
