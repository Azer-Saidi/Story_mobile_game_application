import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/models/teacher_model.dart';
import 'package:storyapp/services/cloudinary_service.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/ui/screens/teacher/create_story_page.dart';
import 'package:storyapp/ui/screens/teacher/submissions_list_page.dart';
import 'package:storyapp/ui/screens/teacher/teacher_profile.dart';
import 'package:storyapp/ui/screens/auth/role_selection.dart';
import 'package:storyapp/providers/auth_provider.dart';

class TeacherDashboard extends StatefulWidget {
  final Teacher teacher;
  const TeacherDashboard({super.key, required this.teacher});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Teacher _teacher;
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
  }

  void _createNewStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStoryPage(
          teacher: _teacher, // Pass the full object
          cloudinaryService: Provider.of<CloudinaryService>(
            context,
            listen: false,
          ),
          authorId: '${widget.teacher.id}',
        ),
      ),
    );
  }

  void _editStory(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStoryPage(
          initialData: story,
          teacher: _teacher, // Pass the full object
          cloudinaryService: Provider.of<CloudinaryService>(
            context,
            listen: false,
          ),
          authorId: '${widget.teacher.id}',
        ),
      ),
    );
  }

  Future<void> _deleteStory(String storyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story?'),
        content: const Text(
          'This will permanently delete the story and all its branches. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteStory(storyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Story deleted successfully"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting story: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openProfile() async {
    final updatedTeacher = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherProfileScreen(teacher: _teacher),
      ),
    );
    if (updatedTeacher != null && updatedTeacher is Teacher) {
      setState(() => _teacher = updatedTeacher);
    }
  }

  /// ✅ Logout functionality for teachers
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const RoleSelectionScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${_teacher.displayName}'s Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _openProfile,
            tooltip: 'My Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildStoriesView(),
          SubmissionsListPage(teacher: _teacher),
          //
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _createNewStory,
              icon: const Icon(Icons.add),
              label: const Text("New Story"),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            label: 'Submissions',
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesView() {
    return StreamBuilder<List<StoryModel>>(
      stream: _firestoreService.getStoriesByAuthor(_teacher.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  "No Stories Yet",
                  style: TextStyle(fontSize: 22, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                const Text("Tap the button below to create your first story."),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _createNewStory,
                  icon: const Icon(Icons.add),
                  label: const Text("Create a Story"),
                ),
              ],
            ),
          );
        }
        final stories = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return _buildStoryCard(story);
          },
        );
      },
    );
  }

  Widget _buildStoryCard(StoryModel story) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: story.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  story.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: const Icon(Icons.book, color: Colors.grey),
              ),
        title: Text(
          story.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          story.description ?? 'No description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.blue),
              onPressed: () => _editStory(story),
              tooltip: 'Edit Story',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteStory(story.id),
              tooltip: 'Delete Story',
            ),
          ],
        ),
      ),
    );
  }
}
