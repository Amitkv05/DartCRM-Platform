import 'dart:async';

import 'package:dart_crm/edit/model/schoolUpdate/StateResponse.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/edit/utils/string_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import '../model/school/SchoolListResponse.dart';
import 'ValueModel.dart';
import 'click_button_widget.dart';
import 'color_constants.dart';
import 'fill_button_widget.dart';
import 'list_bottom_sheet.dart';
import 'message_field_widget.dart';

class AddMoreDropWidget extends StatefulWidget {
  final String field;
  final String required;
  final SchoolListResponse? apiData;

  final int? type;

  final Function(List<StateResponse>? tags) callback;

  const AddMoreDropWidget({
    super.key,
    required this.field,
    required this.type,
    this.required = '',
    required this.apiData,
    required this.callback,
  });

  @override
  State<AddMoreDropWidget> createState() => _AddMoreDropWidgetState();
}

class _AddMoreDropWidgetState extends State<AddMoreDropWidget> {
  final StreamController<List<StateResponse>?> _tagStream = BehaviorSubject();
  List<StateResponse>? tagList = [];
  List<StateResponse>? accountable = [];

  @override
  void initState() {
    super.initState();

    print('widget.apiData ${widget.apiData?.schoolDetails?.length}');

    if (widget.type == 1) {
      var school = AppUtils.getSchool(widget.apiData);
      var trade = AppUtils.getTrade(widget.apiData);
      // String? d = school?.xmlAccountTableExecutiveId ?? '';
      String? d = (school?.xmlAccountTableExecutiveId != null &&
              school!.xmlAccountTableExecutiveId!.isNotEmpty)
          ? school.xmlAccountTableExecutiveId!
          : trade?.xmlAccountTableExecutiveId ?? '';
      BOARD_DATA?.accountableExecutive?.forEach((e) {
        var s = StateResponse();
        s.text = e.executiveName;
        s.value = e.sNo;
        accountable?.add(s);
      });

      accountable?.forEach((ee) {
        var id = ee.value;
        var ff = d.contains('$id');
        if (ff) {
          tagList?.add(ee);
        }
      });
      print('tagList ${tagList?.length}');

      _tagStream.sink.add(tagList);
    } else if (widget.type == 2) {
      var trade = AppUtils.getTrade(widget.apiData);
      String? d = trade?.xmlCustomerCategoryId ?? '';
      BOARD_DATA?.customerCategory?.forEach((e) {
        var s = StateResponse();
        s.text = e.customerCategoryName;
        s.value = e.customerCategoryId;
        accountable?.add(s);
      });

      accountable?.forEach((ee) {
        var id = ee.value;
        var ff = d.contains('$id');
        if (ff) {
          tagList?.add(ee);
        }
      });
      _tagStream.sink.add(tagList);
    } else if (widget.type == 3) {
      BOARD_DATA?.classes?.forEach((e) {
        var s = StateResponse();
        s.text = e.className;
        s.value = e.classNumId;
        accountable?.add(s);
      });
      _tagStream.sink.add(tagList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 15,
        ),
        Row(
          children: [
            Text(
              widget.field,
              style: TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              widget.required,
              style:
                  TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.red),
            ),
            Spacer(
              flex: 1,
            ),
            FillButtonWidget(
              height: 40,
              width: 100,
              title: 'Add',
              bgColor: AppColor.color_4285F4,
              onPressed: () async {
                sendBottomSheet();
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, top: 1),
          child: StreamBuilder<List<StateResponse>?>(
              stream: _tagStream.stream,
              builder: (context, snapshot) {
                var list = snapshot.data;
                widget.callback(list);
                return Wrap(children: _buildRowList(list));
              }),
        ),
      ],
    );
  }

  List<Widget> _buildRowList(List<StateResponse>? data) {
    List<Widget> lines = [];
    data?.forEach((element) {
      lines.add(_widgetChip1(element));
    });

    return lines;
  }

  Widget _widgetChip1(StateResponse data) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 6),
      child: InkWell(
        onTap: () {
          tagList?.remove(data);
          _tagStream.sink.add(tagList);
        },
        child: Container(
          padding: EdgeInsets.only(left: 12, top: 6, right: 12, bottom: 6),
          height: 32,
          decoration: BoxDecoration(
            color: AppColor.color_DADADA,
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.text ?? '',
                style: TextStyle(fontSize: 13, color: AppColor.black),
              ),
              SizedBox(
                width: 6,
              ),
              Icon(Icons.close, color: Colors.black, size: 20)
            ],
          ),
        ),
      ),
    );
  }

/* Widget _widgetField(String name) {
    return TextField(
      focusNode: nameNode,
      onChanged: (value) {},
      onTapOutside: (PointerDownEvent event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
      },
      textCapitalization: TextCapitalization.words,
      cursorColor: AppColor.black,
      keyboardAppearance: Brightness.light,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      maxLines: 1,
      maxLength: 50,
      controller: nameController,
      style: const TextStyle(
        color: AppColor.black,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        counterText: '',
        contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColor.color_737373,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.color_DADADA, width: 1),
        ),
        filled: true,
        labelText: null,
        hintStyle: const TextStyle(
          color: AppColor.color_B0B0B0,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        hintText: 'Enter $name',
        isCollapsed: true,
        fillColor: AppColor.white,
      ),
    );
  }*/

  void sendBottomSheet() {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StringBottomSheet(
          list: accountable ?? [],
          onItemClick: (value) {
            tagList?.add(value);
            tagList = AppUtils.removeDuplicateAccount(tagList);
            _tagStream.sink.add(tagList);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
