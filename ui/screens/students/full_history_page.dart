import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/ui/screens/students/story_reader_page.dart';

class FullHistoryPage extends StatelessWidget {
  const FullHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final student = authProvider.currentUser as Student;
    final firestoreService = FirestoreService();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Full Reading History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.getReadingHistory(student.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No history found.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                );
              }
              final historyItems = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final history = historyItems[index];
                  return _buildHistoryListItem(
                    context,
                    history,
                    student,
                    firestoreService,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryListItem(
    BuildContext context,
    Map<String, dynamic> history,
    Student student,
    FirestoreService service,
  ) {
    return InkWell(
      onTap: () async {
        try {
          final story = await service.getStoryById(history['storyId']);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryReaderPage(
                story: story,
                student: student,
                isRootStory: false,
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
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: history['imageUrl'] != null && history['imageUrl'].isNotEmpty
                ? Image.network(
                    history['imageUrl'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.deepPurple,
                    child: const Icon(Icons.auto_stories, color: Colors.white),
                  ),
          ),
          title: Text(
            history['title'] ?? 'Unknown Story',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            (history['type'] as String? ?? 'Story').toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
