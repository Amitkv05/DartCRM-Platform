import 'dart:async';

import 'package:dart_crm/edit/model/teacher/detail/SchoolContactDetails.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import '../../models/setup_value.dart';
import '../api/repository/api_service.dart';
import '../model/Geo/GeographyModel.dart';
import '../model/school/AddSubject.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/schoolUpdate/StateResponse.dart';
import '../model/teacher/ContactModel.dart';
import '../model/teacherUpdate/TeacherUpdateRequest.dart';
import '../utils/AppUtils.dart';
import '../utils/all_field_widget.dart';
import '../utils/click_button_widget.dart';
import '../utils/click_fill_widget.dart';
import '../utils/color_constants.dart';
import '../utils/fill_button_widget.dart';
import '../utils/message_field_widget.dart';
import '../utils/radio_tab.dart';
import '../utils/widgetUtils.dart';
import 'add_subject_page.dart';

class AddContactPage extends StatefulWidget {
  final ContactModel? teacher;
  final int? type;
  final String? customerType;
  final SchoolListResponse? apiData;
  final int? customerId;
  final String? validated;

  const AddContactPage(
      {super.key,
      required this.teacher,
      required this.type,
      required this.apiData,
      this.customerId,
      required this.customerType,
      required this.validated});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage>
    with SingleTickerProviderStateMixin {
  ContactModel? teacher;
  TeacherUpdateRequest contactUpdateReq = TeacherUpdateRequest();
  SetupValue? mPincode;
  final StreamController<String> _loadDataStream = BehaviorSubject();

  StateResponse? selectedContactStatus;
  StateResponse? selectedPrimary;

  String? selectedSalutation;
  String? selectedDesignation;
  String? selectedCountry = '';
  String? selectedState = '';
  String? selectedDistrict = '';
  String? selectedCity = '';
  String? selectedDataSource = '';
  String? selectedDob;
  String? selectedAnniversary;

  FocusNode nameNode = FocusNode();
  FocusNode lastNode = FocusNode();
  FocusNode designationNode = FocusNode();
  FocusNode mobileNode = FocusNode();
  FocusNode emailNode = FocusNode();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController pinController = TextEditingController();

  bool isChecked = false;
  List<StateResponse> primaryContact = [];
  List<StateResponse> contactStatus = [];
  List<StateResponse> designations = [];
  List<StateResponse> salutations = [];
  List<StateResponse> modelCountry = [];
  List<StateResponse> modelState = [];
  List<StateResponse> modelDistrict = [];
  List<StateResponse> modelCity = [];
  List<StateResponse> dataSource = [];
  String? title = '';

  int index1 = 0;
  int index2 = 0;
  int both = 0;

  int index11 = 0;
  int index12 = 0;
  int both1 = 0;

  @override
  void initState() {
    if (widget.type == 1) {
      title = 'Teacher';
    } else if (widget.type == 2) {
      title = 'Contact';
    } else if (widget.type == 3) {
      title = 'Contact';
    }

    contactUpdateReq = TeacherUpdateRequest();
    teacher = widget.teacher;
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  onPostFrameCallback(BuildContext context) {
    mPincode = AppUtils.filterSetup('GeographyBasedOnPincode');

    var name = AppUtils.filterSetup('CustomerContactFirstLastNameMandatory');

    if (name != null) {
      if (name.keyValue == 'F') {
        index1 = 1;
      } else if (name.keyValue == 'L') {
        index2 = 2;
      } else if (name.keyValue == 'B') {
        both = 1;
      }
    }

    var sMobileEmailMandatory =
        AppUtils.filterSetup('TeacherMobileEmailMandatory');

    if (sMobileEmailMandatory != null) {
      if (sMobileEmailMandatory?.keyValue == 'M') {
        index11 = 1;
      } else if (sMobileEmailMandatory?.keyValue == 'E') {
        index12 = 2;
      } else if (sMobileEmailMandatory?.keyValue == 'B') {
        both1 = 1;
      }
    }

    BOARD_DATA?.salutationMaster?.forEach((e) {
      var s = StateResponse();
      s.text = e.salutationName;
      s.value = e.salutationId;
      salutations.add(s);
    });

    BOARD_DATA?.contactDesignation?.forEach((e) {
      var s = StateResponse();
      s.text = e.contactDesignationName;
      s.value = e.contactDesignationId;
      designations.add(s);
    });

    BOARD_DATA?.dataSource?.forEach((e) {
      var s = StateResponse();
      s.text = e.dataSourceName;
      s.value = e.dataSourceId;
      dataSource.add(s);
    });

    primaryContact.clear();
    var p1 = StateResponse();
    p1.text = 'Y';
    p1.label = 'Yes';
    p1.value = 1;
    primaryContact.add(p1);

    var p2 = StateResponse();
    p2.text = 'N';
    p2.label = 'No';
    p2.value = 2;
    primaryContact.add(p2);

    contactStatus.clear();
    var c1 = StateResponse();
    c1.text = 'Active';
    c1.label = 'Active';
    c1.value = 1;
    contactStatus.add(c1);

    var c2 = StateResponse();
    c2.text = 'Inactive';
    c2.label = 'Inactive';
    c2.value = 2;
    contactStatus.add(c2);

    setCountryData();
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
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FillButtonWidget(
                  height: 40,
                  width: 120,
                  title: teacher == null ? 'Add' : 'Update',
                  bgColor: AppColor.color_4285F4,
                  onPressed: () {
                    updateSchoolAPI();
                  },
                ),
              ),
            ],
            title: Text(
              teacher == null ? 'Add $title' : 'Update $title',
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
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 15, bottom: 50),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioTab(
                          size: 27,
                          field: 'Primary Contact',
                          selectedOption: selectedPrimary,
                          required: '*',
                          resource: primaryContact,
                          callback: (value) {
                            selectedPrimary = value;
                            contactUpdateReq.primaryContact = value?.text;
                          },
                        ),
                        RadioTab(
                          size: 27,
                          field: 'Contact Status',
                          selectedOption: selectedContactStatus,
                          required: '*',
                          resource: contactStatus,
                          callback: (value) {
                            print(
                                'contactUpdateReq ${contactUpdateReq.contactStatus}');
                            selectedContactStatus = value;
                            contactUpdateReq.contactStatus = value?.text;
                          },
                        ),
                        ClickButtonWidget(
                          field: 'Salutation',
                          required: '',
                          value: selectedSalutation,
                          resourceList: salutations,
                          onSelected: (data) {
                            selectedSalutation = data?.text;
                            contactUpdateReq.salutationId = data?.value;
                            setState(() {});
                          },
                        ),
                        AllFieldWidget(
                          controller: firstNameController,
                          preNode: nameNode,
                          nextNode: lastNode,
                          field: 'First Name',
                          required: (index1 == 1 || both == 1) ? '*' : '',
                          onTypeChange: (value) {
                            contactUpdateReq.firstName = value;
                          },
                        ),
                        AllFieldWidget(
                          controller: lastNameController,
                          preNode: lastNode,
                          nextNode: emailNode,
                          field: 'Last Name',
                          required: (index2 == 2 || both == 1) ? '*' : '',
                          onTypeChange: (value) {
                            contactUpdateReq.lastName = value;
                          },
                        ),
                        ClickButtonWidget(
                          field: 'Designation',
                          required: '*',
                          value: selectedDesignation,
                          resourceList: designations,
                          onSelected: (data) {
                            selectedDesignation = data?.text;
                            contactUpdateReq.contactDesignationId = data?.value;
                            setState(() {});
                          },
                        ),
                        AllFieldWidget(
                          controller: mobileController,
                          preNode: mobileNode,
                          nextNode: null,
                          max: 10,
                          format: FORMAT.PHONE,
                          required: (index12 == 1 || both1 == 1) ? '*' : '',
                          field: 'Mobile',
                          onTypeChange: (value) {
                            contactUpdateReq.contactMobile = value;
                          },
                        ),
                        AllFieldWidget(
                          controller: emailController,
                          preNode: emailNode,
                          nextNode: mobileNode,
                          format: FORMAT.EMAIL,
                          required: (index12 == 2 || both1 == 1) ? '*' : '',
                          field: 'Email',
                          onTypeChange: (value) {
                            contactUpdateReq.contactEmailId = value;
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        MessageFieldWidget(
                          maxLength: 200,
                          preNode: null,
                          nextNode: null,
                          textInputAction: TextInputAction.done,
                          controller: addressController,
                          error: '',
                          maxLines: 3,
                          field: 'Address',
                          hint: 'Write the address',
                          onTypeChange: (value) {
                            contactUpdateReq.resAddress = value;
                          },
                        ),
                        mPincode != null && mPincode?.keyValue == 'Y'
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: AllFieldWidget(
                                      controller: pinController,
                                      preNode: null,
                                      nextNode: null,
                                      field: 'Pin code',
                                      format: FORMAT.PHONE,
                                      max: 6,
                                      onTypeChange: (value) {
                                        contactUpdateReq.resPincode = value;
                                      },
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      SizedBox(
                                        height: 40,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.search),
                                        tooltip: 'Search',
                                        iconSize: 24.0,
                                        color: Colors.blue,
                                        splashRadius: 20.0,
                                        onPressed: () {
                                          pincodeAPI();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : SizedBox(),
                        ClickButtonWidget(
                          field: 'Country Name',
                          value: selectedCountry,
                          resourceList: modelCountry,
                          onSelected: (data) {
                            selectedCountry = data?.text;
                            contactUpdateReq.resCountry = data?.value;
                            setStateData(data?.value);
                          },
                        ),
                        ClickButtonWidget(
                          field: 'State Name',
                          value: selectedState,
                          resourceList: modelState,
                          onSelected: (data) {
                            contactUpdateReq.resState = data?.value;
                            selectedState = data?.text;
                            setDistrictData(data?.value);
                          },
                        ),
                        ClickButtonWidget(
                          field: 'District Name',
                          value: selectedDistrict,
                          resourceList: modelDistrict,
                          onSelected: (data) {
                            selectedDistrict = data?.text;
                            contactUpdateReq.resDistrict = data?.value;
                            setCityData(data?.value);
                          },
                        ),
                        ClickButtonWidget(
                          field: 'City Name',
                          value: selectedCity,
                          resourceList: modelCity,
                          onSelected: (data) {
                            UPDATED_REQ.cityId = data?.value;
                            selectedCity = data?.text;
                            contactUpdateReq.resCity = data?.value;
                          },
                        ),
                        mPincode == null || mPincode?.keyValue == 'N'
                            ? AllFieldWidget(
                                controller: pinController,
                                preNode: null,
                                nextNode: null,
                                field: 'Pin code',
                                format: FORMAT.PHONE,
                                max: 6,
                                onTypeChange: (value) {
                                  contactUpdateReq.resPincode = value;
                                },
                              )
                            : SizedBox(),
                        ClickButtonWidget(
                          field: 'Data Source',
                          value: selectedDataSource,
                          resourceList: dataSource,
                          onSelected: (data) {
                            selectedDataSource = data?.text;
                            contactUpdateReq.dataSourceId = data?.value;
                            setState(() {});
                          },
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ClickFillWidget(
                                field: 'Birth Day',
                                value: selectedDob,
                                onSelected: () async {
                                  DateTime initial =
                                      DateTime(DateTime.now().year - 20);
                                  final picked =
                                      await pickDOB(context, initial);
                                  if (picked != null) {
                                    selectedDob = DateFormat('dd MMM yyyy')
                                        .format(picked);
                                    contactUpdateReq.birthDay = selectedDob;
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            selectedDob == null
                                ? SizedBox()
                                : IconButton(
                                    onPressed: () {
                                      selectedDob = null;
                                      setState(() {});
                                    },
                                    icon: Icon(Icons.dangerous))
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ClickFillWidget(
                                field: 'Anniversary',
                                value: selectedAnniversary,
                                onSelected: () async {
                                  DateTime initial =
                                      DateTime(DateTime.now().year - 20);
                                  final picked =
                                      await pickDOB(context, initial);
                                  if (picked != null) {
                                    selectedAnniversary =
                                        DateFormat('dd MMM yyyy')
                                            .format(picked);
                                    contactUpdateReq.anniversary =
                                        selectedAnniversary;
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            selectedAnniversary == null
                                ? SizedBox()
                                : IconButton(
                                    onPressed: () {
                                      selectedAnniversary = null;
                                      setState(() {});
                                    },
                                    icon: Icon(Icons.dangerous))
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        widget.customerType == 'School'
                            ? FillButtonWidget(
                                height: 40,
                                width: 200,
                                title: 'Add Subject',
                                bgColor: AppColor.color_4285F4,
                                onPressed: () async {
                                  WidgetUtils.launchScreen(
                                      context,
                                      AddSubjectPage(
                                        subjectListAdded: subjectListAdded,
                                        apiData: widget.apiData,
                                        callback: (sub) {
                                          subjectListAdded.add(sub);
                                          setState(() {});
                                        },
                                      ));
                                },
                              )
                            : SizedBox(),
                        SizedBox(
                          height: 10,
                        ),
                        _widgetSubjectList(),
                      ],
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }

  List<AddSubject> subjectListAdded = [];

  Future<DateTime?> pickDOB(BuildContext context, DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select your birth date',
    );
  }

  Widget _widgetSubjectList() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 0),
      scrollDirection: Axis.vertical,
      itemCount: subjectListAdded.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index1) {
        var d = subjectListAdded[index1];
        List<String> s = [];
        d.classes?.forEach((action) {
          s.add(action.text ?? '');
        });
        var classes = s.join(', ');
        return Container(
          padding: const EdgeInsets.all(10.0),
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade600,
              width: 1,
            ),
            // boxShadow: [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subject Name',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black),
              ),
              Text(
                d.name ?? '',
                style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 15,
                    color: Colors.black),
              ),
              Text(
                'Class Name',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black),
              ),
              Text(
                classes,
                style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 15,
                    color: Colors.black),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Decision Maker',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Colors.black),
                        ),
                        Text(
                          d.maker ?? '',
                          style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 15,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        subjectListAdded.remove(d);
                        setState(() {});
                      },
                      icon: Icon(size: 20, color: Colors.red, Icons.delete)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void setCountryData() {
    ApiService service2 = ApiService();
    service2.getAllGeoGraphyAll().then((data) {
      GEO_DATA_NEW = data?.geography;
      if (teacher == null) {
        setAllData(null);
      } else {
        contactDetailAPI();
      }
    });
  }

  List<GeographyModel>? GEO_DATA_NEW = [];

  void setAllData(SchoolContactDetails? detail) {
    var c = AppUtils.removeDuplicate(GEO_DATA_NEW);
    c?.forEach((e) {
      var s = StateResponse();
      s.text = e.country;
      s.value = e.countryId;
      modelCountry.add(s);
    });

    List<GeographyModel>? s = [];
    List<GeographyModel>? s2 = [];
    List<GeographyModel>? s3 = [];
    GEO_DATA_NEW?.forEach((e) {
      var countryId = e.countryId;
      if (countryId == detail?.resCountry) {
        s.add(e);
      }
      var stateId = e.stateId;
      if (stateId == detail?.resState) {
        s2.add(e);
      }
      var id = e.districtId;
      if (id == detail?.resDistrict) {
        s3.add(e);
      }
    });
    AppUtils.removeDuplicateState(s)?.forEach((e) {
      var s = StateResponse();
      s.text = e.state;
      s.value = e.stateId;
      modelState.add(s);
    });
    AppUtils.removeDuplicateDistrict(s2)?.forEach((e) {
      var s = StateResponse();
      s.text = e.district;
      s.value = e.districtId;
      modelDistrict.add(s);
    });
    AppUtils.removeDuplicateCity(s3)?.forEach((e) {
      var s = StateResponse();
      s.text = e.city;
      s.value = e.cityId;
      modelCity.add(s);
    });

    _loadDataStream.sink.add('event');
  }

  void setStateData(int? countryId) {
    modelState.clear();
    selectedState = '';
    selectedDistrict = '';
    selectedCity = '';
    List<GeographyModel>? s = [];
    GEO_DATA_NEW?.forEach((e) {
      var id = e.countryId;
      if (id == countryId) {
        s.add(e);
      }
    });
    AppUtils.removeDuplicateState(s)?.forEach((e) {
      var s = StateResponse();
      s.text = e.state;
      s.value = e.stateId;
      modelState?.add(s);
    });
    setState(() {});
  }

  void setDistrictData(int? stateId) {
    modelDistrict?.clear();
    selectedDistrict = '';
    selectedCity = '';
    List<GeographyModel>? s = [];
    GEO_DATA_NEW?.forEach((e) {
      var id = e.stateId;
      if (id == stateId) {
        s.add(e);
      }
    });
    AppUtils.removeDuplicateDistrict(s)?.forEach((e) {
      var s = StateResponse();
      s.text = e.district;
      s.value = e.districtId;
      modelDistrict?.add(s);
    });
    setState(() {});
  }

  void setCityData(int? districId) {
    modelCity?.clear();
    selectedCity = '';
    List<GeographyModel>? s = [];
    GEO_DATA_NEW?.forEach((e) {
      var id = e.districtId;
      if (id == districId) {
        s.add(e);
      }
    });
    AppUtils.removeDuplicateCity(s)?.forEach((e) {
      var s = StateResponse();
      s.text = e.city;
      s.value = e.cityId;
      modelCity.add(s);
    });
    setState(() {});
  }

  void updateSchoolAPI() {
    contactUpdateReq.customerId = widget.customerId;
    contactUpdateReq.customerType = widget.customerType;

    contactUpdateReq.firstName = firstNameController.text.trim();
    contactUpdateReq.lastName = lastNameController.text.trim();
    contactUpdateReq.contactMobile = mobileController.text.trim();
    contactUpdateReq.contactEmailId = emailController.text.trim();
    contactUpdateReq.resAddress = addressController.text.trim();
    contactUpdateReq.resPincode = pinController.text.trim();
    contactUpdateReq.enteredBy = AppUtils.getUserId();
    contactUpdateReq.validated = widget.validated;

    var d = AppUtils.createSchoolSubject(subjectListAdded);
    contactUpdateReq.xmlSubjectClassDM = d;

    var customerContactId = AppUtils.onlyInt(teacher?.edit);
    contactUpdateReq.customerContactId = customerContactId;

    print("object contactUpdateReq.resAddress ${contactUpdateReq.resAddress}");
    print("object contactUpdateReq.resAddress ${addressController.text}");

    var address = AppUtils.isBlank(contactUpdateReq.resAddress);
    var pincode = AppUtils.isBlank(contactUpdateReq.resPincode);
    var countryId = AppUtils.isBlank('${contactUpdateReq.resCountry}');
    var stateId = AppUtils.isBlank('${contactUpdateReq.resState}');
    var districtId = AppUtils.isBlank('${contactUpdateReq.resDistrict}');
    var cityId = AppUtils.isBlank('${contactUpdateReq.resCity}');

    if (AppUtils.isBlank(contactUpdateReq.primaryContact)) {
      AppUtils.showToast('Select Primary Contact');
      return;
    } else if (AppUtils.isBlank(contactUpdateReq.contactStatus)) {
      AppUtils.showToast('Select Contact Status');
      return;
    } else if (AppUtils.isBlank(contactUpdateReq.firstName)) {
      AppUtils.showToast('Enter Contact First Name');
      return;
    } else if (AppUtils.isBlankInt(contactUpdateReq.contactDesignationId)) {
      AppUtils.showToast('Select  Contact Designation');
      return;
    } else if (AppUtils.isBlank(contactUpdateReq.contactEmailId)) {
      AppUtils.showToast('Enter Contact Email Id');
      return;
    } else if (AppUtils.isNotValidEmail(contactUpdateReq.contactEmailId)) {
      AppUtils.showToast('Enter Valid Contact Email Id');
      return;
    }

    var isOk =
        address && pincode && countryId && stateId && districtId && cityId;

    if (isOk) {
    } else {
      if (address) {
        AppUtils.showToast('Enter the Residence Address');
      } else if (pincode) {
        AppUtils.showToast('Enter the Residence Pin code');
      } else if (countryId) {
        AppUtils.showToast('Select the Residence Country Name');
      } else if (stateId) {
        AppUtils.showToast('Select the Residence State Name');
      } else if (districtId) {
        AppUtils.showToast('Select the Residence District Name');
      } else if (cityId) {
        AppUtils.showToast('Select the Residence City Name');
      } else {
        isOk = true;
      }
    }

    print('NNNNN isOkww $isOk');
    if (isOk) {
      showConfirmDialog();
    }
  }

  void showConfirmDialog() {
    AppUtils().showFileDialog(
      context: context,
      onValueCallback: (folderName) {
        if (folderName == true) {
          dismissDialog();
          ApiService service = ApiService();
          service.updateContactAPI(contactUpdateReq).then((data) {
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

  void finishUI(bool data) {
    if (data) {
      Navigator.pop(context);
    }
  }

  void pincodeAPI() {
    String pin = pinController.text.trim();
    if (pin.isNotEmpty == true) {
      final List<int> executive = [];
      USER_LOGIN_DATA?.executiveBasicData?.forEach((action) {
        var d = action.executiveId;
        executive.add(d);
      });
      final List<String?> city = [];
      USER_LOGIN_DATA?.cityAccess?.forEach((action) {
        var d = action.cityAccess;
        city.add(d);
      });

      String? reqExecutiveId;
      if (executive.isNotEmpty) {
        reqExecutiveId = executive.join(',');
      }
      String? reqCity;
      if (executive.isNotEmpty) {
        reqCity = city.join(',');
      }

      ApiService service = ApiService();
      service.pincodeAPI2(pin, 0, reqExecutiveId, reqCity).then((data) {
        print('SSSSS ${data?.length}');
        if (data != null && data.isNotEmpty) {
          var dd = data[0];
          selectedCountry = dd.countryName;
          selectedState = dd.stateName;
          selectedDistrict = dd.districtName;
          selectedCity = dd.cityName;
          contactUpdateReq.resCountry = dd.countryId.toInt();
          contactUpdateReq.resState = dd.stateId.toInt();
          contactUpdateReq.resDistrict = dd.districtId.toInt();
          contactUpdateReq.resCity = dd.cityId.toInt();
          setState(() {});
        } else {
          AppUtils.showToast('No address found from this pin code');
        }
      });
    } else {
      AppUtils.showToast('Pincode is required');
    }
  }

  void contactDetailAPI() {
    var customerContactId = AppUtils.onlyInt(teacher?.edit);
    ApiService service = ApiService();
    service
        .contactDetailAPI(customerContactId, widget.customerType, teacher?.edit,
            widget.customerId)
        .then((data) {
      if (data != null && data.schoolContactDetails != null) {
        var detail = data?.schoolContactDetails?[0];

        firstNameController.text = detail?.firstName ?? '';
        lastNameController.text = detail?.lastName ?? '';
        mobileController.text = detail?.contactMobile ?? '';
        emailController.text = detail?.contactEmailId ?? '';
        addressController.text = detail?.resAddress ?? '';
        pinController.text = detail?.resPincode ?? '';
        contactUpdateReq.enteredBy = AppUtils.getUserId();

        selectedCountry =
            AppUtils.getCountryName(detail?.resCountry?.toDouble());
        selectedState = AppUtils.getStateName(detail?.resState?.toDouble());
        selectedDistrict =
            AppUtils.getDistrictName(detail?.resDistrict?.toDouble());
        selectedCity = AppUtils.getCityName(detail?.resCity?.toDouble());

        contactUpdateReq.resCountry = detail?.resCountry;
        contactUpdateReq.resState = detail?.resState;
        contactUpdateReq.resDistrict = detail?.resDistrict;
        contactUpdateReq.resCity = detail?.resCity;

        selectedAnniversary = detail?.anniversary ?? '';
        selectedDob = detail?.birthDay ?? '';

        contactUpdateReq.salutationId = detail?.salutationId;
        contactUpdateReq.primaryContact = detail?.primaryContact ?? '';
        contactUpdateReq.birthDay = detail?.birthDay ?? '';
        contactUpdateReq.anniversary = detail?.anniversary ?? '';
        contactUpdateReq.contactStatus = detail?.contactStatus;
        contactUpdateReq.primaryContact = detail?.primaryContact;
        contactUpdateReq.contactDesignationId = detail?.contactDesignationId;

        var subjectFromAPI = data?.teacherSubjects;
        subjectFromAPI?.forEach((e) {
          AddSubject as = AddSubject();
          as.name = e.subjectName;
          as.nameId = e.subjectId;
          as.maker = e.decisionValue;
          as.makerId = e.decisionId;

          // ✅ Handle classNames and classNumId safely
          final List<String>? classNames = e.classNames;
          final List<String>? classNumIds = e.classNumId;

          if (classNames != null && classNumIds != null) {
            // Defensive: ensure both lists have same length
            final int count = (classNames.length < classNumIds.length)
                ? classNames.length
                : classNumIds.length;

            for (int i = 0; i < count; i++) {
              StateResponse st = StateResponse();
              st.text = classNames[i];
              // Safe int parsing
              st.value = AppUtils.parseIntSafe(classNumIds[i]);
              as.classes?.add(st);
            }
          }
          subjectListAdded.add(as);
        });

        salutations.clear();
        BOARD_DATA?.salutationMaster?.forEach((e) {
          var s = StateResponse();
          s.text = e.salutationName;
          s.value = e.salutationId;
          salutations.add(s);
          if (e.salutationId == detail?.salutationId) {
            selectedSalutation = e.salutationName;
          }
        });
        designations.clear();
        BOARD_DATA?.contactDesignation?.forEach((e) {
          var s = StateResponse();
          s.text = e.contactDesignationName;
          s.value = e.contactDesignationId;
          designations.add(s);
          if (e.contactDesignationId == detail?.contactDesignationId) {
            selectedDesignation = e.contactDesignationName;
          }
        });
        dataSource.clear();
        BOARD_DATA?.dataSource?.forEach((e) {
          var s = StateResponse();
          s.text = e.dataSourceName;
          s.value = e.dataSourceId;
          dataSource.add(s);
          if (e.dataSourceId == detail?.dataSourceId) {
            selectedDataSource = e.dataSourceName;
          }
        });

        primaryContact.clear();
        var p1 = StateResponse();
        p1.text = 'Y';
        p1.label = 'Yes';
        p1.value = 1;
        primaryContact.add(p1);

        var d = detail?.primaryContact;
        if (d?.contains('Y') == false) {
          var p2 = StateResponse();
          p2.text = 'N';
          p2.label = 'No';
          p2.value = 2;
          primaryContact.add(p2);
          selectedPrimary = p1;
        } else {}
        for (var action in primaryContact) {
          if (action.text?.toLowerCase() ==
              detail?.primaryContact?.toLowerCase()) {
            selectedPrimary = action;
          }
        }
        contactStatus.clear();
        var c1 = StateResponse();
        c1.text = 'Active';
        c1.label = 'Active';
        c1.value = 1;
        contactStatus.add(c1);

        var c2 = StateResponse();
        c2.text = 'Inactive';
        c2.label = 'Inactive';
        c2.value = 2;
        contactStatus.add(c2);

        for (var action in contactStatus) {
          if (action.text?.toLowerCase() ==
              detail?.contactStatus?.toLowerCase()) {
            selectedContactStatus = action;
          }
        }
        print('SSSS in api ');
        setAllData(detail);
      }
    });
  }
}
