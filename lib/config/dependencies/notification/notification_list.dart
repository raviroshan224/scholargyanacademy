import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/utils/ui_helper/app_spacing.dart';
import '../../../core/widgets/text/custom_text.dart';

class NotificationModel {
  final String title;
  final String message;
  final DateTime date;
  final String imageUrl;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.message,
    required this.date,
    required this.imageUrl,
    this.isRead = false,
  });
}

class NotificationList extends StatefulWidget {
  final Map<String, dynamic>? data;

  const NotificationList({super.key, this.data});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final List<NotificationModel> notifications = List.generate(
    10,
        (index) => NotificationModel(
      title: 'Your request to join PASSIONATE GROUP is approved',
      message: 'Congratulations! You have been approved to join the group.',
      date: DateTime.now().subtract(Duration(hours: index * 3)),
      imageUrl: 'https://cdn.pixabay.com/photo/2015/10/20/18/57/furniture-998265_1280.jpg',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CText('Notification List'),
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read, color: AppColors.text),
            onPressed: _markAllAsRead,
            tooltip: 'Mark All as Read',
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.data != null)
            Padding(
              padding: EdgeInsets.all(AppSpacing.mediumPadding),
              child: Card(
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CText('Received Data:', type: TextType.titleMedium, fontWeight: FontWeight.w600),
                      SizedBox(height: AppSpacing.smallPadding),
                      for (var entry in widget.data!.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CText('${entry.key}: ', fontWeight: FontWeight.bold),
                              Expanded(child: CText('${entry.value}')),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(AppSpacing.mediumPadding),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                );
              },
              separatorBuilder: (context, index) => Divider(),
            ),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
  }

  void _handleNotificationTap(NotificationModel notification) {
    setState(() {
      notification.isRead = true;
    });
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(AppSpacing.mediumPadding),
          title: CText(
            notification.title,
            type: TextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (notification.imageUrl.isNotEmpty)
                  Image.network(notification.imageUrl),
                SizedBox(height: AppSpacing.smallPadding),
                CText(notification.message),
                SizedBox(height: AppSpacing.smallPadding),
                Text(
                  'Received on ${_formatDate(notification.date)}',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.0,
              backgroundImage: NetworkImage(notification.imageUrl),
            ),
            AppSpacing.horizontalSpaceMedium,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CText(
                    notification.title,
                    fontWeight:
                    notification.isRead ? FontWeight.normal : FontWeight.bold,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.verticalSpaceSmall,
                  CText(
                    notification.message,
                    color: AppColors.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.verticalSpaceSmall,
                  Text(
                    _formatDate(notification.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}';
}
