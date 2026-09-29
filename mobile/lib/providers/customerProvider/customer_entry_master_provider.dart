import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../edit/utils/AppUtils.dart';

// Model Classes for each section of the API response
class BoardItem {
  final int boardId;
  final String boardName;

  BoardItem({required this.boardId, required this.boardName});

  factory BoardItem.fromJson(Map<String, dynamic> json) {
    return BoardItem(
      boardId: (json['BoardId'] as num).toInt(),
      boardName: json['BoardName'] ?? 'Unknown',
    );
  }
}

class ClassItem {
  final int classNumId;
  final String className;

  ClassItem({required this.classNumId, required this.className});

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      classNumId: (json['ClassNumId'] as num).toInt(),
      className: json['ClassName'] ?? 'Unknown',
    );
  }
}

class ChainSchoolItem {
  final int chainSchoolId;
  final String chainSchoolName;

  ChainSchoolItem({required this.chainSchoolId, required this.chainSchoolName});

  factory ChainSchoolItem.fromJson(Map<String, dynamic> json) {
    return ChainSchoolItem(
      chainSchoolId: (json['ChainSchoolId'] as num).toInt(),
      chainSchoolName: json['ChainSchoolName'] ?? 'Unknown',
    );
  }
}

class DataSourceItem {
  final int dataSourceId;
  final String dataSourceName;

  DataSourceItem({required this.dataSourceId, required this.dataSourceName});

  factory DataSourceItem.fromJson(Map<String, dynamic> json) {
    return DataSourceItem(
      dataSourceId: (json['DataSourceId'] as num).toInt(),
      dataSourceName: json['DataSourceName'] ?? 'Unknown',
    );
  }
}

class AccountableExecutiveItem {
  final int sNo;
  final String executiveName;

  AccountableExecutiveItem({required this.sNo, required this.executiveName});

  factory AccountableExecutiveItem.fromJson(Map<String, dynamic> json) {
    return AccountableExecutiveItem(
      sNo: (json['SNo'] as num).toInt(),
      executiveName: json['ExecutiveName'] ?? 'Unknown',
    );
  }
}

class SalutationItem {
  final int salutationId;
  final String salutationName;

  SalutationItem({required this.salutationId, required this.salutationName});

  factory SalutationItem.fromJson(Map<String, dynamic> json) {
    return SalutationItem(
      salutationId: (json['SalutationId'] as num).toInt(),
      salutationName: json['SalutationName'] ?? 'Unknown',
    );
  }
}

class ContactDesignationItem {
  final int contactDesignationId;
  final String contactDesignationName;

  ContactDesignationItem(
      {required this.contactDesignationId, required this.contactDesignationName});

  factory ContactDesignationItem.fromJson(Map<String, dynamic> json) {
    return ContactDesignationItem(
      contactDesignationId: (json['ContactDesignationId'] as num).toInt(),
      contactDesignationName: json['ContactDesignationName'] ?? 'Unknown',
    );
  }
}

class SubjectItem {
  final int subjectId;
  final String subjectName;

  SubjectItem({required this.subjectId, required this.subjectName});

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      subjectId: (json['SubjectId'] as num).toInt(),
      subjectName: json['SubjectName'] ?? 'Unknown',
    );
  }
}

class DepartmentItem {
  final int departmentId;
  final String departmentName;

  DepartmentItem({required this.departmentId, required this.departmentName});

  factory DepartmentItem.fromJson(Map<String, dynamic> json) {
    return DepartmentItem(
      departmentId: (json['DepartmentId'] as num).toInt(),
      departmentName: json['DepartmentName'] ?? 'Unknown',
    );
  }
}

class AdoptionRoleItem {
  final int adoptionRoleId;
  final String adoptionRole;

  AdoptionRoleItem({required this.adoptionRoleId, required this.adoptionRole});

  factory AdoptionRoleItem.fromJson(Map<String, dynamic> json) {
    return AdoptionRoleItem(
      adoptionRoleId: (json['AdoptionRoleId'] as num).toInt(),
      adoptionRole: json['AdoptionRole'] ?? 'Unknown',
    );
  }
}

class CustomerCategoryItem {
  final int customerCategoryId;
  final String customerCategoryName;

  CustomerCategoryItem(
      {required this.customerCategoryId, required this.customerCategoryName});

  factory CustomerCategoryItem.fromJson(Map<String, dynamic> json) {
    return CustomerCategoryItem(
      customerCategoryId: (json['CustomerCategoryId'] as num).toInt(),
      customerCategoryName: json['CustomerCategoryName'] ?? 'Unknown',
    );
  }
}

