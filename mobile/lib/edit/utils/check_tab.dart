import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import 'ValueModel.dart';
import 'click_button_widget.dart';
import 'list_bottom_sheet.dart';
import 'message_field_widget.dart';

class CheckTab extends StatefulWidget {
  final String field;
  final String required;
  final double size;
  final int count;
  final List<String> resource;

  CheckTab({
    super.key,
    required this.field,
    this.required = '',
    this.count = 3,
    this.size = 80,
    required this.resource,
  });

  @override
  State<CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<CheckTab> {
  Set<String> _selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 15,
        ),
        widget.field == ''
            ? SizedBox()
            : Row(
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
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13, color: Colors.red),
                  ),
                ],
              ),
        SizedBox(
          height: widget.size,
          child: GridView.count(
            crossAxisCount: widget.count,
            childAspectRatio: 4,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: widget.resource.map((option) {
              return InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedOptions.contains(option)) {
                      _selectedOptions.remove(option);
                    } else {
                      _selectedOptions.add(option);
                    }
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectedOptions.contains(option),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedOptions.add(option);
                          } else {
                            _selectedOptions.remove(option);
                          }
                        });
                      },
                      visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    Expanded(child: Text(option)),
                  ],
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }
}
