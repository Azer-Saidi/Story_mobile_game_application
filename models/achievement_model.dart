import 'package:flutter/material.dart';

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final int goal; // The number of stories needed to unlock

  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.goal,
  });
}

// A central list of all achievements available in the app.
class AchievementsList {
  static const List<Achievement> allAchievements = [
    Achievement(
      title: 'First Step',
      description: 'Read your very first story.',
      icon: Icons.looks_one,
      goal: 1,
    ),
    Achievement(
      title: 'Bookworm',
      description: 'Read 5 stories.',
      icon: Icons.menu_book,
      goal: 5,
    ),
    Achievement(
      title: 'Story Explorer',
      description: 'Read 10 stories.',
      icon: Icons.explore,
      goal: 10,
    ),
    Achievement(
      title: 'Library Patron',
      description: 'Read 25 stories.',
      icon: Icons.local_library,
      goal: 25,
    ),
    Achievement(
      title: 'Reading Champion',
      description: 'Read 50 stories.',
      icon: Icons.emoji_events,
      goal: 50,
    ),
    Achievement(
      title: 'Master Storyteller',
      description: 'Read 100 stories.',
      icon: Icons.auto_stories,
      goal: 100,
    ),
  ];
}
