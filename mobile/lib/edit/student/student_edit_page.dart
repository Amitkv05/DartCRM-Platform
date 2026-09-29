import 'dart:async';
import 'dart:math';

import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:dart_crm/edit/api/repository/api_service.dart';
import 'package:dart_crm/edit/model/school/SchoolListResponse.dart';
import 'package:dart_crm/edit/model/schoolUpdate/AllUpdateRequest.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import '../../models/customer/customer_master_list_model.dart';
import '../../models/setup_value.dart';
import '../utils/all_field_widget.dart';
import '../utils/color_constants.dart';
import '../utils/fill_button_widget.dart';
import '../utils/widgetUtils.dart';
import 'address_tab.dart';
import 'contact_tab.dart';
import 'enrollment_tab.dart';
import 'new_add_contact_page.dart';
import 'note_tab.dart';
import 'school_detail_tab.dart';
import 'school_facility_tab.dart';

class StudentEditPage extends StatefulWidget {
  final CustomerMasterListItem? customer;
  final String customerType;

  const StudentEditPage({
    super.key,
    required this.customer,
    required this.customerType,
  });

  @override
  State<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends State<StudentEditPage>
    with SingleTickerProviderStateMixin {
  FocusNode nameNode = FocusNode();
  FocusNode codeNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode mobileNode = FocusNode();

  TextEditingController schoolCodeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  TabController? _tabController;
  final StreamController<String> _loadDataStream = BehaviorSubject();

  int? selectedIndex;
  int? customerId;
  String? action;
  SetupValue? showSchoolFacility;
  bool isFacility = false;

  int index1 = 0;
  int index2 = 0;
  int both = 0;

  @override
  void initState() {
    classes?.clear();

    getAddress();
    getLoginUserData();

    showSchoolFacility = AppUtils.filterSetup('ShowSchoolFacility');
    var sEmailMobile = AppUtils.filterSetup('SchoolMobileEmailMandatory');

    if (sEmailMobile != null) {
      if (sEmailMobile?.keyValue == 'M') {
        index1 = 1;
      } else if (sEmailMobile?.keyValue == 'E') {
        index2 = 2;
      } else if (sEmailMobile?.keyValue == 'B') {
        both = 1;
      }
    }

    isFacility = showSchoolFacility != null && showSchoolFacility?.keyValue == 'Y';

    UPDATED_REQ = AllUpdateRequest();

    try {
      var customer = widget.customer;
      action = customer?.action;
      String s = action ?? '';
      String numericStr = s.replaceAll(RegExp(r'[^0-9]'), '');
      customerId = int.parse(numericStr);
      print('SSSSSS ${customerId}');
    } catch (e) {}

    selectedIndex = 0;
    _tabController =
        TabController(initialIndex: selectedIndex ?? 0, length: 6, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  void setIndexTab(int index) {
    selectedIndex = index;
    _tabController?.animateTo(index);
    setState(() {});
  }

  Future<void> getLoginUserData() async {
    await AppUtils.loadExecutive();
    await AppUtils.loadSetUp();
  }

  bool isUpdate = false;
  String? warningMsg;

  SchoolListResponse? apiData;

  onPostFrameCallback(BuildContext context) {
    if (GEO_DATA == null) {
      ApiService service2 = ApiService();
      service2.getAllGeoGraphy().then((data) {
        GEO_DATA = data?.geography;
        if (BOARD_DATA == null) {
          ApiService service1 = ApiService();
          service1.getBoardData().then((onValue) {
            BOARD_DATA = onValue;
            callAPI();
          });
        } else {
          callAPI();
        }
      });
    } else {
      callAPI();
    }
  }

  void callAPI() {
    if (customerId != null) {
      ApiService service = ApiService();
      service.fetchData(customerId, widget.customerType, action).then((data) {
        apiData = data;
        var school = data?.schoolDetails;
        if (school?.isNotEmpty == true) {
          var s = school?[0];
          var l = s?.msgWarning?.length ?? 0;
          print('isUpdate s?.msgWarning ${s?.msgWarning}');
          if (l > 5) {
            warningMsg = s?.msgWarning;
            isUpdate = true;
          } else {
            isUpdate = false;
          }
          schoolCodeController.text = s?.schoolCode ?? '';
          nameController.text = s?.schoolName ?? '';
          codeController.text = s?.refCode ?? '';
          emailController.text = s?.emailId ?? '';
          mobileController.text = s?.mobile ?? '';

          print('isUpdate $isUpdate');
          AppUtils.makeAPIRequest(
              s, apiData?.enrolmentList, customerId, widget.customerType);

          _loadDataStream.sink.add('event');
        } else {
          _loadDataStream.sink.add('event');
        }
      });
    } else {
      isUpdate = false;
      _loadDataStream.sink.add('event');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
            leading: BackButton(
              color: Colors.white, // Customize the back icon color
            ),
            actions: [
              StreamBuilder<String>(
                  stream: _loadDataStream.stream,
                  builder: (context, snapshot) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: isUpdate
                          ? SizedBox()
                          : FillButtonWidget(
                              height: 40,
                              width: 160,
                              title: customerId == null ? 'Add School' : 'Update School',
                              bgColor: AppColor.black,
                              onPressed: () async {
                                updateSchoolAPI();
                              },
                            ),
                    );
                  }),
            ],
            title: Text(
              customerId == null ? 'Add School' : 'Update School',
              style: TextStyle(fontSize: 19, color: Colors.white),
            ),
            centerTitle: false,
            // Centers the title
            backgroundColor: TColors.warning),
        backgroundColor: AppColor.white,
        body: StreamBuilder<String>(
            stream: _loadDataStream.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[100]!, Colors.grey[50]!],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 50),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        warningMsg == null
                            ? SizedBox()
                            : Text(
                                warningMsg ?? '',
                                style: TextStyle(fontSize: 22, color: Colors.blueAccent),
                              ),
                        AllFieldWidget(
                          controller: schoolCodeController,
                          preNode: null,
                          nextNode: null,
                          field: 'School Code',
                          readOnly: true,
                          onTypeChange: (value) {},
                        ),
                        AllFieldWidget(
                          controller: nameController,
                          preNode: nameNode,
                          nextNode: codeNode,
                          required: '*',
                          field: 'School Name',
                          onTypeChange: (value) {},
                        ),
                        AllFieldWidget(
                          controller: codeController,
                          preNode: codeNode,
                          nextNode: emailNode,
                          max: 10,
                          format: FORMAT.CAP,
                          field: 'Reference Code',
                          onTypeChange: (value) {},
                        ),
                        AllFieldWidget(
                          controller: mobileController,
                          preNode: mobileNode,
                          nextNode: null,
                          format: FORMAT.PHONE,
                          max: 10,
                          required: (index1 == 1 || both == 1) ? '*' : '',
                          field: 'Mobile Number',
                          onTypeChange: (value) {},
                        ),
                        AllFieldWidget(
                          controller: emailController,
                          preNode: emailNode,
                          nextNode: mobileNode,
                          format: FORMAT.EMAIL,
                          field: 'Email Id',
                          required: (index2 == 2 || both == 1) ? '*' : '',
                          onTypeChange: (value) {},
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColor.color_DADADA,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                          ),
                          child: TabBar(
                            tabAlignment: TabAlignment.start,
                            dividerHeight: 0,
                            dividerColor: AppColor.color_B0B0B0,
                            indicator: const UnderlineTabIndicator(
                              borderRadius: BorderRadius.all(Radius.circular(5)),
                              borderSide: BorderSide(color: AppColor.black, width: 4.0),
                              insets: EdgeInsets.only(left: 14, right: 14),
                            ),
                            indicatorSize: TabBarIndicatorSize.label,
                            isScrollable: true,
                            labelPadding: EdgeInsets.zero,
                            labelColor: AppColor.black,
                            unselectedLabelColor: AppColor.black,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                            unselectedLabelStyle:
                                const TextStyle(fontWeight: FontWeight.w300),
                            onTap: (index) {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            tabs: [
                              Tab(
                                child: _widgetGetRow1('Address', 0),
                              ),
                              Tab(
                                child: _widgetGetRow1('School Detail', 1),
                              ),
                              Tab(
                                child: _widgetGetRow1('123 School Strength', 2),
                              ),
                              Tab(
                                child: _widgetGetRow1('Teachers', 3),
                              ),
                              isFacility
                                  ? Tab(
                                      child: _widgetGetRow1('School Facility', 4),
                                    )
                                  : SizedBox(),
                              Tab(
                                child: _widgetGetRow1('Notes/Comments', 5),
                              ),
                            ],
                            controller: _tabController,
                          ),
                        ),
                        IndexedStack(
                          index: selectedIndex,
                          children: [
                            SizedBox(
                              height: selectedIndex == 0 ? null : 1,
                              child: AddressTab(apiData: apiData, type: 1),
                            ),
                            SizedBox(
                              height: selectedIndex == 1 ? null : 1,
                              child: SchoolDetailTab(apiData: apiData, type: 1),
                            ),
                            SizedBox(
                              height: selectedIndex == 2 ? null : 1,
                              child: EnrollmentTab(apiData: apiData, type: 1),
                            ),
                            SizedBox(
                              height: selectedIndex == 3 ? null : 1,
                              child: customerId == null
                                  ? NewAddContactPage(
                                      type: 1,
                                      apiData: apiData,
                                      customerType: widget.customerType)
                                  : ContactTab(
                                      type: 1,
                                      apiData: apiData,
                                      customerId: customerId,
                                      action: action,
                                      customerType: widget.customerType),
                            ),
                            SizedBox(
                              height: selectedIndex == 4 ? null : 1,
                              child: isFacility
                                  ? SchoolFacilityTab(apiData: apiData, type: 1)
                                  : SizedBox(),
                            ),
                            SizedBox(
                              height: selectedIndex == 5 ? null : 1,
                              child: NoteTab(apiData: apiData, type: 1),
                            ),
                            // Continue mapping other tabs similarly...
                          ],
                        ),

                        /*  ContentSizeTabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _tabController,
                          children: [
                            AddressTab(
                              apiData: apiData,
                              type: 1,
                            ),
                            SchoolDetailTab(
                              apiData: apiData,
                              type: 1,
                            ),
                            EnrollmentTab(
                              apiData: apiData,
                              type: 1,
                            ),
                            customerId == null
                                ? NewAddContactPage(
                                    type: 1,
                                    apiData: apiData,
                                    customerType: widget.customerType,
                                  )
                                : ContactTab(
                                    type: 1,
                                    apiData: apiData,
                                    customerId: customerId,
                                    action: action,
                                    customerType: widget.customerType,
                                  ),
                            isFacility
                                ? SchoolFacilityTab(
                                    apiData: apiData,
                                    type: 1,
                                  )
                                : SizedBox(),
                            NoteTab(
                              apiData: apiData,
                              type: 1,
                            ),
                          ],
                        ),*/
                      ],
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget _widgetTab() {
    return Column(
      children: [],
    );
  }

