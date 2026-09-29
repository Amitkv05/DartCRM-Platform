import 'package:dart_crm/models/planList/eProduct_details.dart';

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) => value?.toString() ?? '';

class SamplingResponse {
  final List<String> samplingTypes;
  final List<String> sampleGivenOptions;

  SamplingResponse({
    required this.samplingTypes,
    required this.sampleGivenOptions,
  });
}

class ClassLevelResponse {
  final List<String> classLevels;

  ClassLevelResponse({required this.classLevels});
}

class FollowUpAction {
  final int executiveDepartmentId;
  final String executive;
  final String executiveID;
  final String actionDate;
  final String actionText;

  FollowUpAction({
    required this.executiveDepartmentId,
    required this.executive,
    required this.executiveID,
    required this.actionDate,
    required this.actionText,
  });
}

class DocumentSaveData {
  String documentName = '';
  String fileName = '';
  int size = 0;

  @override
  String toString() {
    return 'DocumentSaveData{documentName: $documentName, fileName: $fileName, size: $size}';
  }
}

class EProductData {
  String? brandId;
  String? brandName;
  String? productId;
  String? productName;
  String? classId;
  String? className;
  String? preSalesStageId;
  String? preSalesStageName;
  String? currentSalesStageId;
  String? currentSalesStageName;
  String? prospectId;
  String? prospectName;
  String? remark;

  EProductData({
    required this.brandId,
    required this.brandName,
    required this.productId,
    required this.productName,
    required this.classId,
    required this.className,
    required this.preSalesStageId,
    required this.preSalesStageName,
    required this.currentSalesStageId,
    required this.currentSalesStageName,
    required this.prospectId,
    required this.prospectName,
    required this.remark,
  });
}

class ProspectData {
  final int ProspectId;
  final String ProspectName;

  const ProspectData({required this.ProspectId, required this.ProspectName});

  factory ProspectData.fromJson(Map<String, dynamic> json) => ProspectData(
        ProspectId: _asInt(json['ProspectId'] ?? json['prospect_id'] ?? json['id']),
        ProspectName: _asString(json['ProspectName'] ?? json['prospect_name'] ?? json['name']),
      );
}

class SaleStagData {
  final int SalesStageId;
  final String SalesStageName;
  final int SequenceNum;

  const SaleStagData({
    required this.SalesStageId,
    required this.SalesStageName,
    required this.SequenceNum,
  });

  factory SaleStagData.fromJson(Map<String, dynamic> json) => SaleStagData(
        SalesStageId: _asInt(json['SalesStageId'] ?? json['sales_stage_id'] ?? json['id']),
        SalesStageName: _asString(json['SalesStageName'] ?? json['sales_stage_name'] ?? json['stage_name']),
        SequenceNum: _asInt(json['SequenceNum'] ?? json['sequence_num']),
      );
}

class AcademicData {
  final String AcademicSession;
  final int AcademicSessionId;
  final String? startDate;
  final String? endDate;

  const AcademicData({
    required this.AcademicSession,
    required this.AcademicSessionId,
    this.startDate,
    this.endDate,
  });

  factory AcademicData.fromJson(Map<String, dynamic> json) => AcademicData(
        AcademicSession: _asString(json['AcademicSession'] ?? json['academic_session'] ?? json['session_name']),
        AcademicSessionId: _asInt(json['AcademicSessionId'] ?? json['academic_session_id'] ?? json['id']),
        startDate: (json['StartDate'] ?? json['start_date'])?.toString(),
        endDate: (json['EndDate'] ?? json['end_date'])?.toString(),
      );
}

class BrandData {
  final int BrandId;
  final String BrandName;

  const BrandData({required this.BrandId, required this.BrandName});

  factory BrandData.fromJson(Map<String, dynamic> json) => BrandData(
        BrandId: _asInt(json['BrandId'] ?? json['brand_id'] ?? json['id']),
        BrandName: _asString(json['BrandName'] ?? json['brand_name'] ?? json['name']),
      );
}

class ApplicationSetupKeyValue {
  final String visitBooksSampling;
  final String visitEProducts;

  const ApplicationSetupKeyValue({
    required this.visitBooksSampling,
    required this.visitEProducts,
  });

