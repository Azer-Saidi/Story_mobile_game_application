import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/achievement_model.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/providers/auth_provider.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, required Student student});

  @override
  Widget build(BuildContext context) {
    // Get the current user's storiesRead count from the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final storiesRead = authProvider.currentUser?.storiesRead ?? 0;

    final allAchievements = AchievementsList.allAchievements;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Achievements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final achievement = allAchievements[index];
              final isUnlocked = storiesRead >= achievement.goal;

              return _buildAchievementCard(achievement, isUnlocked);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isUnlocked ? 8 : 2,
      shadowColor: isUnlocked
          ? Colors.amber.withOpacity(0.5)
          : Colors.black.withOpacity(0.2),
      color: isUnlocked
          ? Colors.white.withOpacity(0.2)
          : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isUnlocked ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              achievement.icon,
              size: 40,
              color: isUnlocked ? Colors.amber : Colors.white54,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnlocked
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked)
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 30,
              ),
          ],
        ),
      ),
    );
  }
}
