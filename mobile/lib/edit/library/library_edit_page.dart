import 'dart:async';

import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import '../../models/customer/customer_master_list_model.dart';
import '../api/repository/api_service.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/schoolUpdate/AllUpdateRequest.dart';
import '../student/address_tab.dart';
import '../student/contact_tab.dart';
import '../student/new_add_contact_page.dart';
import '../student/note_tab.dart';
import '../trade/customer_detail_tab.dart';
import '../utils/AppUtils.dart';
import '../utils/add_text_widget.dart';
import '../utils/all_field_widget.dart';
import '../utils/color_constants.dart';
import '../utils/fill_button_widget.dart';
import '../utils/widgetUtils.dart';

class LibraryEditPage extends StatefulWidget {
  final CustomerMasterListItem? customer;
  final String customerType;

  const LibraryEditPage({
    super.key,
    required this.customer,
    required this.customerType,
  });

  @override
  State<LibraryEditPage> createState() => _LibraryEditPageState();
}

class _LibraryEditPageState extends State<LibraryEditPage>
    with SingleTickerProviderStateMixin {
  FocusNode nameNode = FocusNode();
  FocusNode codeNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode mobileNode = FocusNode();

  TextEditingController libCodeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  TabController? _tabController;
  final StreamController<int?> projectStream = BehaviorSubject();
  SchoolListResponse? apiData;

  int? tabPosition;
  int? customerId;
  final StreamController<String> _loadDataStream = BehaviorSubject();

  bool isUpdate = false;
  String? warningMsg;
  String? action;
  int index1 = 0;
  int index2 = 0;
  int both = 0;

  @override
  void initState() {
    getAddress();

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

    print('object index1 $index1 $index2');

    UPDATED_REQ = AllUpdateRequest();
    try {
      var customer = widget.customer;
      action = customer?.action;
      String s = action ?? '';
      String numericStr = s.replaceAll(RegExp(r'[^0-9]'), '');
      customerId = int.parse(numericStr);
    } catch (e) {}
    tabPosition = 0;
    _tabController =
        TabController(initialIndex: tabPosition ?? 0, length: 4, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => onPostFrameCallback(context));
  }

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
    ApiService service = ApiService();
    if (customerId != null) {
      service.fetchData(customerId, widget.customerType, action).then((data) {
        apiData = data;
        var school = data?.customerDetails;
        if (school?.isNotEmpty == true) {
          var s = school?[0];
          libCodeController.text = s?.customerCode ?? '';
          nameController.text = s?.customerName ?? '';
          codeController.text = s?.refCode ?? '';
          emailController.text = s?.emailId ?? '';
          mobileController.text = s?.mobile ?? '';

          var l = s?.msgWarning?.length ?? 0;
          if (l > 5) {
            warningMsg = s?.msgWarning;
            isUpdate = true;
          } else {
            isUpdate = false;
          }

          AppUtils.makeAPIRequest(
              s, apiData?.enrolmentList, customerId, widget.customerType);

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
                              title:
                                  customerId == null ? 'Add Library' : 'Update Library',
                              bgColor: AppColor.black,
                              onPressed: () async {
                                updateLibraryAPI();
                              },
                            ),
                    );
                  }),
            ],
            title: Text(
              customerId == null ? 'Add Library' : 'Update Library',
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
                          controller: libCodeController,
                          preNode: null,
                          nextNode: null,
                          field: 'Library Code',
                          readOnly: true,
                          onTypeChange: (value) {},
                        ),
                        AllFieldWidget(
                          controller: nameController,
                          preNode: nameNode,
                          nextNode: codeNode,
                          required: '*',
                          field: 'Library Name',
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
                          controller: emailController,
                          preNode: emailNode,
                          nextNode: mobileNode,
                          format: FORMAT.EMAIL,
                          field: 'Email Id',
                          required: (index2 == 2 || both == 1) ? '*' : '',
                          onTypeChange: (value) {},
                        ),
                        AllFieldWidget(
                          controller: mobileController,
                          preNode: mobileNode,
                          nextNode: null,
                          format: FORMAT.PHONE,
                          required: (index1 == 1 || both == 1) ? '*' : '',
                          max: 10,
                          field: 'Mobile Number',
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
                                tabPosition = index;
                              });
                            },
                            tabs: [
                              Tab(
                                child: _widgetGetRow1('Address', 0),
                              ),
                              Tab(
                                child: _widgetGetRow1('Customer Detail', 1),
                              ),
                              Tab(
                                child: _widgetGetRow1('Contact', 2),
                              ),
                              Tab(
                                child: _widgetGetRow1('Notes/Comments', 3),
                              ),
                            ],
                            controller: _tabController,
                          ),
                        ),
                        IndexedStack(
                          index: tabPosition,
                          children: [
                            SizedBox(
                              height: tabPosition == 0 ? null : 1,
                              child: AddressTab(apiData: apiData, type: 3),
                            ),
                            SizedBox(
                              height: tabPosition == 1 ? null : 1,
                              child: CustomerDetailTab(apiData: apiData, type: 3),
                            ),
                            SizedBox(
                              height: tabPosition == 2 ? null : 1,
                              child: customerId == null
                                  ? NewAddContactPage(
                                      type: 3,
                                      apiData: apiData,
                                      customerType: widget.customerType)
                                  : ContactTab(
                                      type: 3,
                                      apiData: apiData,
                                      customerId: customerId,
                                      action: action,
                                      customerType: widget.customerType),
                            ),
                            SizedBox(
                              height: tabPosition == 3 ? null : 1,
                              child: NoteTab(apiData: apiData, type: 3),
                            ),
                          ],
                        ),
                        /* ContentSizeTabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _tabController,
                          children: [
                            AddressTab(
                              apiData: apiData,
                              type: 3,
                            ),
                            CustomerDetailTab(apiData: apiData, type: 3),
                            customerId == null
                                ? NewAddContactPage(
                                    type: 3,
                                    apiData: apiData,
                                    customerType: widget.customerType,
                                  )
                                : ContactTab(
                                    type: 3,
                                    apiData: apiData,
                                    customerId: customerId,
                                    action: action,
                                    customerType: widget.customerType,
                                  ),
                            NoteTab(
                              apiData: apiData,
                              type: 3,
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
              fontWeight: tabPosition == index ? FontWeight.w700 : FontWeight.w400,
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

  void updateLibraryAPI() {
    print('object $LAT_DATA');

    var s = AppUtils.getTrade(apiData);
    UPDATED_REQ.validated = s?.validationStatus;

    UPDATED_REQ.enteredBy = AppUtils.getUserId();
    UPDATED_REQ.latEntry = LAT_DATA;
    UPDATED_REQ.longEntry = LONG_DATA;
    UPDATED_REQ.customerId = s?.customerId;
    UPDATED_REQ.customerType = 'Library';
    UPDATED_REQ.customerName = nameController.text.trim();
    UPDATED_REQ.refCode = codeController.text.trim();
    UPDATED_REQ.emailId = emailController.text.trim();
    UPDATED_REQ.mobile = mobileController.text.trim();
    UPDATED_REQ.xmlClassName = null;

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

    print('SSS ${UPDATED_REQ.firstName}');

    if (AppUtils.isBlank(UPDATED_REQ.customerName)) {
      setIndexTab(0);
      AppUtils.showToast('Enter the Library Name');
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
      setIndexTab(0);
      AppUtils.showToast('Select the State Name');
      return;
    } else if (districtId) {
      AppUtils.showToast('Select the District Name');
      return;
    } else if (cityId) {
      setIndexTab(0);
      AppUtils.showToast('Select the City Name');
      return;
    } else if (AppUtils.isBlank(UPDATED_REQ.xmlCustomerCategoryId)) {
      setIndexTab(1);
      AppUtils.showToast('Select the Customer Category');
      return;
    } else if (AppUtils.isBlank(UPDATED_REQ.xmlAccountTableExecutiveId)) {
      setIndexTab(1);
      AppUtils.showToast('Select Accountable Executive');
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
      if (customerId == null) {
        if (AppUtils.isBlank(UPDATED_REQ.primaryContact)) {
          setIndexTab(2);
          AppUtils.showToast('Select Primary Contact');
          return;
        } else if (AppUtils.isBlank(UPDATED_REQ.contactStatus)) {
          setIndexTab(2);
          AppUtils.showToast('Select Contact Status');
          return;
        } else if (AppUtils.isBlank(UPDATED_REQ.firstName)) {
          setIndexTab(2);
          AppUtils.showToast('Enter Contact First Name');
          return;
        } else if (AppUtils.isBlankInt(UPDATED_REQ.contactDesignationId)) {
          setIndexTab(2);
          AppUtils.showToast('Select  Contact Designation');
          return;
        } else if (AppUtils.isBlank(UPDATED_REQ.contactEmailId)) {
          setIndexTab(2);
          AppUtils.showToast('Enter Contact Email Id');
          return;
        } else if (AppUtils.isNotValidEmail(UPDATED_REQ.contactEmailId)) {
          setIndexTab(2);
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
        setIndexTab(2);
        AppUtils.showToast('Enter the Residence Address');
        return;
      } else if (pincodeT) {
        setIndexTab(2);
        AppUtils.showToast('Enter the Residence Pin code');
        return;
      } else if (countryIdT) {
        setIndexTab(2);
        AppUtils.showToast('Select the Residence Country Name');
        return;
      } else if (stateIdT) {
        setIndexTab(2);
        AppUtils.showToast('Select the Residence State Name');
        return;
      } else if (districtIdT) {
        setIndexTab(2);
        AppUtils.showToast('Select the Residence District Name');
        return;
      } else if (cityIdT) {
        setIndexTab(2);
        AppUtils.showToast('Select the Residence City Name');
        return;
      } else {
        isAPI = true;
      }
    }

    if (isAPI) {
      showConfirmDialog(UPDATED_REQ);
    }
  }

  void finishUI(bool data) {
    if (data) {
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

  void setIndexTab(int index) {
    tabPosition = index;
    _tabController?.animateTo(index);
    setState(() {});
  }

  void dismissDialog() {
    Navigator.pop(context);
  }
}
