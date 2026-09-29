import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../model/school/SchoolDetailsNew.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/schoolUpdate/StateResponse.dart';
import '../utils/AppUtils.dart';
import '../utils/ValueModel.dart';
import '../utils/add_more_drop_widget.dart';
import '../utils/all_field_widget.dart';
import '../utils/radio_tab.dart';
import '../utils/widgetUtils.dart';

class CustomerDetailTab extends StatefulWidget {
  final SchoolListResponse? apiData;
  final int? type;

  const CustomerDetailTab(
      {super.key, required this.apiData, required this.type});

  @override
  State<CustomerDetailTab> createState() => _CustomerDetailTabState();
}

class _CustomerDetailTabState extends State<CustomerDetailTab>
    with AutomaticKeepAliveClientMixin {
  final StreamController<String> _loadDataStream = BehaviorSubject();

  String? selectedCountry = '';
  List<ValueModel> model = [];

  TextEditingController gstC = TextEditingController();
  TextEditingController panC = TextEditingController();

  List<StateResponse> customerStatus = [];
  List<StateResponse> keyCustomer = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  StateResponse? selectedPurchage;
  StateResponse? selectedCustomerStatus;
  StateResponse? selectedKeyCustomer;

  onPostFrameCallback(BuildContext context) {
    var trade = AppUtils.getTrade(widget.apiData);
    panC.text = trade?.panNumber ?? '';
    gstC.text = trade?.gstNumber ?? '';
    UPDATED_REQ.pANNumber = trade?.panNumber;
    UPDATED_REQ.gSTNumber = trade?.gstNumber;

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
      if (action.text?.toLowerCase() == trade?.customerStatus?.toLowerCase()) {
        selectedCustomerStatus = action;
        UPDATED_REQ.customerStatus = trade?.customerStatus;
      }
    }

    var k1 = StateResponse();
    k1.text = 'Y';
    k1.label = 'Yes';
    k1.value = 1;
    keyCustomer.add(k1);

    var k2 = StateResponse();
    k2.text = 'N';
    k2.label = 'No';
    k2.value = 2;
    keyCustomer.add(k2);

    for (var action in keyCustomer) {
      if (action.text?.toLowerCase() == trade?.keyCustomer?.toLowerCase()) {
        selectedKeyCustomer = action;
        UPDATED_REQ.keyCustomer = trade?.keyCustomer;
      }
    }

    _loadDataStream.sink.add('event');
  }

  @override
  Widget build(BuildContext context) {
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
              AllFieldWidget(
                controller: panC,
                preNode: null,
                nextNode: null,
                field: 'PAN Number',
                onTypeChange: (value) {
                  UPDATED_REQ.pANNumber = value;
                },
              ),
              AllFieldWidget(
                controller: gstC,
                preNode: null,
                nextNode: null,
                format: FORMAT.DIGIT,
                field: 'GST Number',
                onTypeChange: (value) {
                  UPDATED_REQ.gSTNumber = value;
                },
              ),
              AddMoreDropWidget(
                apiData: widget.apiData,
                type: 2,
                field: 'Customer Category',
                required: '*',
                callback: (tags) {
                  var accountableSelected = tags;
                  var d =
                      AppUtils.createXmlCustomerCategory(accountableSelected);
                  UPDATED_REQ.xmlCustomerCategoryId = d;
                },
              ),
              AddMoreDropWidget(
                apiData: widget.apiData,
                type: 1,
                field: 'Accountable Executive',
                required: '*',
                callback: (tags) {
                  var accountableSelected = tags;
                  var d = AppUtils.createXmlAccount(accountableSelected);
                  UPDATED_REQ.xmlAccountTableExecutiveId = d;
                },
              ),
              RadioTab(
                size: 27,
                field: 'Key Customer',
                selectedOption: selectedKeyCustomer,
                required: '*',
                resource: keyCustomer,
                callback: (value) {
                  UPDATED_REQ.keyCustomer = value?.text;
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
            ],
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}
