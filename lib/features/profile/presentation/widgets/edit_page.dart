import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../../core/core.dart';
import '../../../auth/model/auth_models.dart';
import '../../../auth/view_model/auth_state.dart';
import '../../../auth/view_model/providers/auth_providers.dart';
import '../../profile.dart';

class EditPage extends ConsumerStatefulWidget {
  const EditPage({super.key});

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _hasPrefilled = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromState(ref.read(authNotifierProvider));
    });
  }

  void _prefillFromState(AuthState state) {
    if (_hasPrefilled) return;
    final UserModel? user = state.user;
    if (user == null) return;
    // Defer modifications to providers until after the current frame
    // to avoid 'modify a provider while the widget tree is building' errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(editCtrlProvider).syncFromUser(user);
    });
    _hasPrefilled = true;
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final editCtrl = ref.read(editCtrlProvider);
    final request = ProfileUpdateModel(
      fullName: editCtrl.userNameController.text.trim(),
      email: editCtrl.emailController.text.trim(),
      mobileNumber: editCtrl.phoneController.text.trim(),
    );

    _isSubmitting = true;
    await ref.read(authNotifierProvider.notifier).updateProfile(request);
    // after updating textual profile, if user picked an image upload it
    final controller = ref.read(editCtrlProvider);
    if (controller.pickedImagePath != null &&
        controller.pickedImagePath!.isNotEmpty) {
      final file = File(controller.pickedImagePath!);
      await ref.read(authNotifierProvider.notifier).uploadProfilePicture(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editCtrlProvider);
    final authState = ref.watch(authNotifierProvider);
    // Sync form fields from the current auth state if needed.
    _prefillFromState(authState);

    // When a submission was initiated, react to the newest auth state
    // during rebuild. This avoids ref.listen timing races and works
    // reliably because `authState` is read above with `ref.watch`.
    if (_isSubmitting) {
      if (authState.status == AuthStatus.authenticated) {
        _isSubmitting = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AppMethods.showCustomSnackBar(
            context: context,
            message: 'Profile updated successfully.',
          );
          Navigator.pop(context);
        });
      } else if (authState.status == AuthStatus.error) {
        _isSubmitting = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AppMethods.showCustomSnackBar(
            context: context,
            message: authState.error ?? 'Failed to update profile.',
            isError: true,
          );
        });
      }
    }
    final isLoading = authState.status == AuthStatus.loading && _isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: ' Edit Profile',
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Stack(
              children: [
                Builder(builder: (context) {
                  final ctrl = ref.watch(editCtrlProvider);
                  // If user just picked an image, show the picked local file
                  if (ctrl.pickedImagePath != null &&
                      ctrl.pickedImagePath!.isNotEmpty) {
                    return CircleAvatar(
                      backgroundImage: FileImage(File(ctrl.pickedImagePath!)),
                      radius: 50,
                    );
                  }

                  // Else if auth user has a photo URL, use NetworkImage
                  final authState = ref.watch(authNotifierProvider);
                  final rawPhoto = authState.user?.photo;
                  String? photoUrl;
                  if (rawPhoto is Map<String, dynamic>) {
                    final candidate = rawPhoto['path'] ?? rawPhoto['url'];
                    if (candidate is String && candidate.isNotEmpty)
                      photoUrl = candidate;
                  }

                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    return CircleAvatar(
                      backgroundImage: NetworkImage(photoUrl),
                      radius: 50,
                    );
                  }

                  return CircleAvatar(
                    backgroundImage: AssetImage(AppAssets.loginBg),
                    radius: 50,
                  );
                }),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: InkWell(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final XFile? picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 70,
                        );
                        if (picked != null) {
                          // Validate file type and size before attempting compression/upload
                          final allowedExt = ['jpg', 'jpeg', 'png', 'gif'];
                          final ext = picked.name.split('.').last.toLowerCase();
                          final pickedFile = File(picked.path);
                          final fileSize = await pickedFile.length();
                          const maxBytes = 5 * 1024 * 1024; // 5MB

                          if (!allowedExt.contains(ext)) {
                            AppMethods.showCustomSnackBar(
                              context: context,
                              message:
                                  'Invalid file type. Please select JPG, PNG or GIF.',
                              isError: true,
                            );
                            return;
                          }

                          if (fileSize > maxBytes) {
                            AppMethods.showCustomSnackBar(
                              context: context,
                              message:
                                  'Selected image is too large. Please choose an image smaller than 5MB.',
                              isError: true,
                            );
                            return;
                          }
                          // store path in controller and notify
                          ref
                              .read(editCtrlProvider)
                              .setPickedImagePath(picked.path);
                          // compress picked image to reduce upload size
                          try {
                            final tempDir = Directory.systemTemp;
                            final targetPath =
                                '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
                            final compressedBytes =
                                await FlutterImageCompress.compressWithFile(
                              picked.path,
                              quality: 70,
                              rotate: 0,
                            );
                            if (compressedBytes != null &&
                                compressedBytes.isNotEmpty) {
                              final compressedFile = await File(targetPath)
                                  .writeAsBytes(compressedBytes);
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .uploadProfilePicture(compressedFile);
                            } else {
                              // fallback to original file
                              final file = File(picked.path);
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .uploadProfilePicture(file);
                            }
                          } catch (e) {
                            // if compression fails, fallback to original file
                            final file = File(picked.path);
                            await ref
                                .read(authNotifierProvider.notifier)
                                .uploadProfilePicture(file);
                          }
                        }
                      } catch (e, st) {
                        AppMethods.showCustomSnackBar(
                          context: context,
                          message: 'Unable to pick image. Please try again.',
                          isError: true,
                        );
                        // ignore: avoid_print
                        print('Image pick error: $e\n$st');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SvgPicture.asset(AppAssets.camerasIcon),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceLarge,
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustTextField(
                    hintText: 'Full Name',
                    hintColor: AppColors.gray400,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SvgPicture.asset(AppAssets.personIcon),
                    ),
                    controller: editState.userNameController,
                    validator: FieldValidators.validateFullName,
                  ),
                  AppSpacing.verticalSpaceMedium,
                  CustTextField(
                    hintText: 'Email Address',
                    hintColor: AppColors.gray400,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SvgPicture.asset(AppAssets.mailIcon),
                    ),
                    controller: editState.emailController,
                    validator: FieldValidators.validateEmail,
                  ),
                  AppSpacing.verticalSpaceMedium,
                  CustTextField(
                    hintText: 'Contact Number',
                    hintColor: AppColors.gray400,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SvgPicture.asset(AppAssets.phoneIcon),
                    ),
                    controller: editState.phoneController,
                    validator: FieldValidators.validateContactNumber,
                  ),
                  AppSpacing.verticalSpaceLarge,
                  SizedBox(
                    width: double.infinity,
                    child: ReusableButton(
                      text: 'Save Changes',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onSavePressed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
