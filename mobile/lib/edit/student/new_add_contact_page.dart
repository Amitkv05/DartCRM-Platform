import 'dart:async';

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

class NewAddContactPage extends StatefulWidget {
  final int? type;
  final String? customerType;
  final SchoolListResponse? apiData;

  const NewAddContactPage(
      {super.key,
      required this.type,
      required this.apiData,
      required this.customerType});

  @override
  State<NewAddContactPage> createState() => _NewAddContactPageState();
}

class _NewAddContactPageState extends State<NewAddContactPage>
    with AutomaticKeepAliveClientMixin {
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
      title = 'Library';
    }

    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  onPostFrameCallback(BuildContext context) {
    mPincode = AppUtils.filterSetup('GeographyBasedOnPincode');

    var name = AppUtils.filterSetup('CustomerContactFirstLastNameMandatory');

    print('object CustomerContactFirstLastNameMandatory ${name?.keyValue}');

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
    setCountryData();
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

    UPDATED_REQ.primaryContact = p1.text;

    selectedPrimary = p1;

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
    _loadDataStream.sink.add('dd');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<String>(
        stream: _loadDataStream.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioTab(
                size: 27,
                field: 'Primary Contact',
                selectedOption: selectedPrimary,
                required: '*',
                resource: primaryContact,
                callback: (value) {
                  UPDATED_REQ.primaryContact = value?.text;
                  setState(() {});
                },
              ),
              RadioTab(
                size: 27,
                field: 'Contact Status',
                selectedOption: selectedContactStatus,
                required: '*',
                resource: contactStatus,
                callback: (value) {
                  UPDATED_REQ.contactStatus = value?.text;
                  setState(() {});
                },
              ),
              ClickButtonWidget(
                field: 'Salutation',
                required: '',
                value: selectedSalutation,
                resourceList: salutations,
                onSelected: (data) {
                  selectedSalutation = data?.text;
                  UPDATED_REQ.salutationId = data?.value;
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
                  UPDATED_REQ.firstName = value.trim();
                },
              ),
              AllFieldWidget(
                controller: lastNameController,
                preNode: lastNode,
                nextNode: emailNode,
                field: 'Last Name',
                required: (index2 == 2 || both == 1) ? '*' : '',
                onTypeChange: (value) {
                  UPDATED_REQ.lastName = value.trim();
                },
              ),
              ClickButtonWidget(
                field: 'Designation',
                required: '*',
                value: selectedDesignation,
                resourceList: designations,
                onSelected: (data) {
                  selectedDesignation = data?.text;
                  UPDATED_REQ.contactDesignationId = data?.value;
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
                  UPDATED_REQ.contactMobile = value.trim();
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
                  UPDATED_REQ.contactEmailId = value.trim();
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
                  UPDATED_REQ.resAddress = value.trim();
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
                              UPDATED_REQ.resPincode = value.trim();
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
                  UPDATED_REQ.resCountry = data?.value;
                  setStateData(data?.value);
                },
              ),
              ClickButtonWidget(
                field: 'State Name',
                value: selectedState,
                resourceList: modelState,
                onSelected: (data) {
                  selectedState = data?.text;
                  UPDATED_REQ.resState = data?.value;
                  setDistrictData(data?.value);
                },
              ),
              ClickButtonWidget(
                field: 'District Name',
                value: selectedDistrict,
                resourceList: modelDistrict,
                onSelected: (data) {
                  selectedDistrict = data?.text;
                  UPDATED_REQ.resDistrict = data?.value;
                  setCityData(data?.value);
                },
              ),
              ClickButtonWidget(
                field: 'City Name',
                value: selectedCity,
                resourceList: modelCity,
                onSelected: (data) {
                  UPDATED_REQ.resCity = data?.value;
                  selectedCity = data?.text;
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
                        UPDATED_REQ.resPincode = value.trim();
                      },
                    )
                  : SizedBox(),
              ClickButtonWidget(
                field: 'Data Source',
                required: '',
                value: selectedDataSource,
                resourceList: dataSource,
                onSelected: (data) {
                  selectedDataSource = data?.text;
                  UPDATED_REQ.dataSourceId = data?.value;
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
                      required: '',
                      value: selectedDob,
                      onSelected: () async {
                        DateTime initial = DateTime(DateTime.now().year - 20);
                        final picked = await pickDOB(context, initial);
                        if (picked != null) {
                          selectedDob = DateFormat('dd-MM-yyyy').format(picked);
                          UPDATED_REQ.birthDay = selectedDob;
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
                            UPDATED_REQ.birthDay = null;
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
                      required: '',
                      value: selectedAnniversary,
                      onSelected: () async {
                        DateTime initial = DateTime(DateTime.now().year - 20);
                        final picked = await pickDOB(context, initial);
                        if (picked != null) {
                          selectedAnniversary =
                              DateFormat('dd-MM-yyyy').format(picked);
                          UPDATED_REQ.anniversary = selectedAnniversary;
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
                            UPDATED_REQ.anniversary = null;
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
                                var d = AppUtils.createSchoolSubject(
                                    subjectListAdded);
                                UPDATED_REQ.xmlSubjectClassDM = d;
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
          );
        });
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
          margin: EdgeInsets.only(bottom: 5),
          padding: EdgeInsets.only(left: 15, top: 15, right: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: AppColor.color_B0B0B0,
              width: 1.0,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        subjectListAdded.remove(d);
                        setState(() {});
                      },
                      icon: Icon(size: 20, Icons.delete)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void setCountryData() {
    var c = AppUtils.removeDuplicate(GEO_DATA);
    c?.forEach((e) {
      var s = StateResponse();
      s.text = e.country;
      s.value = e.countryId;
      modelCountry?.add(s);
    });
  }

  void setStateData(int? countryId) {
    modelState?.clear();
    selectedState = '';
    selectedDistrict = '';
    selectedCity = '';
    List<GeographyModel>? s = [];
    GEO_DATA?.forEach((e) {
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
    GEO_DATA?.forEach((e) {
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
    GEO_DATA?.forEach((e) {
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
        if (data != null && data.isNotEmpty) {
          var dd = data[0];
          selectedCountry = dd.countryName;
          selectedState = dd.stateName;
          selectedDistrict = dd.districtName;
          selectedCity = dd.cityName;
          UPDATED_REQ.cityId = dd.cityId.toInt();
          setState(() {});
        } else {
          AppUtils.showToast('No address found from this pin code');
        }
      });
    } else {
      AppUtils.showToast('Pincode is required');
    }
  }

  @override
  bool get wantKeepAlive => true;
}
