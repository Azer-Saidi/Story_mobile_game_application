import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/providers/sync_provider.dart';
import 'package:storyapp/services/auth_service.dart';
import 'package:storyapp/services/cloudinary_service.dart';
import 'package:storyapp/services/sync_service.dart';
import 'package:storyapp/services/story_cach_manager.dart';
import 'package:storyapp/services/notification_service.dart';

import 'app.dart';

/// ✅ Handles Firebase Messaging setup with enhanced notification service
Future<void> setupNotifications() async {
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint("✅ Enhanced notification service setup successful");
  } catch (e) {
    debugPrint("❌ Enhanced notification service setup failed: $e");

    // Fallback to basic FCM setup
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.subscribeToTopic("new_stories");
      await messaging.subscribeToTopic("summary_reviews");
      debugPrint("✅ Basic FCM setup successful as fallback");
    } catch (fallbackError) {
      debugPrint("❌ Basic FCM setup also failed: $fallbackError");
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase initialized");

    await setupNotifications();

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("⚠️ .env file not found, using default values");
      // Set default values for required environment variables
      dotenv.env['CLOUDINARY_CLOUD_NAME'] =
          'demo'; // Replace with your actual cloud name
    }

    await Hive.initFlutter();
    await Hive.openBox('pending_operations');

    final storyCacheManager = StoryCacheManager();
    // Don't clear cache on every app start - only when needed
    // await storyCacheManager.emptyCache();

    final cloudinaryService = CloudinaryService();
    final syncService = SyncService();
    final connectivity = Connectivity();

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
          Provider<CloudinaryService>.value(value: cloudinaryService),
          Provider<SyncService>.value(value: syncService),
          Provider<Connectivity>.value(value: connectivity),
          Provider<StoryCacheManager>.value(value: storyCacheManager),
          Provider<NotificationService>(create: (_) => NotificationService()),
          ChangeNotifierProxyProvider<AuthService, AuthProvider>(
            create: (ctx) => AuthProvider(ctx.read<AuthService>()),
            update: (ctx, authService, previous) => AuthProvider(authService),
          ),
          ChangeNotifierProvider<SyncProvider>(
            create: (ctx) => SyncProvider(
              syncService: ctx.read<SyncService>(),
              authService: ctx.read<AuthService>(),
            ),
          ),
        ],
        child: MyApp(
          cloudinaryService: cloudinaryService,
          connectivity: connectivity,
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint("❌ App initialization failed: $e");
    debugPrint(stackTrace.toString());

    // Show error screen instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Clear all data and restart
                    try {
                      await Hive.deleteFromDisk();
                      main();
                    } catch (clearError) {
                      debugPrint("Failed to clear data: $clearError");
                    }
                  },
                  child: const Text('Clear Data & Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
