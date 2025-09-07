import 'package:flutter/material.dart';
import 'package:storyapp/ui/screens/students/games/english_quiz_page.dart';
import 'package:storyapp/ui/screens/students/games/multiplication_page.dart';
import 'package:storyapp/ui/screens/students/games/addition_page.dart';
import 'package:storyapp/ui/screens/students/games/subtraction_page.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          "Brain-Booster Challenges",
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
          child: Column(
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: Colors.yellow,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Choose your brain challenge",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    itemCount: _getGames().length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          // Adjusted aspect ratio for the new layout
                          childAspectRatio: 0.8,
                        ),
                    itemBuilder: (context, index) {
                      final game = _getGames()[index];
                      final animation = Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.1 * index,
                            0.5 + 0.1 * index,
                            curve: Curves.easeOut,
                          ),
                        ),
                      );

                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: animation.value,
                            child: Opacity(
                              opacity: animation.value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildGameCard(
                          context: context,
                          title: game['title'],
                          icon: game['icon'],
                          color: game['color'],
                          page: game['page'],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getGames() {
    return [
      {
        'title': 'English Quiz',
        'icon': Icons.spellcheck,
        'color': Colors.blue,
        'page': const EnglishQuizPage(),
      },
      {
        'title': 'Multiplication',
        'icon': Icons.close,
        'color': Colors.green,
        'page': const MultiplicationPage(),
      },
      {
        'title': 'Addition',
        'icon': Icons.add,
        'color': Colors.orange,
        'page': const AdditionPage(),
      },
      {
        'title': 'Subtraction',
        'icon': Icons.remove,
        'color': Colors.red,
        'page': const SubtractionPage(),
      },
    ];
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(20),
      child: Hero(
        tag: title,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon section (now takes more space)
              Expanded(
                flex: 4, // Increased flex to give more space to the icon
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 60, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PLAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Text section (now only contains the title)
              Expanded(
                flex: 1, // Reduced flex as it only holds the title
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  // Center the title vertically
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'ComicNeue',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
