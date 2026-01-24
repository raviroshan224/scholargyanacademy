import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/features/auth/model/auth_models.dart';

final editCtrlProvider = ChangeNotifierProvider<EditCtrl>(
  (Ref ref) => EditCtrl(),
);

class EditCtrl extends ChangeNotifier {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? pickedImagePath;

  void setPickedImagePath(String? path) {
    pickedImagePath = path;
    notifyListeners();
  }

  void syncFromUser(UserModel? user) {
    if (user == null) {
      clearTextFields();
      return;
    }

    userNameController.text = user.fullName ?? '';
    emailController.text = user.email;
    phoneController.text = user.mobileNumber ?? '';
    // keep existing picked path cleared when syncing from server user
    pickedImagePath = null;
    notifyListeners();
  }

  void clearTextFields() {
    userNameController.clear();
    emailController.clear();
    phoneController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
