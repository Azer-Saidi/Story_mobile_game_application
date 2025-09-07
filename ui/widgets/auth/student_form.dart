import 'package:flutter/material.dart';

class StudentForm extends StatelessWidget {
  final int? selectedGrade;
  final ValueChanged<int?> onGradeChanged;
  final TextEditingController schoolNameController;

  const StudentForm({
    super.key,
    required this.selectedGrade,
    required this.onGradeChanged,
    required this.schoolNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Grade Level Dropdown
        DropdownButtonFormField<int>(
          value: selectedGrade,
          decoration: InputDecoration(
            labelText: 'Grade Level',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.school, color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white24,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
          ),
          items: List.generate(6, (index) => index + 1)
              .map(
                (grade) => DropdownMenuItem(
                  value: grade,
                  child: Text(
                    'Grade $grade',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: onGradeChanged,
          validator: (val) =>
              val == null ? 'Please select your grade level' : null,
          dropdownColor: Colors.blue[800],
          style: const TextStyle(color: Colors.white),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16),

        // School Name
        TextFormField(
          controller: schoolNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'School Name',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.location_city, color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white24,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'School name is required';
            }
            if (value.length < 3) {
              return 'Enter a valid school name';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
