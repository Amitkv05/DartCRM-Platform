import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationModel {
  final int notificationId;
  final String notificationDate;
  final String title;
  final String notificationText;
  final String readStatus;
  final int totalUnreadNotifications;
  final String? moduleName;
  final int? entityId;
  final int? approvalId;

  const NotificationModel({
    required this.notificationId,
    required this.notificationDate,
    required this.title,
    required this.notificationText,
    required this.readStatus,
    required this.totalUnreadNotifications,
    this.moduleName,
    this.entityId,
    this.approvalId,
  });

  factory NotificationModel.fromV2(Map<String, dynamic> json, int unreadCount) {
    return NotificationModel(
      notificationId: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      notificationDate: (json['created_at'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      notificationText: (json['message'] ?? json['title'] ?? '').toString(),
      readStatus: json['read_at'] == null ? 'No' : 'Yes',
      totalUnreadNotifications: unreadCount,
      moduleName: json['module_name']?.toString(),
      entityId: int.tryParse((json['entity_id'] ?? '').toString()),
      approvalId: int.tryParse((json['approval_id'] ?? '').toString()),
    );
  }
}

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
  }) => NotificationState(
        isLoading: isLoading ?? this.isLoading,
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this.ref) : super(const NotificationState()) {
    _initializeNotifications();
  }

  final Ref ref;
  final CrmApiClient _api = CrmApiClient.instance;

  void reset() => state = const NotificationState();

  Future<void> _initializeNotifications() async {
    final authState = ref.read(authProvider);
    if (authState.token != null &&
        authState.loginResponse?.executiveBasicData?.isNotEmpty == true) {
      await fetchNotifications(
        authState.loginResponse!.executiveBasicData!.first.executiveId,
      );
    }
  }

  Future<void> fetchNotifications(
    int executiveId, {
    String? notificationIds,
    bool useArrayFormat = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Backend V2 derives the executive from the JWT, so executiveId is kept
      // only for compatibility with existing UI calls.
      final response = await _api.get('/notifications');
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = data['notifications'] is List
          ? List<dynamic>.from(data['notifications'])
          : <dynamic>[];
      final maps = rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final unreadCount = maps.where((e) => e['read_at'] == null).length;
      final models = maps.map((e) => NotificationModel.fromV2(e, unreadCount)).toList();
      state = state.copyWith(
        isLoading: false,
        notifications: models,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: CrmApiClient.messageFrom(e),
      );
    }
  }

  Future<void> markNotificationAsRead(
    int notificationId,
    int executiveId,
  ) async {
    if (notificationId <= 0) return;
    try {
      await _api.patch('/notifications/$notificationId/read');
      final updated = state.notifications.map((notification) {
        if (notification.notificationId != notificationId) return notification;
        return NotificationModel(
          notificationId: notification.notificationId,
          notificationDate: notification.notificationDate,
          title: notification.title,
          notificationText: notification.notificationText,
          readStatus: 'Yes',
          totalUnreadNotifications:
              state.unreadCount > 0 ? state.unreadCount - 1 : 0,
          moduleName: notification.moduleName,
          entityId: notification.entityId,
          approvalId: notification.approvalId,
        );
      }).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: CrmApiClient.messageFrom(e));
      rethrow;
    }
  }

  Future<void> markNotificationsAsRead(int executiveId) async {
    final unread = state.notifications
        .where((n) => n.readStatus == 'No' && n.notificationId > 0)
        .toList();
    try {
      for (final notification in unread) {
        await _api.patch('/notifications/${notification.notificationId}/read');
      }
      await fetchNotifications(executiveId);
    } catch (e) {
      state = state.copyWith(errorMessage: CrmApiClient.messageFrom(e));
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
