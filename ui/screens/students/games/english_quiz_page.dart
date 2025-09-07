import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/providers/auth_provider.dart';

// A simple data class for our quiz questions
class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class EnglishQuizPage extends StatefulWidget {
  const EnglishQuizPage({super.key});

  @override
  State<EnglishQuizPage> createState() => _EnglishQuizPageState();
}

class _EnglishQuizPageState extends State<EnglishQuizPage> {
  // Simplified questions for kids
  final List<QuizQuestion> _allQuestions = [
    QuizQuestion(
      question: "What color is the sun?",
      options: ["Blue", "Yellow", "Green", "Purple"],
      correctAnswer: "Yellow",
    ),
    QuizQuestion(
      question: "How many legs does a cat have?",
      options: ["2", "4", "6", "8"],
      correctAnswer: "4",
    ),
    QuizQuestion(
      question: "What do you use to write?",
      options: ["Spoon", "Pencil", "Cup", "Shoe"],
      correctAnswer: "Pencil",
    ),
    QuizQuestion(
      question: "Where do fish live?",
      options: ["Tree", "Sky", "Water", "Car"],
      correctAnswer: "Water",
    ),
    QuizQuestion(
      question: "What sound does a dog make?",
      options: ["Meow", "Moo", "Woof", "Chirp"],
      correctAnswer: "Woof",
    ),
    QuizQuestion(
      question: "What do you wear on your feet?",
      options: ["Hat", "Shoes", "Gloves", "Scarf"],
      correctAnswer: "Shoes",
    ),
    QuizQuestion(
      question: "What fruit is red?",
      options: ["Banana", "Apple", "Orange", "Grape"],
      correctAnswer: "Apple",
    ),
    QuizQuestion(
      question: "How many eyes do you have?",
      options: ["1", "2", "3", "4"],
      correctAnswer: "2",
    ),
    QuizQuestion(
      question: "What do bees make?",
      options: ["Milk", "Honey", "Bread", "Juice"],
      correctAnswer: "Honey",
    ),
    QuizQuestion(
      question: "What comes after Monday?",
      options: ["Sunday", "Tuesday", "Friday", "Saturday"],
      correctAnswer: "Tuesday",
    ),
    QuizQuestion(
      question: "What do you sleep in?",
      options: ["Chair", "Table", "Bed", "Car"],
      correctAnswer: "Bed",
    ),
    QuizQuestion(
      question: "What season comes after winter?",
      options: ["Summer", "Fall", "Spring", "Winter"],
      correctAnswer: "Spring",
    ),
  ];

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _selectRandomQuestions();
  }

  void _selectRandomQuestions() {
    // Select 5 random questions from the pool
    final random = Random();
    final shuffled = List<QuizQuestion>.from(_allQuestions);
    shuffled.shuffle(random);
    _questions = shuffled.take(5).toList();
  }

  void _checkAnswer(String selectedAnswer) {
    setState(() {
      _answered = true;
      _selectedAnswer = selectedAnswer;
      if (selectedAnswer == _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswer = null;
        });
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    final pointsWon = _score * 10; // 10 points per correct answer
    Provider.of<AuthProvider>(context, listen: false).addPoints(pointsWon);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quiz Complete!',
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You scored $_score out of ${_questions.length}!\nYou earned $pointsWon points!',
          style: const TextStyle(fontFamily: 'ComicNeue', fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to challenges page
            },
            child: const Text(
              'Great!',
              style: TextStyle(fontFamily: 'ComicNeue'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(String option) {
    if (!_answered) {
      return Colors.white.withOpacity(0.9);
    }

    if (option == _questions[_currentQuestionIndex].correctAnswer) {
      return Colors.green.withOpacity(0.8);
    } else if (option == _selectedAnswer) {
      return Colors.red.withOpacity(0.8);
    } else {
      return Colors.white.withOpacity(0.5);
    }
  }

  Color _getButtonTextColor(String option) {
    if (!_answered) {
      return const Color(0xFF6A11CB);
    }

    if (option == _questions[_currentQuestionIndex].correctAnswer ||
        option == _selectedAnswer) {
      return Colors.white;
    } else {
      return const Color(0xFF6A11CB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'English Quiz',
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'ComicNeue',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Score: $_score',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.yellow,
                        ),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Question section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ComicNeue',
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Options section
                Expanded(
                  child: Column(
                    children: currentQuestion.options.map((option) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _answered
                              ? null
                              : () => _checkAnswer(option),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getButtonColor(option),
                            foregroundColor: _getButtonTextColor(option),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ComicNeue',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_answered &&
                                  option ==
                                      _questions[_currentQuestionIndex]
                                          .correctAnswer)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              if (_answered &&
                                  option == _selectedAnswer &&
                                  option !=
                                      _questions[_currentQuestionIndex]
                                          .correctAnswer)
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              if (_answered &&
                                  (option ==
                                          _questions[_currentQuestionIndex]
                                              .correctAnswer ||
                                      option == _selectedAnswer))
                                const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  option,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