class MonthItem {
  final int id;
  final String name;

  MonthItem({required this.id, required this.name});

  factory MonthItem.fromJson(Map<String, dynamic> json) {
    return MonthItem(
      id: (json['ID'] as num).toInt(),
      name: json['Name'] ?? 'Unknown',
    );
  }
}

class PurchaseModeItem {
  final String modeValue;
  final String modeName;

  PurchaseModeItem({required this.modeValue, required this.modeName});

  factory PurchaseModeItem.fromJson(Map<String, dynamic> json) {
    return PurchaseModeItem(
      modeValue: json['ModeValue'] ?? 'Unknown',
      modeName: json['ModeName'] ?? 'Unknown',
    );
  }
}

class InstituteTypeItem {
  final String id;
  final String instituteType;

  InstituteTypeItem({required this.id, required this.instituteType});

  factory InstituteTypeItem.fromJson(Map<String, dynamic> json) {
    return InstituteTypeItem(
      id: json['ID'] ?? 'Unknown',
      instituteType: json['InstituteType'] ?? 'Unknown',
    );
  }
}

class InstituteLevelItem {
  final String id;
  final String instituteLevel;

  InstituteLevelItem({required this.id, required this.instituteLevel});

  factory InstituteLevelItem.fromJson(Map<String, dynamic> json) {
    return InstituteLevelItem(
      id: json['ID'] ?? 'Unknown',
      instituteLevel: json['InstituteLevel'] ?? 'Unknown',
    );
  }
}

class AffiliateTypeItem {
  final String id;
  final String affiliateType;

  AffiliateTypeItem({required this.id, required this.affiliateType});

  factory AffiliateTypeItem.fromJson(Map<String, dynamic> json) {
    return AffiliateTypeItem(
      id: json['ID'] ?? 'Unknown',
      affiliateType: json['AffiliateType'] ?? 'Unknown',
    );
  }
}

// State class to hold all data
class CustomerEntryMasterState {
  final List<BoardItem> boards;
  final List<ClassItem> classes;
  final List<ChainSchoolItem> chainSchools;
  final List<DataSourceItem> dataSources;
  final List<AccountableExecutiveItem> accountableExecutives;
  final List<SalutationItem> salutations;
  final List<ContactDesignationItem> contactDesignations;
  final List<SubjectItem> subjects;
  final List<DepartmentItem> departments;
  final List<AdoptionRoleItem> adoptionRoles;
  final List<CustomerCategoryItem> customerCategories;
  final List<MonthItem> months;
  final List<PurchaseModeItem> purchaseModes;
  final List<InstituteTypeItem> instituteTypes;
  final List<InstituteLevelItem> instituteLevels;
  final List<AffiliateTypeItem> affiliateTypes;
  final bool isLoading;
  final String? error;

  CustomerEntryMasterState({
    required this.boards,
    required this.classes,
    required this.chainSchools,
    required this.dataSources,
    required this.accountableExecutives,
    required this.salutations,
    required this.contactDesignations,
    required this.subjects,
    required this.departments,
    required this.adoptionRoles,
    required this.customerCategories,
    required this.months,
    required this.purchaseModes,
    required this.instituteTypes,
    required this.instituteLevels,
    required this.affiliateTypes,
    this.isLoading = false,
    this.error,
  });

