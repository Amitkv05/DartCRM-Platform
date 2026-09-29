class MasterData {
  final List<String> boardMaster;
  final List<String> chainSchool;
  final List<String> classes;
  final List<String> months;
  final List<String> purchaseMode;
  final List<String> accountableExecutive;
  final List<String> salutationMaster;
  final List<String> contactDesignation;
  final List<String> dataSource;
  final List<String> subject;

  MasterData({
    this.boardMaster = const [],
    this.chainSchool = const [],
    this.classes = const [],
    this.months = const [],
    this.purchaseMode = const [],
    this.accountableExecutive = const [],
    this.salutationMaster = const [],
    this.contactDesignation = const [],
    this.dataSource = const [],
    this.subject = const [],
  });

  factory MasterData.fromJson(Map<String, dynamic> json) {
    return MasterData(
      boardMaster: (json['BoardMaster'] as List?)
              ?.map((e) => e['BoardName'] as String)
              .toList() ??
          [],
      chainSchool: (json['ChainSchool'] as List?)
              ?.map((e) => e['ChainSchoolName'] as String)
              .toList() ??
          [],
      classes: (json['Classes'] as List?)
              ?.map((e) => e['ClassName'] as String)
              .toList() ??
          [],
      months:
          (json['Months'] as List?)?.map((e) => e['Name'] as String).toList() ??
              [],
      purchaseMode: (json['PurchaseMode'] as List?)
              ?.map((e) => e['ModeName'] as String)
              .toList() ??
          [],
      accountableExecutive: (json['AccountableExecutive'] as List?)
              ?.map((e) => e['ExecutiveName'] as String)
              .toList() ??
          [],
      salutationMaster: (json['SalutationMaster'] as List?)
              ?.map((e) => e['SalutationName'] as String)
              .toList() ??
          [],
      contactDesignation: (json['ContactDesignation'] as List?)
              ?.map((e) => e['ContactDesignationName'] as String)
              .toList() ??
          [],
      dataSource: (json['DataSource'] as List?)
              ?.map((e) => e['DataSourceName'] as String)
              .toList() ??
          [],
      subject: (json['Subject'] as List?)
              ?.map((e) => e['SubjectName'] as String)
              .toList() ??
          [],
    );
  }
}
