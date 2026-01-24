import 'dart:core';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constant/app_colors.dart';
import '../constant/app_string.dart';
import '../widgets/text/custom_text.dart';

class AppMethods {
  static showFlexibleSizeBottomSheet({
    required Widget widget,
    required BuildContext context,
    bool isScrollable = true,
    bool showConstraints = true,
  }) {
    return showModalBottomSheet(
      backgroundColor: AppColors.gray500,
      isScrollControlled: isScrollable,
      // constraints: BoxConstraints(maxHeight: 0.70.sh),
      constraints:
          showConstraints ? const BoxConstraints(maxHeight: 0.70) : null,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: widget,
      ),
    );
  }

  static void showLoaderDialog(BuildContext context,
      {String? txt, bool dismissible = true}) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
              margin: const EdgeInsets.only(left: 8),
              child: Text(txt ?? AppStrings.loadingTxt)),
        ],
      ),
    );
    showDialog(
      barrierDismissible: dismissible,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static void dismissLoaderDialog(BuildContext context) {
    Navigator.pop(context);
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    String? id,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        surfaceTintColor: AppColors.white,
        title: CText(
          title,
          type: TextType.titleLarge,
        ),
        content: SingleChildScrollView(
          child: CText(message),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: CText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print("Property Deleted");
              // context.pop();
              // Navigator.pop(context,true);
            },
            child: const CText('Confirm'),
          ),
        ],
      ),
    );
  }

  static String parseHtmlToPlainText({required String htmlString}) {
    dom.Document document = parse(htmlString);
    return _parseElementToPlainText(document.body);
  }

  static String _parseElementToPlainText(dom.Element? element) {
    if (element == null) return '';
    StringBuffer buffer = StringBuffer();
    element.nodes.forEach((node) {
      if (node is dom.Text) {
        buffer.write(node.text);
      } else if (node is dom.Element) {
        buffer.write(_parseElementToPlainText(node));
      }
    });
    return buffer.toString();
  }

  static showCustomSnackBar({
    required BuildContext context,
    required String message,
    Color textColor = Colors.white,
    Color backgroundColor = AppColors.secondary,
    bool isError = false,
    Duration? duration,
    SnackBarBehavior? behaviour,
  }) {
    // Longer default duration for errors, slightly longer for success than previous 1200ms.
    final effectiveDuration = duration ??
        (isError
            ? const Duration(milliseconds: 4000)
            : const Duration(milliseconds: 2500));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        behavior: behaviour ?? SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : backgroundColor,
        duration: effectiveDuration,
      ),
    );
  }

  static Future<void> urlLauncherHelper(
      BuildContext context, String? url) async {
    if (url != null && url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        showCustomSnackBar(
            context: context, message: 'Could not launch $url', isError: true);
      }
    } else {
      showCustomSnackBar(
          context: context, message: 'Invalid Url : $url', isError: true);
    }
  }
}
