import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../../config/services/remote_services/http_service_provider.dart';
import '../../model/course_models.dart';
import '../../view_model/course_view_model.dart';
import '../pages/pdf_viewer_page.dart';

class MaterialsInfo extends ConsumerWidget {
  const MaterialsInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);
    final materials = state.materials;
    final subjects = state.subjects;
    final bool isEnrolled = state.isEnrolled;

    if (!isEnrolled) {
      return const Center(child: CText('Enroll to access materials'));
    }

    if (state.loadingMaterials && materials.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.materialsError != null && materials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CText(
            state.materialsError!.message,
            type: TextType.bodyMedium,
            color: AppColors.failure,
          ),
        ),
      );
    }

    if (materials.isEmpty) {
      return const Center(child: CText('No materials available'));
    }

    final subjectNameById = {
      for (final subject in subjects) subject.id: subject.subjectName
    };
    const uncategorizedKey = '_uncategorized';
    final Map<String, List<CourseMaterialModel>> grouped = {
      for (final subject in subjects) subject.id: <CourseMaterialModel>[],
    };

    for (final material in materials) {
      final key = material.subjectId != null && material.subjectId!.isNotEmpty
          ? material.subjectId!
          : uncategorizedKey;
      grouped.putIfAbsent(key, () => <CourseMaterialModel>[]).add(material);
    }

    final List<_MaterialGroup> groups = [];

    for (final subject in subjects) {
      final items = grouped.remove(subject.id);
      if (items != null && items.isNotEmpty) {
        groups
            .add(_MaterialGroup(title: subject.subjectName, materials: items));
      }
    }

    grouped.forEach((key, value) {
      if (value.isEmpty) return;
      final title = key == uncategorizedKey
          ? 'General Materials'
          : (subjectNameById[key] ?? 'Subject $key');
      groups.add(_MaterialGroup(title: title, materials: value));
    });

    Future<void> openMaterial(CourseMaterialModel material) async {
      if (!isEnrolled) {
        AppMethods.showCustomSnackBar(
          context: context,
          message: 'Please enroll to access this material.',
          isError: true,
        );
        return;
      }

      final notifier = ref.read(coursesViewModelProvider.notifier);

      Future<void> openPdf(String url) async {
        final httpService = ref.read(httpServiceProvider);
        final dio = (httpService as dynamic).dio as Dio;
        final resolvedFileName = (material.fileName ?? '').trim().isNotEmpty
            ? material.fileName!.trim()
            : '${material.materialTitle}.pdf';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: url,
              fileName: resolvedFileName,
              title: material.materialTitle,
              dio: dio,
            ),
          ),
        );
      }

      // Prefer downloadUrl sourced from enrolled course details payload.
      final enrolledDownloadUrl = material.downloadUrl;
      if (enrolledDownloadUrl != null && enrolledDownloadUrl.isNotEmpty) {
        await openPdf(enrolledDownloadUrl);
        return;
      }

      // Fallback to direct fileUrl when provided in the base course payload.
      final directUrl = material.fileUrl;
      if (directUrl != null && directUrl.isNotEmpty) {
        await openPdf(directUrl);
        return;
      }

      final result = await notifier.materialDownloadLink(material.id);
      result.fold(
        (failure) => AppMethods.showCustomSnackBar(
          context: context,
          message: failure.message,
          isError: true,
        ),
        (downloadUrl) async {
          if (downloadUrl == null || downloadUrl.isEmpty) {
            AppMethods.showCustomSnackBar(
              context: context,
              message: 'No download link available',
              isError: true,
            );
            return;
          }
          await openPdf(downloadUrl);
        },
      );
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.gray300,
                width: 1,
              ),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                backgroundColor: AppColors.white,
                collapsedBackgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: CText(group.title, type: TextType.titleMedium),
                children: [
                  for (final material in group.materials)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 2.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          title: CText(material.materialTitle,
                              type: TextType.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((material.materialDescription ?? '')
                                  .isNotEmpty)
                                CText(
                                  material.materialDescription!,
                                  type: TextType.bodySmall,
                                  color: AppColors.gray600,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              CText(
                                _formatMaterialMeta(material),
                                type: TextType.bodySmall,
                                color: AppColors.gray500,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(isEnrolled
                                ? Icons.download_rounded
                                : Icons.lock_outline),
                            color: isEnrolled
                                ? AppColors.primary
                                : AppColors.gray400,
                            onPressed: () => openMaterial(material),
                          ),
                          onTap: () => openMaterial(material),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatMaterialMeta(CourseMaterialModel material) {
    final parts = <String>[];
    if ((material.materialType ?? '').isNotEmpty) {
      parts.add(material.materialType!.toUpperCase());
    }
    if (material.fileSize != null && material.fileSize! > 0) {
      parts.add(_formatSize(material.fileSize!));
    }
    if (material.uploadedAt != null) {
      parts.add(_formatDate(material.uploadedAt!));
    }
    return parts.isEmpty ? 'Available for download' : parts.join(' • ');
  }

  static String _formatSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _MaterialGroup {
  _MaterialGroup({required this.title, required this.materials});

  final String title;
  final List<CourseMaterialModel> materials;
}
