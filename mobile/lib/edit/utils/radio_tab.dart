import 'package:flutter/material.dart';

import '../model/schoolUpdate/StateResponse.dart';

class RadioTab extends StatefulWidget {
  final String field;
  final String required;
  final double size;
  final List<StateResponse> resource;
  final StateResponse? selectedOption;
  final Function(StateResponse? selected) callback;

  RadioTab({
    super.key,
    required this.field,
    required this.callback,
    required this.selectedOption,
    this.required = '',
    this.size = 80,
    required this.resource,
  });

  @override
  State<RadioTab> createState() => _RadioTabState();
}

class _RadioTabState extends State<RadioTab> {
  StateResponse? _selectedOption;

  @override
  void initState() {
    _selectedOption = widget.selectedOption;
    super.initState();
    setState(() {});
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
          ],
        ),
        SizedBox(
          height: widget.size,
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 4,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: widget.resource.map((option) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedOption = option;
                    widget.callback(option);
                  });
                },
                child: Row(
                  children: [
                    Radio<StateResponse>(
                      visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      value: option,
                      groupValue: _selectedOption,
                      onChanged: (StateResponse? value) {
                        setState(() {
                          _selectedOption = value;
                          widget.callback(value);
                        });
                      },
                    ),
                    Expanded(child: Text(option.label ?? '')),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
