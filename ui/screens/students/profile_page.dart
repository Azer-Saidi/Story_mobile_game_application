import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/ui/screens/auth/role_selection.dart';
import 'package:storyapp/ui/screens/students/notification_settings_page.dart';
import 'package:storyapp/ui/widgets/offline_indicator.dart';
import 'package:storyapp/ui/screens/students/security_page.dart';
import 'package:storyapp/ui/screens/students/avatar_selection_page.dart';
import 'package:storyapp/utils/responsive_utils.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // This method shows the confirmation dialog before logging out.
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
              onPressed: () async {
                await authProvider.logout();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const RoleSelectionScreen(),
                    ),
                    (Route<dynamic> route) => false,
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
  Widget build(BuildContext context) {
    // The Consumer ensures this page always shows the latest data from the provider.
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final student = authProvider.currentUser as Student;

        // ✅ --- THE SCAFFOLD NO LONGER HAS AN APPBAR ---
        // It's now part of the main dashboard's structure.
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
              child: ListView(
                padding: ResponsiveUtils.responsivePadding(context),
                children: [
                  // --- User Info Header ---
                  Column(
                    children: [
                      // ✅ A custom title replaces the AppBar title.
                      Text(
                        'My Profile',
                        style: ResponsiveTextStyles.headlineLarge(context)
                            .copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(context,
                              small: 20.0,
                              medium: 25.0,
                              large: 30.0,
                              xlarge: 35.0)),
                      // Avatar section with change option
                      GestureDetector(
                        onTap: () => _showAvatarChangeDialog(context, student),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: ResponsiveUtils.responsiveAvatarSize(
                                context,
                                small: 35.0,
                                medium: 40.0,
                                large: 50.0,
                                xlarge: 60.0),
                            backgroundColor:
                                _getAvatarColor(student.selectedAvatarId),
                            child: student.selectedAvatarId != null
                                ? Icon(
                                    _getAvatarIcon(student.selectedAvatarId!),
                                    color: Colors.white,
                                    size: ResponsiveUtils.responsiveIconSize(
                                        context,
                                        small: 30.0,
                                        medium: 35.0,
                                        large: 50.0,
                                        xlarge: 60.0),
                                  )
                                : CircleAvatar(
                                    radius:
                                        ResponsiveUtils.responsiveAvatarSize(
                                            context,
                                            small: 35.0,
                                            medium: 40.0,
                                            large: 50.0,
                                            xlarge: 60.0),
                                    backgroundImage: NetworkImage(
                                        student.generatedAvatarUrl),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(context)),
                      Text(
                        student.displayName,
                        style:
                            ResponsiveTextStyles.titleLarge(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(context,
                              small: 6.0,
                              medium: 8.0,
                              large: 10.0,
                              xlarge: 12.0)),
                      Text(
                        student.email,
                        style: ResponsiveTextStyles.bodyLarge(context).copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- Statistics Card ---
                  _buildProfileCard(
                    title: 'My Stats',
                    children: [
                      _buildStatItem(
                        Icons.star_rounded,
                        'Points Earned',
                        student.points.toString(),
                      ),
                      const Divider(color: Colors.white24),
                      _buildStatItem(
                        Icons.menu_book_rounded,
                        'Stories Read',
                        student.storiesRead.toString(),
                      ),
                      const Divider(color: Colors.white24),
                      _buildStatItem(
                        Icons.local_fire_department_rounded,
                        'Current Streak',
                        '${student.loginStreak} Days',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Avatar Traits Card ---
                  _buildProfileCard(
                    title: 'Character Traits',
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getAvatarIcon(student.selectedAvatarId ?? ''),
                            color: _getAvatarColor(student.selectedAvatarId),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Avatar: ${_getAvatarName(student.selectedAvatarId ?? '')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: student.avatarTraits.entries.map((entry) {
                          if (entry.value > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getAvatarColor(student.selectedAvatarId)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color:
                                      _getAvatarColor(student.selectedAvatarId),
                                ),
                              ),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _getAvatarColor(student.selectedAvatarId),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dominant Trait: ${student.dominantTrait}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Settings Card ---
                  _buildProfileCard(
                    title: 'Settings',
                    children: [
                      _buildSettingsItem(
                        Icons.notifications_active_rounded,
                        'Notifications',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      _buildSettingsItem(
                        Icons.lock_person_rounded,
                        'Account & Security',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SecurityPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- Logout Button ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () => _showLogoutConfirmationDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for building a card section
  Widget _buildProfileCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Helper widget for a single statistic item
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for a single settings item
  Widget _buildSettingsItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white70,
        size: 16,
      ),
      onTap: onTap,
    );
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

  void _showAvatarChangeDialog(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Avatar',
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Would you like to change your avatar? This will take you to the avatar selection page.',
          style: TextStyle(fontFamily: 'ComicNeue'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AvatarSelectionPage(
                    student: student,
                    isFirstTime: false,
                  ),
                ),
              );
            },
            child: const Text('Change Avatar'),
          ),
        ],
      ),
    );
  }
}
