import 'package:flutter/material.dart';

class TeacherForm extends StatelessWidget {
  final TextEditingController cinController;
  final TextEditingController schoolController;
  final TextEditingController specialtyController;
  final TextEditingController phoneController; // Added phone controller

  const TeacherForm({
    super.key,
    required this.cinController,
    required this.schoolController,
    required this.specialtyController,
    required this.phoneController, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CIN Field
        TextFormField(
          controller: cinController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'CIN (National ID)',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.badge, color: Colors.white70),
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
              return 'CIN is required';
            }
            if (value.length < 6) {
              return 'CIN must be at least 6 characters';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16),

        // School/Institution
        TextFormField(
          controller: schoolController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'School/Institution',
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
        const SizedBox(height: 16),

        // Teaching Specialty
        TextFormField(
          controller: specialtyController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Teaching Specialty',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.work, color: Colors.white70),
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
              return 'Specialty is required';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16),

        // Phone Number Field (New)
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.phone, color: Colors.white70),
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
              return 'Phone number is required';
            }
            // Simple phone validation (exactly 8 digits)
            final phoneRegex = RegExp(r'^[0-9]{8}$');
            if (!phoneRegex.hasMatch(value)) {
              return 'Enter a valid phone number (exactly 8 digits)';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
