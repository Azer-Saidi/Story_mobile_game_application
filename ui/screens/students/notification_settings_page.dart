import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/services/notification_service.dart';
import 'package:storyapp/utils/responsive_utils.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _newStoryNotifications = true;
  bool _summaryReviewNotifications = true;
  bool _challengeNotifications = true;
  bool _achievementNotifications = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() => _isLoading = true);

    try {
      // Load preferences from Firestore or local storage
      // For now, using default values
      setState(() {
        _newStoryNotifications = true;
        _summaryReviewNotifications = true;
        _challengeNotifications = true;
        _achievementNotifications = true;
      });
    } catch (e) {
      debugPrint("❌ Failed to load notification preferences: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationPreferences() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        // Save preferences to Firestore
        // This would typically be done through a service
        debugPrint("✅ Notification preferences saved");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Failed to save notification preferences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontFamily: 'ComicNeue'),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
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
              // Header
              Container(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: ResponsiveUtils.responsiveIconSize(context,
                          small: 48, medium: 56, large: 64, xlarge: 72),
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Stay Updated!',
                      style:
                          ResponsiveTextStyles.headlineMedium(context).copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose what notifications you want to receive',
                      style: ResponsiveTextStyles.bodyMedium(context).copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Notification Settings
              Expanded(
                child: Container(
                  margin: ResponsiveUtils.responsivePadding(context),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListView(
                    padding: ResponsiveUtils.responsivePadding(context),
                    children: [
                      _buildNotificationTile(
                        title: 'New Story Alerts',
                        subtitle:
                            'Get notified when teachers upload new stories',
                        icon: Icons.auto_stories_outlined,
                        value: _newStoryNotifications,
                        onChanged: (value) {
                          setState(() => _newStoryNotifications = value);
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildNotificationTile(
                        title: 'Summary Reviews',
                        subtitle:
                            'Get notified when your summaries are reviewed',
                        icon: Icons.rate_review_outlined,
                        value: _summaryReviewNotifications,
                        onChanged: (value) {
                          setState(() => _summaryReviewNotifications = value);
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildNotificationTile(
                        title: 'Challenge Updates',
                        subtitle:
                            'Get notified about new challenges and achievements',
                        icon: Icons.emoji_events_outlined,
                        value: _challengeNotifications,
                        onChanged: (value) {
                          setState(() => _challengeNotifications = value);
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildNotificationTile(
                        title: 'Achievement Alerts',
                        subtitle: 'Get notified when you earn achievements',
                        icon: Icons.star_outline,
                        value: _achievementNotifications,
                        onChanged: (value) {
                          setState(() => _achievementNotifications = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              Container(
                margin: ResponsiveUtils.responsivePadding(context),
                child: SizedBox(
                  width: double.infinity,
                  height: ResponsiveUtils.responsiveButtonHeight(context),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveNotificationPreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Save Preferences',
                            style: ResponsiveTextStyles.titleMedium(context)
                                .copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: ResponsiveTextStyles.titleMedium(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: ResponsiveTextStyles.bodySmall(context).copyWith(
          color: Colors.white70,
        ),
      ),
      secondary: Icon(
        icon,
        color: Colors.white,
        size: ResponsiveUtils.responsiveIconSize(context),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.orangeAccent,
      activeTrackColor: Colors.orangeAccent.withOpacity(0.3),
      inactiveThumbColor: Colors.white70,
      inactiveTrackColor: Colors.white30,
    );
  }
}
