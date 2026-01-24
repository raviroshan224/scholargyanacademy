class RegisterRequest {
  final String fullName;
  final String email;
  final String mobileNumber;
  final String password;
  final String confirmPassword;
  final bool hasConfirmedToTerms;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.password,
    required this.confirmPassword,
    required this.hasConfirmedToTerms,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'password': password,
      'confirmPassword': confirmPassword,
      'hasConfirmedToTerms': hasConfirmedToTerms,
    };
  }
}
