import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/core.dart';
import '../../../auth/model/auth_models.dart';

class ProfileInfo extends StatelessWidget {
  const ProfileInfo({
    super.key,
    required this.onEdit,
    this.user,
    this.isLoading = false,
  });

  final UserModel? user;
  final bool isLoading;
  final VoidCallback onEdit;

  String _resolveDisplayName() {
    if (user == null || (user!.fullName ?? '').trim().isEmpty) {
      return 'Guest';
    }
    return user!.fullName!;
  }

  String _resolveEmail() {
    if (user == null || user!.email.trim().isEmpty) {
      return 'No email available';
    }
    return user!.email;
  }

  ImageProvider _resolveAvatar() {
    String? photoPath;
    final dynamic rawPhoto = user?.photo;
    if (rawPhoto is Map<String, dynamic>) {
      final dynamic candidate = rawPhoto['path'] ?? rawPhoto['url'];
      if (candidate is String && candidate.isNotEmpty) {
        photoPath = candidate;
      }
    }

    if (photoPath != null && photoPath.isNotEmpty) {
      return NetworkImage(photoPath);
    }
    return AssetImage(AppAssets.loginBg);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            CircleAvatar(
              backgroundImage: _resolveAvatar(),
              radius: 36,
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: InkWell(
                onTap: isLoading ? null : onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isLoading ? AppColors.gray400 : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SvgPicture.asset(
                    AppAssets.editIcon,
                    height: 16,
                    width: 16,
                    colorFilter: isLoading
                        ? const ColorFilter.mode(
                            Colors.white70,
                            BlendMode.srcIn,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.horizontalSpaceLarge,
        Expanded(
          child: isLoading && user == null
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: CircularProgressIndicator(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CText(
                      _resolveDisplayName(),
                      type: TextType.bodyMedium,
                      color: AppColors.black,
                    ),
                    CText(
                      _resolveEmail(),
                      type: TextType.bodyMedium,
                      color: AppColors.gray700,
                    ),
                  ],
                ),
        )
      ],
    );
  }
}
