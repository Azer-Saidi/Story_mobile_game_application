import 'package:flutter/material.dart';
import 'package:storyapp/models/story_model.dart';
import 'package:storyapp/models/student_model.dart';
import 'package:storyapp/services/avatar_service.dart';

class AvatarInterventionDialog extends StatefulWidget {
  final AvatarInterventionPoint intervention;
  final Student student;
  final Function(AvatarInterventionPoint, String) onResponse;

  const AvatarInterventionDialog({
    super.key,
    required this.intervention,
    required this.student,
    required this.onResponse,
  });

  @override
  State<AvatarInterventionDialog> createState() =>
      _AvatarInterventionDialogState();
}

class _AvatarInterventionDialogState extends State<AvatarInterventionDialog> {
  final AvatarService _avatarService = AvatarService();
  String? _selectedResponse;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        _avatarService.getTraitColorScheme(widget.student.dominantTrait);
    final primaryColor = Color(
        int.parse(colorScheme['primary']!.substring(1), radix: 16) +
            0xFF000000);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _avatarService.getTraitIcon(widget.student.dominantTrait)
                    as IconData?,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              widget.intervention.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 20),

            // Response options (if any)
            if (widget.intervention.additionalData?['responseOptions'] != null)
              Column(
                children: (widget.intervention
                        .additionalData!['responseOptions'] as List<dynamic>)
                    .map((option) => RadioListTile<String>(
                          title: Text(option.toString()),
                          value: option.toString(),
                          groupValue: _selectedResponse,
                          onChanged: (value) {
                            setState(() {
                              _selectedResponse = value;
                            });
                          },
                        ))
                    .toList(),
              ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onResponse(
                        widget.intervention, _selectedResponse ?? 'dismissed');
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
