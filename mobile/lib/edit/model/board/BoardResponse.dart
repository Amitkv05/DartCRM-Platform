import 'BoardMaster.dart';
import 'Classes.dart';
import 'ChainSchool.dart';
import 'DataSource.dart';
import 'AccountableExecutive.dart';
import 'SalutationMaster.dart';
import 'ContactDesignation.dart';
import 'Subject.dart';
import 'Department.dart';
import 'AdoptionRoleMaster.dart';
import 'CustomerCategory.dart';
import 'Months.dart';
import 'PurchaseMode.dart';
import 'InstituteType.dart';
import 'InstituteLevel.dart';
import 'AffiliateType.dart';

class BoardResponse {
  BoardResponse({
    this.status,
    this.boardMaster,
    this.classes,
    this.chainSchool,
    this.dataSource,
    this.accountableExecutive,
    this.salutationMaster,
    this.contactDesignation,
    this.subject,
    this.department,
    this.adoptionRoleMaster,
    this.customerCategory,
    this.months,
    this.purchaseMode,
    this.instituteType,
    this.instituteLevel,
    this.affiliateType,
    this.customerEntryData,
  });

  BoardResponse.fromJson(dynamic json) {
    status = json['Status'];
    if (json['BoardMaster'] != null) {
      boardMaster = [];
      json['BoardMaster'].forEach((v) {
        boardMaster?.add(BoardMaster.fromJson(v));
      });
    }
    if (json['Classes'] != null) {
      classes = [];
      json['Classes'].forEach((v) {
        classes?.add(Classes.fromJson(v));
      });
    }
    if (json['ChainSchool'] != null) {
      chainSchool = [];
      json['ChainSchool'].forEach((v) {
        chainSchool?.add(ChainSchool.fromJson(v));
      });
    }
    if (json['DataSource'] != null) {
      dataSource = [];
      json['DataSource'].forEach((v) {
        dataSource?.add(DataSource.fromJson(v));
      });
    }
    if (json['AccountableExecutive'] != null) {
      accountableExecutive = [];
      json['AccountableExecutive'].forEach((v) {
        accountableExecutive?.add(AccountableExecutive.fromJson(v));
      });
    }
    if (json['SalutationMaster'] != null) {
      salutationMaster = [];
      json['SalutationMaster'].forEach((v) {
        salutationMaster?.add(SalutationMaster.fromJson(v));
      });
    }
    if (json['ContactDesignation'] != null) {
      contactDesignation = [];
      json['ContactDesignation'].forEach((v) {
        contactDesignation?.add(ContactDesignation.fromJson(v));
      });
    }
    if (json['Subject'] != null) {
      subject = [];
      json['Subject'].forEach((v) {
        subject?.add(Subject.fromJson(v));
      });
    }
    if (json['Department'] != null) {
      department = [];
      json['Department'].forEach((v) {
        department?.add(Department.fromJson(v));
      });
    }
    if (json['AdoptionRoleMaster'] != null) {
      adoptionRoleMaster = [];
      json['AdoptionRoleMaster'].forEach((v) {
        adoptionRoleMaster?.add(AdoptionRoleMaster.fromJson(v));
      });
    }
    if (json['CustomerCategory'] != null) {
      customerCategory = [];
      json['CustomerCategory'].forEach((v) {
        customerCategory?.add(CustomerCategory.fromJson(v));
      });
    }
    if (json['Months'] != null) {
      months = [];
      json['Months'].forEach((v) {
        months?.add(Months.fromJson(v));
      });
    }
    if (json['PurchaseMode'] != null) {
      purchaseMode = [];
      json['PurchaseMode'].forEach((v) {
        purchaseMode?.add(PurchaseMode.fromJson(v));
      });
    }
    if (json['InstituteType'] != null) {
      instituteType = [];
      json['InstituteType'].forEach((v) {
        instituteType?.add(InstituteType.fromJson(v));
      });
    }
    if (json['InstituteLevel'] != null) {
      instituteLevel = [];
      json['InstituteLevel'].forEach((v) {
        instituteLevel?.add(InstituteLevel.fromJson(v));
      });
    }
    if (json['AffiliateType'] != null) {
      affiliateType = [];
      json['AffiliateType'].forEach((v) {
        affiliateType?.add(AffiliateType.fromJson(v));
      });
    }
  }

  String? status;
  List<BoardMaster>? boardMaster;
  List<Classes>? classes;
  List<ChainSchool>? chainSchool;
  List<DataSource>? dataSource;
  List<AccountableExecutive>? accountableExecutive;
  List<SalutationMaster>? salutationMaster;
  List<ContactDesignation>? contactDesignation;
  List<Subject>? subject;
  List<Department>? department;
  List<AdoptionRoleMaster>? adoptionRoleMaster;
  List<CustomerCategory>? customerCategory;
  List<Months>? months;
  List<PurchaseMode>? purchaseMode;
  List<InstituteType>? instituteType;
  List<InstituteLevel>? instituteLevel;
  List<AffiliateType>? affiliateType;
  List<dynamic>? customerEntryData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Status'] = status;
    if (boardMaster != null) {
      map['BoardMaster'] = boardMaster?.map((v) => v.toJson()).toList();
    }
    if (classes != null) {
      map['Classes'] = classes?.map((v) => v.toJson()).toList();
    }
    if (chainSchool != null) {
      map['ChainSchool'] = chainSchool?.map((v) => v.toJson()).toList();
    }
    if (dataSource != null) {
      map['DataSource'] = dataSource?.map((v) => v.toJson()).toList();
    }
    if (accountableExecutive != null) {
      map['AccountableExecutive'] = accountableExecutive?.map((v) => v.toJson()).toList();
    }
    if (salutationMaster != null) {
      map['SalutationMaster'] = salutationMaster?.map((v) => v.toJson()).toList();
    }
    if (contactDesignation != null) {
      map['ContactDesignation'] = contactDesignation?.map((v) => v.toJson()).toList();
    }
    if (subject != null) {
      map['Subject'] = subject?.map((v) => v.toJson()).toList();
    }
    if (department != null) {
      map['Department'] = department?.map((v) => v.toJson()).toList();
    }
    if (adoptionRoleMaster != null) {
      map['AdoptionRoleMaster'] = adoptionRoleMaster?.map((v) => v.toJson()).toList();
    }
    if (customerCategory != null) {
      map['CustomerCategory'] = customerCategory?.map((v) => v.toJson()).toList();
    }
    if (months != null) {
      map['Months'] = months?.map((v) => v.toJson()).toList();
    }
    if (purchaseMode != null) {
      map['PurchaseMode'] = purchaseMode?.map((v) => v.toJson()).toList();
    }
    if (instituteType != null) {
      map['InstituteType'] = instituteType?.map((v) => v.toJson()).toList();
    }
    if (instituteLevel != null) {
      map['InstituteLevel'] = instituteLevel?.map((v) => v.toJson()).toList();
    }
    if (affiliateType != null) {
      map['AffiliateType'] = affiliateType?.map((v) => v.toJson()).toList();
    }
    if (customerEntryData != null) {
      map['CustomerEntryData'] = customerEntryData?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