  CustomerEntryMasterState copyWith({
    List<BoardItem>? boards,
    List<ClassItem>? classes,
    List<ChainSchoolItem>? chainSchools,
    List<DataSourceItem>? dataSources,
    List<AccountableExecutiveItem>? accountableExecutives,
    List<SalutationItem>? salutations,
    List<ContactDesignationItem>? contactDesignations,
    List<SubjectItem>? subjects,
    List<DepartmentItem>? departments,
    List<AdoptionRoleItem>? adoptionRoles,
    List<CustomerCategoryItem>? customerCategories,
    List<MonthItem>? months,
    List<PurchaseModeItem>? purchaseModes,
    List<InstituteTypeItem>? instituteTypes,
    List<InstituteLevelItem>? instituteLevels,
    List<AffiliateTypeItem>? affiliateTypes,
    bool? isLoading,
    String? error,
  }) {
    return CustomerEntryMasterState(
      boards: boards ?? this.boards,
      classes: classes ?? this.classes,
      chainSchools: chainSchools ?? this.chainSchools,
      dataSources: dataSources ?? this.dataSources,
      accountableExecutives: accountableExecutives ?? this.accountableExecutives,
      salutations: salutations ?? this.salutations,
      contactDesignations: contactDesignations ?? this.contactDesignations,
      subjects: subjects ?? this.subjects,
      departments: departments ?? this.departments,
      adoptionRoles: adoptionRoles ?? this.adoptionRoles,
      customerCategories: customerCategories ?? this.customerCategories,
      months: months ?? this.months,
      purchaseModes: purchaseModes ?? this.purchaseModes,
      instituteTypes: instituteTypes ?? this.instituteTypes,
      instituteLevels: instituteLevels ?? this.instituteLevels,
      affiliateTypes: affiliateTypes ?? this.affiliateTypes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CustomerEntryMasterNotifier extends StateNotifier<CustomerEntryMasterState> {
  final Ref ref;

  CustomerEntryMasterNotifier(this.ref)
      : super(CustomerEntryMasterState(
          boards: [],
          classes: [],
          chainSchools: [],
          dataSources: [],
          accountableExecutives: [],
          salutations: [],
          contactDesignations: [],
          subjects: [],
          departments: [],
          adoptionRoles: [],
          customerCategories: [],
          months: [],
          purchaseModes: [],
          instituteTypes: [],
          instituteLevels: [],
          affiliateTypes: [],
        )) {
    fetchCustomerEntryMaster();
  }

  Future<void> fetchCustomerEntryMaster() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = ref.read(authProvider).token;
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'No token available');
        return;
      }

      final data = await LegacyApiAdapter.instance.post(
        '/CustomerEntryMasterAPI',
        data: const <String, dynamic>{},
      );

      if (data['Status'] != 'Success') {
        state = state.copyWith(
          isLoading: false,
          error: 'API returned non-success status: ${data['Status']}',
        );
        return;
      }

      final boards = (data['BoardMaster'] as List)
          .map((json) => BoardItem.fromJson(json))
          .toList();
      final classes = (data['Classes'] as List)
          .map((json) => ClassItem.fromJson(json))
          .toList();
      final chainSchools = (data['ChainSchool'] as List)
          .map((json) => ChainSchoolItem.fromJson(json))
          .toList();
      final dataSources = (data['DataSource'] as List)
          .map((json) => DataSourceItem.fromJson(json))
          .toList();
      final accountableExecutives = (data['AccountableExecutive'] as List)
          .map((json) => AccountableExecutiveItem.fromJson(json))
          .toList();
      final salutations = (data['SalutationMaster'] as List)
          .map((json) => SalutationItem.fromJson(json))
          .toList();
      final contactDesignations = (data['ContactDesignation'] as List)
          .map((json) => ContactDesignationItem.fromJson(json))
          .toList();
      final subjects = (data['Subject'] as List)
          .map((json) => SubjectItem.fromJson(json))
          .toList();
      final departments = (data['Department'] as List)
          .map((json) => DepartmentItem.fromJson(json))
          .toList();
      final adoptionRoles = (data['AdoptionRoleMaster'] as List)
          .map((json) => AdoptionRoleItem.fromJson(json))
          .toList();
      final customerCategories = (data['CustomerCategory'] as List)
          .map((json) => CustomerCategoryItem.fromJson(json))
          .toList();
      final months = (data['Months'] as List)
          .map((json) => MonthItem.fromJson(json))
          .toList();
      final purchaseModes = (data['PurchaseMode'] as List)
          .map((json) => PurchaseModeItem.fromJson(json))
          .toList();
      final instituteTypes = (data['InstituteType'] as List)
          .map((json) => InstituteTypeItem.fromJson(json))
          .toList();
      final instituteLevels = (data['InstituteLevel'] as List)
          .map((json) => InstituteLevelItem.fromJson(json))
          .toList();
      final affiliateTypes = (data['AffiliateType'] as List)
          .map((json) => AffiliateTypeItem.fromJson(json))
          .toList();

      state = state.copyWith(
        boards: boards,
        classes: classes,
        chainSchools: chainSchools,
        dataSources: dataSources,
        accountableExecutives: accountableExecutives,
        salutations: salutations,
        contactDesignations: contactDesignations,
        subjects: subjects,
        departments: departments,
        adoptionRoles: adoptionRoles,
        customerCategories: customerCategories,
        months: months,
        purchaseModes: purchaseModes,
        instituteTypes: instituteTypes,
        instituteLevels: instituteLevels,
        affiliateTypes: affiliateTypes,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final customerEntryMasterProvider =
    StateNotifierProvider<CustomerEntryMasterNotifier, CustomerEntryMasterState>(
        (ref) => CustomerEntryMasterNotifier(ref));
