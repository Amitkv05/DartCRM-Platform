import 'dart:async';

import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:dart_crm/edit/api/repository/api_service.dart';
import 'package:dart_crm/edit/model/schoolUpdate/StateResponse.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import '../model/Geo/GeographyModel.dart';
import '../model/seller/BookSellerData.dart';
import '../model/seller/BookSellerRequest.dart';
import '../utils/AppUtils.dart';
import '../utils/ValueModel.dart';
import '../utils/all_field_widget.dart';
import '../utils/click_button_widget.dart';
import '../utils/color_constants.dart';
import '../utils/fill_button_widget.dart';
import '../utils/widgetUtils.dart';
import 'package:collection/collection.dart';

class AddBookPage extends StatefulWidget {
  final BookSellerData? bookSeller1;
  final BookSellerData? bookSeller2;

  final Function(BookSellerData? bookSeller1, BookSellerData? bookSeller2) bookCallback;

  const AddBookPage({
    super.key,
    required this.bookSeller1,
    required this.bookSeller2,
    required this.bookCallback,
  });

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> with SingleTickerProviderStateMixin {
  TextEditingController codeController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  List<StateResponse> model = [];

  String? selectedCountry = '';
  String? selectedState = '';
  String? selectedDistrict = '';
  String? selectedCity = '';

  String? selectedRegion = '';
  String? selectedArea = '';
  String? selectedTerritory = '';

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
  BookSellerRequest request = BookSellerRequest();
  bool isSearch = false;
  BookSellerData? book1;
  BookSellerData? book2;

  @override
  void initState() {
    request = BookSellerRequest();
    book1 = widget.bookSeller1;
    book2 = widget.bookSeller2;
    setCountryData();
    super.initState();
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
                  width: 100,
                  title: 'Search',
                  bgColor: AppColor.color_4285F4,
                  onPressed: () async {
                    if (!isSearch) {
                      bookList = null;
                      searchBookAPI();
                    } else {
                      isSearch = !isSearch;
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
            title: Text(
              'Search Book Seller',
              style: TextStyle(fontSize: 19, color: Colors.white),
            ),
            centerTitle: false,
            // Centers the title
            backgroundColor: TColors.warning),
        backgroundColor: AppColor.white,
        body: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 50),
          child: SingleChildScrollView(
            child: isSearch
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Book Seller List',
                            style: TextStyle(fontSize: 19, color: Colors.black),
                          ),
                          Spacer(
                            flex: 1,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FillButtonWidget(
                              height: 40,
                              width: 180,
                              title: 'Add Book Seller',
                              bgColor: AppColor.color_4285F4,
                              onPressed: () async {
                                BookSellerData? book1;
                                BookSellerData? book2;

                                if (bookList != null) {
                                  final selected =
                                      bookList?.where((b) => b.isSelected).toList();

                                  if (selected?.length == 1) {
                                    book1 = selected?.firstOrNull;
                                  } else {
                                    book1 = selected?.firstOrNull;
                                    book2 = selected?.lastOrNull;
                                  }
                                }
                                widget.bookCallback(book1, book2);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      _widgetList(),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AllFieldWidget(
                        controller: nameController,
                        preNode: nameNode,
                        nextNode: codeNode,
                        field: 'Book Seller Name',
                        onTypeChange: (value) {},
                      ),
                      AllFieldWidget(
                        controller: codeController,
                        preNode: codeNode,
                        nextNode: null,
                        max: 10,
                        format: FORMAT.CAP,
                        field: 'Book Seller Code/RefCode',
                        onTypeChange: (value) {},
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Geographical Structure',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black),
                      ),
                      ClickButtonWidget(
                        field: 'Country Name',
                        value: selectedCountry,
                        resourceList: modelCountry,
                        onSelected: (data) {
                          selectedCountry = data?.text;
                          request.countryId = data?.value;
                          setStateData(data?.value);
                        },
                      ),
                      ClickButtonWidget(
                        field: 'State Name',
                        value: selectedState,
                        resourceList: modelState,
                        onSelected: (data) {
                          request.stateId = data?.value;
                          selectedState = data?.text;
                          setDistrictData(data?.value);
                        },
                      ),
                      ClickButtonWidget(
                        field: 'District Name',
                        value: selectedDistrict,
                        resourceList: modelDistrict,
                        onSelected: (data) {
                          request.districtId = data?.value;
                          selectedDistrict = data?.text;
                          setCityData(data?.value);
                        },
                      ),
                      ClickButtonWidget(
                        field: 'City Name',
                        value: selectedCity,
                        resourceList: modelCity,
                        onSelected: (data) {
                          request.cityId = data?.value;
                          selectedCity = data?.text;
                          setState(() {});
                        },
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
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
      modelCity?.add(s);
    });
    setState(() {});
  }

  Widget _widgetList() {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: bookList?.length ?? 0,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var book = bookList?[index];
        return Container(
          padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4, right: 1),
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade600,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              if (book?.isSelected == true) {
              } else {
                int count = 0;
                bookList?.forEach((action) {
                  if (action.isSelected) {
                    count++;
                  }
                });
                if (count > 1) {
                  AppUtils.showToast('Only 2 Book Seller is allow');
                  return;
                }
              }
              book?.isSelected = !(book.isSelected);
              setState(() {});
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book?.bookSellerName ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    book?.isSelected == true
                        ? Icon(
                            Icons.check_box,
                            color: Colors.blue,
                          )
                        : Icon(Icons.check_box_outline_blank),
                    SizedBox(
                      width: 10,
                    )
                  ],
                ),
                AppUtils.isBlank(book?.address?.trim())
                    ? SizedBox()
                    : Text(
                        book?.address ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.black),
                      ),
                AppUtils.isBlank(book?.city?.trim())
                    ? SizedBox()
                    : Text(
                        book?.city ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.black),
                      ),
                Text(
                  book?.state ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 13, color: Colors.black),
                ),
                Text(
                  book?.country ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 13, color: Colors.black),
                ),
                SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  List<BookSellerData>? bookList = [];

/*
  '{"BookSellerName":"","BookSellerCode":"","CountryId":1,
  "StateId":0,"DistrictId":0,"CityId":0,"RegionId":0,"AreaId":0,"TerritoryId":0,
  "loggedInExecutiveId":0,"downHierarchy":"110","TerritoryAccess":"1,2,3,4,5,6,7,8"}'*/

  void searchBookAPI() {
    request.bookSellerName = nameController.text.trim();
    request.bookSellerCode = codeController.text.trim();

    request.loggedInExecutiveId = AppUtils.getExecutiveStr();
    request.downHierarchy = AppUtils.getDownStr();
    request.territoryAccess = AppUtils.getTerritoryAccess();

    print('request ${request.toJson()}');

    ApiService service = ApiService();
    service.bookSellerSearchAPI(request).then((data) {
      isSearch = true;
      bookList = data;
      if (bookList != null) {
        final found = bookList?.firstWhereOrNull((item) => item.action == book1?.action);
        found?.isSelected = true;

        final found2 = bookList?.firstWhereOrNull((item) => item.action == book2?.action);
        found2?.isSelected = true;
      }
      setState(() {});
    });
  }
}
