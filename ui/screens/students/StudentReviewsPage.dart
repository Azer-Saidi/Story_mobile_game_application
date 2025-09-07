import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/models/summary_model.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:intl/intl.dart';

class StudentReviewsPage extends StatefulWidget {
  final Student student;
  const StudentReviewsPage({super.key, required this.student});

  @override
  State<StudentReviewsPage> createState() => _StudentReviewsPageState();
}

class _StudentReviewsPageState extends State<StudentReviewsPage> {
  late Stream<List<SummaryModel>> _summariesStream;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _summariesStream = _firestoreService.getSummariesForStudent(
      widget.student.uid,
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.greenAccent;
    if (score >= 70) return Colors.orangeAccent;
    if (score >= 50) return Colors.lightBlueAccent;
    return Colors.redAccent;
  }

  String _getScoreText(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    // MODIFIÉ: Le Scaffold n'a plus de AppBar ici, car on l'ajoute dans le corps pour la transparence.
    return Scaffold(
      // MODIFIÉ: Le corps est maintenant enveloppé dans un Container avec le dégradé.
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
              // MODIFIÉ: Ajout d'un en-tête personnalisé pour correspondre au style.
              _buildHeader(),
              Expanded(
                child: StreamBuilder<List<SummaryModel>>(
                  stream: _summariesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      print('Error fetching summaries: ${snapshot.error}');
                      return const Center(
                        child: Text(
                          'Could not load reviews.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final summaries = snapshot.data!;
                    final reviewedSummaries = summaries
                        .where(
                          (s) =>
                              s.aiReview != null && s.aiAccuracyScore != null,
                        )
                        .toList();
                    final pendingSummaries = summaries
                        .where(
                          (s) =>
                              s.aiReview == null || s.aiAccuracyScore == null,
                        )
                        .toList();

                    if (summaries.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (reviewedSummaries.isNotEmpty) ...[
                          _buildSummaryStats(reviewedSummaries),
                          const SizedBox(height: 20),
                          const Text(
                            'Reviewed Summaries',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...reviewedSummaries
                              .map((s) => _buildReviewCard(s))
                              .toList(),
                        ],
                        if (pendingSummaries.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              top: reviewedSummaries.isNotEmpty ? 20 : 0,
                              bottom: 10,
                            ),
                            child: const Text(
                              'Pending AI Review',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'ComicNeue',
                              ),
                            ),
                          ),
                          ...pendingSummaries
                              .map((s) => _buildPendingCard(s))
                              .toList(),
                        ],
                        const SizedBox(height: 20), // Espace en bas
                      ],
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

  // MODIFIÉ: Nouveau widget pour l'en-tête de la page.
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        'My Reviews',
        style: TextStyle(
          fontFamily: 'ComicNeue',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // MODIFIÉ: Nouveau widget pour l'état vide.
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'ComicNeue',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Submit a story summary to see your reviews here.',
            style: TextStyle(color: Colors.white70, fontFamily: 'ComicNeue'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(List<SummaryModel> summaries) {
    final scores = summaries.map((s) => s.aiAccuracyScore!).toList();
    final averageScore = scores.isNotEmpty
        ? scores.reduce((a, b) => a + b) / scores.length
        : 0.0;
    final teacherRatings = summaries
        .where((s) => s.rating != null)
        .map((s) => s.rating!.toDouble())
        .toList();
    final averageTeacherRating = teacherRatings.isNotEmpty
        ? teacherRatings.reduce((a, b) => a + b) / teacherRatings.length
        : 0.0;

    // MODIFIÉ: Style de la carte de statistiques.
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Your Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'AI Average',
                  '${averageScore.toStringAsFixed(1)}%',
                  _getScoreColor(averageScore),
                ),
                _buildStatCard(
                  'Teacher Avg.',
                  '${averageTeacherRating.toStringAsFixed(1)}/5',
                  Colors.amber,
                ),
                _buildStatCard(
                  'Reviewed',
                  '${summaries.length}',
                  Colors.cyanAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontFamily: 'ComicNeue',
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(SummaryModel summary) {
    final score = summary.aiAccuracyScore ?? 0;

    // MODIFIÉ: Style de la carte de révision.
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.1),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(score).withOpacity(0.2),
          child: Text(
            '${score.toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
        ),
        title: Text(
          summary.storyTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'ComicNeue',
          ),
        ),
        subtitle: Text(
          DateFormat.yMMMd().add_jm().format(summary.submittedAt),
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'ComicNeue',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  icon: Icons.auto_awesome,
                  title: 'AI Review: ${_getScoreText(score)}',
                  color: Colors.purpleAccent,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    summary.aiReview ?? 'No AI review available.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  icon: Icons.school,
                  title: 'Teacher Feedback',
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(height: 10),
                if (summary.rating != null)
                  Row(
                    children: [
                      const Text(
                        'Rating: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < summary.rating!
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Teacher has not rated this summary yet.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  icon: Icons.text_snippet,
                  title: 'Your Summary',
                  color: Colors.tealAccent,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    summary.summaryText,
                    style: const TextStyle(height: 1.5, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'ComicNeue',
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCard(SummaryModel summary) {
    // MODIFIÉ: Style de la carte en attente.
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        title: Text(
          summary.storyTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'ComicNeue',
          ),
        ),
        subtitle: Text(
          'Submitted: ${DateFormat.yMMMd().format(summary.submittedAt)}',
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'ComicNeue',
          ),
        ),
        trailing: const Text(
          'Processing...',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
        ),
      ),
    );
  }
}
