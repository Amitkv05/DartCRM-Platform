import 'package:dart_crm/screens/approvals/approval_request_detail_screen.dart';
import 'package:dart_crm/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';


String _approvalTitle(String moduleName) {
  switch (moduleName) {
    case 'CUSTOMER_CREATE': return 'Customer Creation Approval';
    case 'CUSTOMER_UPDATE': return 'Customer Update Approval';
    case 'CUSTOMER_DELETE': return 'Customer Delete Approval';
    case 'CONTACT_CREATE': return 'Contact Approval';
    case 'VISIT_BACKDATE': return 'Visit Backdate Approval';
    case 'CUSTOMER_SAMPLING': return 'Customer Sampling Approval';
    case 'SELF_STOCK': return 'Self-Stock Approval';
    default: return 'Approval Details';
  }
}

class NotificationView extends ConsumerWidget {
  final int executiveId;

  const NotificationView({Key? key, required this.executiveId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        foregroundColor: Colors.blueGrey[900],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notificationProvider.notifier)
              .fetchNotifications(executiveId);
        },
        child: notificationState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueGrey,
                ),
              )
            : notificationState.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notificationState.notifications.length,
                    itemBuilder: (context, index) {
                      final notification =
                          notificationState.notifications[index];
                      // Parse date with correct format: "DD MMM YYYY"
                      final inputFormat = DateFormat('dd MMM yyyy');
                      final outputFormat = DateFormat('MMM d, yyyy');
                      String formattedDate;
                      try {
                        final parsedDate =
                            inputFormat.parse(notification.notificationDate);
                        formattedDate = outputFormat.format(parsedDate);
                      } catch (e) {
                        formattedDate = notification.notificationDate;
                      }

                      return AnimatedOpacity(
                        opacity: notification.readStatus == 'No' ? 1.0 : 0.7,
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: notification.readStatus == 'No'
                                  ? Colors.blueGrey[700]
                                  : Colors.grey[300],
                              child: Icon(
                                Icons.notifications,
                                color: notification.readStatus == 'No'
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 24,
                              ),
                            ),
                            title: Text(
                              notification.notificationText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.readStatus == 'No'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: Colors.blueGrey[900],
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            trailing: notification.readStatus == 'No'
                                ? Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              try {
                                if (notification.readStatus == 'No') {
                                  await ref
                                      .read(notificationProvider.notifier)
                                      .markNotificationAsRead(
                                        notification.notificationId,
                                        executiveId,
                                      );
                                }

                                if (!context.mounted) return;
                                if (notification.approvalId != null &&
                                    notification.approvalId! > 0 &&
                                    notification.moduleName != null) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ApprovalRequestDetailScreen(
                                        approvalId: notification.approvalId!,
                                        moduleName: notification.moduleName!,
                                        title: _approvalTitle(notification.moduleName!),
                                      ),
                                    ),
                                  );
                                } else {
                                  await showDialog<void>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(notification.title),
                                      content: Text(notification.notificationText),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Unable to open notification: $error',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
