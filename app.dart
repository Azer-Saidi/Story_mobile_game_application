import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/services/cloudinary_service.dart';
import 'package:storyapp/ui/screens/auth/login_page.dart';
import 'package:storyapp/ui/screens/auth/role_selection.dart';
import 'package:storyapp/ui/screens/students/student_dashboard.dart';
import 'package:storyapp/ui/screens/students/avatar_selection_page.dart';
import 'package:storyapp/ui/screens/students/story_explorer_page.dart';
import 'package:storyapp/ui/screens/students/story_reader_page.dart';
import 'package:storyapp/ui/screens/teacher/create_story_page.dart';
import 'package:storyapp/ui/screens/teacher/teacher_dashboard.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/models/teacher_model.dart';
import 'package:storyapp/ui/widgets/offline_indicator.dart';

class MyApp extends StatelessWidget {
  final CloudinaryService cloudinaryService;
  final Connectivity connectivity;

  const MyApp({
    super.key,
    required this.cloudinaryService,
    required this.connectivity,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        /// ✅ Show loading until provider initializes
        if (!authProvider.isInitialized) {
          debugPrint("🔄 AuthProvider not initialized yet, showing loading...");
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        }

        debugPrint("✅ AuthProvider initialized, building main app...");

        return MaterialApp(
          title: 'StoryApp',
          debugShowCheckedModeBanner: false,
          theme: _themeData,
          home: _getHomeScreen(authProvider),
          builder: (context, child) => OfflineIndicator(
            child: child ?? const SizedBox.shrink(),
          ),
          onGenerateRoute: (settings) {
            // Add null safety check
            if (authProvider.isLoading) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final currentUser = authProvider.currentUser;

            /// If no user is logged in
            if (currentUser == null) {
              if (settings.name == '/' || settings.name == '/role-selection') {
                return MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                );
              } else if (settings.name == '/login') {
                final role = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => LoginPage(role: role ?? 'student'),
                );
              }

              /// Default fallback when not logged in
              return MaterialPageRoute(
                builder: (_) => const RoleSelectionScreen(),
              );
            }

            /// If logged in as Student
            if (currentUser is Student) {
              try {
                if (!currentUser.hasCompletedAvatarSetup) {
                  return MaterialPageRoute(
                    builder: (_) => AvatarSelectionPage(
                      student: currentUser,
                      isFirstTime: true,
                    ),
                  );
                } else {
                  return MaterialPageRoute(
                    builder: (_) => const StudentDashboard(),
                  );
                }
              } catch (e) {
                debugPrint("Error with Student object in route: $e");
                return MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                );
              }
            }

            /// If logged in as Teacher
            if (currentUser is Teacher) {
              return MaterialPageRoute(
                builder: (_) => TeacherDashboard(teacher: currentUser),
              );
            }

            /// ✅ Handle additional named routes
            switch (settings.name) {
              case '/role-selection':
                return MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                );

              case '/login':
                final role = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => LoginPage(role: role ?? 'student'),
                );

              case '/create-story':
                final teacher = settings.arguments as Teacher?;
                if (teacher != null) {
                  return MaterialPageRoute(
                    builder: (_) => CreateStoryPage(
                      cloudinaryService: cloudinaryService,
                      authorId: teacher.id,
                      teacher: teacher,
                    ),
                  );
                }
                return _errorRoute('Teacher info missing for create-story');

              case '/student-dashboard':
                return MaterialPageRoute(
                  builder: (_) => const StudentDashboard(),
                );

              case '/story-explorer':
                final currentUser = authProvider.currentUser;
                if (currentUser is Student) {
                  return MaterialPageRoute(
                    builder: (_) => StoryExplorerPage(
                      student: currentUser,
                      onStorySelected: (story) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryReaderPage(
                              story: story,
                              student: currentUser,
                              isRootStory: true,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return _errorRoute('Only students can access Story Explorer');

              default:
                // If currentUser is null or unknown type, redirect to role selection
                return MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                );
            }
          },
        );
      },
    );
  }

  /// ✅ Get the appropriate home screen based on auth state
  Widget _getHomeScreen(AuthProvider authProvider) {
    debugPrint("🏠 Getting home screen...");
    debugPrint("Loading: ${authProvider.isLoading}");
    debugPrint("Current user: ${authProvider.currentUser}");

    if (authProvider.isLoading) {
      debugPrint("⏳ Still loading, showing loading screen...");
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      debugPrint("👤 No user logged in, showing role selection...");
      return const RoleSelectionScreen();
    }

    if (currentUser is Student) {
      try {
        if (!currentUser.hasCompletedAvatarSetup) {
          return AvatarSelectionPage(
            student: currentUser,
            isFirstTime: true,
          );
        } else {
          return const StudentDashboard();
        }
      } catch (e) {
        debugPrint("Error with Student object: $e");
        return const RoleSelectionScreen();
      }
    }

    if (currentUser is Teacher) {
      return TeacherDashboard(teacher: currentUser);
    }

    return const RoleSelectionScreen();
  }

  /// ✅ Error Route
  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(message, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  /// ✅ App Theme
  ThemeData get _themeData => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'ComicNeue',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.deepPurple,
          ),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.deepPurple,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.deepPurple,
          ),
          titleMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
