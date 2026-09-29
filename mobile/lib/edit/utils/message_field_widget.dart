import 'package:flutter/material.dart';

import 'color_constants.dart';

class MessageFieldWidget extends StatefulWidget {
  final TextInputAction? textInputAction;
  final TextEditingController controller;
  final FocusNode? preNode;
  final FocusNode? nextNode;
  final String error;
  final String? hint;
  final String? field;
  final String? required;
  final int? maxLength;
  final int? maxLines;
  final bool? autoFocus;
  final Function(String value) onTypeChange;
  final TextCapitalization? textCapitalization;

  MessageFieldWidget(
      {required this.preNode,
      required this.nextNode,
      this.textInputAction = TextInputAction.done,
      required this.controller,
      required this.error,
      this.hint,
      this.field = '',
      this.required = '',
      this.maxLines = 5,
      this.maxLength = 200,
      this.autoFocus = false,
      this.textCapitalization = TextCapitalization.sentences,
      required this.onTypeChange});

  @override
  _MessageFieldWidgetState createState() => _MessageFieldWidgetState();
}

class _MessageFieldWidgetState extends State<MessageFieldWidget> {
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          height: 5,
        ),
        Scrollbar(
          thumbVisibility: true,
          controller: scrollController,
          child: TextFormField(
            scrollController: scrollController,
            scrollPadding: EdgeInsets.zero,
            autofocus: widget.autoFocus ?? false,
            focusNode: widget.preNode,
            onChanged: (value) {
              widget.onTypeChange(value);
            },
            onTapOutside: (PointerDownEvent event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            onEditingComplete: () {
              if (widget.nextNode == null) {
                FocusScope.of(context).unfocus();
              } else {
                FocusScope.of(context).requestFocus(widget.nextNode);
              }
            },
            textCapitalization: widget.textCapitalization ?? TextCapitalization.sentences,
            cursorColor: AppColor.color_0A1B35,
            keyboardAppearance: Brightness.light,
            keyboardType: TextInputType.multiline,
            maxLines: widget.maxLines ?? 5,
            maxLength: widget.maxLength ?? 500,
            controller: widget.controller,
            textAlign: TextAlign.start,
            style: TextStyle(color: AppColor.color_0A1B35, fontSize: 15),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.only(left: 20, right: 20, top: 13, bottom: 13),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: widget.error == '' ? AppColor.color_737373 : AppColor.red,
                    width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColor.color_DADADA, width: 1),
              ),
              filled: true,
              hintStyle: const TextStyle(color: AppColor.color_BBBBBB, fontSize: 15),
              hintText: widget.hint,
              fillColor: AppColor.white,
            ),
          ),
        ),
      ],
    );
  }
}
