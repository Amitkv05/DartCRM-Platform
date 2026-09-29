import 'dart:async';

import 'package:dart_crm/edit/model/schoolUpdate/StateResponse.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/setup_value.dart';
import '../model/school/SchoolDetailsNew.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/seller/BookSellerData.dart';
import '../utils/AppUtils.dart';
import '../utils/add_button_widget.dart';
import '../utils/add_more_drop_widget.dart';
import '../utils/all_field_widget.dart';
import '../utils/click_button_widget.dart';
import '../utils/color_constants.dart';
import '../utils/radio_tab.dart';
import '../utils/widgetUtils.dart';
import 'add_book_page.dart';

class SchoolDetailTab extends StatefulWidget {
  final SchoolListResponse? apiData;
  final int? type;

  const SchoolDetailTab({super.key, required this.apiData, required this.type});

  @override
  State<SchoolDetailTab> createState() => _SchoolDetailTabState();
}

class _SchoolDetailTabState extends State<SchoolDetailTab>
    with AutomaticKeepAliveClientMixin {
  String? selectedDecisionMonth = '';
  String? boardSelect,
      selectedStartClass,
      selectedEndClass,
      selectedRank,
      selectedChain,
      selectedSamplingMonth = '';

  List<StateResponse>? modelBoard = [];

  List<StateResponse>? modelChain = [];
  List<StateResponse>? modelStartClass = [];
  List<StateResponse>? modelEndClass = [];
  List<StateResponse>? modelMonthSampling = [];
  List<StateResponse> modelRank = [];

  TextEditingController mediumController = TextEditingController();
  TextEditingController panController = TextEditingController();
  TextEditingController gstController = TextEditingController();
  TextEditingController avGFeeController = TextEditingController();

  List<StateResponse> modePurchase = [];
  List<StateResponse> customerStatus = [];
  List<StateResponse> KeyCustomer = [];
  List<StateResponse>? accountableSelected;

  StateResponse? selectedPurchage;
  StateResponse? selectedCustomerStatus;
  StateResponse? selectedKeyCustomer;
  bool isBookSeller = false;
  BookSellerData? bookSeller1;
  BookSellerData? bookSeller2;

  final StreamController<String> _loadDataStream = BehaviorSubject();
  SetupValue? schoolAverageFee;

  @override
  void initState() {
    var books = widget.apiData?.bookSellerList;
    var sizeBook = books?.length;

    if (sizeBook == 1) {
      bookSeller1 = books?[0];
      isBookSeller = true;
      UPDATED_REQ.bookSellerId1 = bookSeller1?.action;
    }
    if (sizeBook == 2) {
      isBookSeller = true;
      bookSeller1 = books?[0];
      bookSeller2 = books?[1];
      UPDATED_REQ.bookSellerId1 = bookSeller1?.action;
      UPDATED_REQ.bookSellerId2 = bookSeller2?.action;
    }
    UPDATED_REQ.customerStatus = 'Active';
    UPDATED_REQ.keyCustomer = 'Yes';
    schoolAverageFee = AppUtils.filterSetup('SchoolAverageFee');
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  SchoolDetailsNew? school;

  onPostFrameCallback(BuildContext context) {
    school = AppUtils.getSchool(widget.apiData);

    mediumController.text = UPDATED_REQ?.mediumInstruction ?? '';
    panController.text = UPDATED_REQ?.pANNumber ?? '';
    gstController.text = UPDATED_REQ?.gSTNumber ?? '';
    if (school?.averageFee == null || school?.averageFee == 0) {
      avGFeeController.text = '';
    } else {
      avGFeeController.text = '${UPDATED_REQ?.averageFee}';
    }

    BOARD_DATA?.boardMaster?.forEach((e) {
      var s = StateResponse();
      s.text = e.boardName;
      s.value = e.boardId;
      modelBoard?.add(s);
      if (e.boardId == school?.boardId) {
        boardSelect = e.boardName;
        UPDATED_REQ.boardId = school?.boardId;
      }
    });

    print('boardSelect $boardSelect');

    BOARD_DATA?.classes?.forEach((e) {
      var s = StateResponse();
      s.text = e.className;
      s.value = e.classNumId;
      modelStartClass?.add(s);
      modelEndClass?.add(s);

      if (e.classNumId == UPDATED_REQ?.startClassId) {
        selectedStartClass = e.className;
        UPDATED_REQ.startClassId = UPDATED_REQ?.startClassId;
      }

      if (e.classNumId == UPDATED_REQ?.endClassId) {
        selectedEndClass = e.className;
        UPDATED_REQ.endClassId = UPDATED_REQ?.endClassId;
      }
    });

    BOARD_DATA?.months?.forEach((e) {
      var s = StateResponse();
      s.text = e.name;
      s.value = e.id;
      modelMonthSampling?.add(s);
      if (e.id == UPDATED_REQ?.samplingMonth) {
        selectedSamplingMonth = e.name;
        UPDATED_REQ.samplingMonth = UPDATED_REQ?.samplingMonth;
      }
      if (e.id == UPDATED_REQ?.decisionMonth) {
        selectedDecisionMonth = e.name;
        UPDATED_REQ.decisionMonth = UPDATED_REQ?.decisionMonth;
      }
    });

    BOARD_DATA?.chainSchool?.forEach((e) {
      var s = StateResponse();
      s.text = e.chainSchoolName;
      s.value = e.chainSchoolId;
      modelChain?.add(s);
      if (e.chainSchoolId == UPDATED_REQ?.chainSchoolId) {
        selectedChain = e.chainSchoolName;
        UPDATED_REQ.chainSchoolId = UPDATED_REQ?.chainSchoolId;
      }
    });

    BOARD_DATA?.purchaseMode?.forEach((e) {
      var s = StateResponse();
      s.text = e.modeName;
      s.label = e.modeValue;

      print('object purchaseMode ${e.toJson()}');

      modePurchase.add(s);
      if (e.modeValue?.toLowerCase() ==
          UPDATED_REQ?.purchaseMode?.toLowerCase()) {
        UPDATED_REQ.purchaseMode = e.modeValue;
        selectedPurchage = s;
      }
    });

    var r1 = StateResponse();
    r1.text = 'A';
    r1.value = 1;
    modelRank.add(r1);

    var r2 = StateResponse();
    r2.text = 'B';
    r2.value = 2;
    modelRank.add(r2);

    var r3 = StateResponse();
    r3.text = 'C';
    r3.value = 3;
    modelRank.add(r3);

    for (var action in modelRank) {
      if (action.text == UPDATED_REQ?.ranking) {
        selectedRank = action.text;
        UPDATED_REQ.ranking = UPDATED_REQ?.ranking;
      }
    }

    var c1 = StateResponse();
    c1.text = 'Active';
    c1.label = 'Active';
    c1.value = 1;
    customerStatus.add(c1);

    var c2 = StateResponse();
    c2.text = 'Inactive';
    c2.label = 'Inactive';
    c2.value = 2;
    customerStatus.add(c2);

    for (var action in customerStatus) {
      if (action.text?.toLowerCase() ==
          UPDATED_REQ?.customerStatus?.toLowerCase()) {
        selectedCustomerStatus = action;
        UPDATED_REQ.customerStatus = UPDATED_REQ?.customerStatus;
      }
    }

    var k1 = StateResponse();
    k1.text = 'Yes';
    k1.label = 'Yes';
    k1.value = 1;
    KeyCustomer.add(k1);

    var k2 = StateResponse();
    k2.text = 'No';
    k2.label = 'No';
    k2.value = 2;
    KeyCustomer.add(k2);

    for (var action in KeyCustomer) {
      if (action.text?.toLowerCase() ==
          UPDATED_REQ.keyCustomer?.toLowerCase()) {
        selectedKeyCustomer = action;
        UPDATED_REQ.keyCustomer = UPDATED_REQ?.keyCustomer;
      }
    }
    _loadDataStream.sink.add('event');
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
            children: [
              ClickButtonWidget(
                field: 'Board',
                required: '*',
                value: boardSelect,
                resourceList: modelBoard,
                onSelected: (data) {
                  boardSelect = data?.text;
                  UPDATED_REQ.boardId = data?.value;
                  setState(() {});
                },
              ),
              ClickButtonWidget(
                field: 'Chain School',
                required: '',
                value: selectedChain,
                resourceList: modelChain,
                onSelected: (data) {
                  selectedChain = data?.text;
                  UPDATED_REQ.chainSchoolId = data?.value;
                  setState(() {});
                },
              ),
              AllFieldWidget(
                controller: mediumController,
                preNode: null,
                nextNode: null,
                max: 20,
                required: '*',
                field: 'Medium',
                onTypeChange: (value) {
                  UPDATED_REQ.mediumInstruction = value;
                },
              ),
              ClickButtonWidget(
                field: 'Ranking/Category',
                required: '*',
                value: selectedRank,
                resourceList: modelRank,
                onSelected: (data) {
                  selectedRank = data?.text;
                  UPDATED_REQ.ranking = data?.text;
                  setState(() {});
                },
              ),
              ClickButtonWidget(
                field: 'Demo Month',
                required: '*',
                value: selectedSamplingMonth,
                resourceList: modelMonthSampling,
                onSelected: (data) {
                  selectedSamplingMonth = data?.text;
                  UPDATED_REQ.samplingMonth = data?.value;
                  setState(() {});
                },
              ),
              ClickButtonWidget(
                field: 'Decision Month',
                required: '*',
                value: selectedDecisionMonth,
                resourceList: modelMonthSampling,
                onSelected: (data) {
                  selectedDecisionMonth = data?.text;
                  UPDATED_REQ.decisionMonth = data?.value;
                  setState(() {});
                },
              ),
              RadioTab(
                size: 27,
                field: 'Purchase Mode',
                required: '*',
                selectedOption: selectedPurchage,
                resource: modePurchase,
                callback: (value) {
                  UPDATED_REQ.purchaseMode = value?.label;
                  print('object text ${value?.label}');
                  isBookSeller = value?.label?.toLowerCase() == 'bookseller';
                  print('object isBookSeller $isBookSeller');
                  _loadDataStream.sink.add('event');
                },
              ),
              RadioTab(
                size: 27,
                field: 'Key Customer',
                selectedOption: selectedKeyCustomer,
                required: '*',
                resource: KeyCustomer,
                callback: (value) {
                  UPDATED_REQ.keyCustomer = value?.text;
                },
              ),
              AllFieldWidget(
                controller: panController,
                preNode: null,
                max: 6,
                nextNode: null,
                format: FORMAT.DIGIT,
                field: 'PAN Number',
                onTypeChange: (value) {
                  UPDATED_REQ.pANNumber = value;
                },
              ),
              AllFieldWidget(
                controller: gstController,
                preNode: null,
                nextNode: null,
                format: FORMAT.CAP,
                max: 10,
                field: 'GST Number',
                onTypeChange: (value) {
                  UPDATED_REQ.gSTNumber = value;
                },
              ),
              RadioTab(
                size: 27,
                field: 'Customer Status',
                selectedOption: selectedCustomerStatus,
                required: '*',
                resource: customerStatus,
                callback: (value) {
                  UPDATED_REQ.customerStatus = value?.text;
                },
              ),
              schoolAverageFee != null && schoolAverageFee?.keyValue == 'Y'
                  ? AllFieldWidget(
                      controller: avGFeeController,
                      preNode: null,
                      nextNode: null,
                      max: 8,
                      required: '*',
                      format: FORMAT.DIGIT,
                      field: 'Average Fee',
                      onTypeChange: (value) {
                        UPDATED_REQ.averageFee = int.tryParse(value);
                      },
                    )
                  : SizedBox(),
              AddMoreDropWidget(
                apiData: widget.apiData,
                field: 'Accountable Executive',
                required: '*',
                type: widget.type,
                callback: (tags) {
                  accountableSelected = tags;
                  var d = AppUtils.createXmlAccount(accountableSelected);
                  UPDATED_REQ.xmlAccountTableExecutiveId = d;
                },
              ),
              isBookSeller
                  ? bookSeller1 == null || bookSeller2 == null
                      ? AddButtonWidget(
                          field: 'Book Seller',
                          required: '*',
                          title: 'Add Book Seller',
                          onPressed: () {
                            WidgetUtils.launchScreen(
                              context,
                              AddBookPage(
                                bookSeller1: bookSeller1,
                                bookSeller2: bookSeller2,
                                bookCallback: (b1, b2) {
                                  bookSeller1 = b1;
                                  bookSeller2 = b2;
                                  UPDATED_REQ.bookSellerId1 =
                                      bookSeller1?.action;
                                  UPDATED_REQ.bookSellerId2 =
                                      bookSeller2?.action;
                                  setState(() {});
                                },
                              ),
                            );
                          })
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: SizedBox(
                                child: Text(
                                  'Book Seller *',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        )
                  : SizedBox(),
              SizedBox(
                height: 15,
              ),
              isBookSeller ? _widgetList() : SizedBox(),
              SizedBox(
                height: 100,
              ),
            ],
          );
        });
  }

  Widget _widgetList() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bookSeller1 == null
            ? Container(
                alignment: Alignment.center,
                height: 70,
                child: Text(
                  'Click to Add Book Seller',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black),
                ),
              )
            : Text(
                'Book Seller 1',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black),
              ),
        bookSeller1 == null
            ? SizedBox()
            : Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(
                    left: 15, top: 4, bottom: 4, right: 1),
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade600,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookSeller1?.bookSellerName ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black),
                          ),
                          Text(
                            bookSeller1?.city ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 13,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        bookSeller1 = bookSeller2;
                        bookSeller2 = null;
                        if (bookSeller1 == null) {
                          UPDATED_REQ.bookSellerId1 = null;
                        }
                        UPDATED_REQ.bookSellerId2 = null;
                        setState(() {});
                      },
                      icon: Icon(Icons.delete),
                    )
                  ],
                ),
              ),
        SizedBox(
          height: 10,
        ),
        bookSeller2 == null
            ? SizedBox()
            : Text(
                'Book Seller 2',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black),
              ),
        bookSeller2 == null
            ? SizedBox()
            : Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(
                    left: 15, top: 4, bottom: 4, right: 1),
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade600,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookSeller2?.bookSellerName ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black),
                          ),
                          Text(
                            bookSeller2?.city ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 13,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        UPDATED_REQ.bookSellerId2 = null;
                        bookSeller2 = null;
                        setState(() {});
                      },
                      icon: Icon(Icons.delete),
                    )
                  ],
                ),
              ),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
