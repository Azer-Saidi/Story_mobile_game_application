import 'package:flutter/material.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/ui/widgets/avatar_intervention_dialog.dart';

class AvatarInterventionOverlay extends StatefulWidget {
  final Student student;
  final List<AvatarInterventionPoint> interventionPoints;
  final String currentStorySection;
  final Function(AvatarInterventionPoint, String) onInterventionResponse;
  final Widget child;

  const AvatarInterventionOverlay({
    super.key,
    required this.student,
    required this.interventionPoints,
    required this.currentStorySection,
    required this.onInterventionResponse,
    required this.child,
  });

  @override
  State<AvatarInterventionOverlay> createState() =>
      _AvatarInterventionOverlayState();
}

class _AvatarInterventionOverlayState extends State<AvatarInterventionOverlay> {
  @override
  void didUpdateWidget(covariant AvatarInterventionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for interventions when the story section changes
    if (oldWidget.currentStorySection != widget.currentStorySection) {
      _checkForInterventions();
    }
  }

  void _checkForInterventions() {
    for (final intervention in widget.interventionPoints) {
      if (intervention.shouldTriggerForStudent(
          widget.student.avatarTraits, widget.currentStorySection)) {
        // Show the intervention after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showIntervention(intervention);
          }
        });
        break; // Show only one intervention at a time
      }
    }
  }

  void _showIntervention(AvatarInterventionPoint intervention) {
    showDialog(
      context: context,
      builder: (context) => AvatarInterventionDialog(
        intervention: intervention,
        student: widget.student,
        onResponse: widget.onInterventionResponse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
