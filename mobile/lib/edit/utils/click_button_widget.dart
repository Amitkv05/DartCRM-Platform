import 'package:flutter/material.dart';
import '../model/schoolUpdate/StateResponse.dart';
import 'ValueModel.dart';
import 'color_constants.dart';
import 'widgetUtils.dart';

class ClickButtonWidget extends StatefulWidget {
  final Function(StateResponse? data) onSelected;
  final double? width;
  final String? hint;
  final String? field;
  final String? value;
  final String? required;
  final List<StateResponse>? resourceList;

  ClickButtonWidget({
    super.key,
    this.hint = '',
    this.field = '',
    this.required = '',
    this.value = '',
    this.width,
    required this.resourceList,
    required this.onSelected,
  });

  @override
  _ClickButtonWidgetState createState() => _ClickButtonWidgetState();
}

class _ClickButtonWidgetState extends State<ClickButtonWidget> {
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          height: 12,
        ),
        Row(
          children: [
            Text(
              widget.field ?? '',
              style: TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              widget.required ?? '',
              style:
                  TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.red),
            ),
          ],
        ),
        SizedBox(
          height: 4,
        ),
        SizedBox(
          width: widget.width ?? w,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              elevation: 10,
              backgroundColor: AppColor.white,
              side: BorderSide(width: 1, color: AppColor.color_DADADA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onPressed: () {
              WidgetUtils().identificationDialog(
                  context, 'Select ${widget.field}', widget.resourceList,
                  onSelected: widget.onSelected);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value == '' || widget.value == null
                        ? 'Select ${widget.field}'
                        : widget.value ?? '',
                    style: TextStyle(
                      color: widget.value == '' || widget.value == null
                          ? AppColor.color_B0B0B0
                          : AppColor.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.value == '' ? AppColor.color_B0B0B0 : AppColor.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
