class FieldValidators {
  /// Email Validator
  static String? validateEmail(String? value) {
    // Regular expression for email validation
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      return 'Enter a valid email address';
    } else {
      return null;
    }
  }

  /// Passsword validator
  static String? validatePassword(String? value) {
    // Add your validation logic here
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 4) {
      // Example: minimum 8 characters
      return 'Password must be at least 4 characters long';
    }
    return null; // Return null if the input is valid
  }

  /// Contact number validator
  static String? validateContactNumber(String? value) {
    // Add your validation logic here
    String pattern =
        r'^[0-9]{10}$'; // Regular expression for 10-digit phone number
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      return 'Enter a valid 10-digit contact number';
    }
    return null; // Return null if the input is valid
  }

  /// User full name validator
  static String? validateFullName(String? value) {
    // Add your validation logic here
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    return null; // Return null if the input is valid
  }

  static String? validateLocation(String? value) {
    // Add your validation logic here
    if (value == null || value.isEmpty) {
      return 'Please enter your location';
    }
    return null; // Return null if the input is valid
  }

  /// Confirm Password validator
  static String? validateConfirmPassword(String? value, String? password) {
    // Add your validation logic here
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null; // Return null if the input is valid
  }

  static String? validateMessage(String? value, String? message) {
    // Add your validation logic here
    if (value == null || value.isEmpty) {
      return message ?? 'Please enter your message';
    }
    return null; // Return null if the input is valid
  }
}