  Widget _widgetGetRow1(String value, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 15,
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: selectedIndex == index ? FontWeight.w700 : FontWeight.w400,
              color: AppColor.black),
        ),
        const SizedBox(
          width: 15,
        ),
        Container(
          width: 1.5,
          height: 22,
          color: AppColor.color_B0B0B0,
        ),
      ],
    );
  }

  void updateSchoolAPI() {
    var s = AppUtils.getSchool(apiData);

    UPDATED_REQ.validated = s?.validationStatus;

    UPDATED_REQ.enteredBy = AppUtils.getUserId();
    UPDATED_REQ.customerId = s?.schoolId;
    UPDATED_REQ.customerType = widget.customerType;
    UPDATED_REQ.customerName = nameController.text.trim();
    UPDATED_REQ.refCode = codeController.text.trim();
    UPDATED_REQ.emailId = emailController.text.trim();
    UPDATED_REQ.mobile = mobileController.text.trim();

    var address = AppUtils.isBlank(UPDATED_REQ.address);
    var pincode = AppUtils.isBlank(UPDATED_REQ.pincode);
    var countryId = AppUtils.isBlank('${UPDATED_REQ.countryId}');
    var stateId = AppUtils.isBlank('${UPDATED_REQ.stateId}');
    var districtId = AppUtils.isBlank('${UPDATED_REQ.districtId}');
    var cityId = AppUtils.isBlank('${UPDATED_REQ.cityId}');

    var addressT = AppUtils.isBlank(UPDATED_REQ.resAddress);
    var pincodeT = AppUtils.isBlank(UPDATED_REQ.resPincode);
    var countryIdT = AppUtils.isBlank('${UPDATED_REQ.resCountry}');
    var stateIdT = AppUtils.isBlank('${UPDATED_REQ.resState}');
    var districtIdT = AppUtils.isBlank('${UPDATED_REQ.resDistrict}');
    var cityIdT = AppUtils.isBlank('${UPDATED_REQ.resCity}');

    bool isAPI = false;

    print('UPDATED_REQ.purchaseMode ${UPDATED_REQ.purchaseMode}');

    if (AppUtils.isBlank(UPDATED_REQ.customerName)) {
      setIndexTab(0);
      AppUtils.showToast('Enter the School Name');
      return;
    } else if (index2 == 2 && AppUtils.isBlank(emailController.text.trim())) {
      setIndexTab(0);
      AppUtils.showToast('Enter the Email Id');
      return;
    } else if (index2 == 2 && AppUtils.isNotValidEmail(emailController.text.trim())) {
      setIndexTab(0);
      AppUtils.showToast('Enter Valid Email Id');
      return;
    } else if (!AppUtils.isBlank(emailController.text) &&
        AppUtils.isNotValidEmail(emailController.text.trim())) {
      setIndexTab(0);
      AppUtils.showToast('Enter Valid Email Id');
      return;
    } else if (index1 == 1 && AppUtils.isBlank(mobileController.text.trim())) {
      setIndexTab(0);
      AppUtils.showToast('Enter the Mobile Number');
      return;
    } else if (address) {
      setIndexTab(0);
      AppUtils.showToast('Enter the Address');
      return;
    } else if (pincode) {
      setIndexTab(0);
      AppUtils.showToast('Enter the Pin code');
      return;
    } else if (countryId) {
      setIndexTab(0);
      AppUtils.showToast('Select the Country Name');
      return;
    } else if (stateId) {
      AppUtils.showToast('Select the State Name');
      setIndexTab(0);
      return;
    } else if (districtId) {
      setIndexTab(0);
      AppUtils.showToast('Select the District Name');
      return;
    } else if (cityId) {
      setIndexTab(0);
      AppUtils.showToast('Select the City Name');
      setIndexTab(1);
      return;
    } else if (AppUtils.isBlankInt(UPDATED_REQ.boardId)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Board');
      return;
    } else if (AppUtils.isBlank(UPDATED_REQ.mediumInstruction)) {
      setIndexTab(1);
      AppUtils.showToast('Enter the Medium');
      return;
    } else if (AppUtils.isBlank(UPDATED_REQ.ranking)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Ranking');
      return;
    } else if (AppUtils.isBlankInt(UPDATED_REQ.samplingMonth)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Demo Month');
      return;
    } else if (AppUtils.isBlankInt(UPDATED_REQ.decisionMonth)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Decision Month');
      return;
    } else if (AppUtils.isBlank(UPDATED_REQ.purchaseMode)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Purchase Mode');
      return;
    } else if (UPDATED_REQ.purchaseMode?.toLowerCase() == 'bookseller' &&
        AppUtils.isBlankInt(UPDATED_REQ.bookSellerId1) &&
        AppUtils.isBlankInt(UPDATED_REQ.bookSellerId2)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Book Seller');
      return;
    } else if (AppUtils.isBlank(UPDATED_REQ.keyCustomer)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Key Customer');
      return;
    } else if (AppUtils.isBlank(UPDATED_REQ.customerStatus)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Customer Status');
      return;
    } else {
      var schoolAverageFee = AppUtils.filterSetup('SchoolAverageFee');
      if (schoolAverageFee != null && schoolAverageFee.keyValue == 'Y') {
        var fee = UPDATED_REQ.averageFee;
        if (fee == null || fee == 0) {
          setIndexTab(1);
          AppUtils.showToast('Average Fee is required.');
          return;
        }
      }
      if (AppUtils.isBlank(UPDATED_REQ.xmlAccountTableExecutiveId)) {
        setIndexTab(1);
        AppUtils.showToast('Select Accountable Executive');
        return;
      } else if (AppUtils.isBlankInt(UPDATED_REQ.startClassId)) {
        setIndexTab(2);
        AppUtils.showToast('Select Start Class');
        return;
      } else if (UPDATED_REQ.endClassId == -10) {
        setIndexTab(2);
        AppUtils.showToast('Select End Class');
        return;
      } else {
        bool isOneTime = true;
        classes?.forEach((action) {
          if (action.readOnly == false &&
              AppUtils.isBlank(action.editingController.text)) {
            isOneTime = false;
            isAPI = false;
          }
        });
        if (!isOneTime) {
          setIndexTab(2);
          AppUtils.showSnack(context, 'Enrollment value can not be empty.');
          return;
        }

        if (customerId == null) {
          if (AppUtils.isBlank(UPDATED_REQ.primaryContact)) {
            setIndexTab(3);
            AppUtils.showToast('Select Primary Contact');
            return;
          } else if (AppUtils.isBlank(UPDATED_REQ.contactStatus)) {
            setIndexTab(3);
            AppUtils.showToast('Select Contact Status');
            return;
          } else if (AppUtils.isBlank(UPDATED_REQ.firstName)) {
            setIndexTab(3);
            AppUtils.showToast('Enter Contact First Name');
            return;
          } else if (AppUtils.isBlankInt(UPDATED_REQ.contactDesignationId)) {
            setIndexTab(3);
            AppUtils.showToast('Select  Contact Designation');
            return;
          } else if (AppUtils.isBlank(UPDATED_REQ.contactEmailId)) {
            setIndexTab(3);
            AppUtils.showToast('Enter Contact Email Id');
            return;
          } else if (AppUtils.isNotValidEmail(UPDATED_REQ.contactEmailId)) {
            setIndexTab(3);
            AppUtils.showToast('Enter Valid Contact Email Id');
            return;
          }
        }
      }
      var isOk = addressT && pincodeT && countryIdT && stateIdT && districtIdT && cityIdT;

      if (isOk) {
        isAPI = true;
      } else {
        if (addressT) {
          setIndexTab(3);
          AppUtils.showToast('Enter the Residence Address');
          return;
        } else if (pincodeT) {
          setIndexTab(3);
          AppUtils.showToast('Enter the Residence Pin code');
          return;
        } else if (countryIdT) {
          setIndexTab(3);
          AppUtils.showToast('Select the Residence Country Name');
          return;
        } else if (stateIdT) {
          setIndexTab(3);
          AppUtils.showToast('Select the Residence State Name');
          return;
        } else if (districtIdT) {
          setIndexTab(3);
          AppUtils.showToast('Select the Residence District Name');
          return;
        } else if (cityIdT) {
          setIndexTab(3);
          AppUtils.showToast('Select the Residence City Name');
          return;
        } else {
          isAPI = true;
        }
      }
    }

    if (UPDATED_REQ.purchaseMode?.toLowerCase() != 'bookseller') {
      UPDATED_REQ.bookSellerId1 = null;
      UPDATED_REQ.bookSellerId2 = null;
    }
    print('SSS isAPI:: $isAPI');
    if (isAPI) {
      showConfirmDialog(UPDATED_REQ);
    }
  }

  void finishUI(bool data) {
    if (data) {
      print('SSSSSS  EDIT');
      Navigator.pop(context);
    }
  }

  Future<void> getAddress() async {
    Position pos = await AppUtils.determinePosition();
    LAT_DATA = '${pos.latitude}';
    LONG_DATA = '${pos.longitude}';
    print('object getAddress $LAT_DATA');

    setState(() {});
  }

  void showConfirmDialog(UPDATED_REQ) {
    AppUtils().showFileDialog(
      context: context,
      onValueCallback: (folderName) {
        if (folderName == true) {
          dismissDialog();
          ApiService service = ApiService();
          service.updateAPI(UPDATED_REQ).then((data) {
            finishUI(data);
          });
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  void dismissDialog() {
    Navigator.pop(context);
  }
}
