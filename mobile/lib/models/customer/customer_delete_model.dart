class CustomerDeleteRequest {
  final int executiveId;
  final int customerId;
  final int customerContactId;
  final int enteredBy;
  final String validated;
  final String remarks;

  CustomerDeleteRequest({
    required this.executiveId,
    required this.customerId,
    required this.customerContactId,
    required this.enteredBy,
    required this.validated,
    required this.remarks,
  });

  Map<String, dynamic> toJson() => {
        'ExecutiveId': executiveId,
        'CustomerId': customerId,
        'CustomerContactId': customerContactId,
        'EnteredBy': enteredBy,
        'Validated': validated,
        'Remarks': remarks,
      };
}

class CustomerDeleteResponse {
  final String status;
  final List<ReturnMessage> returnMessage;
  final List<dynamic> list;

  CustomerDeleteResponse(
      {required this.status, required this.returnMessage, required this.list});

  factory CustomerDeleteResponse.fromJson(Map<String, dynamic> json) =>
      CustomerDeleteResponse(
        status: json['Status'],
        returnMessage: (json['ReturnMessage'] as List)
            .map((e) => ReturnMessage.fromJson(e))
            .toList(),
        list: json['List'],
      );
}

class ReturnMessage {
  final String msgType;
  final String msgText;

  ReturnMessage({required this.msgType, required this.msgText});

  factory ReturnMessage.fromJson(Map<String, dynamic> json) => ReturnMessage(
        msgType: json['MsgType'],
        msgText: json['MsgText'],
      );
}
