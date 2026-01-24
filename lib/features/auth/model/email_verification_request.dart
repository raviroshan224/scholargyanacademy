class SendEmailVerificationRequest {
  final String email;

  SendEmailVerificationRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class VerifyEmailOtpRequest {
  final String email;
  final String otp;

  VerifyEmailOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}
