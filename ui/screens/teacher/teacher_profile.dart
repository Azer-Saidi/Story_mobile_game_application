import 'package:flutter/material.dart';
import 'package:storyapp/models/teacher_model.dart';

class TeacherProfileScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherProfileScreen({super.key, required this.teacher});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late Teacher _updatedTeacher;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _updatedTeacher = Teacher(
      id: widget.teacher.id,
      email: widget.teacher.email,
      displayName: widget.teacher.displayName,
      cin: widget.teacher.cin,
      school: widget.teacher.school,
      specialty: widget.teacher.specialty,
      createdAt: widget.teacher.createdAt,
      isVerified: widget.teacher.isVerified,
      avatarUrl: widget.teacher.avatarUrl,
      phoneNumber: widget.teacher.phoneNumber,
      createdStoryIds: widget.teacher.createdStoryIds,
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In real app, send update to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isLoading = false);
      Navigator.pop(context, _updatedTeacher);
    }
  }

  void _changePassword() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _isLoading = false;
      _passwordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _updatedTeacher.avatarUrl.isNotEmpty
                            ? NetworkImage(_updatedTeacher.avatarUrl)
                            : null,
                        child: _updatedTeacher.avatarUrl.isEmpty
                            ? Text(
                                _updatedTeacher.initials,
                                style: const TextStyle(fontSize: 36),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _updatedTeacher.displayName,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (value) => _updatedTeacher = _updatedTeacher
                          .copyWith(displayName: value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: _updatedTeacher.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => _updatedTeacher = _updatedTeacher
                          .copyWith(email: value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: _updatedTeacher.phoneNumber,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => _updatedTeacher = _updatedTeacher
                          .copyWith(phoneNumber: value),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: _updatedTeacher.school,
                      decoration: const InputDecoration(
                        labelText: 'School',
                        prefixIcon: Icon(Icons.school),
                      ),
                      onChanged: (value) => _updatedTeacher = _updatedTeacher
                          .copyWith(school: value),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: _updatedTeacher.specialty,
                      decoration: const InputDecoration(
                        labelText: 'Specialty',
                        prefixIcon: Icon(Icons.work),
                      ),
                      onChanged: (value) => _updatedTeacher = _updatedTeacher
                          .copyWith(specialty: value),
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Password Change Section
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      obscureText: !_showPassword,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      obscureText: !_showPassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _passwordError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _changePassword,
                      child: const Text('Change Password'),
                    ),

                    // Verification status
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Icon(
                          _updatedTeacher.isVerified
                              ? Icons.verified
                              : Icons.pending,
                          color: _updatedTeacher.isVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _updatedTeacher.isVerified
                              ? 'Account Verified'
                              : 'Account Pending Verification',
                          style: TextStyle(
                            color: _updatedTeacher.isVerified
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
