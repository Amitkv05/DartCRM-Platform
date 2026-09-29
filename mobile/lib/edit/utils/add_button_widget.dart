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

class AddButtonWidget extends StatefulWidget {
  final String field;
  final String? title;
  final String required;
  final double w;
  final VoidCallback onPressed;

  const AddButtonWidget({
    super.key,
    this.w = 170,
    required this.field,
    this.required = '',
    required this.title,
    required this.onPressed,
  });

  @override
  State<AddButtonWidget> createState() => _AddButtonWidgetState();
}

class _AddButtonWidgetState extends State<AddButtonWidget> {
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
            widget.title == null || widget.title == ''
                ? SizedBox()
                : FillButtonWidget(
                    height: 40,
                    width: widget.w,
                    bgColor: AppColor.colorBlue,
                    title: widget.title ?? '',
                    onPressed: () async {
                      widget.onPressed();
                    },
                  ),
          ],
        ),
      ],
    );
  }
}
