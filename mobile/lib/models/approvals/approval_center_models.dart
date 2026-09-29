class ApprovalSummary {
  final int approvalId;
  final String moduleName;
  final int entityId;
  final String requestNumber;
  final int currentLevel;
  final String status;
  final String requestedBy;
  final String requestedByCode;
  final DateTime? createdAt;

  const ApprovalSummary({
    required this.approvalId,
    required this.moduleName,
    required this.entityId,
    required this.requestNumber,
    required this.currentLevel,
    required this.status,
    required this.requestedBy,
    required this.requestedByCode,
    this.createdAt,
  });

  factory ApprovalSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
    return ApprovalSummary(
      approvalId: asInt(json['approval_id'] ?? json['approvalId']),
      moduleName: (json['module_name'] ?? json['moduleName'] ?? '').toString(),
      entityId: asInt(json['entity_id'] ?? json['entityId']),
      requestNumber: (json['request_number'] ?? json['requestNumber'] ?? '').toString(),
      currentLevel: asInt(json['current_level'] ?? json['currentLevel']),
      status: (json['status'] ?? '').toString(),
      requestedBy: (json['requested_by'] ?? json['requestedBy'] ?? '').toString(),
      requestedByCode: (json['requested_by_code'] ?? json['requestedByCode'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()),
    );
  }
}

class ApprovalCapabilities {
  final bool canAct;
  final bool supportsEditableQuantities;
  final bool canSendToNextLevel;
  final Map<String, dynamic>? nextEligibleApprover;

  const ApprovalCapabilities({
    required this.canAct,
    required this.supportsEditableQuantities,
    required this.canSendToNextLevel,
    this.nextEligibleApprover,
  });

  factory ApprovalCapabilities.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? next;
    if (json['nextEligibleApprover'] is Map) {
      next = Map<String, dynamic>.from(json['nextEligibleApprover'] as Map);
    }
    return ApprovalCapabilities(
      canAct: json['canAct'] == true,
      supportsEditableQuantities: json['supportsEditableQuantities'] == true,
      canSendToNextLevel: json['canSendToNextLevel'] == true,
      nextEligibleApprover: next,
    );
  }
}

class ApprovalDetailData {
  final Map<String, dynamic> approval;
  final Map<String, dynamic> requestData;
  final List<Map<String, dynamic>> history;
  final List<Map<String, dynamic>> itemHistory;
  final ApprovalCapabilities capabilities;

  const ApprovalDetailData({
    required this.approval,
    required this.requestData,
    required this.history,
    required this.itemHistory,
    required this.capabilities,
  });

  factory ApprovalDetailData.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> mapList(dynamic value) {
      if (value is! List) return <Map<String, dynamic>>[];
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return ApprovalDetailData(
      approval: json['approval'] is Map
          ? Map<String, dynamic>.from(json['approval'] as Map)
          : <String, dynamic>{},
      requestData: json['requestData'] is Map
          ? Map<String, dynamic>.from(json['requestData'] as Map)
          : <String, dynamic>{},
      history: mapList(json['history']),
      itemHistory: mapList(json['itemHistory']),
      capabilities: ApprovalCapabilities.fromJson(
        json['capabilities'] is Map
            ? Map<String, dynamic>.from(json['capabilities'] as Map)
            : <String, dynamic>{},
      ),
    );
  }
}

class ApprovalRoleExecutive {
  final int executiveId;
  final String executiveCode;
  final String executiveName;
  final String designation;
  final String profileCode;
  final String profileName;
  final int levelRank;
  final bool approvalEnabled;
  final bool isAdmin;
  final String? managerName;
  final int pendingApprovals;

  const ApprovalRoleExecutive({
    required this.executiveId,
    required this.executiveCode,
    required this.executiveName,
    required this.designation,
    required this.profileCode,
    required this.profileName,
    required this.levelRank,
    required this.approvalEnabled,
    required this.isAdmin,
    required this.pendingApprovals,
    this.managerName,
  });

  factory ApprovalRoleExecutive.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
    bool asBool(dynamic value) => value == true || value == 1 || value?.toString() == '1';
    return ApprovalRoleExecutive(
      executiveId: asInt(json['executive_id']),
      executiveCode: (json['executive_code'] ?? '').toString(),
      executiveName: (json['executive_name'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      profileCode: (json['profile_code'] ?? '').toString(),
      profileName: (json['profile_name'] ?? '').toString(),
      levelRank: asInt(json['level_rank']),
      approvalEnabled: asBool(json['approval_enabled']),
      isAdmin: asBool(json['is_admin']),
      managerName: json['manager_name']?.toString(),
      pendingApprovals: asInt(json['pending_approvals']),
    );
  }
}
