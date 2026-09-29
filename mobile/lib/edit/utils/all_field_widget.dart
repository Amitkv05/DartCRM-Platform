import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_constants.dart';
import 'widgetUtils.dart';

class AllFieldWidget extends StatefulWidget {
  final TextInputAction? textInputAction;
  final TextEditingController controller;
  final String field;
  final String required;
  final FocusNode? preNode;
  final FocusNode? nextNode;
  final bool? readOnly;
  final int format;
  final int? max;
  final Function(String value) onTypeChange;

  AllFieldWidget({
    this.textInputAction = TextInputAction.next,
    this.format = FORMAT.ALL,
    required this.controller,
    required this.field,
    required this.preNode,
    required this.nextNode,
    this.readOnly = false,
    this.required = '',
    this.max = 100,
    required this.onTypeChange,
  });

  @override
  _AllFieldWidgetState createState() => _AllFieldWidgetState();
}

class _AllFieldWidgetState extends State<AllFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        _widgetField(widget.field, widget.preNode, widget.nextNode, widget.readOnly),
      ],
    );
  }

  Widget _widgetField(
    String name,
    FocusNode? preNode,
    FocusNode? nextNode,
    bool? readOnly,
  ) {
    return TextField(
      focusNode: preNode,
      onChanged: (value) {
        widget.onTypeChange(value);
      },
      onTapOutside: (PointerDownEvent event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onEditingComplete: () {
        if (nextNode == null) {
          FocusScope.of(context).unfocus();
        } else {
          FocusScope.of(context).requestFocus(nextNode);
        }
      },
      inputFormatters: getFormat(),
      textCapitalization: getTextCapitalization(),
      cursorColor: AppColor.black,
      keyboardAppearance: Brightness.light,
      keyboardType: getKeyboardType(),
      textInputAction: nextNode == null ? TextInputAction.done : TextInputAction.next,
      maxLines: 1,
      maxLength: widget.max,
      readOnly: readOnly ?? false,
      controller: widget.controller,
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
        fillColor: readOnly == true ? AppColor.color_DADADA : AppColor.white,
      ),
    );
  }

  TextInputType getKeyboardType() {
    if (widget.format == FORMAT.ALL) {
      return TextInputType.text;
    } else if (widget.format == FORMAT.EMAIL) {
      return TextInputType.emailAddress;
    } else if (widget.format == FORMAT.DIGIT) {
      return TextInputType.number;
    } else if (widget.format == FORMAT.PHONE) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  TextCapitalization getTextCapitalization() {
    if (widget.format == FORMAT.ALL) {
      return TextCapitalization.words;
    } else if (widget.format == FORMAT.EMAIL) {
      return TextCapitalization.none;
    } else if (widget.format == FORMAT.DIGIT) {
      return TextCapitalization.sentences;
    } else if (widget.format == FORMAT.PHONE) {
      return TextCapitalization.sentences;
    } else if (widget.format == FORMAT.CAP) {
      return TextCapitalization.characters;
    }
    return TextCapitalization.words;
  }

  List<TextInputFormatter>? getFormat() {
    if (widget.format == FORMAT.ALL) {
      return null;
    } else if (widget.format == FORMAT.EMAIL) {
      return null;
    } else if (widget.format == FORMAT.DIGIT) {
      return [FilteringTextInputFormatter.digitsOnly];
    } else if (widget.format == FORMAT.PHONE) {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return null;
  }
}
