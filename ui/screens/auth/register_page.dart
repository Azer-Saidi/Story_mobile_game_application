import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/providers/auth_provider.dart';
import 'package:storyapp/ui/widgets/auth/student_form.dart';
import 'package:storyapp/ui/widgets/auth/teacher_form.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final String role;
  const RegisterPage({super.key, required this.role});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  // Role-specific controllers
  final _cinController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _selectedGrade;
  int? _selectedAge;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _cinController.dispose();
    _schoolNameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(role: widget.role),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Column(
                      children: [
                        Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join as ${widget.role}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Form container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personal Information
                            Text(
                              'Personal Information',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Name field
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter your name'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Role-specific form
                            Text(
                              widget.role == 'teacher'
                                  ? 'Professional Information'
                                  : 'Academic Information',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            if (widget.role == 'teacher')
                              TeacherForm(
                                cinController: _cinController,
                                schoolController: _schoolNameController,
                                specialtyController: _specialtyController,
                                phoneController: _phoneController,
                              )
                            else
                              Column(
                                children: [
                                  StudentForm(
                                    selectedGrade: _selectedGrade,
                                    onGradeChanged: (grade) =>
                                        setState(() => _selectedGrade = grade),
                                    schoolNameController: _schoolNameController,
                                  ),
                                  const SizedBox(height: 20),
                                  // Age Dropdown
                                  _buildAgeDropdown(),
                                ],
                              ),
                            const SizedBox(height: 24),

                            // Account Information
                            Text(
                              'Account Information',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password field
                            _buildPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password field
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.role == 'student'
                              ? Colors.lightBlueAccent
                              : Colors.amberAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: widget.role == 'teacher'
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(role: widget.role),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.role == 'student'
                                  ? Colors.lightBlueAccent
                                  : Colors.amberAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      validator: validator,
    );
  }

  // Age Dropdown Widget
  Widget _buildAgeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Age',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedAge,
          onChanged: (int? newValue) {
            setState(() => _selectedAge = newValue);
          },
          items: List.generate(7, (index) {
            int age = index + 6; // Ages 6 to 12
            return DropdownMenuItem<int>(
              value: age,
              child: Text(
                '$age years',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.cake, color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
          ),
          dropdownColor: const Color(0xFF6A11CB),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null) {
              return 'Please select your age';
            }
            if (value < 6 || value > 12) {
              return 'Age must be between 6-12';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Form Submission
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    
    if (widget.role == 'student') {
      if (_selectedGrade == null) {
        setState(() => _errorMessage = 'Please select grade level');
        return;
      }
      if (_selectedAge == null) {
        setState(() => _errorMessage = 'Please select your age');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.role == 'student') {
        await authProvider.signUpStudent(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
          gradeLevel: _selectedGrade!,
          schoolName: _schoolNameController.text.trim(),
          age: _selectedAge!,
        );
      } else {
        await authProvider.signUpTeacher(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
          cin: _cinController.text.trim(),
          school: _schoolNameController.text.trim(),
          specialty: _specialtyController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
      }

      // Sign out user immediately after registration
      await FirebaseAuth.instance.signOut();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(role: widget.role)),
      );
    } catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Email already in use';
        case 'invalid-email':
          return 'Invalid email address';
        case 'operation-not-allowed':
          return 'Operation not allowed. Contact support';
        case 'weak-password':
          return 'Password must be at least 6 characters';
        case 'network-request-failed':
          return 'Network error. Check your connection';
        default:
          return 'Registration failed: ${error.message}';
      }
    }
    return 'Registration failed. Please try again.';
  }
}
