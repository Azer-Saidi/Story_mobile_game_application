import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/providers/auth_provider.dart';

class AdditionPage extends StatefulWidget {
  const AdditionPage({super.key});

  @override
  State<AdditionPage> createState() => _AdditionPageState();
}

class _AdditionPageState extends State<AdditionPage> {
  final Random _random = Random();
  int _num1 = 0, _num2 = 0, _score = 0;
  final List<int> _options = [];
  Timer? _timer;
  int _timeLeft = 10;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _generateQuestion() {
    _num1 = _random.nextInt(50) + 1; // Numbers from 1 to 50
    _num2 = _random.nextInt(50) + 1;
    int correctAnswer = _num1 + _num2;

    _options.clear();
    _options.add(correctAnswer);
    while (_options.length < 4) {
      int wrongOption = (_random.nextInt(20) - 10) + correctAnswer;
      if (wrongOption > 0 && !_options.contains(wrongOption)) {
        _options.add(wrongOption);
      }
    }
    _options.shuffle();
    _startTimer();
  }

  void _checkAnswer(int selectedAnswer) {
    if (selectedAnswer == _num1 + _num2) {
      setState(() => _score++);
      _generateQuestion();
    } else {
      _endGame();
    }
  }

  void _endGame() {
    _timer?.cancel();
    final pointsWon = _score * 5; // 5 points per correct answer
    // Update student's points
    Provider.of<AuthProvider>(context, listen: false).addPoints(pointsWon);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('You scored $_score!\nYou earned $pointsWon points!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to challenges page
            },
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Addition Blitz',
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Score: $_score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _timeLeft < 4
                        ? Colors.red.withOpacity(0.8)
                        : Colors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        color: _timeLeft < 4 ? Colors.white : Colors.yellow,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Time: $_timeLeft',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft < 4 ? Colors.white : Colors.white,
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
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
                    '$_num1 + $_num2 = ?',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ComicNeue',
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: _options.map((option) {
                    return Container(
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
                        onPressed: () => _checkAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: const Color(0xFF6A11CB),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ComicNeue',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Text('$option'),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
