import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/ui/screens/students/StudentReviewsPage.dart';
import 'package:storyapp/ui/screens/students/achievements_page.dart';
import 'package:storyapp/ui/screens/students/challenges_page.dart';
import 'package:storyapp/ui/screens/students/full_history_page.dart';

import 'package:storyapp/ui/screens/students/profile_page.dart';
import 'package:storyapp/ui/screens/students/story_explorer_page.dart';
import 'package:storyapp/ui/screens/students/story_reader_page.dart';
import 'package:storyapp/utils/responsive_utils.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final student = Provider.of<AuthProvider>(context, listen: false)
        .currentUser as Student;

    _pages = [
      _HomeTab(student: student),
      StoryExplorerPage(
        student: student,
        onStorySelected: (story) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryReaderPage(
                story: story,
                student: student,
                isRootStory: true,
              ),
            ),
          );
        },
      ),
      const ChallengesPage(),
      AchievementsPage(student: student),
      StudentReviewsPage(student: student),
      const ProfilePage(),
    ];

    // Écouter les récompenses de série
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForStreakRewards();
    });
  }

  void _listenForStreakRewards() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.addListener(() {
      // Vérifie si le message d'erreur spécifique à la récompense est présent
      if (authProvider.errorMessage == 'STREAK_REWARD_100') {
        _showStreakRewardDialog();
        authProvider
            .clearError(); // Nettoie le message pour ne pas le réafficher
      }
    });
  }

  void _showStreakRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
            SizedBox(width: 10),
            Text(
              '7-Day Streak!',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, color: Colors.amber[600], size: 64),
            SizedBox(height: 16),
            Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ve completed a 7-day login streak and earned 100 bonus points!',
              style: TextStyle(fontSize: 16, fontFamily: 'ComicNeue'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.yellow[700], size: 20),
                  SizedBox(width: 5),
                  Text(
                    '+100 Points',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Awesome!', style: TextStyle(fontFamily: 'ComicNeue')),
          ),
        ],
      ),
    );
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
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6A11CB),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedFontSize: ResponsiveUtils.responsiveFontSize(context,
            small: 10.0, medium: 11.0, large: 12.0, xlarge: 13.0),
        unselectedFontSize: ResponsiveUtils.responsiveFontSize(context,
            small: 9.0, medium: 10.0, large: 11.0, xlarge: 12.0),
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home,
                  size: ResponsiveUtils.responsiveIconSize(context)),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore,
                  size: ResponsiveUtils.responsiveIconSize(context)),
              label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events,
                size: ResponsiveUtils.responsiveIconSize(context)),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star,
                size: ResponsiveUtils.responsiveIconSize(context)),
            label: 'Achievements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews,
                size: ResponsiveUtils.responsiveIconSize(context)),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person,
                  size: ResponsiveUtils.responsiveIconSize(context)),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final Student student;
  const _HomeTab({required this.student});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Stream<List<Map<String, dynamic>>>? _historyStream;

  @override
  void initState() {
    super.initState();
    final firestoreService = FirestoreService();
    _historyStream = firestoreService.getReadingHistory(widget.student.uid);
  }

  // Avatar helper methods
  Color _getAvatarColor(String? avatarId) {
    switch (avatarId) {
      case 'hero_knight':
        return Colors.blue;
      case 'curious_explorer':
        return Colors.orange;
      case 'kind_healer':
        return Colors.green;
      case 'honest_sage':
        return Colors.purple;
      case 'creative_artist':
        return Colors.pink;
      case 'brave_adventurer':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAvatarIcon(String avatarId) {
    switch (avatarId) {
      case 'hero_knight':
        return Icons.shield;
      case 'curious_explorer':
        return Icons.explore;
      case 'kind_healer':
        return Icons.healing;
      case 'honest_sage':
        return Icons.auto_stories;
      case 'creative_artist':
        return Icons.palette;
      case 'brave_adventurer':
        return Icons.hiking;
      default:
        return Icons.person;
    }
  }

  String _getAvatarName(String avatarId) {
    switch (avatarId) {
      case 'hero_knight':
        return 'Hero Knight';
      case 'curious_explorer':
        return 'Curious Explorer';
      case 'kind_healer':
        return 'Kind Healer';
      case 'honest_sage':
        return 'Honest Sage';
      case 'creative_artist':
        return 'Creative Artist';
      case 'brave_adventurer':
        return 'Brave Adventurer';
      default:
        return 'Adventurer';
    }
  }

  void _showAvatarInfo(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getAvatarIcon(student.selectedAvatarId ?? ''),
              color: _getAvatarColor(student.selectedAvatarId),
              size: 32,
            ),
            const SizedBox(width: 10),
            Text(
              _getAvatarName(student.selectedAvatarId ?? ''),
              style: const TextStyle(
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar traits
            const Text(
              'Your Traits:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: student.avatarTraits.entries.map((entry) {
                if (entry.value > 0) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getAvatarColor(student.selectedAvatarId)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getAvatarColor(student.selectedAvatarId),
                      ),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getAvatarColor(student.selectedAvatarId),
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Trait Points: ${student.totalTraitPoints}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dominant Trait: ${student.dominantTrait}',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final student = auth.currentUser as Student;
        return ListView(
          padding: ResponsiveUtils.responsivePadding(context),
          children: [
            // Header with Avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: ResponsiveTextStyles.headlineMedium(context)
                            .copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        student.displayName,
                        style: ResponsiveTextStyles.headlineLarge(context)
                            .copyWith(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Avatar with selection indicator
                GestureDetector(
                  onTap: () => _showAvatarInfo(context, student),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: ResponsiveUtils.responsiveAvatarSize(context,
                          small: 20.0, medium: 24.0, large: 28.0, xlarge: 32.0),
                      backgroundColor:
                          _getAvatarColor(student.selectedAvatarId),
                      child: student.selectedAvatarId != null
                          ? Icon(
                              _getAvatarIcon(student.selectedAvatarId!),
                              color: Colors.white,
                              size: ResponsiveUtils.responsiveIconSize(context,
                                  small: 24.0,
                                  medium: 28.0,
                                  large: 32.0,
                                  xlarge: 36.0),
                            )
                          : CircleAvatar(
                              radius: ResponsiveUtils.responsiveAvatarSize(
                                  context,
                                  small: 20.0,
                                  medium: 24.0,
                                  large: 28.0,
                                  xlarge: 32.0),
                              backgroundImage:
                                  NetworkImage(student.generatedAvatarUrl),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Points Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.green.withOpacity(0.3),
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.yellow,
                      size: ResponsiveUtils.responsiveIconSize(context,
                          small: 20.0, medium: 24.0, large: 28.0, xlarge: 32.0),
                    ),
                    SizedBox(width: ResponsiveUtils.responsiveSpacing(context)),
                    Text(
                      '${student.points} Points',
                      style: ResponsiveTextStyles.titleLarge(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Avatar Traits Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: _getAvatarColor(student.selectedAvatarId).withOpacity(0.3),
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getAvatarIcon(student.selectedAvatarId ?? ''),
                          color: _getAvatarColor(student.selectedAvatarId),
                          size: ResponsiveUtils.responsiveIconSize(context),
                        ),
                        SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(context)),
                        Expanded(
                          child: Text(
                            'Your Avatar: ${_getAvatarName(student.selectedAvatarId ?? '')}',
                            style: ResponsiveTextStyles.titleMedium(context)
                                .copyWith(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(context)),
                    Text(
                      'Character Traits:',
                      style: ResponsiveTextStyles.bodyLarge(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(context,
                            small: 6.0,
                            medium: 8.0,
                            large: 10.0,
                            xlarge: 12.0)),
                    Wrap(
                      spacing: ResponsiveUtils.responsiveSpacing(context,
                          small: 6.0, medium: 8.0, large: 10.0, xlarge: 12.0),
                      runSpacing: ResponsiveUtils.responsiveSpacing(context,
                          small: 6.0, medium: 8.0, large: 10.0, xlarge: 12.0),
                      children: student.avatarTraits.entries.map((entry) {
                        if (entry.value > 0) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  small: 8.0,
                                  medium: 10.0,
                                  large: 12.0,
                                  xlarge: 14.0),
                              vertical: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  small: 3.0,
                                  medium: 4.0,
                                  large: 5.0,
                                  xlarge: 6.0),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: ResponsiveTextStyles.bodySmall(context)
                                  .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                    ),
                    SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(context,
                            small: 6.0,
                            medium: 8.0,
                            large: 10.0,
                            xlarge: 12.0)),
                    Text(
                      'Dominant: ${student.dominantTrait}',
                      style: ResponsiveTextStyles.bodyMedium(context).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Enhanced Daily Streak Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.amber.withOpacity(0.3),
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: student.loginStreak > 0
                              ? Colors.orange
                              : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Daily Streak: ${student.loginStreak}/7',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Streak progress indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        bool isAchieved = index < student.loginStreak;
                        bool isCurrent = index == student.loginStreak &&
                            student.loginStreak < 7;

                        return Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAchieved
                                ? Colors.orange
                                : isCurrent
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.2),
                            border: isCurrent
                                ? Border.all(color: Colors.orange, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: isAchieved
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? Colors.orange
                                          : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    // Streak reward info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.yellow,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Complete 7 days for 100 bonus points!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'ComicNeue',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // History Section
            _buildHistorySection(),
          ],
        );
      },
    );
  }

  Widget _buildHistorySection() {
    if (_historyStream == null) return const SizedBox.shrink();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        // Filter to show only root stories (stories with choices, not path stories)
        final allHistory = snapshot.data!;
        final rootStories = allHistory.where((history) {
          // Check if this story has choices (indicating it's a root story)
          // We'll assume stories with choices are root stories
          return true; // For now, show all stories until we can implement proper filtering
        }).toList();

        if (rootStories.isEmpty) return const SizedBox.shrink();

        final recentHistory = rootStories.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Continue Reading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ComicNeue',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FullHistoryPage()),
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: recentHistory.length,
                itemBuilder: (context, index) =>
                    _buildHistoryCard(context, recentHistory[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> history) {
    return InkWell(
      onTap: () => _openStory(context, history),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(16),
          image: history['imageUrl'] != null && history['imageUrl'].isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(history['imageUrl']),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            if (history['imageUrl'] == null || history['imageUrl'].isEmpty)
              const Center(
                child: Icon(Icons.auto_stories, color: Colors.white, size: 40),
              ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                history['title'] ?? 'Unknown Story',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ComicNeue',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStory(
    BuildContext context,
    Map<String, dynamic> history,
  ) async {
    final firestoreService = FirestoreService();
    final student = Provider.of<AuthProvider>(context, listen: false)
        .currentUser as Student?;
    if (student == null) return;
    try {
      final story = await firestoreService.getStoryById(history['storyId']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryReaderPage(
            story: story,
            student: student,
            isRootStory: true,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open story. It may have been deleted.'),
        ),
      );
    }
  }
}
