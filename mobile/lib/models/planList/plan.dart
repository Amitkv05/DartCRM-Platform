class Plan {
  final String customerName;
  final String customerCode;
  final String visitPurpose;
  final String refCode;
  final String customerType;
  final String address;
  final String contact;
  final String city;
  final String state;
  final String emailId;
  final String phone;
  final int customerId;

  const Plan({
    required this.customerName,
    required this.customerCode,
    required this.visitPurpose,
    required this.refCode,
    required this.customerType,
    required this.address,
    required this.contact,
    required this.city,
    required this.state,
    required this.emailId,
    required this.phone,
    required this.customerId,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    dynamic pick(String oldKey, String newKey) => json[oldKey] ?? json[newKey];
    return Plan(
      customerName: pick('CustomerName', 'customer_name')?.toString() ?? '',
      customerCode: pick('CustomerCode', 'customer_code')?.toString() ?? '',
      visitPurpose: pick('VisitPurpose', 'visit_purpose')?.toString() ?? '',
      refCode: pick('RefCode', 'ref_code')?.toString() ?? '',
      customerType: pick('CustomerType', 'customer_type')?.toString() ?? '',
      address: pick('Address', 'address')?.toString() ?? '',
      contact: pick('Contact', 'contact')?.toString() ?? '',
      city: pick('City', 'city')?.toString() ?? '',
      state: pick('State', 'state')?.toString() ?? '',
      emailId: pick('EmailId', 'email')?.toString() ?? '',
      phone: pick('Phone', 'mobile')?.toString() ?? '',
      customerId: int.tryParse((pick('CustomerId', 'customer_id') ?? 0).toString()) ?? 0,
    );
  }
}

class PlanResponse {
  final String status;
  final List<Plan> todayPlan;
  final List<Plan> tomorrowPlan;
  final List<Plan> travelPlan;

  const PlanResponse({
    required this.status,
    required this.todayPlan,
    required this.tomorrowPlan,
    required this.travelPlan,
  });

  factory PlanResponse.fromJson(Map<String, dynamic> json) {
    final todayPlanJson = (json['TodayPlan'] ?? json['todayPlan']) as List<dynamic>? ?? [];
    final tomorrowPlanJson = (json['TommorowPlan'] ?? json['tomorrowPlan']) as List<dynamic>? ?? [];
    final travelPlanJson = (json['TravelPlan'] ?? json['travelPlan']) as List<dynamic>? ?? [];
    final rawStatus = (json['Status'] ?? json['status'] ?? 'error').toString();
    return PlanResponse(
      status: rawStatus.toLowerCase() == 'success' ? 'Success' : rawStatus,
      todayPlan: todayPlanJson.map((e) => Plan.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      tomorrowPlan: tomorrowPlanJson.map((e) => Plan.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      travelPlan: travelPlanJson.map((e) => Plan.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}
