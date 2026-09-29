class LoginResponse {
  final String? status;
  final String? message;
  final String? token;
  final String? refreshToken;
  final List<ExecutiveBasicData>? executiveBasicData;
  final List<ApplicationSetup>? applicationSetup;
  final List<UpHierarchy>? upHierarchy;
  final List<DownHierarchy>? downHierarchy;
  final List<TerritoryAccess>? territoryAccess;
  final List<CityAccess>? cityAccess;
  final List<EntryAccess>? entryAccess;
  final List<ProductDivision>? productDivision;
  final List<dynamic>? executiveMessages;
  final List<dynamic>? loginSuccess;

  const LoginResponse({
    this.status,
    this.message,
    this.token,
    this.refreshToken,
    this.executiveBasicData,
    this.applicationSetup,
    this.upHierarchy,
    this.downHierarchy,
    this.territoryAccess,
    this.cityAccess,
    this.entryAccess,
    this.productDivision,
    this.executiveMessages,
    this.loginSuccess,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    if (json['user'] is Map) {
      return LoginResponse._fromV2(json);
    }
    return LoginResponse._fromLegacy(json);
  }

  factory LoginResponse._fromV2(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map);
    final setupMap = json['applicationSetup'] is Map
        ? Map<String, dynamic>.from(json['applicationSetup'] as Map)
        : <String, dynamic>{};

    List<int> intList(dynamic value) => value is List
        ? value.map((e) => int.tryParse(e.toString())).whereType<int>().toList()
        : <int>[];

    final up = intList(json['upHierarchy']);
    final down = intList(json['downHierarchy']);

    final territoryRows = json['territoryAccess'] is List
        ? List<dynamic>.from(json['territoryAccess'] as List)
        : <dynamic>[];
    final cityRows = json['cityAccess'] is List
        ? List<dynamic>.from(json['cityAccess'] as List)
        : <dynamic>[];
    final productRows = json['productDivision'] is List
        ? List<dynamic>.from(json['productDivision'] as List)
        : <dynamic>[];
    final entryRows = intList(json['entryAccess']);

    String idsFromRows(List<dynamic> rows) => rows
        .map((e) => e is Map ? e['id'] : e)
        .where((e) => e != null)
        .map((e) => e.toString())
        .join(',');

    return LoginResponse(
      status: 'Success',
      message: json['message']?.toString() ?? 'Login successful',
      token: json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      executiveBasicData: [
        ExecutiveBasicData(
          userId: int.tryParse(user['userId'].toString()) ?? 0,
          userName: json['loginEmail']?.toString() ?? user['email']?.toString() ?? '',
          executiveName: user['executiveName']?.toString() ?? '',
          executiveId: int.tryParse(user['executiveId'].toString()) ?? 0,
          executiveCode: user['executiveCode']?.toString() ?? '',
          profileId: int.tryParse(user['profileId'].toString()) ?? 0,
          profileName: user['profileName']?.toString() ?? '',
          profileCode: user['profileCode']?.toString() ?? '',
          profileRank: int.tryParse(user['profileRank'].toString()) ?? 0,
          designation: user['designation']?.toString(),
          mobile: user['mobile']?.toString(),
        ),
      ],
      applicationSetup: setupMap.entries
          .map((e) => ApplicationSetup(
                key: e.key,
                keyValue: e.value?.toString() ?? '',
                loginStatus: 'Successful',
              ))
          .toList(),
      upHierarchy: [UpHierarchy(upHierarchy: up.join(','))],
      downHierarchy: [DownHierarchy(downHierarchy: down.join(','))],
      territoryAccess: [TerritoryAccess(territoryAccess: idsFromRows(territoryRows))],
      cityAccess: [CityAccess(cityAccess: idsFromRows(cityRows))],
      entryAccess: [EntryAccess(entryAccess: entryRows.join(','))],
      productDivision: [
        ProductDivision(
          executiveId: int.tryParse(user['executiveId'].toString()),
          productDivisionIds: idsFromRows(productRows),
          executiveDepartmentCode: null,
        )
      ],
      executiveMessages: const [],
      loginSuccess: const [],
    );
  }

  factory LoginResponse._fromLegacy(Map<String, dynamic> json) {
    List<T>? parseList<T>(String key, T Function(Map<String, dynamic>) builder) {
      final raw = json[key];
      if (raw is! List) return null;
      return raw.whereType<Map>().map((e) => builder(Map<String, dynamic>.from(e))).toList();
    }

    return LoginResponse(
      status: json['Status']?.toString() ?? json['status']?.toString(),
      message: json['message']?.toString() ?? json['Message']?.toString(),
      token: json['Token']?.toString() ?? json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      executiveBasicData: parseList('ExecutiveBasicdata', ExecutiveBasicData.fromJson),
      applicationSetup: parseList('ApplicationSetup', ApplicationSetup.fromJson),
      upHierarchy: parseList('UpHierarchy', UpHierarchy.fromJson),
      downHierarchy: parseList('DownHierarchy', DownHierarchy.fromJson),
      territoryAccess: parseList('TerritoryAccess', TerritoryAccess.fromJson),
      cityAccess: parseList('CityAccess', CityAccess.fromJson),
      entryAccess: parseList('EntryAccess', EntryAccess.fromJson),
      productDivision: parseList('ProductDivision', ProductDivision.fromJson),
      executiveMessages: json['ExecutiveMessages'] is List ? json['ExecutiveMessages'] : const [],
      loginSuccess: json['LoginSuccess'] is List ? json['LoginSuccess'] : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'Status': status,
        'message': message,
        'Token': token,
        'refreshToken': refreshToken,
        'ExecutiveBasicdata': executiveBasicData?.map((e) => e.toJson()).toList(),
        'ApplicationSetup': applicationSetup?.map((e) => e.toJson()).toList(),
        'UpHierarchy': upHierarchy?.map((e) => e.toJson()).toList(),
        'DownHierarchy': downHierarchy?.map((e) => e.toJson()).toList(),
        'TerritoryAccess': territoryAccess?.map((e) => e.toJson()).toList(),
        'CityAccess': cityAccess?.map((e) => e.toJson()).toList(),
        'EntryAccess': entryAccess?.map((e) => e.toJson()).toList(),
        'ProductDivision': productDivision?.map((e) => e.toJson()).toList(),
        'ExecutiveMessages': executiveMessages,
        'LoginSuccess': loginSuccess,
      };
}

class ExecutiveBasicData {
  final int userId;
  final String userName;
  final String executiveName;
  final int executiveId;
  final String executiveCode;
  final int profileId;
  final String profileName;
  final String profileCode;
  final int profileRank;
  final String? designation;
  final String? mobile;

  const ExecutiveBasicData({
    required this.userId,
    required this.userName,
    required this.executiveName,
    required this.executiveId,
    required this.executiveCode,
    required this.profileId,
    required this.profileName,
    required this.profileCode,
    this.profileRank = 0,
    this.designation,
    this.mobile,
  });

  factory ExecutiveBasicData.fromJson(Map<String, dynamic> json) => ExecutiveBasicData(
        userId: int.tryParse((json['UserId'] ?? json['userId'] ?? 0).toString()) ?? 0,
        userName: (json['UserName'] ?? json['email'] ?? '').toString(),
        executiveName: (json['ExecutiveName'] ?? json['executiveName'] ?? '').toString(),
        executiveId: int.tryParse((json['ExecutiveId'] ?? json['executiveId'] ?? 0).toString()) ?? 0,
        executiveCode: (json['ExecutiveCode'] ?? json['executiveCode'] ?? '').toString(),
        profileId: int.tryParse((json['ProfileId'] ?? json['profileId'] ?? 0).toString()) ?? 0,
        profileName: (json['ProfileName'] ?? json['profileName'] ?? '').toString(),
        profileCode: (json['ProfileCode'] ?? json['profileCode'] ?? '').toString(),
        profileRank: int.tryParse((json['ProfileRank'] ?? json['profileRank'] ?? 0).toString()) ?? 0,
        designation: (json['Designation'] ?? json['designation'])?.toString(),
        mobile: (json['Mobile'] ?? json['mobile'])?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'UserId': userId,
        'UserName': userName,
        'ExecutiveName': executiveName,
        'ExecutiveId': executiveId,
        'ExecutiveCode': executiveCode,
        'ProfileId': profileId,
        'ProfileName': profileName,
        'ProfileCode': profileCode,
        'ProfileRank': profileRank,
        'Designation': designation,
        'Mobile': mobile,
      };
}

class ApplicationSetup {
  final String? key;
  final String? keyValue;
  final String? loginStatus;
  const ApplicationSetup({this.key, this.keyValue, this.loginStatus});
  factory ApplicationSetup.fromJson(Map<String, dynamic> json) => ApplicationSetup(
        key: (json['key'] ?? json['KeyName'])?.toString(),
        keyValue: (json['KeyValue'] ?? json['key_value'])?.toString(),
        loginStatus: json['LoginStatus']?.toString(),
      );
  Map<String, dynamic> toJson() => {'key': key, 'KeyValue': keyValue, 'LoginStatus': loginStatus};
}

class UpHierarchy {
  final String? upHierarchy;
  const UpHierarchy({this.upHierarchy});
  factory UpHierarchy.fromJson(Map<String, dynamic> json) => UpHierarchy(upHierarchy: json['UpHierarchy']?.toString());
  Map<String, dynamic> toJson() => {'UpHierarchy': upHierarchy};
}

class DownHierarchy {
  final String? downHierarchy;
  const DownHierarchy({this.downHierarchy});
  factory DownHierarchy.fromJson(Map<String, dynamic> json) => DownHierarchy(downHierarchy: json['DownHierarchy']?.toString());
  Map<String, dynamic> toJson() => {'DownHierarchy': downHierarchy};
}

class TerritoryAccess {
  final String? territoryAccess;
  const TerritoryAccess({this.territoryAccess});
  factory TerritoryAccess.fromJson(Map<String, dynamic> json) => TerritoryAccess(territoryAccess: json['TerritoryAccess']?.toString());
  Map<String, dynamic> toJson() => {'TerritoryAccess': territoryAccess};
}

class CityAccess {
  final String? cityAccess;
  const CityAccess({this.cityAccess});
  factory CityAccess.fromJson(Map<String, dynamic> json) => CityAccess(cityAccess: json['CityAccess']?.toString());
  Map<String, dynamic> toJson() => {'CityAccess': cityAccess};
}

class EntryAccess {
  final String? entryAccess;
  const EntryAccess({this.entryAccess});
  factory EntryAccess.fromJson(Map<String, dynamic> json) => EntryAccess(entryAccess: json['EntryAccess']?.toString());
  Map<String, dynamic> toJson() => {'EntryAccess': entryAccess};
}

class ProductDivision {
  final int? executiveId;
  final String? productDivisionIds;
  final String? executiveDepartmentCode;
  const ProductDivision({this.executiveId, this.productDivisionIds, this.executiveDepartmentCode});
  factory ProductDivision.fromJson(Map<String, dynamic> json) => ProductDivision(
        executiveId: int.tryParse((json['ExecutiveId'] ?? json['executiveId'] ?? 0).toString()),
        productDivisionIds: (json['ProductDivisionIds'] ?? json['productDivisionIds'])?.toString(),
        executiveDepartmentCode: (json['ExecutiveDepartmentCode'] ?? json['executiveDepartmentCode'])?.toString(),
      );
  Map<String, dynamic> toJson() => {
        'ExecutiveId': executiveId,
        'ProductDivisionIds': productDivisionIds,
        'ExecutiveDepartmentCode': executiveDepartmentCode,
      };
}
