import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/providers/auth_provider.dart';

class StoryExplorerPage extends StatefulWidget {
  final Student student;
  final void Function(StoryModel story) onStorySelected;

  const StoryExplorerPage({
    super.key,
    required this.student,
    required this.onStorySelected,
  });

  @override
  State<StoryExplorerPage> createState() => _StoryExplorerPageState();
}

class _StoryExplorerPageState extends State<StoryExplorerPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final List<String> categories = ["All", ...StoryType.allTypes];
  final FirestoreService _firestoreService = FirestoreService();

  late Future<List<StoryModel>> _storiesFuture;
  late Stream<List<String>> _unlockedStoriesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    _storiesFuture = _firestoreService.getStoriesByCategoryOnce(null);
    _unlockedStoriesStream = _firestoreService.getUnlockedStoryIdsStream(
      widget.student.uid,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _updateStoriesForCategory(categories[_tabController.index]);
      }
    });
  }

  void _updateStoriesForCategory(String category) {
    setState(() {
      _storiesFuture = _firestoreService.getStoriesByCategoryOnce(
        category == 'All' ? null : category,
      );
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _handleStoryTap(
    StoryModel story,
    bool isUnlocked,
    BuildContext context,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (story.pointsToUnlock == 0 || isUnlocked) {
      widget.onStorySelected(story);
    } else {
      _showUnlockConfirmationDialog(story, authProvider);
    }
  }

  Future<void> _showUnlockConfirmationDialog(
    StoryModel story,
    AuthProvider authProvider,
  ) async {
    final student = authProvider.currentUser as Student;
    final bool canAfford = student.points >= story.pointsToUnlock;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(canAfford ? 'Unlock this Story?' : 'Not Enough Points'),
          content: Text(
            canAfford
                ? 'This will cost ${story.pointsToUnlock} points. Your current balance is ${student.points}. Do you want to proceed?'
                : 'You need ${story.pointsToUnlock} points to unlock this story, but you only have ${student.points}. Play some games in the Challenges tab to earn more!',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            if (canAfford)
              ElevatedButton(
                child: const Text('Unlock'),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  bool success = await authProvider.unlockStory(story);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Story Unlocked!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage ?? 'Failed to unlock story',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          "Story Explorer",
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: categories.map((category) {
            return Tab(text: category);
          }).toList(),
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
          ),
          onTap: (index) {
            // _updateStoriesForCategory is called by the listener
          },
        ),
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
              // Points Display
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final student = authProvider.currentUser as Student;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Choose your magical journey",
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 360
                                  ? 16
                                  : 18,
                              color: Colors.white,
                              fontFamily: 'ComicNeue',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${student.points} Points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _unlockedStoriesStream,
                  builder: (context, unlockedSnapshot) {
                    if (unlockedSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (unlockedSnapshot.hasError) {
                      print(
                        "Unlocked stories stream error: ${unlockedSnapshot.error}",
                      );
                      return Center(
                        child: Text(
                          "Error loading unlocked stories: ${unlockedSnapshot.error}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final unlockedIds = unlockedSnapshot.data?.toSet() ?? {};

                    return FutureBuilder<List<StoryModel>>(
                      future: _storiesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          print("Firestore error: ${snapshot.error}");
                          return Center(
                            child: Text(
                              "Something went wrong: ${snapshot.error}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              _tabController.index == 0
                                  ? "No stories available yet"
                                  : "No ${categories[_tabController.index].toLowerCase()} stories yet",
                              style: const TextStyle(
                                fontFamily: 'ComicNeue',
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        final stories = snapshot.data!;
                        final bottomPadding = MediaQuery.of(
                          context,
                        ).padding.bottom;

                        return Padding(
                          padding: EdgeInsets.only(bottom: bottomPadding),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final screenWidth = constraints.maxWidth;
                              final crossAxisCount = 2;
                              final childAspectRatio =
                                  screenWidth < 400 ? 0.62 : 0.65;

                              return GridView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: stories.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemBuilder: (context, index) {
                                  final story = stories[index];
                                  final isUnlocked =
                                      unlockedIds.contains(story.id);
                                  final double totalItems =
                                      stories.length.toDouble();
                                  final double startFactor = 0.1;
                                  final double endFactor = 0.5;
                                  final double maxIntervalEnd =
                                      startFactor + endFactor;

                                  final double normalizedBegin =
                                      (startFactor * index) /
                                          (totalItems * maxIntervalEnd);
                                  final double normalizedEnd =
                                      (endFactor + startFactor * index) /
                                          (totalItems * maxIntervalEnd);

                                  final animation =
                                      Tween<double>(begin: 0, end: 1).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        normalizedBegin,
                                        normalizedEnd.clamp(0.0, 1.0),
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
                                    child: _buildStoryCard(
                                        context, story, isUnlocked),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(
    BuildContext context,
    StoryModel story,
    bool isUnlocked,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final bool showLock = !isUnlocked && story.pointsToUnlock > 0;

    return InkWell(
      onTap: () => _handleStoryTap(story, isUnlocked, context),
      borderRadius: BorderRadius.circular(20),
      child: Hero(
        tag: story.id,
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
              // Image section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    story.imageUrl.isNotEmpty
                        ? Image.network(
                            story.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          (progress.expectedTotalBytes ?? 1)
                                      : null,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.deepPurple,
                              child: const Icon(
                                Icons.auto_stories,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.deepPurple,
                            child: const Icon(
                              Icons.auto_stories,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                    if (showLock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 50,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${story.pointsToUnlock} Points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Text section
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.4),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        story.title,
                        style: TextStyle(
                          fontFamily: 'ComicNeue',
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Description
                      if (story.description?.isNotEmpty ?? false)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              story.description!,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'ComicNeue',
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      // Category chip
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(story.type),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: _getCategoryColor(story.type)
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          story.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 8 : 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'ADVENTURE':
        return Colors.orange.shade600;
      case 'MYSTERY':
        return Colors.purple.shade700;
      case 'FANTASY':
        return Colors.indigo.shade500;
      case 'EDUCATIONAL':
        return Colors.teal.shade600;
      default:
        return Colors.deepPurple.shade600;
    }
  }
}
