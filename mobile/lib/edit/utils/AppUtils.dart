import 'dart:convert';

import 'package:dart_crm/core/config/app_config.dart';

import 'package:dart_crm/edit/api/repository/api_repository.dart';
import 'package:dart_crm/edit/model/school/AddSubject.dart';
import 'package:dart_crm/edit/model/school/SchoolDetailsNew.dart';
import 'package:dart_crm/edit/model/schoolUpdate/StateResponse.dart';
import 'package:dart_crm/edit/model/teacherUpdate/TeacherUpdateRequest.dart';
import 'package:dart_crm/edit/utils/ext.dart';
import 'package:dart_crm/models/planList/dsr_sampling_details.dart';
import 'package:dart_crm/models/setup_value.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/login_response.dart';

// import '../../models/planList/sampling_details.dart';
import '../model/Geo/GeographyModel.dart';
import '../model/board/BoardResponse.dart';
import '../model/school/EnrolmentList.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/schoolUpdate/AllUpdateRequest.dart';
import '../model/seller/BookSellerData.dart';
import '../model/teacher/ContactModel.dart';
import 'click_fill_widget.dart';
import 'color_constants.dart';
import 'fill_button_widget.dart';

List<GeographyModel>? GEO_DATA;
AllUpdateRequest UPDATED_REQ = AllUpdateRequest();
BoardResponse? BOARD_DATA;
LoginResponse? USER_LOGIN_DATA;
String? LAT_DATA;
String? LONG_DATA;
int FROM_TODSR = 0;
List<SamplingModel> sampleInSeries = [];
List<SamplingModel> sampleNotInSeries = [];
List<EnrolmentList>? classes = [];

String BASE_URL_1 = AppConfig.serverBaseUrl;
String BASE_URL = AppConfig.apiBaseUrl;

