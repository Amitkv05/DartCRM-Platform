import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:flutter/material.dart';

import '../../models/setup_value.dart';
import '../api/repository/api_service.dart';
import '../model/Geo/GeographyModel.dart';
import '../model/school/SchoolDetailsNew.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/schoolUpdate/StateResponse.dart';
import '../utils/all_field_widget.dart';
import '../utils/click_button_widget.dart';
import '../utils/message_field_widget.dart';
import '../utils/widgetUtils.dart';

class AddressTab extends StatefulWidget {
  final SchoolListResponse? apiData;
  final int? type;

  const AddressTab({super.key, required this.apiData, required this.type});

  @override
  State<AddressTab> createState() => _AddressTabState();
}

class _AddressTabState extends State<AddressTab> with AutomaticKeepAliveClientMixin {
  String? selectedCountry = '';
  String? selectedState = '';
  String? selectedDistrict = '';
  String? selectedCity = '';

  FocusNode nameNode = FocusNode();
  FocusNode codeNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode mobileNode = FocusNode();

  TextEditingController addressController = TextEditingController();
  TextEditingController pinController = TextEditingController();

  List<StateResponse>? modelCountry = [];
  List<StateResponse>? modelState = [];
  List<StateResponse>? modelDistrict = [];
  List<StateResponse>? modelCity = [];
  SetupValue? mPincode;
  SchoolDetailsNew? sData;

  @override
  void initState() {
    mPincode = AppUtils.filterSetup('GeographyBasedOnPincode');
    if (widget.type == 1) {
      sData = AppUtils.getSchool(widget.apiData);
    } else if (widget.type == 2) {
      sData = AppUtils.getTrade(widget.apiData);
    } else if (widget.type == 3) {
      sData = AppUtils.getTrade(widget.apiData);
    }
    setCountryData();

    addressController.text = UPDATED_REQ.address ?? '';
    pinController.text = UPDATED_REQ.pincode ?? '';
    selectedCountry = AppUtils.getCountryName(UPDATED_REQ.countryId?.toDouble());
    selectedState = AppUtils.getStateName(UPDATED_REQ.stateId?.toDouble());
    selectedDistrict = AppUtils.getDistrictName(UPDATED_REQ.districtId?.toDouble());
    selectedCity = AppUtils.getCityName(UPDATED_REQ.cityId?.toDouble());

    UPDATED_REQ.address = addressController.text;
    UPDATED_REQ.pincode = pinController.text;

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  onPostFrameCallback(BuildContext context) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SizedBox(
          height: 20,
        ),
        MessageFieldWidget(
          preNode: null,
          nextNode: null,
          textInputAction: TextInputAction.done,
          controller: addressController,
          error: '',
          maxLines: 3,
          field: 'Address',
          required: '*',
          hint: 'Write the address',
          onTypeChange: (value) {
            UPDATED_REQ.address = value;
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
                      required: '*',
                      field: 'Pin code',
                      format: FORMAT.PHONE,
                      max: 6,
                      onTypeChange: (value) {
                        UPDATED_REQ.pincode = value;
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
          required: '*',
          resourceList: modelCountry,
          onSelected: (data) {
            UPDATED_REQ.countryId = data?.value;
            selectedCountry = data?.text;
            setStateData(data?.value);
          },
        ),
        ClickButtonWidget(
          field: 'State Name',
          required: '*',
          value: selectedState,
          resourceList: modelState,
          onSelected: (data) {
            UPDATED_REQ.stateId = data?.value;
            selectedState = data?.text;
            setDistrictData(data?.value);
          },
        ),
        ClickButtonWidget(
          field: 'District Name',
          required: '*',
          value: selectedDistrict,
          resourceList: modelDistrict,
          onSelected: (data) {
            UPDATED_REQ.districtId = data?.value;
            selectedDistrict = data?.text;
            setCityData(data?.value);
          },
        ),
        ClickButtonWidget(
          field: 'City Name',
          required: '*',
          value: selectedCity,
          resourceList: modelCity,
          onSelected: (data) {
            UPDATED_REQ.cityId = data?.value;
            selectedCity = data?.text;
            setState(() {});
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
                  UPDATED_REQ.pincode = value;
                },
              )
            : SizedBox(),
      ],
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
    // for State
    modelState?.clear();
    List<GeographyModel>? s = [];
    List<GeographyModel>? s2 = [];
    List<GeographyModel>? s3 = [];
    GEO_DATA?.forEach((e) {
      var countryId = e.countryId;
      if (countryId == UPDATED_REQ.countryId) {
        s.add(e);
      }

      var stateId = e.stateId;
      if (stateId == UPDATED_REQ.stateId) {
        s2.add(e);
      }

      var id = e.districtId;
      if (id == UPDATED_REQ.districtId) {
        s3.add(e);
      }
    });
    AppUtils.removeDuplicateState(s)?.forEach((e) {
      var s = StateResponse();
      s.text = e.state;
      s.value = e.stateId;
      modelState?.add(s);
    });
    AppUtils.removeDuplicateDistrict(s2)?.forEach((e) {
      var s = StateResponse();
      s.text = e.district;
      s.value = e.districtId;
      modelDistrict?.add(s);
    });
    AppUtils.removeDuplicateCity(s3)?.forEach((e) {
      var s = StateResponse();
      s.text = e.city;
      s.value = e.cityId;
      modelCity?.add(s);
    });
    setState(() {});
  }

  void setStateData(int? countryId) {
    modelState?.clear();
    selectedState = '';
    selectedDistrict = '';
    selectedCity = '';
    UPDATED_REQ.stateId = null;
    UPDATED_REQ.districtId = null;
    UPDATED_REQ.cityId = null;
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
    UPDATED_REQ.districtId = null;
    UPDATED_REQ.cityId = null;
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
    UPDATED_REQ.cityId = null;
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
      modelCity?.add(s);
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
      AppUtils.showToast('Pin code is required');
    }
  }

  @override
  bool get wantKeepAlive => true;
}
