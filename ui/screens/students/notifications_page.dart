import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _newStoryNotifications = true; // Default value
  bool _summaryRatedNotifications = true; // Default value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile.adaptive(
            title: const Text('New Story Alerts'),
            subtitle: const Text(
              'Get notified when a teacher uploads a new story.',
            ),
            value: _newStoryNotifications,
            onChanged: (bool value) {
              setState(() {
                _newStoryNotifications = value;
                // Here you would save this preference to Firestore or local storage
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'New Story Alerts ${value ? "enabled" : "disabled"}',
                  ),
                ),
              );
            },
            secondary: const Icon(Icons.auto_stories_outlined),
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Summary Rated Alerts'),
            subtitle: const Text(
              'Get notified when a teacher rates your summary.',
            ),
            value: _summaryRatedNotifications,
            onChanged: (bool value) {
              setState(() {
                _summaryRatedNotifications = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Summary Rated Alerts ${value ? "enabled" : "disabled"}',
                  ),
                ),
              );
            },
            secondary: const Icon(Icons.rate_review_outlined),
          ),
        ],
      ),
    );
  }
}