List<SetupValue>? SETUP_VALUE;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppUtils {
  static String getTerritoryAccess() {
    final List<String?> str = [];

    USER_LOGIN_DATA?.territoryAccess?.forEach((action) {
      var d = action.territoryAccess;
      str.add(d);
    });
    String? ids;
    if (str.isNotEmpty) {
      ids = str.join(',');
    }
    return ids ?? '';
  }

  static String getExecutiveStr() {
    final List<int> executive = [];
    USER_LOGIN_DATA?.executiveBasicData?.forEach((action) {
      var d = action.executiveId;
      executive.add(d);
    });
    String? reqExecutiveId;
    if (executive.isNotEmpty) {
      reqExecutiveId = executive.join(',');
    }
    return reqExecutiveId ?? '';
  }

  static String getContactId() {
    final List<int> contactId = [];
    USER_LOGIN_DATA?.executiveBasicData?.forEach((action) {
      var d = action.executiveId;
      contactId.add(d);
    });
    String? reqContactId;
    if (contactId.isNotEmpty) {
      reqContactId = contactId.join(',');
    }
    return reqContactId ?? '';
  }

  static int getUserId() {
    int userId = 0;
    if (USER_LOGIN_DATA?.executiveBasicData != null &&
        (USER_LOGIN_DATA?.executiveBasicData!.length ?? 0) > 0) {
      userId = USER_LOGIN_DATA?.executiveBasicData?[0].userId ?? 0;
    }
    return userId;
  }

  static String getProfileCodeStr() {
    final List<String> executive = [];
    USER_LOGIN_DATA?.executiveBasicData?.forEach((action) {
      var d = action.profileCode;
      executive.add(d);
    });
    String? reqExecutiveId;
    if (executive.isNotEmpty) {
      reqExecutiveId = executive.join(',');
    }
    return reqExecutiveId ?? 'L1';
  }

  static String getProfileIdStr() {
    final List<int> executive = [];
    USER_LOGIN_DATA?.executiveBasicData?.forEach((action) {
      var d = action.profileId;
      executive.add(d);
    });
    String? reqExecutiveId;
    if (executive.isNotEmpty) {
      reqExecutiveId = executive.join(',');
    }
    return reqExecutiveId ?? '5';
  }

  static String getUpStr() {
    final List<String?> executive = [];
    USER_LOGIN_DATA?.upHierarchy?.forEach((action) {
      var d = action.upHierarchy;
      executive.add(d);
    });
    String? reqExecutiveId;
    if (executive.isNotEmpty) {
      reqExecutiveId = executive.join(',');
    }
    return reqExecutiveId ?? '';
  }

  static String getDownStr() {
    final List<String?> executive = [];
    USER_LOGIN_DATA?.downHierarchy?.forEach((action) {
      var d = action.downHierarchy;
      executive.add(d);
    });
    String? reqExecutiveId;
    if (executive.isNotEmpty) {
      reqExecutiveId = executive.join(',');
    }
    return reqExecutiveId ?? '';
  }

  static String getCityAccess() {
    final List<String?> str = [];

    USER_LOGIN_DATA?.cityAccess?.forEach((action) {
      var d = action.cityAccess;
      str.add(d);
    });
    String? ids;
    if (str.isNotEmpty) {
      ids = str.join(',');
    }
    return ids ?? '';
  }

  static loadExecutive() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user_login_data');
    if (jsonString == null) return null;
    final Map<String, dynamic> data = jsonDecode(jsonString);
    USER_LOGIN_DATA = LoginResponse.fromJson(data);
  }

  static Future<void> saveExecutive(LoginResponse exec) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(exec.toJson());
    await prefs.setString('user_login_data', jsonString);
  }

  static Future<void> saveSetUp(List<SetupValue> setupValues) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert each item to JSON, then encode the whole list
    final jsonList = setupValues.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await prefs.setString('saveSetUp', jsonString);

    loadSetUp();
  }

  static Future<void> loadSetUp() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('saveSetUp');

    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString);
        SETUP_VALUE =
            (decoded as List).map((item) => SetupValue.fromJson(item)).toList();
      } catch (e) {}
    }
  }

  static SetupValue? filterSetup(String key) {
    if (SETUP_VALUE != null) {
      try {
        return SETUP_VALUE!.firstWhere((m) => m.keyName == key);
      } on StateError {
        return null;
      }
    }
    return null;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saveToken', token);
  }

  static getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saveToken');
  }

  static SchoolDetailsNew? getSchool(SchoolListResponse? fetchData) {
    if (fetchData != null &&
        fetchData.schoolDetails != null &&
        fetchData.schoolDetails!.isNotEmpty) {
      return fetchData.schoolDetails![0];
    }
    return null;
  }

  static SchoolDetailsNew? getTrade(SchoolListResponse? fetchData) {
    if (fetchData != null &&
        fetchData.customerDetails != null &&
        fetchData.customerDetails!.isNotEmpty) {
      return fetchData.customerDetails![0];
    }
    return null;
  }

  static List<GeographyModel>? removeDuplicate(
      List<GeographyModel>? projectItems) {
    if (projectItems != null) {
      return projectItems
          .whereWithIndex((element, index) =>
              projectItems.indexWhere(
                  (element2) => element2.countryId == element.countryId) ==
              index)
          .toList();
    }
    return projectItems;
  }

  static List<GeographyModel>? removeDuplicateState(
      List<GeographyModel>? projectItems) {
    if (projectItems != null) {
      return projectItems
          .whereWithIndex((element, index) =>
              projectItems.indexWhere(
                  (element2) => element2.stateId == element.stateId) ==
              index)
          .toList();
    }
    return projectItems;
  }

  static List<GeographyModel>? removeDuplicateDistrict(
      List<GeographyModel>? projectItems) {
    if (projectItems != null) {
      return projectItems
          .whereWithIndex((element, index) =>
              projectItems.indexWhere(
                  (element2) => element2.districtId == element.districtId) ==
              index)
          .toList();
    }
    return projectItems;
  }

  static List<GeographyModel>? removeDuplicateCity(
      List<GeographyModel>? projectItems) {
    if (projectItems != null) {
      return projectItems
          .whereWithIndex((element, index) =>
              projectItems.indexWhere(
                  (element2) => element2.cityId == element.cityId) ==
              index)
          .toList();
    }
    return projectItems;
  }

  static List<StateResponse>? removeDuplicateAccount(
      List<StateResponse>? projectItems) {
    if (projectItems != null) {
      return projectItems
          .whereWithIndex((element, index) =>
              projectItems
                  .indexWhere((element2) => element2.text == element.text) ==
              index)
          .toList();
    }
    return projectItems;
  }

  static String? getCountryName(double? countryId) {
    String? countryName = '';
    GEO_DATA?.forEach((action) {
      if (countryId == action.countryId) {
        countryName = action.country;
      }
    });
    return countryName;
  }

  static String? getStateName(double? stateId) {
    String? name = '';
    GEO_DATA?.forEach((action) {
      if (stateId == action.stateId) {
        name = action.state;
      }
    });
    return name;
  }

  static String? getDistrictName(double? dit) {
    String? name = '';
    GEO_DATA?.forEach((action) {
      if (dit == action.districtId) {
        name = action.district;
      }
    });
    return name;
  }

  static String? getCityName(double? cityId) {
    String? name = '';
    GEO_DATA?.forEach((action) {
      if (cityId == action.cityId) {
        name = action.city;
        UPDATED_REQ.cityId = action.cityId;
      }
    });
    return name;
  }

  static void makeAPIRequest(
      SchoolDetailsNew? dataAPI,
      List<EnrolmentList>? enrolmentList,
      int? customerId,
      String? customerType) {
    UPDATED_REQ.customerId = customerId;
    UPDATED_REQ.customerType = customerType;
    UPDATED_REQ.customerName = dataAPI?.schoolName;
    UPDATED_REQ.refCode = dataAPI?.schoolCode;
    UPDATED_REQ.emailId = dataAPI?.emailId;
    UPDATED_REQ.mobile = dataAPI?.mobile;
    UPDATED_REQ.address = dataAPI?.address;
    UPDATED_REQ.countryId = dataAPI?.countryId?.toInt();
    UPDATED_REQ.stateId = dataAPI?.stateId?.toInt();
    UPDATED_REQ.districtId = dataAPI?.districtId?.toInt();
    UPDATED_REQ.cityId = dataAPI?.cityId?.toInt();
    UPDATED_REQ.pincode = dataAPI?.pincode;
    UPDATED_REQ.keyCustomer = dataAPI?.keyCustomer;
    UPDATED_REQ.customerStatus = dataAPI?.customerStatus;
    UPDATED_REQ.xmlCustomerCategoryId = '';
    UPDATED_REQ.xmlAccountTableExecutiveId =
        dataAPI?.xmlAccountTableExecutiveId;
    UPDATED_REQ.enteredBy = AppUtils.getUserId();
    UPDATED_REQ.latEntry = dataAPI?.latEntry;
    UPDATED_REQ.longEntry = dataAPI?.longEntry;
    UPDATED_REQ.ranking = dataAPI?.ranking;
    UPDATED_REQ.boardId = dataAPI?.boardId;
    UPDATED_REQ.chainSchoolId = dataAPI?.chainSchoolId;
    UPDATED_REQ.endClassId = dataAPI?.endClassId;
    UPDATED_REQ.startClassId = dataAPI?.startClassId;
    UPDATED_REQ.mediumInstruction = dataAPI?.mediumInstruction;
    UPDATED_REQ.samplingMonth = dataAPI?.samplingMonth;
    UPDATED_REQ.decisionMonth = dataAPI?.decisionMonth;
    UPDATED_REQ.purchaseMode = dataAPI?.purchaseMode;
    UPDATED_REQ.averageFee = dataAPI?.averageFee;
    int nry = 0;
    int lkg = 0;
    int ukg = 0;
    int c1 = 0;
    int c2 = 0;
    int c3 = 0;
    int c4 = 0;
    int c5 = 0;
    int c6 = 0;
    int c7 = 0;
    int c8 = 0;
    int c9 = 0;
    int c10 = 0;
    int c11 = 0;
    int c12 = 0;

    enrolmentList?.forEach((e) {
      if (e.classNumId == -3) {
        nry = e.enrolValue ?? 0;
      }
      if (e.classNumId == -2) {
        lkg = e.enrolValue ?? 0;
      }
      if (e.classNumId == -1) {
        ukg = e.enrolValue ?? 0;
      }
      if (e.classNumId == 1) {
        c1 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 2) {
        c2 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 3) {
        c3 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 4) {
        c4 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 5) {
        c5 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 6) {
        c6 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 7) {
        c7 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 8) {
        c8 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 9) {
        c9 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 10) {
        c10 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 11) {
        c11 = e.enrolValue ?? 0;
      }
      if (e.classNumId == 12) {
        c12 = e.enrolValue ?? 0;
      }
    });

    String data =
        "<row_ClassName><ClassName><ClassId>-3</ClassId><Enrolment>$nry</Enrolment></ClassName><ClassName><ClassId>-2</ClassId><Enrolment>$lkg</Enrolment></ClassName><ClassName><ClassId>-1</ClassId><Enrolment>$ukg</Enrolment></ClassName><ClassName><ClassId>1</ClassId><Enrolment>$c1</Enrolment></ClassName><ClassName><ClassId>2</ClassId><Enrolment>$c2</Enrolment></ClassName><ClassName><ClassId>3</ClassId><Enrolment>$c3</Enrolment></ClassName><ClassName><ClassId>4</ClassId><Enrolment>$c4</Enrolment></ClassName><ClassName><ClassId>5</ClassId> <Enrolment>$c5</Enrolment></ClassName><ClassName><ClassId>6</ClassId><Enrolment>$c6</Enrolment></ClassName><ClassName><ClassId>7</ClassId><Enrolment>$c7</Enrolment></ClassName><ClassName><ClassId>8</ClassId><Enrolment>$c8</Enrolment></ClassName><ClassName><ClassId>9</ClassId><Enrolment>$c9</Enrolment></ClassName><ClassName><ClassId>10</ClassId><Enrolment>$c10</Enrolment></ClassName><ClassName><ClassId>11</ClassId><Enrolment>$c11</Enrolment></ClassName><ClassName><ClassId>12</ClassId><Enrolment>$c12</Enrolment></ClassName></row_ClassName>";
    UPDATED_REQ.xmlClassName = data;
    UPDATED_REQ.gSTNumber = dataAPI?.gstNumber;
    UPDATED_REQ.pANNumber = dataAPI?.panNumber;
  }

  static String? createXmlAccount(List<StateResponse>? acc) {
    if (acc == null || acc.isEmpty) {
      return null;
    }
    String data = '';
    for (var ee in acc) {
      var id = ee.value;
      data =
          '$data<CustomerExecutive><AccountTableExecutiveId>$id</AccountTableExecutiveId></CustomerExecutive>';
    }
    print(data);
    var d = "<CustomerExecutive_Data>$data</CustomerExecutive_Data>";
    return d;
  }

  static String? createXmlCustomerCategory(List<StateResponse>? acc) {
    if (acc == null || acc.isEmpty) {
      return null;
    }
    String data = '';
    for (var ee in acc) {
      var id = ee.value;
      data =
          '$data<CustomerCategory><CustomerCategoryId>$id</CustomerCategoryId></CustomerCategory>';
    }
    var d = "<CustomerCategory_Data>$data</CustomerCategory_Data>";
    return d;
  }

  static void makeTeacherRequest(
      TeacherUpdateRequest? tReq, ContactModel? teacher) {
    tReq?.customerType = 'school';
    tReq?.primaryContact = teacher?.primaryContact ?? 'No';
    tReq?.salutationId = teacher?.salutationId;
    tReq?.contactDesignationId = teacher?.contactDesignationId ?? 1;
    tReq?.firstName = teacher?.contactName;
    tReq?.contactEmailId = teacher?.email;
    tReq?.contactMobile = teacher?.mobile;
    tReq?.contactStatus = teacher?.contactStatus ?? 'Active';
    tReq?.enteredBy = AppUtils.getUserId();
    tReq?.validated = 'A';
    tReq?.resAddress = teacher?.address;
    tReq?.resCity = teacher?.resCity;
    tReq?.resPincode = teacher?.pincode;
    tReq?.birthDay = teacher?.birthDay;
    tReq?.anniversary = teacher?.anniversary;
    tReq?.xmlSubjectClassDM = '';
    tReq?.dataSourceId = teacher?.dataSourceId;
    tReq?.customerContactId = teacher?.sNo;
  }

  static String? createSchoolSubject(List<AddSubject>? acc) {
    if (acc == null || acc.isEmpty) {
      return '';
    }
    String data = '';
    for (var ee in acc) {
      var sId = ee.nameId;
      var m = ee.maker;
      var mId = ee.maker?.characters.first;

      // Collect all class IDs first
      var classIds = <String>[];
      var cc = ee.classes;

      cc?.forEach((action) {
        classIds.add(action.value.toString());
      });

      // Join into one string
      var cl = classIds.join(',');

      data =
          '$data<data_CCD><SubjectId>$sId</SubjectId><ClassNumId>$cl</ClassNumId><DecisionId>$mId</DecisionId></data_CCD>';
    }
    var d = "<dataRow_CCD>$data</dataRow_CCD>";

    print('SSSSSS $d');
    return d;
  }

  static void showTop(String? msg) {
    if (msg?.isNotEmpty == true) {
      Fluttertoast.showToast(
        msg: msg!,
        backgroundColor: AppColor.black,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        textColor: Colors.white,
        fontSize: 17.0,
      );
    }
  }

  static void showToast(String? msg) {
    if (msg?.isNotEmpty == true) {
      showSnack(navigatorKey.currentContext, msg);
      /*Fluttertoast.showToast(
        msg: msg!,
        backgroundColor: AppColor.black,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        textColor: Colors.white,
        fontSize: 17.0,
      );*/
    }
  }

  static void showSnack(context, String? msg) {
    if (msg?.isNotEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg ?? '',
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white),
          ),
        ),
      );
    }
  }

  static int onlyInt(String? str) {
    int customerContactId = 0;
    try {
      String numericStr = str!.replaceAll(RegExp(r'[^0-9]'), '');
      customerContactId = int.parse(numericStr);
    } catch (e) {}
    return customerContactId;
  }

  static String onlyChar(String? str) {
    print('SSSSSS str $str ');

    String charsOnly = '';
    try {
      String numericStr = str!.replaceAll(RegExp(r'[^0-9]'), '');
      var intOnly = int.parse(numericStr);
      charsOnly = str.replaceAll('$intOnly', '');
    } catch (e) {}

    print('SSSSSS charsOnly $charsOnly ');

    return charsOnly;
  }

  static bool isNotValidEmail(String? email) {
    if (email?.isNotEmpty == true) {
      return !RegExp(
              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
          .hasMatch(email!);
    }
    return true;
  }

  static bool isBlank(String? str) {
    if (str == null ||
        str.isEmpty == true ||
        str.trim().isEmpty == true ||
        str == 'null' ||
        str == 'Null') {
      return true;
    }
    return false;
  }

  static bool isBlankInt(int? str) {
    if (str == null ||
        str == 0 ||
        '${str}' == 'null' ||
        '${str}'.trim().isEmpty == true) {
      return true;
    }
    return false;
  }

  static int parseIntSafe(String? value, {int defaultValue = 0}) {
    // Check null or empty
    if (value == null || value.trim().isEmpty) {
      return defaultValue;
    }

    // Try to parse
    return int.tryParse(value) ?? defaultValue;
  }

  static String? createSampling(List<AddSubject>? acc) {
    if (acc == null || acc.isEmpty) {
      return '';
    }
    String data = '';
    for (var ee in acc) {
      /*<CustomerSamplingRequestDetails>
    <SeriesId>$seriesId</SeriesId>
    <BookId>${title.bookId}</BookId>
    <RequestedQty>${title.quantity.toString().padLeft(2, '0')}</RequestedQty>
    <ShipTo>${escapeXml(container['shipTo'] ?? '')}</ShipTo>
    <ShippingAddress>${escapeXml(addressEntryController.text)}</ShippingAddress>
    <SamplingType>${escapeXml(selectedSamplingType!)}</SamplingType>
    <SampleTo>${container['sampleTo']}</SampleTo>
    <SampleGiven>${escapeXml(selectedSampleGiven!)}</SampleGiven>
    <MRP>${title.price ?? 0}</MRP>
    </CustomerSamplingRequestDetails>*/
    }
    var d = "<DocumentElement>$data</DocumentElement>";

    print('SSSSSS $d');
    return d;
  }

  static Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void showFileDialog(
      {required BuildContext context,
      required Function(bool? isOK) onValueCallback}) {
    var dialog = Dialog(
      backgroundColor: AppColor.white,
      surfaceTintColor: AppColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      //this right here
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 15,
            ),
            Text(
              "Confirmation!",
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColor.black,
                  fontSize: 23),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "Are you sure, you want to submit the information?",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColor.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            ),
            SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 190,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: AppColor.black,
                  side: BorderSide(width: 1, color: AppColor.color_DADADA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                onPressed: () {
                  onValueCallback(false);
                },
                child: Text(
                  'No',
                  style: TextStyle(
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            FillButtonWidget(
              height: 46,
              width: 190,
              title: 'Yes',
              fontSize: 20,
              bgColor: AppColor.colorBlue,
              onPressed: () async {
                onValueCallback(true);
              },
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }
}
