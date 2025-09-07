import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// This is the background message handler for Firebase Cloud Messaging
/// It must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // await Firebase.initializeApp();

  debugPrint("📩 Background message received: ${message.notification?.title}");

  // Handle background message
  await _handleBackgroundMessage(message);
}

/// Handle background messages
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final data = message.data;
    final userId = data['userId'];

    if (userId != null) {
      // Store notification in Firestore
      await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': message.notification?.title ?? 'New Notification',
        'body': message.notification?.body ?? '',
        'type': data['type'] ?? 'general',
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'receivedInBackground': true,
      });

      // Update unread count
      await firestore.collection('users').doc(userId).update({
        'unreadNotifications': FieldValue.increment(1),
        'lastNotificationTime': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Background notification processed for user: $userId");
    }
  } catch (e) {
    debugPrint("❌ Failed to process background notification: $e");
  }
}
