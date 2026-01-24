class SuccessResponseModel {
  SuccessResponseModel({
    this.message,
  });

  SuccessResponseModel.fromJson(dynamic json) {
    message = json['message'];
  }

  String? message;

  SuccessResponseModel copyWith({
    String? type,
    String? message,
  }) =>
      SuccessResponseModel(
        message: message ?? this.message,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    return map;
  }
}
