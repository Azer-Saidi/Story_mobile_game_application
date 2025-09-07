String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Name is required';
  }
  if (value.length < 3) {
    return 'Name must be at least 3 characters long';
  }
  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
    return 'Name must contain only letters and spaces';
  }
  return null;
}

String? validateCIN(String? value) {
  if (value == null || value.isEmpty) {
    return 'CIN is required';
  }
  if (value.length != 8) {
    return 'CIN must be 8 digits';
  }
  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
    return 'CIN must contain only numbers';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(value)) {
    return 'Invalid email format';
  }
  return null;
}

String? email(String? value) {
  if (value == null || value.isEmpty) return 'Email is required';
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Enter valid email';
  }
  return null;
}

String? password(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? requiredField(String? value) {
  if (value == null || value.isEmpty) return 'This field is required';
  return null;
}
