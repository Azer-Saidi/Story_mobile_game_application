import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storyapp/models/summary_model.dart';
import 'package:storyapp/models/teacher_model.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/ui/screens/teacher/summary_review_page.dart';

class SubmissionsListPage extends StatelessWidget {
  final Teacher teacher;

  const SubmissionsListPage({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      // ✅ CHANGE: The AppBar has been completely removed from this Scaffold.
      // This page will now display under the main TeacherDashboard's AppBar.
      body: StreamBuilder<List<SummaryModel>>(
        stream: firestoreService.getSummariesForTeacher(teacher.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "No Submissions Yet",
                    style: TextStyle(fontSize: 22, color: Colors.grey),
                  ),
                  Text(
                    "Student summaries will appear here.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final summaries = snapshot.data!;

          summaries.sort((a, b) {
            if (a.rating == null && b.rating != null) return -1;
            if (a.rating != null && b.rating == null) return 1;
            return b.submittedAt.compareTo(a.submittedAt);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return _buildSummaryCard(context, summary);
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, SummaryModel summary) {
    final bool isRated = summary.rating != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: isRated
              ? Colors.green.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
          child: Text(
            summary.studentName.isNotEmpty
                ? summary.studentName[0].toUpperCase()
                : 'S',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRated ? Colors.green : Colors.blue,
            ),
          ),
        ),
        title: Text(
          summary.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'For story: "${summary.storyTitle}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isRated
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary.rating.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              )
            : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SummaryReviewPage(summary: summary, summaries: [summary]),
            ),
          );
        },
      ),
    );
  }
}
