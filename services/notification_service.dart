import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_messaging_background.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      await _requestPermission();

      // Set up Firebase messaging handlers
      await _setupFirebaseMessaging();

      // Subscribe to topics
      await _subscribeToTopics();

      _isInitialized = true;
      debugPrint("✅ Notification service initialized successfully");
    } catch (e) {
      debugPrint("❌ Failed to initialize notification service: $e");
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
        "📱 Notification permission status: ${settings.authorizationStatus}");
  }

  /// Set up Firebase messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    // Get initial message if app was opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpened(initialMessage);
    }
  }

  /// Subscribe to notification topics
  Future<void> _subscribeToTopics() async {
    try {
      await _firebaseMessaging.subscribeToTopic('new_stories');
      await _firebaseMessaging.subscribeToTopic('summary_reviews');
      debugPrint("✅ Subscribed to notification topics");
    } catch (e) {
      debugPrint("❌ Failed to subscribe to topics: $e");
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        "📩 Foreground message received: ${message.notification?.title}");

    // Update notification count in Firestore if needed
    _updateNotificationCount(message);

    // Show in-app notification (you can customize this)
    _showInAppNotification(message);
  }

  /// Show in-app notification using SnackBar
  void _showInAppNotification(RemoteMessage message) {
    // This will be handled by the UI layer
    // You can implement a custom in-app notification system here
    debugPrint("📱 In-app notification: ${message.notification?.title}");
  }

  /// Handle notification tap
  void _handleNotificationOpened(RemoteMessage message) {
    debugPrint("👆 Notification tapped: ${message.notification?.title}");

    // Handle navigation based on notification type
    _handleNotificationNavigation(message);
  }

  /// Update notification count in Firestore
  void _updateNotificationCount(RemoteMessage message) {
    try {
      final userId = message.data['userId'];
      if (userId != null) {
        _firestore.collection('users').doc(userId).update({
          'unreadNotifications': FieldValue.increment(1),
          'lastNotificationTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to update notification count: $e");
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'new_story':
        // Navigate to story explorer
        debugPrint("📚 Navigate to new story: ${data['storyId']}");
        break;
      case 'summary_review':
        // Navigate to summary review
        debugPrint("📝 Navigate to summary review: ${data['summaryId']}");
        break;
      default:
        debugPrint("❓ Unknown notification type: $type");
    }
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update unread count
      await _firestore.collection('users').doc(userId).update({
        'unreadNotifications': FieldValue.increment(1),
        'lastNotificationTime': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Notification sent to user: $userId");
    } catch (e) {
      debugPrint("❌ Failed to send notification: $e");
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Decrease unread count
      await _firestore.collection('users').doc(userId).update({
        'unreadNotifications': FieldValue.increment(-1),
      });

      debugPrint("✅ Notification marked as read: $notificationId");
    } catch (e) {
      debugPrint("❌ Failed to mark notification as read: $e");
    }
  }

  /// Get user's notifications
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection('users').doc(userId).update({
        'unreadNotifications': 0,
      });

      debugPrint("✅ All notifications cleared for user: $userId");
    } catch (e) {
      debugPrint("❌ Failed to clear notifications: $e");
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopics() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('new_stories');
      await _firebaseMessaging.unsubscribeFromTopic('summary_reviews');
      debugPrint("✅ Unsubscribed from notification topics");
    } catch (e) {
      debugPrint("❌ Failed to unsubscribe from topics: $e");
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint("❌ Failed to get FCM token: $e");
      return null;
    }
  }
}
