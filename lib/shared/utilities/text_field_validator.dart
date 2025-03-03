class TextFieldValidator {
  // Required field validation (optional flag)
  static String? requiredField(String? value, String fieldName,
      {bool isOptional = false}) {
    if (!isOptional && (value == null || value.isEmpty)) {
      return '$fieldName is required';
    }
    return null;
  }

  // Phone number validation (digits only, optional flag)
  static String? phoneNumberOnly(String? value, {bool isOptional = false}) {
    if (!isOptional && (value == null || value.isEmpty)) {
      return 'Phone number is required';
    }

    // Skip validation if field is optional and empty
    if (isOptional && (value == null || value.isEmpty)) {
      return null;
    }

    final phoneRegExp = RegExp(r'^[0-9]+$');
    if (!phoneRegExp.hasMatch(value!)) {
      return 'Enter a valid phone number';
    }
    if (value.length < 10 || value.length > 15) {
      return 'Phone number should be 10 to 15 digits long';
    }
    return null;
  }

  // Name validation (letters only, optional flag)
  static String? nameOnly(String? value, {bool isOptional = false}) {
    if (!isOptional && (value == null || value.isEmpty)) {
      return 'Name is required';
    }

    // Skip validation if field is optional and empty
    if (isOptional && (value == null || value.isEmpty)) {
      return null;
    }

    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegExp.hasMatch(value!)) {
      return 'Enter a valid name (letters only)';
    }
    return null;
  }

  // Numbers-only validation (optional flag)
  static String? numbersOnly(String? value, {bool isOptional = false}) {
    if (!isOptional && (value == null || value.isEmpty)) {
      return 'This field is required';
    }

    // Skip validation if field is optional and empty
    if (isOptional && (value == null || value.isEmpty)) {
      return null;
    }

    final numberRegExp = RegExp(r'^[0-9]+$');
    if (!numberRegExp.hasMatch(value!)) {
      return 'Enter numbers only';
    }
    return null;
  }
}
