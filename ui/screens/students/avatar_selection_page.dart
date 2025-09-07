import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/services/firestore_service.dart';
import 'package:storyapp/utils/responsive_utils.dart';

class AvatarSelectionPage extends StatefulWidget {
  final Student? student; // Made nullable for safety
  final bool isFirstTime;

  const AvatarSelectionPage({
    super.key,
    required this.student,
    required this.isFirstTime,
  });

  @override
  State<AvatarSelectionPage> createState() => _AvatarSelectionPageState();
}

class _AvatarSelectionPageState extends State<AvatarSelectionPage>
    with TickerProviderStateMixin {
  String? _selectedAvatarId;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FirestoreService _firestoreService = FirestoreService();

  final List<Map<String, dynamic>> _avatarStyles = [
    {
      'id': 'hero_knight',
      'name': 'Hero Knight',
      'description': 'Brave and protective, always ready to help others',
      'icon': Icons.shield,
      'color': Colors.blue,
      'traits': ['brave', 'helpful'],
    },
    {
      'id': 'curious_explorer',
      'name': 'Curious Explorer',
      'description': 'Loves to discover new things and ask questions',
      'icon': Icons.explore,
      'color': Colors.orange,
      'traits': ['curious', 'creative'],
    },
    {
      'id': 'kind_healer',
      'name': 'Kind Healer',
      'description': 'Gentle and caring, always thinking of others',
      'icon': Icons.healing,
      'color': Colors.green,
      'traits': ['kind', 'helpful'],
    },
    {
      'id': 'honest_sage',
      'name': 'Honest Sage',
      'description': 'Wise and truthful, values honesty above all',
      'icon': Icons.auto_stories,
      'color': Colors.purple,
      'traits': ['honest', 'curious'],
    },
    {
      'id': 'creative_artist',
      'name': 'Creative Artist',
      'description': 'Imaginative and artistic, loves to create',
      'icon': Icons.palette,
      'color': Colors.pink,
      'traits': ['creative', 'kind'],
    },
    {
      'id': 'brave_adventurer',
      'name': 'Brave Adventurer',
      'description': 'Fearless and bold, ready for any challenge',
      'icon': Icons.hiking,
      'color': Colors.red,
      'traits': ['brave', 'curious'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectAvatar() async {
    if (_selectedAvatarId == null) return;
    if (widget.student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student data is missing. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedAvatar = _avatarStyles.firstWhere(
        (avatar) => avatar['id'] == _selectedAvatarId,
      );

      // Initialize avatar traits
      Map<String, int> initialTraits = {
        'helpful': 0,
        'brave': 0,
        'kind': 0,
        'curious': 0,
        'creative': 0,
        'honest': 0,
      };

      // Add points for selected avatar's traits
      for (String trait in selectedAvatar['traits']) {
        initialTraits[trait] = 5;
      }

      // Update Firestore
      await _firestoreService.updateUser(widget.student!.uid, {
        'selectedAvatarId': _selectedAvatarId,
        'avatarTraits': initialTraits,
        'hasCompletedAvatarSetup': true,
      });

      // Update local AuthProvider
      final authProvider = context.read<AuthProvider>();
      final updatedStudent = widget.student!.copyWith(
        selectedAvatarId: _selectedAvatarId,
        avatarTraits: initialTraits,
        hasCompletedAvatarSetup: true,
      );
      authProvider.setCurrentUser(updatedStudent);

      if (widget.isFirstTime) {
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      } else {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar "${selectedAvatar['name']}" selected!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting avatar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: ResponsiveUtils.responsivePadding(context),
                  child: Column(
                    children: [
                      if (!widget.isFirstTime)
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      Icon(Icons.person_add,
                          size: ResponsiveUtils.responsiveIconSize(context,
                              small: 60.0,
                              medium: 70.0,
                              large: 80.0,
                              xlarge: 90.0),
                          color: Colors.white),
                      SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(context)),
                      Text(
                        widget.isFirstTime
                            ? 'Choose Your Avatar!'
                            : 'Change Avatar',
                        style: ResponsiveTextStyles.headlineLarge(context)
                            .copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height: ResponsiveUtils.responsiveSpacing(context,
                              small: 6.0,
                              medium: 8.0,
                              large: 10.0,
                              xlarge: 12.0)),
                      Text(
                        'Your avatar will grow and develop based on the choices you make in stories!',
                        style: ResponsiveTextStyles.bodyLarge(context).copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Avatar Grid
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.responsiveSpacing(context,
                          small: 12.0, medium: 16.0, large: 20.0, xlarge: 24.0),
                    ),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            ResponsiveUtils.responsiveGridCrossAxisCount(
                                context),
                        mainAxisSpacing:
                            ResponsiveUtils.responsiveSpacing(context),
                        crossAxisSpacing:
                            ResponsiveUtils.responsiveSpacing(context),
                        childAspectRatio:
                            ResponsiveUtils.responsiveChildAspectRatio(context),
                      ),
                      itemCount: _avatarStyles.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatarStyles[index];
                        final isSelected = _selectedAvatarId == avatar['id'];

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(color: avatar['color'], width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: avatar['color'].withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                _selectedAvatarId = avatar['id'];
                              });
                            },
                            child: Padding(
                              padding:
                                  ResponsiveUtils.responsivePadding(context),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar Icon
                                  Container(
                                    width: ResponsiveUtils.responsiveIconSize(
                                        context,
                                        small: 40.0,
                                        medium: 50.0,
                                        large: 60.0,
                                        xlarge: 70.0),
                                    height: ResponsiveUtils.responsiveIconSize(
                                        context,
                                        small: 40.0,
                                        medium: 50.0,
                                        large: 60.0,
                                        xlarge: 70.0),
                                    decoration: BoxDecoration(
                                      color: avatar['color'],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              avatar['color'].withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      avatar['icon'],
                                      color: Colors.white,
                                      size: ResponsiveUtils.responsiveIconSize(
                                          context,
                                          small: 20.0,
                                          medium: 25.0,
                                          large: 30.0,
                                          xlarge: 35.0),
                                    ),
                                  ),
                                  SizedBox(
                                      height: ResponsiveUtils.responsiveSpacing(
                                          context,
                                          small: 6.0,
                                          medium: 8.0,
                                          large: 10.0,
                                          xlarge: 12.0)),

                                  // Avatar Name
                                  Text(
                                    avatar['name'],
                                    style:
                                        ResponsiveTextStyles.bodyMedium(context)
                                            .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                      height: ResponsiveUtils.responsiveSpacing(
                                          context,
                                          small: 4.0,
                                          medium: 6.0,
                                          large: 8.0,
                                          xlarge: 10.0)),

                                  // Avatar Description
                                  Flexible(
                                    child: Text(
                                      avatar['description'],
                                      style: ResponsiveTextStyles.bodySmall(
                                              context)
                                          .copyWith(
                                        color: isSelected
                                            ? Colors.black54
                                            : Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Traits
                                  SizedBox(
                                      height: ResponsiveUtils.responsiveSpacing(
                                          context,
                                          small: 4.0,
                                          medium: 6.0,
                                          large: 8.0,
                                          xlarge: 10.0)),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: ResponsiveUtils.responsiveSpacing(
                                        context,
                                        small: 2.0,
                                        medium: 3.0,
                                        large: 4.0,
                                        xlarge: 5.0),
                                    runSpacing:
                                        ResponsiveUtils.responsiveSpacing(
                                            context,
                                            small: 2.0,
                                            medium: 3.0,
                                            large: 4.0,
                                            xlarge: 5.0),
                                    children: (avatar['traits'] as List<String>)
                                        .map((trait) => Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: ResponsiveUtils
                                                    .responsiveSpacing(context,
                                                        small: 4.0,
                                                        medium: 5.0,
                                                        large: 6.0,
                                                        xlarge: 7.0),
                                                vertical: ResponsiveUtils
                                                    .responsiveSpacing(context,
                                                        small: 1.0,
                                                        medium: 2.0,
                                                        large: 2.0,
                                                        xlarge: 3.0),
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? avatar['color']
                                                        .withOpacity(0.2)
                                                    : Colors.white
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                trait.toUpperCase(),
                                                style: ResponsiveTextStyles
                                                        .caption(context)
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? avatar['color']
                                                      : Colors.white,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Confirm Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_selectedAvatarId != null && !_isLoading)
                          ? _selectAvatar
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAvatarId != null
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        foregroundColor: _selectedAvatarId != null
                            ? const Color(0xFF6A11CB)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _selectedAvatarId != null ? 8 : 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              _selectedAvatarId != null
                                  ? 'Confirm Selection'
                                  : 'Select an Avatar',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ComicNeue',
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
