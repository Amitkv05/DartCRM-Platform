class SchoolDetails {
  final String board;
  final String? chainSchool;
  final String startClass;
  final String endClass;
  final String medium;
  final String ranking;
  final String samplingMonth;
  final String decisionMonth;
  final String purchaseMode;
  final String? bookSeller;
  final String keyCustomer;
  final String? panNumber;
  final String? gstNumber;
  final String customerStatus;

  SchoolDetails({
    required this.board,
    this.chainSchool,
    required this.startClass,
    required this.endClass,
    required this.medium,
    required this.ranking,
    required this.samplingMonth,
    required this.decisionMonth,
    required this.purchaseMode,
    this.bookSeller,
    required this.keyCustomer,
    this.panNumber,
    this.gstNumber,
    required this.customerStatus,
  });

  factory SchoolDetails.fromJson(Map<String, dynamic> json) {
    return SchoolDetails(
      board: json['Board'] ?? 'CBSE',
      chainSchool: json['ChainSchool'],
      startClass: json['StartClass'] ?? 'Nry',
      endClass: json['EndClass'] ?? '12',
      medium: json['Medium'] ?? 'English',
      ranking: json['Ranking'] ?? 'A',
      samplingMonth: json['SamplingMonth'] ?? 'December',
      decisionMonth: json['DecisionMonth'] ?? 'February',
      purchaseMode: json['PurchaseMode'] ?? 'Book Seller',
      bookSeller: json['BookSeller'],
      keyCustomer: json['KeyCustomer'] ?? 'Yes',
      panNumber: json['PANNumber'],
      gstNumber: json['GSTNumber'],
      customerStatus: json['CustomerStatus'] ?? 'Active',
    );
  }
}
