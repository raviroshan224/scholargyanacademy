class RegisterRequest {
  final String fullName;
  final String email;
  final String? mobileNumber; // Optional field
  final String password;
  final String confirmPassword;
  final bool hasConfirmedToTerms;

  RegisterRequest({
    required this.fullName,
    required this.email,
    this.mobileNumber, // Optional parameter
    required this.password,
    required this.confirmPassword,
    required this.hasConfirmedToTerms,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'hasConfirmedToTerms': hasConfirmedToTerms,
    };
    // Only include mobileNumber if it's not null and not empty
    if (mobileNumber != null && mobileNumber!.trim().isNotEmpty) {
      data['mobileNumber'] = mobileNumber;
    }
    return data;
  }
}
