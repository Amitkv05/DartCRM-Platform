import 'package:flutter/material.dart';
import '../model/schoolUpdate/StateResponse.dart';
import 'ValueModel.dart';
import 'color_constants.dart';
import 'widgetUtils.dart';

class CrossButtonWidget extends StatefulWidget {
  final Function(StateResponse? data) onSelected;
  final Function() onRemove;
  final double? width;
  final String? hint;
  final String? field;
  final String? value;
  final String? required;
  final List<StateResponse>? resourceList;

  CrossButtonWidget({
    super.key,
    this.hint = '',
    this.field = '',
    this.required = '',
    this.value = '',
    this.width,
    required this.resourceList,
    required this.onSelected,
    required this.onRemove,
  });

  @override
  _CrossButtonWidgetState createState() => _CrossButtonWidgetState();
}

class _CrossButtonWidgetState extends State<CrossButtonWidget> {
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          height: 8,
        ),
        Row(
          children: [
            Text(
              widget.field ?? '',
              style: TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black),
            ),
            SizedBox(
              width: 5,
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
          width: w,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              // Removes all padding including end
              minimumSize: Size(0, 0),
              // Optional: allow the button to shrink
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 10,
              side: BorderSide(width: 0.3, color: AppColor.black),
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
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Text(
                    widget.value == '' || widget.value == null
                        ? 'Select ${widget.field}'
                        : widget.value ?? '',
                    style: TextStyle(
                      color: widget.value == '' || widget.value == null
                          ? AppColor.color_56595D
                          : AppColor.black,
                      fontWeight: FontWeight.w400,
                      fontSize: widget.value == '' || widget.value == null ? 14 : 15,
                    ),
                  ),
                ),
                widget.value == '' || widget.value == null
                    ? SizedBox()
                    : IconButton(
                        onPressed: () {
                          widget.onRemove();
                        },
                        icon: Icon(
                          Icons.highlight_remove,
                          color: AppColor.black,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
