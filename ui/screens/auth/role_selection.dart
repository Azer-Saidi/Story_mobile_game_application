import 'dart:math';

import 'package:flutter/material.dart';
import 'login_page.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleRoleTap(String role) {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(role: role)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Static background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
            ),
          ),

          // Floating stars animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return CustomPaint(
                  painter: StarPainter(
                    animationValue: _animationController.value,
                  ),
                );
              },
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, -_bounceAnimation.value),
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: const CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.menu_book,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // Title with animation
                    _AnimatedText(
                      text: 'StoryCraft',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black38,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Where stories come to life',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),

                    // Role selection cards with animation
                    _AnimatedCard(
                      delay: 0,
                      child: _buildRoleCard(
                        title: "I'm a Student",
                        subtitle: "Join exciting story adventures",
                        icon: Icons.school,
                        color: Colors.lightBlueAccent,
                        onTap: () => _handleRoleTap('student'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AnimatedCard(
                      delay: 200,
                      child: _buildRoleCard(
                        title: "I'm a Teacher",
                        subtitle: "Create engaging stories",
                        icon: Icons.person,
                        color: Colors.amberAccent,
                        onTap: () => _handleRoleTap('teacher'),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Footer
                    const Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AnimatedBookLoader(),
                    SizedBox(height: 20),
                    Text(
                      'Opening your story world...',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

//------------------------ PRIVATE WIDGETS ------------------------

class _AnimatedBookLoader extends StatefulWidget {
  const _AnimatedBookLoader();

  @override
  State<_AnimatedBookLoader> createState() => __AnimatedBookLoaderState();
}

class __AnimatedBookLoaderState extends State<_AnimatedBookLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnimation;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _flipAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value * pi),
            child: const Icon(Icons.menu_book, size: 80, color: Colors.white),
          ),
        );
      },
    );
  }
}

class StarPainter extends CustomPainter {
  final double animationValue;
  static const _starCount = 15;

  StarPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Fixed seed for consistent star placement

    // Draw multiple stars
    for (int i = 0; i < _starCount; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();

      // Add animation to make stars twinkle
      final scale = 0.5 + 0.5 * (animationValue + i * 0.1) % 1.0;
      final radius = 2.0 * scale;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _AnimatedText({required this.text, required this.style});

  @override
  State<_AnimatedText> createState() => __AnimatedTextState();
}

class __AnimatedTextState extends State<_AnimatedText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        // Clamp opacity value to valid range [0.0, 1.0]
        final clampedOpacity = _animation.value.clamp(0.0, 1.0);

        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: clampedOpacity,
            child: Text(widget.text, style: widget.style),
          ),
        );
      },
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => __AnimatedCardState();
}

class __AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Add delay to animation
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
        );
      },
    );
  }
}
// This code defines a RoleSelectionScreen widget that allows users to select their role (student or teacher) before proceeding to the login page. It features animated elements like a bouncing logo, floating stars, and animated cards for role selection. The screen has a modern design with a gradient background and loading animations when transitioning to the login page.
// The RoleSelectionScreen uses Flutter's animation framework to create a visually appealing user interface. It