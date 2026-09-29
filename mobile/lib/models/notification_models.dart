// class NotificationModel {
//   final int notificationId;
//   final String notificationDate;
//   final String notificationText;
//   final String readStatus;
//   final int totalUnreadNotifications;

//   NotificationModel({
//     required this.notificationId,
//     required this.notificationDate,
//     required this.notificationText,
//     required this.readStatus,
//     required this.totalUnreadNotifications,
//   });

//   factory NotificationModel.fromJson(Map<String, dynamic> json) {
//     return NotificationModel(
//       notificationId: json['NotificationId'] ?? 0,
//       notificationDate: json['NotificationDate'] ?? '',
//       notificationText: json['NotificationText'] ?? '',
//       readStatus: json['ReadStatus'] ?? 'No',
//       totalUnreadNotifications: json['TotalUnreadNotifications'] ?? 0,
//     );
//   }
// }
