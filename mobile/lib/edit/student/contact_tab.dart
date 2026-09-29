import 'dart:async';

import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../api/repository/api_service.dart';
import '../model/school/SchoolDetailsNew.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/teacher/ContactModel.dart';
import '../utils/add_button_widget.dart';
import '../utils/color_constants.dart';
import '../utils/widgetUtils.dart';
import 'add_contact_page.dart';

class ContactTab extends StatefulWidget {
  final int? customerId;
  final String? customerType;
  final SchoolListResponse? apiData;
  final int? type;
  final String? action;

  const ContactTab(
      {super.key,
      required this.customerId,
      required this.apiData,
      required this.type,
      required this.action,
      required this.customerType});

  @override
  State<ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<ContactTab>
    with AutomaticKeepAliveClientMixin {
  String? title;
  int? customerId;

  @override
  void initState() {
    customerId = widget.customerId;
    SchoolDetailsNew? dd;
    var schoolC = widget.apiData?.customerDetails;
    var schoolD = widget.apiData?.schoolDetails;

    if (schoolC?.isNotEmpty == true) {
      dd = schoolC?[0];
    } else if (schoolD?.isNotEmpty == true) {
      dd = schoolD?[0];
    }

    print('object validationStatus:: ${dd?.validationStatus}');

    if (dd?.validationStatus?.toLowerCase() == 'y' ||
        dd?.validationStatus?.toLowerCase() == 'yes') {
      if (widget.type == 1) {
        title = 'Add New Teacher';
      } else if (widget.type == 2) {
        title = 'Add New Contact';
      } else if (widget.type == 3) {
        title = 'Add New Contact';
      }
    }

    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  final StreamController<List<ContactModel>?> _loadDataStream =
      BehaviorSubject();

  onPostFrameCallback(BuildContext context) {
    ApiService service1 = ApiService();
    if (widget.customerId != null && widget.customerId != 0) {
      service1
          .getContactList(
              widget.customerId!, widget.customerType, widget.action)
          .then((data) {
        var contactList = data?.contactList ?? [];
        _loadDataStream.sink.add(contactList);
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        AddButtonWidget(
            w: 200,
            field: 'List Of Contacts',
            title: title ?? '',
            onPressed: () {
              WidgetUtils.launchScreen(
                context,
                AddContactPage(
                  apiData: widget.apiData,
                  type: widget.type,
                  customerType: widget.customerType,
                  teacher: null,
                  customerId: widget.customerId,
                  validated: AppUtils.onlyChar(widget.action),
                ),
              );
            }),
        SizedBox(
          height: 15,
        ),
        StreamBuilder<List<ContactModel>?>(
            stream: _loadDataStream.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var data = snapshot.data;
                return _widgetList(data);
              }
              return Text(
                'No contact here.',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
              );
            }),
      ],
    );
  }

  Widget _widgetList(List<ContactModel>? contactList) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 0),
      scrollDirection: Axis.vertical,
      itemCount: contactList?.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var teacher = contactList?[index];
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Text(
                teacher?.contactName?.trim() ?? '',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    color: Colors.black),
              ),
              teacher?.designation == null ||
                      teacher?.designation?.isEmpty == true
                  ? SizedBox()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          teacher?.designation!.trim() ?? 'NA',
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: Colors.black),
                        ),
                      ],
                    ),
              teacher?.mobile == null || teacher?.mobile?.isEmpty == true
                  ? SizedBox()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          teacher?.mobile ?? 'NA',
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: Colors.black),
                        ),
                      ],
                    ),
              teacher?.email == null || teacher?.email?.isEmpty == true
                  ? SizedBox()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          teacher?.email?.trim() ?? 'NA',
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: Colors.black),
                        ),
                      ],
                    ),
              SizedBox(
                height: 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Contact',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Colors.black),
                        ),
                        Text(
                          teacher?.primaryContact ?? 'NA',
                          style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 17,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      WidgetUtils.launchScreen(
                        context,
                        AddContactPage(
                          apiData: widget.apiData,
                          type: widget.type,
                          customerType: widget.customerType,
                          teacher: teacher,
                          customerId: widget.customerId,
                          validated: AppUtils.onlyChar(widget.action),
                        ),
                      );
                    },
                    icon: Icon(size: 20, Icons.edit),
                  ),
                  teacher?.primaryContact!.contains('Y') == false
                      ? IconButton(
                          onPressed: () {
                            ApiService service = ApiService();
                            service
                                .deleteContact(customerId, teacher?.edit, 12,
                                    widget.customerType)
                                .then((data) {
                              if (data) {
                                contactList?.remove(teacher);
                                setState(() {});
                              }
                            });
                          },
                          icon: Icon(color: Colors.red, size: 20, Icons.delete),
                        )
                      : SizedBox(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
