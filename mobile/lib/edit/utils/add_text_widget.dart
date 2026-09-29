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

class AddTextWidget extends StatefulWidget {
  final String field;

  const AddTextWidget({
    super.key,
    required this.field,
  });

  @override
  State<AddTextWidget> createState() => _AddTextWidgetState();
}

class _AddTextWidgetState extends State<AddTextWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          textAlign: TextAlign.start,
          widget.field,
          style:
              TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: AppColor.black),
        ),
      ],
    );
  }
}
