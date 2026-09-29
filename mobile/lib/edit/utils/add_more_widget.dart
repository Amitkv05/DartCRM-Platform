import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import 'ValueModel.dart';
import 'click_button_widget.dart';
import 'color_constants.dart';
import 'fill_button_widget.dart';
import 'list_bottom_sheet.dart';
import 'message_field_widget.dart';

class AddMoreWidget extends StatefulWidget {
  final String field;
  final String required;

  AddMoreWidget({
    super.key,
    required this.field,
    this.required = '',
  });

  @override
  State<AddMoreWidget> createState() => _AddMoreWidgetState();
}

class _AddMoreWidgetState extends State<AddMoreWidget> {
  TextEditingController nameController = TextEditingController();
  final StreamController<List<ValueModel>?> _tagStream = BehaviorSubject();
  List<ValueModel>? tagList = [];
  FocusNode nameNode = FocusNode();

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
          ],
        ),
        SizedBox(
          height: 6,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _widgetField(widget.field)),
            SizedBox(
              width: 10,
            ),
            FillButtonWidget(
              height: 40,
              width: 80,
              title: 'Add',
              bgColor: AppColor.color_4285F4,
              onPressed: () async {
                var name = nameController.text.trim();

                if (name.isNotEmpty) {
                  var s = ValueModel();
                  s.name = name;
                  tagList?.add(s);
                  _tagStream.sink.add(tagList);
                  nameController.text = '';
                }
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, top: 1),
          child: StreamBuilder<List<ValueModel>?>(
              stream: _tagStream.stream,
              builder: (context, snapshot) {
                var list = snapshot.data;
                return Wrap(children: _buildRowList(list));
              }),
        ),
      ],
    );
  }

  List<Widget> _buildRowList(List<ValueModel>? data) {
    List<Widget> lines = [];
    data?.forEach((element) {
      lines.add(_widgetChip1(element));
    });

    return lines;
  }

  Widget _widgetChip1(ValueModel data) {
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
                data.name ?? '',
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

  Widget _widgetField(String name) {
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
  }
}