  bool get booksSamplingEnabled => visitBooksSampling.toUpperCase() == 'Y' || visitBooksSampling.toLowerCase() == 'yes';
  bool get eProductsEnabled => visitEProducts.toUpperCase() == 'Y' || visitEProducts.toLowerCase() == 'yes';

  factory ApplicationSetupKeyValue.fromJson(Map<String, dynamic> json) =>
      ApplicationSetupKeyValue(
        visitBooksSampling: _asString(json['VisitBooksSampling'] ?? json['visitBooksSampling'] ?? 'N'),
        visitEProducts: _asString(json['VisitEProducts'] ?? json['visitEProducts'] ?? 'N'),
      );
}

class AllowedDateRange {
  final String fromDate;
  final String toDate;
  final String? source;
  final int? backdateRequestId;

  const AllowedDateRange({
    required this.fromDate,
    required this.toDate,
    this.source,
    this.backdateRequestId,
  });

  DateTime? get from => DateTime.tryParse(fromDate);
  DateTime? get to => DateTime.tryParse(toDate);

  bool contains(DateTime date) {
    final start = from;
    final end = to;
    if (start == null || end == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  factory AllowedDateRange.fromJson(Map<String, dynamic> json) => AllowedDateRange(
        fromDate: _asString(json['FromDate'] ?? json['fromDate'] ?? json['from_date']),
        toDate: _asString(json['ToDate'] ?? json['toDate'] ?? json['to_date']),
        source: (json['Source'] ?? json['source'])?.toString(),
        backdateRequestId: _asInt(json['BackdateRequestId'] ?? json['backdateRequestId']) == 0
            ? null
            : _asInt(json['BackdateRequestId'] ?? json['backdateRequestId']),
      );
}

class VisitPurpose {
  final int id;
  final String visitPurpose;

  VisitPurpose({
    required this.id,
    required this.visitPurpose,
  });

  factory VisitPurpose.fromJson(Map<String, dynamic> json) {
    return VisitPurpose(
      id: int.tryParse((json['Id'] ?? json['id'] ?? 0).toString()) ?? 0,
      visitPurpose: (json['VisitPurpose'] ?? json['visit_purpose'] ?? '').toString(),
    );
  }
}

class CustomerSummary {
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final String? emailId;
  final String? mobile;
  final String refCode;

  CustomerSummary({
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.address,
    this.emailId,
    this.mobile,
    required this.refCode,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    return CustomerSummary(
      customerId: int.tryParse((json['CustomerId'] ?? json['id'] ?? json['customer_id'] ?? 0).toString()) ?? 0,
      customerName: (json['CustomerName'] ?? json['customer_name'] ?? '').toString(),
      customerCode: (json['CustomerCode'] ?? json['customer_code'] ?? '').toString(),
      customerType: (json['CustomerType'] ?? json['customer_type'] ?? '').toString(),
      address: (json['Address'] ?? json['address'] ?? '').toString(),
      emailId: (json['EmailId'] ?? json['email'])?.toString(),
      mobile: (json['Mobile'] ?? json['mobile'])?.toString(),
      refCode: (json['RefCode'] ?? json['ref_code'] ?? '').toString(),
    );
  }
}

class PersonMet {
  final int customerContactId;
  final String customerContactName;

  PersonMet({
    required this.customerContactId,
    required this.customerContactName,
  });

  factory PersonMet.fromJson(Map<String, dynamic> json) {
    return PersonMet(
      customerContactId: int.tryParse((json['CustomerContactId'] ?? json['customer_contact_id'] ?? 0).toString()) ?? 0,
      customerContactName: (json['CustomerContactName'] ?? json['customer_contact_name'] ?? '').toString(),
    );
  }
}

class JoinVisit {
  final int executiveId;
  final String executiveName;

  JoinVisit({
    required this.executiveId,
    required this.executiveName,
  });

  factory JoinVisit.fromJson(Map<String, dynamic> json) {
    return JoinVisit(
      executiveId: int.tryParse((json['ExecutiveId'] ?? json['executive_id'] ?? 0).toString()) ?? 0,
      executiveName: (json['ExecutiveName'] ?? json['executive_name'] ?? '').toString(),
    );
  }
}

class Executive {
  final int executiveId;
  final String name;

  Executive({
    required this.executiveId,
    required this.name,
  });

  factory Executive.fromJson(Map<String, dynamic> json) {
    return Executive(
      executiveId: int.tryParse((json['ExecutiveId'] ?? json['executive_id'] ?? 0).toString()) ?? 0,
      name: (json['ExecutiveName'] ?? json['executive_name'] ?? '').toString(),
    );
  }
}

class Department {
  final int id;
  final String executiveDepartmentName;

  Department({
    required this.id,
    required this.executiveDepartmentName,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: int.tryParse((json['Id'] ?? json['id'] ?? 0).toString()) ?? 0,
      executiveDepartmentName: (json['ExecutiveDepartmentName'] ?? json['department'] ?? json['name'] ?? '').toString(),
    );
  }
}

class DSREntryResponse {
  final String status;
  final List<VisitPurpose> visitPurpose;
  final List<CustomerSummary> customerSummary;
  final List<PersonMet> personMet;
  final List<JoinVisit> joinVisit;
  final List<Department> department;
  final EProductDetails? eProductDetails;
  final List<BrandData> brand;
  final List<ProspectData> prospect;
  final List<SaleStagData> saleStage;
  final List<AcademicData> academicSession;
  final List<ApplicationSetupKeyValue> applicationSetupKeyValue;
  final List<AllowedDateRange> allowedDateRange;

  DSREntryResponse({
    required this.status,
    required this.visitPurpose,
    required this.customerSummary,
    required this.personMet,
    required this.joinVisit,
    required this.department,
    required this.brand,
    this.eProductDetails,
    this.prospect = const [],
    this.saleStage = const [],
    this.academicSession = const [],
    this.applicationSetupKeyValue = const [],
    this.allowedDateRange = const [],
  });

  factory DSREntryResponse.fromJson(Map<String, dynamic> json) {
    final rawCustomer = json['CustomerSummary'] ?? json['customerSummary'];
    final customerRows = rawCustomer is List
        ? rawCustomer
        : rawCustomer is Map
            ? [rawCustomer]
            : <dynamic>[];
    final rawStatus = (json['Status'] ?? json['status'] ?? 'error').toString();

    List<dynamic> rows(dynamic value) => value is List ? value : const [];
    Map<String, dynamic> asMap(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

    return DSREntryResponse(
      status: rawStatus.toLowerCase() == 'success' ? 'Success' : rawStatus,
      visitPurpose: rows(json['VisitPurpose'] ?? json['visitPurpose'])
          .map((e) => VisitPurpose.fromJson(asMap(e)))
          .toList(),
      customerSummary: customerRows
          .map((e) => CustomerSummary.fromJson(asMap(e)))
          .toList(),
      personMet: rows(json['PersonMet'] ?? json['personMet'])
          .map((e) => PersonMet.fromJson(asMap(e)))
          .toList(),
      joinVisit: rows(json['JoinVisit'] ?? json['joinVisit'])
          .map((e) => JoinVisit.fromJson(asMap(e)))
          .toList(),
      department: rows(json['Department'] ?? json['departments'])
          .map((e) => Department.fromJson(asMap(e)))
          .toList(),
      brand: rows(json['Brand'] ?? json['brands'])
          .map((e) => BrandData.fromJson(asMap(e)))
          .toList(),
      prospect: rows(json['Prospect'] ?? json['prospects'])
          .map((e) => ProspectData.fromJson(asMap(e)))
          .toList(),
      saleStage: rows(json['SalesStage'] ?? json['salesStage'])
          .map((e) => SaleStagData.fromJson(asMap(e)))
          .toList(),
      academicSession: rows(json['AcademicSession'] ?? json['academicSessions'])
          .map((e) => AcademicData.fromJson(asMap(e)))
          .toList(),
      applicationSetupKeyValue: rows(json['ApplicationSetupKeyValue'] ?? json['applicationSetupKeyValue'])
          .map((e) => ApplicationSetupKeyValue.fromJson(asMap(e)))
          .toList(),
      allowedDateRange: rows(json['AllowedDateRange'] ?? json['allowedDateRanges'])
          .map((e) => AllowedDateRange.fromJson(asMap(e)))
          .toList(),
      eProductDetails: null,
    );
  }
}

class FollowUpActionResponse {
  final String status;
  final List<Executive> executives;

  FollowUpActionResponse({
    required this.status,
    required this.executives,
  });

  factory FollowUpActionResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['Status'] ?? json['status'] ?? 'error').toString();
    final rows = (json['Executive'] ?? json['executives']) as List<dynamic>? ?? [];
    return FollowUpActionResponse(
      status: rawStatus.toLowerCase() == 'success' ? 'Success' : rawStatus,
      executives: rows.map((e) => Executive.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class DepartmentResponse {
  final String status;
  final List<Department> departments;

  DepartmentResponse({
    required this.status,
    required this.departments,
  });

  factory DepartmentResponse.fromJson(Map<String, dynamic> json) {
    return DepartmentResponse(
      status: json['Status'] ?? 'error',
      departments: (json['DepartmentList'] as List<dynamic>?)
              ?.map((e) => Department.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EProductEntry {
  final int brandId;
  final int eProductId;
  final String productName;
  final List<int> classNumIds;
  final int salesStageId;
  final int prospectId;
  final String remarks;

  EProductEntry({
    required this.brandId,
    required this.eProductId,
    required this.productName,
    required this.classNumIds,
    required this.salesStageId,
    required this.prospectId,
    required this.remarks,
  });
}

// Product details response
class ProductDetailsResponse {
  final String status;
  final List<ProductDetail> productDetails;
  final List<ProductClass> classes;
  final List<dynamic> products;

  ProductDetailsResponse({
    required this.status,
    required this.productDetails,
    required this.classes,
    required this.products,
  });

  factory ProductDetailsResponse.fromJson(Map<String, dynamic> json) =>
      ProductDetailsResponse(
        status: json['Status'] ?? 'error',
        productDetails: (json['ProductDetails'] as List<dynamic>?)
                ?.map((e) => ProductDetail.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        classes: (json['classes'] as List<dynamic>?)
                ?.map((e) => ProductClass.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        products: json['Products'] ?? [],
      );
}

// Product detail
class ProductDetail {
  final int eProductId;
  final String eProductName;
  final double listPrice;
  final String subjectName;
  final String previousSalesStage;
  final int previousStageSequenceNum;

  ProductDetail({
    required this.eProductId,
    required this.eProductName,
    required this.listPrice,
    required this.subjectName,
    required this.previousSalesStage,
    required this.previousStageSequenceNum,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) => ProductDetail(
        eProductId: json['eProductId'] ?? 0,
        eProductName: json['eProductName'] ?? '',
        listPrice: (json['ListPrice'] ?? 0.0).toDouble(),
        subjectName: json['SubjectName'] ?? '',
        previousSalesStage: json['PreviousSalesStage'] ?? '',
        previousStageSequenceNum: json['PreviousStageSequenceNum'] ?? 0,
      );
}

// Product class
class ProductClass {
  final int classNumId;
  final String className;

  ProductClass({
    required this.classNumId,
    required this.className,
  });

  factory ProductClass.fromJson(Map<String, dynamic> json) => ProductClass(
        classNumId: json['ClassNumId'] ?? 0,
        className: json['ClassName'] ?? '',
      );
}

// Product list response
class ProductListResponse {
  final String status;
  final List<ProductListItem> productList;
  final List<dynamic> products;

  ProductListResponse({
    required this.status,
    required this.productList,
    required this.products,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) => ProductListResponse(
        status: json['Status'] ?? 'error',
        productList: (json['ProductList'] as List<dynamic>?)
                ?.map((e) => ProductListItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        products: json['Products'] ?? [],
      );
}

// Product list item
class ProductListItem {
  final int id;
  final String productName;

  ProductListItem({
    required this.id,
    required this.productName,
  });

  factory ProductListItem.fromJson(Map<String, dynamic> json) => ProductListItem(
        id: json['Id'] ?? 0,
        productName: json['ProductName'] ?? '',
      );
}
